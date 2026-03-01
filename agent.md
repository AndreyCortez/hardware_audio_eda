# Documentação do Projeto: Framework Python-Centric para Design de Áudio Analógico

## 1. Visão Geral do Projeto

Este projeto consiste no desenvolvimento de um ecossistema de automação de design eletrônico (EDA) totalmente unificado e governado por Python. O objetivo final é projetar, documentar e testar um pedal analógico de Overdrive com estágio de Buffer de entrada, eliminando a dependência de interfaces gráficas manuais e processos de transcrição propensos a falhas.

Ao invés de tratar o esquemático, a simulação matemática e a lista de materiais (BOM) como entidades separadas, este framework adota o paradigma da **Única Fonte de Verdade (Single Source of Truth)**. Uma única estrutura de dados dita o comportamento matemático do circuito, renderiza sua representação visual e exporta as especificações físicas necessárias para a montagem no mundo real.

## 2. Objetivos Principais

* **Erradicação de Erros de Sincronia:** Garantir que o circuito que está sendo simulado é matematicamente idêntico ao circuito que está sendo desenhado e às peças que estão sendo compradas.
* **Validação Pré-Física:** Usar o processamento SPICE em background para validar correntes e tensões lógicas antes que qualquer componente físico seja soldado ou submetido à energia, mitigando o risco de destruição de hardware.
* **Processamento de Áudio Digital em Circuito Analógico:** Permitir a injeção de arquivos `.wav` de gravações reais de guitarra para dentro da simulação do circuito e exportar o resultado processado, permitindo "ouvir" o pedal virtual antes de construir a placa de circuito impresso (PCB).

## 3. A Arquitetura do Hardware (O Pedal)

O circuito embarcado neste framework é um **Overdrive Clássico com Buffer Integrado**. O fluxo do sinal (Signal Chain) é dividido em três estágios precisos:

1. **Estágio de Isolamento (Buffer):** Utiliza um transistor NPN 2N3904 na topologia de *Seguidor de Emissor* (Emitter Follower). Ele recebe o sinal de alta impedância da guitarra e o converte para um sinal de baixa impedância e alta corrente. Isso previne a degradação das frequências agudas (tone suck) e blinda os captadores da guitarra contra interações elétricas prejudiciais com o resto do circuito.
2. **Estágio de Ganho (Overdrive):** Um segundo transistor NPN amplifica o sinal. O controle de Drive ajusta a resistência no emissor, permitindo ao usuário saturar o transistor empurrando mais corrente pela base.
3. **Estágio de Clipagem (Diodos):** Um par de diodos de silício (1N4148) paralelos e invertidos ao terra "ceifam" (clipam) os picos da onda sonora amplificada. Essa limitação abrupta de voltagem é o que fisicamente gera a distorção harmônica característica do Overdrive.

## 4. Funcionalidades do Framework de Software

A arquitetura do software é modularizada nas seguintes funcionalidades:

* **Data Structure Core:** Um dicionário centralizado onde cada componente recebe seu `spice_val` (valor matemático), seu `label` (representação visual) e sua `spec` (especificação de limite físico e tolerância).
* **Motor de Simulação Analógica (PySpice/Ngspice):** Gera o Netlist automaticamente e resolve as equações diferenciais não-lineares do circuito para validação de ganho e comportamento no domínio do tempo.
* **Motor de Renderização Visual (Schemdraw):** Gera diagramas de circuitos em formato vetorial de alta resolução, lendo exatamente os mesmos nós declarados no motor de simulação.
* **Motor de Processamento DSP (NumPy/SciPy):** Realiza a conversão de arquivos de áudio PCM estéreo/mono para matrizes de voltagem contínua, alimenta o Ngspice e normaliza a saída analógica de volta para o domínio digital sem perda de fidelidade.
* **Extrator de BOM:** Compila o manifesto de montagem física exigindo a declaração de capacidades de potência e tensão.

## 5. Diretrizes de Segurança de Hardware Rigorosamente Aplicadas

O design eletrônico no mundo real carrega riscos físicos que a tela do computador muitas vezes esconde. Este projeto foi estruturado com salvaguardas explícitas tanto no hardware projetado quanto no software gerador:

* **Isolamento de Corrente Contínua (DC Blocking):** Capacitores de acoplamento na entrada e na saída são obrigatórios na estrutura. Isso impede que os 9V da fonte de alimentação vazem pelo cabo P10, o que destruiria instantaneamente os captadores da guitarra ou o estágio inicial do amplificador.
* **Remoção de Offset DC em Áudio Digital:** O motor de DSP possui uma rotina de normalização (`out_signal -= np.mean(out_signal)`) que remove qualquer tensão contínua residual antes de exportar o arquivo `.wav` final. Reproduzir um arquivo com offset DC não tratado em monitores de referência causaria excursão violenta e rasgo potencial no cone dos alto-falantes, além de risco de trauma acústico.
* **Resistor de Pull-Down (Anti-Pop):** Implementação arquitetônica de um resistor de 2.2MΩ na entrada principal para drenar cargas parasitas. Isso elimina o pico transiente explosivo (Switch Pop) gerado pelo acionamento mecânico da chave 3PDT real.
* **Prevenção de Curto-Circuito Térmico:** O estágio de ganho incorpora um "resistor de freio" de 100 ohms em série com o potenciômetro de Drive. Caso o usuário zere a resistência do potenciômetro, o transistor é impedido de entrar em curto-circuito (drain de corrente infinita), o que causaria a fusão térmica da peça na protoboard e potencial dano à fonte de alimentação externa.
* **Especificações de Tolerância Críticas:** A BOM gerada não aceita valores puramente lógicos (ex: "100k"). A estrutura de dados força a especificação de potência (ex: "1/4W Metal Film") e voltagem de ruptura ("Min 16V"). Usar resistores de baixa dissipação ou capacitores de 6V em um barramento de 9V resultaria em superaquecimento, fumaça ou pequenas explosões dos componentes.

---

**Gostaria que eu gerasse o script final unificado (um arquivo `main.py` abrangendo todas as funcionalidades e o módulo de áudio .wav) para você rodar, fechar essa versão do framework e ir testar o som virtualmente?**