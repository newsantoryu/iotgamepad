# Documentação Técnica - IoT GamePad PS2

## Visão Geral

O IoT GamePad é um sistema inovador que expande a jogabilidade em tempo real através da integração de sensores de movimento IoT com emulação de PlayStation 2. O sistema permite que jogadores executem ações no jogo através de movimentos físicos detectados por um ESP32.

## Arquitetura do Sistema

### Componentes de Hardware

```
┌─────────────────┐    Serial     ┌──────────────────┐
│   ESP32 +       │◄──────────────►│  Bridge Python   │
│   MPU6050       │   115200 baud  │  (Linux)         │
└─────────────────┘                └──────────────────┘
                                            │
                                            ▼ uinput
┌─────────────────┐    evdev      ┌──────────────────┐
│ DualShock 4     │◄──────────────►│  PCSX2           │
│ (USB/BT)        │                │  Emulator       │
└─────────────────┘                └──────────────────┘
```

#### ESP32 + MPU6050
- **Microcontrolador**: ESP32-DOIT-DEVKIT-V1
- **Sensor**: MPU6050 (acelerômetro 3-axis + giroscópio 3-axis)
- **Conexão**: I2C (SDA: GPIO32, SCL: GPIO33)
- **LED Status**: GPIO14 para feedback visual

#### DualShock 4
- **Conexão**: USB ou Bluetooth
- **Interface**: evdev (Linux input subsystem)
- **Modo**: Exclusivo (grab) para evitar conflitos

### Componentes de Software

#### Firmware ESP32 (Arduino)
- **Framework**: Arduino Core for ESP32
- **Bibliotecas**: Adafruit MPU6050, Adafruit Unified Sensor
- **Processamento**: Tempo real de dados do acelerômetro
- **Saída**: Comandos seriais para gestos detectados

#### Bridge Python
- **Linguagem**: Python 3.8+
- **Dependências**: pyserial, evdev, asyncio
- **Funcionalidade**: 
  - Leitura assíncrona de dispositivos evdev
  - Comunicação serial com ESP32
  - Criação de dispositivo virtual uinput
  - Combinação de inputs em controle unificado

## Fluxo de Dados

### 1. Detecção de Movimentos (ESP32)

```cpp
// Cálculo do vetor total de aceleração
float total = sqrt(ax*ax + ay*ay + az*az);
float movimento = abs(total - 9.8f);  // Remove gravidade

// Classificação do movimento
if (movimento >= CABECADA_FORTE_MIN) {
    Serial.println("BTN_SQUARE_DOUBLE");  // 5.0+ m/s²
} else if (movimento >= CABECADA_LEVE_MIN) {
    Serial.println("BTN_SQUARE");         // 2.5-5.0 m/s²
}
```

### 2. Processamento no Bridge

```python
# Mapeamento de gestos para botões
GESTURE_MAP = {
    "BTN_SQUARE":        ecodes.BTN_WEST,   # quadrado leve
    "BTN_SQUARE_DOUBLE": ecodes.BTN_WEST,   # quadrado forte
}

# Injeção de pulso assíncrono
async def inject_pulse(ui: UInput, code: int, double: bool = False):
    # Simula pressão do botão no dispositivo virtual
```

### 3. Integração com PCSX2

O dispositivo virtual `ESP32-DS4-Bridge` aparece como:
- **Nome**: ESP32-DS4-Bridge
- **Tipo**: Gamepad compatível com evdev
- **Capacidades**: Todas as capacidades do DS4 original
- **Delay**: <16ms (60fps)

## Protocolos e Interfaces

### Comunicação Serial
- **Porta**: /dev/ttyACM0 (auto-detecção)
- **Baud Rate**: 115200
- **Formato**: ASCII, linha terminada em \n
- **Comandos**: BTN_SQUARE, BTN_SQUARE_DOUBLE

### Interface evdev
- **Dispositivo DS4**: /dev/input/eventX
- **Modo**: Exclusivo (grab)
- **Eventos**: EV_KEY, EV_ABS, EV_SYN
- **Latência**: <1ms

### Interface uinput
- **Dispositivo Virtual**: /dev/uinput
- **Nome**: ESP32-DS4-Bridge
- **Versão**: 0x3
- **Sincronização**: EV_SYN após cada evento

