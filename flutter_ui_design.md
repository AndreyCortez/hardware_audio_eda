# Audio EDA Framework - Architecture & Design Document

Este documento define a arquitetura definitiva e a interface do aplicativo Web (construído em Flutter) que servirá como frontend para o nosso framework Audio EDA em Python. O objetivo fundamental é fornecer uma interface interativa baseada em Canvas (arrastar e soltar) com janelas ancoráveis (Dockable), onde o usuário possa desenhar circuitos analógicos, processar áudio pesado (`.wav`) pelo motor de simulação SPICE backend e inspecionar visualmente o sinal resultante.

---

## 1. Arquitetura do Sistema e Deploy (Docker)

O ecossistema é estritamente isolado da máquina cliente para evitar os antigos conflitos de dependências C (Ngspice e Buffer API).

A orquestração é feita via `docker-compose.yml` na raiz, consistindo de dois serviços mestre que se comunicam operando em sub-redes virtuais:

### 1.1 Backend Python Engine (`/api`)
- **Papel:** Motor de processamento DSP e solucionador SPICE.
- **Tecnologia:** FastAPI rodando em Python 3.12 (`uvicorn`).
- **Comunicação:** Expõe endpoints RESTful (ex: `POST /simulate`). Recebe payloads contendo a Netlist SPICE dinâmica gerada pelo Frontend juntamente com arquivos Multipart do input `.wav`.
- **Containers Internos:** A imagem base inclui bibliotecas do sistema `ngspice` e bibliotecas pesadas de Data Science (`numpy`, `scipy`). Ele executa a classe PySpice `NgSpiceSubprocess` modificada para bypassar deadlocks de memória em strings de 10k+ linhas.

### 1.2 Frontend Web App (`/audio_eda_ui`)
- **Papel:** Editor esquemático, gerenciador da Tiling UI e comparador de áudio.
- **Tecnologia:** Flutter Web compilado nativamente.
- **Comunicação:** Faz as interações com o usuário e mapeamentos Canvas. Ao final, compila um texto plano `.cir` e faz o push HTTP para o Backend Python.
- **Distribuição:** A build estática gerada é envelopada dentro de um container leve do Nginx, exposta na porta `8081` da máquina host. Não requer instalação do SDK do Flutter pelo usuário final.

---

## 2. Visão Geral da Interface (UI/UX) - Arquitetura "Dockable"

Inspirado em IDEs modernos como o *VS Code* e *Tiling Window Managers*, o aplicativo abandona layouts fixos. O ambiente funciona como um editor mestre onde painéis (Views) podem ser arrastados, movidos ou escondidos conforme a necessidade do fluxo de trabalho.

### 2.1 Princípios Diretores do Layout
1. **Otimização do Canvas:** O espaço disponível para os fios e trilhas deve ser implacavelmente maximizado. 
2. **Contexto On-Demand:** Os painéis laterais só devem tomar espaço se o usuário estiver ativamente arrastando uma peça nova.
3. **Persistência de Espaço Virtual (Workspace):** As dimensões das colunas e áreas colapsadas devem ser persistidas via Web Storage nativo.

### 2.2 Estrutura Modular da Tiling UI (Painéis TWM)

O pacote **`flutter_resizable_container`** será o núcleo para montar a matriz divisível:

*   **Left Activity Bar (A Barra de Menu Verticais):** Permite focar ou desfocar os "Dockers" à direita dela (Ex: Ícone de Componente abre o *Component Browser*, Ícone de Áudio abre o *Audio Setup*).
*   **Aba DockLeft - Component Browser:** Catálogo infinito contendo os SVG/Ícones de Resistores, Transistores e Diodos prontos para o *drag-and-drop*.
*   **Main Center Dock - Schematic Visual Editor (O Coração):** 
    * O Canvas interativo contendo grade (grid) de engenharia.
    * Baseia-se no paradigma node-and-wire; onde extremidades de componentes se conectam gerando "Nodes" dinâmicos.
    * A conversão mágica de UI para SPICE ocorre aqui: Toda peça no grid converte-se em suas strings nativas Ngspice ao ler as conexões físicas criadas.
*   **Aba DockRight - Component Inspector:** Ao clicar em um transistor já desenhado no Main Center, este inspetor à direita exibe sliders para afinar o valor Ohmmico ou o VCC sem ocupar espaço desnecessário no canvas.
*   **DockBottom - Painel de Audiologia & SPICE DSP:** 
    * Dividido em dois "Players": *Dry Pipeline (Input)* e *Wet Pipeline (Ngspice Output)*.
    * Funciona como um painel retrátil que, quando elevado, engloba de forma expandida as osciloscopias ou Waveforms para análise de Timbre. O botão máster "Compilar Arquivo WAV" reside aqui.

