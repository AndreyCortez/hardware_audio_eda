import os
import sys
import numpy as np
from scipy.io import wavfile
import schemdraw
import schemdraw.elements as elm
from PySpice.Spice.Netlist import Circuit
import PySpice.Logging.Logging as Logging

logger = Logging.setup_logging(logging_level='WARNING')

# 1. DATA STRUCTURE CORE (Single Source of Truth)
component_data = {
    'power': {'spice_val': 9, 'label': '9V', 'spec': '9V DC Power Supply'},
    'r_pulldown': {'spice_val': '2.2Meg', 'label': '2.2Meg', 'spec': '1/4W Metal Film'},
    'c_input': {'spice_val': '0.1u', 'label': '0.1u', 'spec': 'Min 16V Polyester'},
    'q_buffer': {'spice_val': '2N3904', 'label': '2n3904', 'spec': 'NPN BJT'},
    'r_buf_emit': {'spice_val': '10k', 'label': '10k', 'spec': '1/4W Metal Film'},
    'c_buf_out': {'spice_val': '0.1u', 'label': '0.1u', 'spec': 'Min 16V Polyester'},
    'r_bias': {'spice_val': '2.2Meg', 'label': '2.2Meg', 'spec': '1/4W Metal Film'},
    'q_drive': {'spice_val': '2N3904', 'label': '2n3904', 'spec': 'NPN BJT'},
    'r_col': {'spice_val': '4.7k', 'label': '4.7k', 'spec': '1/4W Metal Film'},
    'r_safety': {'spice_val': '100', 'label': '100', 'spec': '1/4W Metal Film'},
    'pot_drive': {'spice_val': '1k', 'label': '1k_drive', 'spec': '1k Linear (1kB)'},
    'c_out': {'spice_val': '0.1u', 'label': '0.1u', 'spec': 'Min 16V Polyester'},
    'd_clip_1': {'spice_val': '1N4148', 'label': '1n4148', 'spec': 'Silicon Diode'},
    'd_clip_2': {'spice_val': '1N4148', 'label': '1n4148', 'spec': 'Silicon Diode'},
    'pot_vol': {'spice_val': '100k', 'label': '100k_vol', 'spec': '100k Log (100kA)'}
}

# 2. MOTOR DE RENDERIZAÇÃO VISUAL (Schemdraw)
def render_schematic(filename='pedal_unified.svg'):
    print(f"[Schemdraw] Gerando esquemático em: {filename}")
    with schemdraw.Drawing(file=filename) as drawing:
        drawing += elm.Dot().label('input')
        drawing.push()
        drawing += elm.Resistor().down().label(component_data['r_pulldown']['label'])
        drawing += elm.Ground()
        drawing.pop()
        drawing += elm.Capacitor().right().label(component_data['c_input']['label'])
        
        q_buffer = drawing.add(elm.BjtNpn(anchor='base').label(component_data['q_buffer']['label']))
        drawing.push()
        drawing += elm.Vdd().at(q_buffer.collector).label(component_data['power']['label'])
        drawing.pop()
        drawing += elm.Resistor().down().at(q_buffer.emitter).label(component_data['r_buf_emit']['label'])
        drawing += elm.Ground()
        drawing += elm.Capacitor().right().at(q_buffer.emitter).label(component_data['c_buf_out']['label'])
        
        drawing.push()
        drawing += elm.Resistor().up().label(component_data['r_bias']['label'])
        drawing += elm.Vdd().label(component_data['power']['label'])
        drawing.pop()
        
        q_drive = drawing.add(elm.BjtNpn(anchor='base').label(component_data['q_drive']['label']))
        drawing.push()
        drawing += elm.Resistor().up().at(q_drive.collector).label(component_data['r_col']['label'])
        drawing += elm.Vdd().label(component_data['power']['label'])
        drawing.pop()
        
        drawing.push()
        drawing += elm.Resistor().down().at(q_drive.emitter).label(component_data['r_safety']['label'])
        drawing += elm.Potentiometer().down().label(component_data['pot_drive']['label'])
        drawing += elm.Ground()
        drawing.pop()
        
        drawing += elm.Capacitor().right().at(q_drive.collector).label(component_data['c_out']['label'])
        
        drawing.push()
        drawing += elm.Diode().down().label(component_data['d_clip_1']['label'])
        drawing += elm.Ground()
        drawing.pop()
        
        drawing += elm.Line().right().length(2)
        drawing.push()
        drawing += elm.Diode().down().reverse().label(component_data['d_clip_2']['label'])
        drawing += elm.Ground()
        drawing.pop()
        
        drawing += elm.Line().right().length(2)
        drawing.push()
        drawing += elm.Potentiometer().down().label(component_data['pot_vol']['label'])
        drawing += elm.Ground()
        drawing.pop()
        
        # Vol wiper is output
        drawing += elm.Line().right().length(2)
        drawing += elm.Dot().label('output')