## Configurações e Parâmetros

### Sensibilidade do Sensor
```cpp
#define CABECADA_LEVE_MIN  2.5f   // m/s² - threshold mínimo
#define CABECADA_LEVE_MAX  5.0f   // m/s² - limite cabeçada leve
#define CABECADA_FORTE_MIN 5.0f   // m/s² - threshold cabeçada forte
#define ANTI_SPAM_MS       600    // ms - anti-spam
```

### Timing do Bridge
```python
PULSE_DURATION     = 0.08   # segundos - duração do pulso
PULSE_DOUBLE_PAUSE = 0.10   # segundos - pausa entre pulsos
GESTURE_LOOP_FREQ  = 60     # Hz - frequência de processamento
```

## Performance e Latência

### Métricas do Sistema
- **Latência Total**: <50ms (movimento → jogo)
- **Taxa de Amostragem**: 60Hz (sensor)
- **Taxa de Processamento**: 60Hz (bridge)
- **Throughput Serial**: 115200 bps
- **CPU Usage**: <2% (bridge Python)

### Fatores de Latência
1. **Sensor**: 16.67ms (60Hz)
2. **Serial**: ~1ms (115200 baud)
3. **Bridge**: ~16ms (60Hz loop)
4. **uinput**: <1ms
5. **PCSX2**: ~10ms (input processing)

## Segurança e Permissões

### Permissões Necessárias
```bash
# Grupo input para evdev/uinput
sudo usermod -a -G input $USER

# Regra udev para uinput
echo 'KERNEL=="uinput", MODE="0660", GROUP="input"' | \
    sudo tee /etc/udev/rules.d/99-uinput.rules

# Recarregar regras
sudo udevadm control --reload-rules && sudo udevadm trigger

# Módulo kernel
sudo modprobe uinput
```

### Considerações de Segurança
- **Acesso Serial**: Requer permissões de grupo dialout
- **Dispositivos Input**: Requer grupo input
- **Modo Exclusivo**: Previne interferência do sistema
- **Sem Rede**: Operação local sem exposição externa

## Extensibilidade e Modularidade

### Suporte a Novos Gestos
```cpp
// Adicionar novos thresholds
#define CHUTE_LEVE_MIN    3.0f
#define CHUTE_FORTE_MIN   6.0f
#define PULO_MIN          8.0f
```

### Suporte a Múltiplos Controles
```python
# Mapa expandido de dispositivos
DEVICE_MAP = {
    "ds4": DualShock4Handler,
    "xbox": XboxHandler,
    "switch": ProControllerHandler,
}
```

### Configuração Dinâmica
```python
# Carregar configurações de arquivo YAML
with open('config.yaml') as f:
    config = yaml.safe_load(f)
    GESTURE_MAP.update(config.get('gestures', {}))
```

## Debugging e Monitoramento

### Logs do Sistema
```
[SERIAL] Conectado: /dev/ttyACM0 @ 115200
[DS4]    Encontrado: Wireless Controller (/dev/input/event3)
[VIRT]   Controle virtual: /dev/input/event17
[GESTO]  BTN_SQUARE_DOUBLE
```

### Ferramentas de Debug
```bash
# Monitorar eventos evdev
evtest /dev/input/event3

# Monitorar serial
sudo minicom -D /dev/ttyACM0 -b 115200

# Ver dispositivos uinput
ls -la /dev/input/by-id/
```

## Considerações de Deploy

### Requisitos Mínimos
- **Sistema**: Linux (Ubuntu 18.04+)
- **Python**: 3.8+
- **Kernel**: 4.15+ (suporte uinput)
- **Hardware**: ESP32 + MPU6050 + DS4

### Instalação Automatizada
```bash
# Script de instalação
./install.sh  # Instala dependências e permissões
./setup.sh    # Configura dispositivos
./start.sh    # Inicia o bridge
```

### Serviço Systemd
```ini
[Unit]
Description=IoT GamePad Bridge
After=graphical-session.target

[Service]
Type=simple
User=gamer
ExecStart=/usr/bin/python3 /opt/iotgamepad/bridge.py
Restart=always

[Install]
WantedBy=graphical-session.target
```