---

## 3. Road Map Metódico de Implementação

O processo de acoplamento dessa macro-arquitetura na codebase baseia-se num sistema *Bottom-Up*:

### Fase 1: Fundação do Tiling Window Manager (Concluído)
- [x] Implementar a `Left Activity Bar` base na Main Root (Ícones fixos na esquerda simulando abas de navegador verticais).
- [x] Incorporar injetores abstratos usando `flutter_resizable_container`.
- [x] Configurar os Listeners de tamanho (largura/altura). Se o usuário fechar/ocultar a Aba Direita, o Main Center Canvas deve expandir-se proativamente.
- [x] O Estado de Resize e das Docks ativas deve ser governado por um Provider State global para persistência em memória.

### Fase 2: Drag and Drop & Canvas Engine (Concluído)
- [x] Construir o Workspace Canvas e aplicar matrizes de Zoom/Pan (permitir rolar pelo mouse wheel).
- [x] Criar modelos de dados rígidos (Classes base do Dart) para Componentes Eletrônicos (resistores, capacitores, BJTs). Cada modelo deve possuir (ID Universal, Coordenadas X/Y, Modelo Textual Ngspice, Portas IN/OUT).
- [x] Habilitar callbacks de colisão e *Snap-to-Grid*. Os terminais do componente devem grudar caso fiquem próximos, gerando "Nós (Nodes)".
- [x] Programar o gerador textual de SPICE: Ao clicar "Compilar", o Flutter itera sobre todos os componentes na tela e injeta a sintaxe SPICE baseada na numeração de seus nós conectados no Canvas.

### Fase 3: Backend Python FastAPI (Concluído)
- [x] Refatorar a classe monolítica `main.py` do projeto em um Router FastAPI conteinerizado escalável.
- [x] O `POST /simulate` tem que lidar com `multipart/form-data`. Fazer bind entre a string raw `.cir` com o áudio buffer recém lido usando a nossa classe modificada de PySpice.
- [x] Desenvolver mecanismo de Streaming File Response. O servidor não salvará WAVs lixo em disco. Retornará os bytes normatizados em WAV direto no buffer HTTP para segurança de I/O.

### Fase 4: O Painel DSP do Flutter (Concluído)
- [x] Integrar packages de manipulação sonora HTTP/Memória (`audioplayers`).
- [x] Implementar um botão FilePicker permitindo apontar e carregar `.wav` locais da máquina cliente.
- [x] Construir canais paralelos de Waveforms e Lógica de Switch Instantâneo (Mute/Solo) para testes A/B interativos do Áudio Limpo Vs. Distorção Simulada.

### Fase 5: Roteamento de Fios Avançado (Wire Routing)
- [ ] Desenvolver o renderizador de Trilha (Wire Pathing) ligando dois Nós Terminais via curvas ortogonais em ângulos de 90 graus (estilo Altium/Kicad).
- [ ] Criar lógica de *Junction Dots*: Ao sobrepor 3 ou mais extremidades de fios, renderizar um círculo visual indicando colisão real de Node em SPICE.
- [ ] Habilitar seleção de múltiplas peças no Canvas através de arraste com caixa delimitadora (Bounding Box Selection) para deletar conexões em massa.

### Fase 6: Gerenciamento Local de Sessão & Banco de Dados
- [ ] Modelar formato JSON proprietário capaz de salvar todo o estado do `SchematicProvider` (X, Y, Components, Wires, Rotations, Spice Models).
- [ ] Adicionar funcionalidade "Save/Load Project" lendo e escrevendo buffers `.json` no FilePicker da web (Upload/Download de Workspace local).
- [ ] Persistencia de Caches: Criar um DB local em navegador (Hive ou IndexedDB) para impedir que recarregar a página evapore as simulações já compridas e a netlist.

### Fase 7: Visualização Analítica aprofundada & WebSockets (Opcional Futuro)
- [ ] Atualizar o FastAPI para transmitir logs contínuos em WebSockets (`WS`), provendo uma barra de progresso viva na interface enquanto Ngspice calcula processamentos pesados de > 1M de samples PWL.
- [ ] Enviar de volta não apenas o `.WAV`, mas Arrays brutos flutuantes NumPy contendo gráficos FFT e Frequência para plotagem de THD (Total Harmonic Distortion) nativo no Flutter.