# 3. EXTRATOR DE BOM
def export_bom(filename='bom_unified.txt'):
    print(f"[BOM Inspector] Verificando tolerâncias críticas e exportando BOM para: {filename}")
    with open(filename, 'w') as file:
        file.write("BOM - Unified Overdrive Pedal (100% Python Generated)\n")
        file.write("=====================================================\n")
        for key, data in component_data.items():
            if '1/4W' not in data['spec'] and 'r_' in key:
                print(f"ALERTA DE SEGURANÇA: Resistor {key} não possui especificação de potência (1/4W)!")
            if '16V' not in data['spec'] and 'c_' in key:
                print(f"ALERTA DE SEGURANÇA: Capacitor {key} não possui voltagem de ruptura definida para operar em barramento 9V!")
            
            line = f"{key.ljust(15)} : {str(data['spice_val']).ljust(10)} | Spec: {data['spec']}\n"
            file.write(line)

# 4. MOTOR DE PROCESSAMENTO DSP E SIMULAÇÃO ANALÓGICA (SciPy & Ngspice)
def simulate_audio(input_file='input.wav', output_file='output.wav', 
                  drive_pot_val=0.1, vol_pot_val=0.5):
    """
    drive_pot_val: 0.1 a 1000 (Ohms). 0.1 = distorção máxima (resistor safety age)
    vol_pot_val: 0.0 a 1.0. 1.0 = volume máximo do cursor
    """
    
    # 4.1 Carregar ou gerar áudio digital
    if not os.path.exists(input_file):
        print(f"[DSP Module] Arquivo {input_file} não encontrado. Gerando um tom de teste estéreo a 440Hz com decaimento...")
        sample_rate = 44100
        t = np.linspace(0, 1, sample_rate, False)
        # Tom limpo, nível de instrumento (~0.1Vp)
        audio_data = (0.1 * np.sin(2 * np.pi * 440 * t) * np.exp(-3*t)).astype(np.float32)
        wavfile.write(input_file, sample_rate, audio_data)
        
    print(f"[DSP Module] Lendo áudio PCM: {input_file}")
    sample_rate, ds_audio = wavfile.read(input_file)
    
    # Normalizações se a origem não for float
    if ds_audio.dtype == np.int16:
        ds_audio = ds_audio / 32768.0
    elif ds_audio.dtype == np.int32:
        ds_audio = ds_audio / 2147483648.0
    
    # Stereo para Mono
    if len(ds_audio.shape) > 1:
        print("[DSP Module] Convertendo input esteréo para mono.")
        ds_audio = ds_audio.mean(axis=1)
        
    duration = len(ds_audio) / sample_rate
    print(f"[DSP Module] Duração do sinal: {duration:.3f}s. Taxa de amostragem: {sample_rate}Hz.")
    
    # Array de Tempo
    time_array = np.linspace(0, duration, len(ds_audio))
    # PySpice espera uma lista de pares iteráveis [(t, v), (t, v)...]
    pwl_values = np.column_stack((time_array, ds_audio)).tolist()
    
    # 4.2 Construção do Circuito PySpice
    print("[Ngspice] Construindo Topologia e Netlist...")
    circuit = Circuit('Unified Overdrive Pedal Process')
    circuit.model('2N3904', 'npn', is_='1e-14', vaf='100', bf='300', tf='0.3e-9', cjc='4e-12', cje='8e-12')
    circuit.model('1N4148', 'd', is_='2.52e-9', rs='0.568', n='1.752', cjo='4e-12', m='0.333', vj='0.5')
    
    # Alimentação VDC e PWL Source
    circuit.V('power', 'v_cc', circuit.gnd, component_data['power']['spice_val'])
    
    # Injecting PWL with explicit + continuation lines to bypass line length limits
    v_signal_str = "Vsignal in_node 0 PWL"
    points = []
    for t, v in pwl_values:
        points.append(f"{t:.6e} {v:.6f}")
        if len(points) >= 10:
            v_signal_str += "\n+ " + " ".join(points)
            points = []
    if points:
        v_signal_str += "\n+ " + " ".join(points)
    circuit.raw_spice = v_signal_str
    
    # INPUT BUFFER MATCHING
    circuit.R('pulldown', 'in_node', circuit.gnd, component_data['r_pulldown']['spice_val'])
    circuit.C('input', 'in_node', 'buf_base', component_data['c_input']['spice_val'])
    circuit.BJT('buffer', 'v_cc', 'buf_base', 'buf_emit', model='2N3904')
    circuit.R('buf_emit', 'buf_emit', circuit.gnd, component_data['r_buf_emit']['spice_val'])
    circuit.C('buf_out', 'buf_emit', 'drive_base', component_data['c_buf_out']['spice_val'])
    
    # GAIN STAGE
    circuit.R('bias', 'v_cc', 'drive_base', component_data['r_bias']['spice_val'])
    circuit.BJT('drive', 'drive_col', 'drive_base', 'drive_emit', model='2N3904')
    circuit.R('col', 'v_cc', 'drive_col', component_data['r_col']['spice_val'])
    circuit.R('safety', 'drive_emit', 'pot_node', component_data['r_safety']['spice_val'])
    
    # DRIVE POTENTIOMETER (Simulado como Rheostat)
    # Validações de segurança e resistência no emissor
    if drive_pot_val <= 0: drive_pot_val = 0.001 
    circuit.R('drive_pot', 'pot_node', circuit.gnd, str(drive_pot_val))
    
    # DC BLOCKING
    circuit.C('out', 'drive_col', 'out_node_pre_clip', component_data['c_out']['spice_val'])
    
    # CLIPPING DIODE STAGE
    circuit.Diode('clip_1', 'out_node_pre_clip', circuit.gnd, model='1N4148')
    circuit.Diode('clip_2', circuit.gnd, 'out_node_pre_clip', model='1N4148')
    
    # VOLUME POTENTIOMETER (Simulado como Divisor de Tensão)
    vol_pot_total = 100000.0 # 100k
    r_top = max(1.0, vol_pot_total * (1.0 - vol_pot_val))
    r_bot = max(1.0, vol_pot_total * vol_pot_val)
    circuit.R('vol_top', 'out_node_pre_clip', 'out_node', str(r_top))
    circuit.R('vol_bot', 'out_node', circuit.gnd, str(r_bot))

    with open('pedal_unified.cir', 'w') as file:
        file.write(str(circuit))
        
    print("[Ngspice] Resolvendo equações diferenciais para transient response... (isso pode demorar)")
    # 4.3 Solver Ngspice
    simulator = circuit.simulator(temperature=25, nominal_temperature=25, simulator='ngspice-subprocess')
    # Acelerar step de análise: Em vez de capturar toda a onda perfeitamente (demora muito para longos PWL), 
    # mantemos o step cravado no inverso de sample rate.
    analysis = simulator.transient(step_time=1.0/sample_rate, end_time=duration)
    
    raw_out = np.array(analysis.out_node)
    sim_time = np.array(analysis.time)
    
    print("[Ngspice] Simulação concluída.")
    
    # 4.4 Resampling e Normalização DC
    print("[DSP Module] Interpolando e removendo Componente DC do sinal...")
    
    # Ngspice pode ajustar transientes (pontos fora da malha). Interpolamos de volta pra malha fixa 44.1Khz.
    resampled_out = np.interp(time_array, sim_time, raw_out)
    
    # Remoção do Offset (DC Tuning Preventivo contra clipping destrutivo na master)
    dc_offset = np.mean(resampled_out)
    resampled_out -= dc_offset
    print(f"[DSP Module] DC offset corrigido em {-dc_offset:.4f}V.")
    
    # Normalização em ponto flutuante para preservar faixa dinâmica máxima tolerável de áudio sem quebrar os falantes
    peak = np.max(np.abs(resampled_out))
    if peak > 0:
        target_headroom = 0.9 # -0.9dB ~ -1dB True Peak
        resampled_out = (resampled_out / peak) * target_headroom

    print(f"[DSP Module] Exportando pipeline masterizado ({target_headroom*100}% T-Peak) para {output_file}...")
    wavfile.write(output_file, sample_rate, resampled_out.astype(np.float32))


def run():
    print("=========================================================")
    print(" UNIFIED FRAMEWORK OVERDRIVE PEDAL - VIRTUAL PROTOTYPING ")
    print("=========================================================")
    export_bom()
    render_schematic()
    
    # Simula com drive no máximo (~0 Ohms de resistência variável no emissor, deixando apenas r_safety)
    simulate_audio(input_file='input_guitar.wav', output_file='output_overdrive_max.wav', drive_pot_val=0.1, vol_pot_val=1.0)
    
    print("=========================================================")
    print(" PROCESSO INTEIRAMENTE FINALIZADO. ")
    print(" Verifique os diretórios para esquema iterativo (.svg) e gravação destrutiva (.wav)")

if __name__ == '__main__':
    run()
