# Guia de Uso - IoT GamePad PS2

Este guia explica como usar o IoT GamePad para expandir sua jogabilidade no PCSX2 através de movimentos físicos.

## 🎮 Conceitos Básicos

### Como o Sistema Funciona

O IoT GamePad transforma seus movimentos físicos em comandos de controle:

1. **Movimento Detectado** → ESP32 com sensor MPU6050
2. **Processamento** → Classificação do tipo de movimento
3. **Comando Enviado** → Via serial para o bridge Python
4. **Ação no Jogo** → Controle virtual no PCSX2

### Movimentos Suportados

#### Cabeçada Leve 🟢
- **Movimento**: Balanço moderado da cabeça
- **Ação**: `⬜ Quadrado` (chute normal)
- **Uso**: Passes curtos, chutes de curta distância
- **Sensibilidade**: 2.5 - 5.0 m/s²

#### Cabeçada Forte 🔴
- **Movimento**: Balanço forte da cabeça
- **Ação**: `⬜⬜ Quadrado Duplo` (chute forte/finalização)
- **Uso**: Chutes longos, finalizações, defesas
- **Sensibilidade**: > 5.0 m/s²

## 🚀 Iniciando o Sistema

### 1. Preparação do Ambiente

```bash
# Ativar ambiente Python (se necessário)
source ~/iotgamepad-env/bin/activate

# Iniciar bridge manualmente
python3 /home/victor/esp32_ds4_bridge_linux.py
```

### 2. Verificação de Status

#### Status LEDs no ESP32
- **3 blinks rápidos**: Sistema OK
- **1 blink**: Erro no MPU6050
- **1 blink rápido**: Cabeçada leve detectada
- **2 blinks rápidos**: Cabeçada forte detectada

#### Logs do Bridge
```
[SERIAL] Conectado: /dev/ttyACM0 @ 115200
[DS4]    Encontrado: Wireless Controller (/dev/input/event3)
[VIRT]   Controle virtual: /dev/input/event17
[OK] Bridge rodando — Ctrl+C para sair.
```

### 3. Iniciar PCSX2

1. Abra o PCSX2
2. Carregue seu jogo favorito
3. Verifique se o controle "ESP32-DS4-Bridge" está selecionado

## 🏃‍♂️ Técnicas de Movimento

### Posicionamento Correto

#### Posição do ESP32
```
Recomendado: 👤 Cabeça/Topo da cabeça
Alternativa: 🧢 Boné/capacete
Evitar: 📱 Bolsos ou mãos (movimentos involuntários)
```

#### Postura Ideal
- **Sentado**: ESP32 na testa ou top da cabeça
- **Em pé**: Posição fixa, movimentos controlados
- **Distância**: 50-100cm do monitor

### Técnicas de Cabeçada

#### Cabeçada Leve (Chute Normal)
```
1️⃣ Posição inicial: Olhos para frente
2️⃣ Movimento: Inclinação suave (15-30°)
3️⃣ Direção: Para frente ou lateral
4️⃣ Retorno: Posição original
5️⃣ Timing: 0.5-1 segundo
```

#### Cabeçada Forte (Chute Forte)
```
1️⃣ Posição inicial: Olhos para frente
2️⃣ Movimento: Inclinação acentuada (45-60°)
3️⃣ Direção: Movimento decidido para frente
4️⃣ Retorno: Posição original
5️⃣ Timing: 1-2 segundos
```

### Dicas de Movimento

#### ✅ Boas Práticas
- Movimentos firmes e controlados
- Direção consistente
- Timing adequado ao jogo
- Pausas entre movimentos

#### ❌ Erros Comuns
- Movimentos muito bruscos
- Balanços excessivos
- Timing incorreto
- Movimentos involuntários

## 🎯 Aplicações em Jogos

### Futebol (Winning Eleven/PES/FIFA)

#### Situações de Uso

**Cabeçada Leve** ⬜
- ✅ Passes curtos
- ✅ Chutes de curta distância
- ✅ Lançamentos curtos
- ✅ Primeiro toque

**Cabeçada Forte** ⬜⬜
- ✅ Chutes longos
- ✅ Finalizações
- ✅ Lançamentos longos
- ✅ Defesas de bola alta

#### Estratégias de Jogo

**Ataque**
```
Posição de ataque → Cabeçada forte → Gol 🥅
Passe curto → Cabeçada leve → Condução → Cabeçada forte
```

**Defesa**
```
Bola alta → Cabeçada forte → Interceptação
Canto → Cabeçada forte → Defesa
```

### Outros Jogos Esportivos

#### Basquete
- **Cabeçada leve**: Arremessos curtos
- **Cabeçada forte**: Arremessos de 3 pontos

#### Tênis
- **Cabeçada leve**: Saques curtos
- **Cabeçada forte**: Saques potentes

#### Voleibol
- **Cabeçada leve**: Toques leves
- **Cabeçada forte**: Ataques potentes

## ⚙️ Personalização

### Ajuste de Sensibilidade

#### Editar Firmware ESP32
```cpp
// src/main.cpp
#define CABECADA_LEVE_MIN  2.5f   // Aumentar para menos sensível
#define CABECADA_LEVE_MAX  5.0f   // Ajustar range
#define CABECADA_FORTE_MIN 5.0f   // Aumentar para mais exigente
#define ANTI_SPAM_MS       600    // Aumentar para evitar spam
```

