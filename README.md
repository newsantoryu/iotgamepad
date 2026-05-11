# IoT GamePad - Expansor de Jogabilidade PS2

[![PlatformIO](https://img.shields.io/badge/PlatformIO-ESP32-blue.svg)](https://platformio.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Python](https://img.shields.io/badge/Python-3.8+-yellow.svg)](https://python.org)

Sistema inovador que integra IoT + PC + emulador PS2 através de movimentos físicos em tempo real. Transforme cabeçadas e movimentos em ações de jogo no PCSX2!

## 🎮 Como Funciona

O sistema detecta seus movimentos físicos através de um sensor ESP32 e os converte em comandos de controle no PlayStation 2:

```
Movimento Físico → ESP32 + MPU6050 → Bridge Python → PCSX2
    🏃‍♂️              📡                 💻            🎯
```

### Movimentos Suportados

- **Cabeçada Leve** → `⬜ Quadrado` (chute normal)
- **Cabeçada Forte** → `⬜⬜ Quadrado Duplo` (finalização/chute forte)

## 🚀 Quick Start

### Pré-requisitos

- Linux (Ubuntu 18.04+)
- Python 3.8+
- ESP32 com MPU6050
- DualShock 4
- PCSX2 Emulator

### Instalação Rápida

```bash
# 1. Clonar o projeto
git clone https://github.com/seu-usuario/iotgamepad.git
cd iotgamepad

# 2. Instalar dependências Python
pip install pyserial evdev

# 3. Configurar permissões (uma vez)
sudo usermod -a -G input $USER
echo 'KERNEL=="uinput", MODE="0660", GROUP="input"' | sudo tee /etc/udev/rules.d/99-uinput.rules
sudo udevadm control --reload-rules && sudo udevadm trigger
sudo modprobe uinput

# 4. Compilar firmware ESP32
pio run --target upload

# 5. Iniciar bridge
python3 /home/victor/esp32_ds4_bridge_linux.py
```

### Configuração PCSX2

1. Abra o PCSX2
2. Vá em `Settings → Controllers`
3. Selecione `ESP32-DS4-Bridge` como dispositivo
4. Configure mapeamento conforme preferência

## 📁 Estrutura do Projeto

```
iotgamepad/
├── src/
│   └── main.cpp              # Firmware ESP32
├── scripts/
│   └── bridge.sh            # Script de inicialização
├── docs/
│   ├── TECHNICAL.md         # Documentação técnica
│   ├── INSTALL.md           # Guia de instalação
│   └── USAGE.md             # Guia de uso
├── platformio.ini           # Configuração PlatformIO
└── README.md               # Este arquivo
```

## 🔧 Hardware Necessário

### Componentes Principais
- **ESP32-DOIT-DEVKIT-V1** - Microcontrolador principal
- **MPU6050** - Sensor acelerômetro/giroscópio
- **DualShock 4** - Controle PlayStation 4
- **LED** - Feedback visual (GPIO14)

### Conexões ESP32
```
MPU6050    ESP32
VCC    →   3.3V
GND    →   GND
SDA    →   GPIO32
SCL    →   GPIO33
LED    →   GPIO14
```

## 💻 Software

### Firmware ESP32
- **Framework**: Arduino Core for ESP32
- **Bibliotecas**: Adafruit MPU6050, Adafruit Unified Sensor
- **Processamento**: Tempo real de dados do acelerômetro

### Bridge Python
- **Arquivo**: `esp32_ds4_bridge_linux.py`
- **Função**: Integra ESP32 + DS4 + PCSX2
- **Interface**: uinput (dispositivo virtual)

## 🎮 Jogos Compatíveis

Ideal para jogos de futebol e esportes no PCSX2:

- **Winning Eleven** / **Pro Evolution Soccer**
- **FIFA** series
- **Outros jogos esportivos**
- Jogos que utilizam botão `⬜ Quadrado` para chutes

## ⚙️ Configuração

### Sensibilidade do Sensor

Edite `src/main.cpp` para ajustar thresholds:

```cpp
#define CABECADA_LEVE_MIN  2.5f   // m/s² - cabeçada leve
#define CABECADA_LEVE_MAX  5.0f   // m/s² - limite máximo
#define CABECADA_FORTE_MIN 5.0f   // m/s² - cabeçada forte
#define ANTI_SPAM_MS       600    // ms - anti-spam
```

### Tempo de Resposta

Configure em `esp32_ds4_bridge_linux.py`:

```python
PULSE_DURATION     = 0.08   # segundos - duração do pulso
PULSE_DOUBLE_PAUSE = 0.10   # segundos - pausa entre pulsos
```

## 🔍 Debug e Monitoramento

### Logs do Sistema
```bash
# Monitor serial
sudo minicom -D /dev/ttyACM0 -b 115200

# Monitor eventos input
evtest /dev/input/eventX

# Ver dispositivos
ls -la /dev/input/by-id/
```

### Status LEDs
- **1 blink**: Erro MPU6050
- **3 blinks**: Sistema OK
- **2 blinks rápidos**: Cabeçada forte detectada
- **1 blink rápido**: Cabeçada leve detectada

## 🐛 Troubleshooting

### Problemas Comuns

**ESP32 não encontrado:**
```bash
# Verificar permissões serial
sudo usermod -a -G dialout $USER
sudo chmod 666 /dev/ttyACM0
```

**DS4 não detectado:**
```bash
# Verificar dispositivos disponíveis
python3 -c "import evdev; print([d.name for d in evdev.list_devices()])"
```

**Permissões uinput:**
```bash
# Verificar grupo
groups $USER | grep input

# Recarregar módulo
sudo rmmod uinput && sudo modprobe uinput
```

## 📚 Documentação Completa

- [📋 Documentação Técnica](docs/TECHNICAL.md)
- [🔧 Guia de Instalação](docs/INSTALL.md)
- [🎮 Guia de Uso](docs/USAGE.md)
- [🐛 Troubleshooting Avançado](docs/TROUBLESHOOTING.md)

## 🤝 Contribuição

Contribuições são bem-vindas! Por favor:

1. Fork o projeto
2. Crie uma branch (`git checkout -b feature/nova-funcionalidade`)
3. Commit suas mudanças (`git commit -am 'Adiciona nova funcionalidade'`)
4. Push para a branch (`git push origin feature/nova-funcionalidade`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

## 👥 Créditos

- **Desenvolvimento**: [Seu Nome]
- **Inspiração**: Comunidade de emulação e IoT
- **Bibliotecas**: Adafruit, PlatformIO, evdev

## 📞 Suporte

- 📧 Email: seu-email@exemplo.com
- 💬 Discord: [Link do servidor]
- 🐛 Issues: [GitHub Issues]

---

**⚠️ Aviso**: Use com responsabilidade. Faça pausas regulares durante o jogo para evitar fadiga.
