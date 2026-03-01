import io
import os
import tempfile
import numpy as np
import scipy.io.wavfile as wav
from fastapi import FastAPI, File, UploadFile, Form
from fastapi.responses import Response
from fastapi.middleware.cors import CORSMiddleware
from PySpice.Spice.Netlist import Circuit
from PySpice.Spice.NgSpice.Shared import NgSpiceCommandError

# Configure PySpice environment for Linux Docker
os.environ['NGSPICE_COMMAND'] = 'ngspice'

app = FastAPI(title="Audio EDA Backend", description="SPICE DSP Engine")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.post("/simulate")
async def simulate_audio(netlist: str = Form(...), audio: UploadFile = File(...)):
    """
    Receives a SPICE .cir string and a .wav file via Multipart form.
    Executes the Ngspice DSP simulation using ngspice-subprocess 
    to prevent memory bounds on 1M+ point PWL arrays.
    """
    # 1. Read the audio file
    audio_bytes = await audio.read()
    sample_rate, data = wav.read(io.BytesIO(audio_bytes))

    # Convert to mono float32 if necessary
    if data.ndim > 1:
        data = data[:, 0]
    if data.dtype == np.int16:
        data = data.astype(np.float32) / 32768.0

    # 2. Extract PWL Time Array
    duration = len(data) / sample_rate
    time_array = np.linspace(0, duration, len(data), endpoint=False)
    
    # Fast iteration to construct string, chunked to prevent ngspice line length bugs
    pwl_str_parts = []
    for i in range(len(data)):
        pwl_str_parts.append(f"{time_array[i]:.6e} {data[i]:.6f}")
        if i % 10 == 9 and i != len(data) - 1:
            pwl_str_parts.append("\n+")
    
    pwl_content = " ".join(pwl_str_parts)

    # 3. Construct the massive simulation netlist
    # The frontend injects standard nodes. We attach the Vsignal to Audio IN node (default 1)
    # and expect the Audio OUT to be probed (default out node 2 or specified)
    
    final_netlist = f"""{netlist}
* Audio Signal Injected by Backend
Vsignal 1 0 PWL({pwl_content})
.tran {1.0/sample_rate} {duration}
"""

    # 4. Write Netlist to temp file for subprocess execution
    with tempfile.NamedTemporaryFile(suffix='.cir', delete=False, mode='w') as f_cir:
        filepath = f_cir.name
        f_cir.write(final_netlist)
        
    try:
        # 5. Execute using PySpice's robust Subprocess engine
        import PySpice.Logging.Logging as Logging
        logger = Logging.setup_logging()
        from PySpice.Spice.NgSpice.Shared import NgSpiceShared
        from PySpice.Probe.Plot import Figure
        from PySpice.Spice.Netlist import Circuit
        from PySpice.Spice.Simulation import CircuitSimulator
        
        # In a real heavy setup, we invoke 'ngspice -b' directly to avoid PySpice wrapper bugs,
        # but here we can try using the native py package via dummy circuit
        import subprocess
        
        raw_out_path = filepath.replace('.cir', '.raw')
        
        # Append save commands to the netlist to output raw
        with open(filepath, 'a') as f_cir:
            f_cir.write(f"\n.save all\n.end\n")

        # Run ngspice batch mode
        process = subprocess.run(
            ['ngspice', '-b', '-r', raw_out_path, filepath],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )

        if process.returncode != 0:
            return Response(content=f"Simulation Failed:\n{process.stderr}", status_code=500)
            
        # 6. Parse the raw file output back to numpy using PySpice's RawFile
        from PySpice.Spice.NgSpice.RawFile import RawFile
        raw_file = RawFile(raw_out_path)
        
        # Typically the output node is 2 in our schematic, or named V(2) 
        output_voltage = None
        for v in raw_file.variables:
            if v.name == 'v(2)':
                output_voltage = v.data
                break
                
        if output_voltage is None:
            # Fallback if V(2) isn't explicitly defined, try to extract any non-source node
             for v in raw_file.variables:
                 if 'v(' in v.name and v.name != 'v(1)':
                     output_voltage = v.data
                     break
                     
        if output_voltage is None:
             return Response(content="Simulation succeeded but output node V(2) not found.", status_code=500)

        # 7. Normalize & Export Audio back to WAV
        output_audio = np.real(output_voltage).astype(np.float32)
        max_val = np.max(np.abs(output_audio))
        if max_val > 0:
            output_audio = output_audio / max_val
            
        wav_io = io.BytesIO()
        wav.write(wav_io, int(sample_rate), output_audio)
        wav_bytes = wav_io.getvalue()
        
        # Cleanup temp
        os.remove(filepath)
        if os.path.exists(raw_out_path):
            os.remove(raw_out_path)
            
        return Response(content=wav_bytes, media_type="audio/wav")

    except Exception as e:
        return Response(content=f"Internal Backend Error: {str(e)}", status_code=500)