#### Editar Bridge Python
```python
# esp32_ds4_bridge_linux.py
PULSE_DURATION     = 0.08   # Duração do pulso (segundos)
PULSE_DOUBLE_PAUSE = 0.10   # Pausa entre pulsos duplos
```

### Configurações Avançadas

#### Modo Treinamento
```bash
# Ativar modo verbose
python3 /home/victor/esp32_ds4_bridge_linux.py --verbose

# Monitorar movimentos em tempo real
tail -f /var/log/iotgamepad.log
```

#### Calibração Personalizada
```bash
# Script de calibração
./scripts/calibrate.sh

# Teste de sensibilidade
./scripts/sensitivity_test.sh
```

## 🎮 Estratégias de Jogo

### Técnicas Avançadas

#### Combo de Movimentos
```
Cabeçada leve → Chute curto → Cabeçada forte → Finalização
```

#### Timing de Jogo
```
Defesa → Posicionamento → Cabeçada forte → Interceptação
Ataque → Condução → Cabeçada leve → Passe → Cabeçada forte → Gol
```

#### Antecipação
- Observe o movimento da bola
- Posicione-se antecipadamente
- Execute o movimento no timing correto

### Dicas Profissionais

#### Consistência
- Mantenha o mesmo padrão de movimento
- Pratique movimentos padronizados
- Desenvolva memória muscular

#### Eficiência
- Movimentos econômicos
- Timing preciso
- Recuperação rápida

#### Adaptação
- Ajuste sensibilidade conforme necessário
- Adapte-se a diferentes jogos
- Modifique técnicas conforme o oponente

## 📊 Monitoramento e Estatísticas

### Registro de Desempenho

#### Criar Log de Jogo
```bash
# Criar arquivo de log
mkdir -p ~/.iotgamepad/logs
echo "$(date): Início da sessão" >> ~/.iotgamepad/logs/gameplay.log
```

#### Estatísticas de Movimento
```bash
# Script de análise
./scripts/stats.sh

# Relatório de desempenho
cat ~/.iotgamepad/logs/stats.txt
```

### Métricas Importantes

#### Precisão de Movimento
- Taxa de acerto: % de movimentos corretos
- Consistência: variação dos movimentos
- Timing: precisão temporal

#### Desempenho no Jogo
- Gols marcados com cabeçada forte
- Passes concluídos com cabeçada leve
- Taxa de sucesso geral

## 🔧 Solução de Problemas

### Problemas Comuns de Uso

#### Movimentos Não Reconhecidos
**Sintoma**: Movimentos não geram comandos
**Causas**:
- ESP32 mal posicionado
- Sensibilidade muito alta/baixa
- Movimentos muito suaves

**Soluções**:
 Reposicione o ESP32
 Ajuste sensibilidade no firmware
 Aumente a intensidade dos movimentos

#### Comandos Duplicados
**Sintoma**: Um movimento gera múltiplos comandos
**Causas**:
- ANTI_SPAM_MS muito baixo
- Movimentos muito rápidos
- Vibrações excessivas

**Soluções**:
- Aumente ANTI_SPAM_MS para 800-1000
- Movimentos mais controlados
- Estabilize o ESP32

#### Latência Excessiva
**Sintoma**: Demora entre movimento e ação no jogo
**Causas**:
- Sistema sobrecarregado
- USB com problemas
- Bridge com problemas

**Soluções**:
- Feche programas desnecessários
- Troque porta USB
- Reinicie o bridge

### Diagnóstico Rápido

#### Teste de Movimento
```bash
# Monitor serial em tempo real
sudo minicom -D /dev/ttyACM0 -b 115200

# Faça movimentos e observe as saídas
# Deverá ver BTN_SQUARE ou BTN_SQUARE_DOUBLE
```

#### Teste de Bridge
```bash
# Verificar se bridge está rodando
ps aux | grep esp32_ds4_bridge

# Verificar dispositivo virtual
ls -la /dev/input/by-id/ | grep ESP32
```

## 🎯 Dicas Profissionais

### Otimização de Desempenho

#### Preparação Física
- Aquecimento antes de jogar
- Hidratação adequada
- Pausas regulares

#### Configuração Ideal
- Sala bem iluminada
- Sem distrações
- Posição confortável

#### Treinamento
- Prática regular
- Movimentos padronizados
- Adaptação gradual

### Competitivo

#### Treinamento Específico
```bash
# Modo treinamento
./scripts/training_mode.sh

# Drills de movimentos
./scripts/movement_drills.sh
```

#### Análise de Jogo
- Grave suas sessões
- Analise padrões de movimento
- Identifique áreas de melhoria

## 📱 Integração com Outras Tecnologias

### Stream e Gravação

#### OBS Studio Integration
```bash
# Plugin para mostrar movimentos
# Adicionar overlay de status do IoT GamePad
```

#### Discord Integration
```bash
# Bot para compartilhar estatísticas
# Webhook para notificações
```

### Mobile Apps

#### Controle Remoto
- Status do sistema
- Ajuste de sensibilidade
- Estatísticas em tempo real

#### Treinamento Mobile
- Tutoriais de movimento
- Drills personalizados
- Progress tracking

## 🏆 Comunidade e Competições

### Tournaments
- Organize campeonatos de IoT GamePad
- Categorias por nível
- Regras específicas

### Rankings
- Sistema de pontuação
- Leaderboards globais
- Temporadas competitivas

### Compartilhamento
- Compartilhe configurações
- Troque estratégias
- Colabore em melhorias

---

**Próximo passo**: Para problemas específicos, consulte o [Guia de Troubleshooting](TROUBLESHOOTING.md).
