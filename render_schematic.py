import schemdraw
import schemdraw.elements as elm
from PySpice.Spice.Netlist import Circuit
from PySpice.Unit import *
import PySpice.Logging.Logging as Logging
import matplotlib.pyplot as plt

logger = Logging.setup_logging(logging_level='WARNING')

def get_component_data():
    return {
        'r_pulldown': {'spice_val': '2.2Meg', 'label': '2.2Meg', 'spec': '1/4W Metal Film'},
        'c_input': {'spice_val': '0.1u', 'label': '0.1u', 'spec': 'Min 16V Polyester'},
        'r_buf_bias_high': {'spice_val': '1Meg', 'label': '1Meg', 'spec': '1/4W Metal Film'},
        'r_buf_bias_low': {'spice_val': '1Meg', 'label': '1Meg', 'spec': '1/4W Metal Film'},
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

def generate_bom(component_data):
    with open('bom_unified.txt', 'w') as file:
        file.write("BOM - Unified Overdrive Pedal\n")
        file.write("="*30 + "\n")
        for key, data in component_data.items():
            line = f"{key}: {data['spice_val']} | Spec: {data['spec']}\n"
            file.write(line)

def build_spice_circuit(component_data):
    circuit = Circuit('unified_overdrive_pedal')
    
    circuit.model('2N3904', 'npn')
    circuit.model('1N4148', 'd')
    
    circuit.V('power', 'v_cc', circuit.gnd, 9)
    circuit.SinusoidalVoltageSource('signal', 'in_node', circuit.gnd, amplitude=1, frequency=1000)
    
    circuit.R('pulldown', 'in_node', circuit.gnd, component_data['r_pulldown']['spice_val'])
    circuit.C('input', 'in_node', 'buf_base', component_data['c_input']['spice_val'])
    
    circuit.R('buf_bias_high', 'v_cc', 'buf_base', component_data['r_buf_bias_high']['spice_val'])
    circuit.R('buf_bias_low', 'buf_base', circuit.gnd, component_data['r_buf_bias_low']['spice_val'])
    
    circuit.BJT('buffer', 'v_cc', 'buf_base', 'buf_emit', model='2N3904')
    circuit.R('buf_emit', 'buf_emit', circuit.gnd, component_data['r_buf_emit']['spice_val'])
    circuit.C('buf_out', 'buf_emit', 'drive_base', component_data['c_buf_out']['spice_val'])
    
    circuit.R('bias', 'v_cc', 'drive_base', component_data['r_bias']['spice_val'])
    circuit.BJT('drive', 'drive_col', 'drive_base', 'drive_emit', model='2N3904')
    circuit.R('col', 'v_cc', 'drive_col', component_data['r_col']['spice_val'])
    
    circuit.R('safety', 'drive_emit', 'pot_node', component_data['r_safety']['spice_val'])
    circuit.R('drive_pot', 'pot_node', circuit.gnd, '0.1')
    circuit.C('out', 'drive_col', 'out_node', component_data['c_out']['spice_val'])
    
    circuit.Diode('clip_1', 'out_node', circuit.gnd, model='1N4148')
    circuit.Diode('clip_2', circuit.gnd, 'out_node', model='1N4148')
    
    with open('pedal_unified.cir', 'w') as file:
        file.write(str(circuit))
        
    return circuit

def simulate_circuit(circuit):
    simulator = circuit.simulator(temperature=25, nominal_temperature=25)
    analysis = simulator.transient(step_time=10@u_us, end_time=5@u_ms)
    
    fig, ax = plt.subplots(figsize=(10, 5))
    ax.plot(analysis.time, analysis['in_node'], label='input_signal')
    ax.plot(analysis.time, analysis['out_node'], label='output_clipped')
    
    ax.set_xlabel('time')
    ax.set_ylabel('voltage')
    ax.legend()
    ax.grid()
    
    plt.savefig('simulation_plot.png')

def build_schematic(component_data):
    with schemdraw.Drawing(file='pedal_unified.svg') as drawing:
        drawing += elm.Dot().label('input')
        drawing.push()
        drawing += elm.Resistor().down().label(component_data['r_pulldown']['label'])
        drawing += elm.Ground()
        drawing.pop()
        drawing += elm.Capacitor().right().label(component_data['c_input']['label'])
        
        drawing.push()
        drawing += elm.Resistor().up().label(component_data['r_buf_bias_high']['label'])
        drawing += elm.Vdd().label('9v')
        drawing.pop()
        drawing.push()
        drawing += elm.Resistor().down().label(component_data['r_buf_bias_low']['label'])
        drawing += elm.Ground()
        drawing.pop()
        
        q_buffer = drawing.add(elm.BjtNpn(anchor='base').label(component_data['q_buffer']['label']))
        drawing.push()
        drawing += elm.Vdd().at(q_buffer.collector).label('9v')
        drawing.pop()
        drawing += elm.Resistor().down().at(q_buffer.emitter).label(component_data['r_buf_emit']['label'])
        drawing += elm.Ground()
        drawing += elm.Capacitor().right().at(q_buffer.emitter).label(component_data['c_buf_out']['label'])
        
        drawing.push()
        drawing += elm.Resistor().up().label(component_data['r_bias']['label'])
        drawing += elm.Vdd().label('9v')
        drawing.pop()
        q_drive = drawing.add(elm.BjtNpn(anchor='base').label(component_data['q_drive']['label']))
        drawing.push()
        drawing += elm.Resistor().up().at(q_drive.collector).label(component_data['r_col']['label'])
        drawing += elm.Vdd().label('9v')
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
        drawing += elm.Line().right().length(2)
        drawing += elm.Dot().label('output')

def run_framework():
    component_data = get_component_data()
    generate_bom(component_data)
    circuit = build_spice_circuit(component_data)
    simulate_circuit(circuit)
    build_schematic(component_data)

if __name__ == '__main__':
    run_framework()