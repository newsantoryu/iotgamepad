# Guia de Instalação Completa

Este guia detalha o processo completo de instalação e configuração do IoT GamePad PS2.

## 📋 Requisitos do Sistema

### Sistema Operacional
- **Linux** (Ubuntu 18.04+, Debian 10+, Fedora 32+, Arch Linux)
- **Kernel**: 4.15+ (suporte uinput)
- **Arquitetura**: x86_64 ou ARM64

### Hardware Mínimo
- **Processador**: Dual-core 2.0GHz
- **Memória RAM**: 4GB
- **Portas USB**: 2 portas livres
- **Conexão Internet**: Para downloads

### Software Necessário
- **Python**: 3.8+
- **PlatformIO**: 6.0+
- **PCSX2**: 1.6+
- **Git**: 2.0+

## 🔧 Instalação do Sistema

### 1. Atualizar Sistema

```bash
# Ubuntu/Debian
sudo apt update && sudo apt upgrade -y

# Fedora
sudo dnf update -y

# Arch Linux
sudo pacman -Syu
```

### 2. Instalar Dependências

#### Ubuntu/Debian
```bash
sudo apt install -y \
    python3 python3-pip python3-venv \
    platformio \
    git \
    build-essential \
    linux-headers-$(uname -r) \
    udev \
    minicom \
    evtest
```

#### Fedora
```bash
sudo dnf install -y \
    python3 python3-pip \
    platformio \
    git \
    gcc gcc-c++ make \
    kernel-devel \
    systemd-udev \
    minicom \
    evtest
```

#### Arch Linux
```bash
sudo pacman -S --needed \
    python python-pip \
    platformio \
    git \
    base-devel \
    linux-headers \
    systemd-udev \
    minicom \
    evtest
```

### 3. Configurar Ambiente Python

```bash
# Criar ambiente virtual
python3 -m venv ~/iotgamepad-env
source ~/iotgamepad-env/bin/activate

# Instalar dependências Python
pip install --upgrade pip
pip install pyserial evdev asyncio
```

### 4. Configurar Permissões do Sistema

#### Adicionar Usuário aos Grupos Necessários
```bash
# Grupo para dispositivos de input
sudo usermod -a -G input $USER

# Grupo para dispositivos seriais
sudo usermod -a -G dialout $USER

# Verificar grupos
groups $USER
```

#### Configurar Regras udev para uinput
```bash
# Criar regra para uinput
sudo tee /etc/udev/rules.d/99-uinput.rules << EOF
KERNEL=="uinput", MODE="0660", GROUP="input", OPTIONS+="static_node=uinput"
EOF

# Recarregar regras udev
sudo udevadm control --reload-rules
sudo udevadm trigger

# Carregar módulo kernel
sudo modprobe uinput

# Verificar se uinput está disponível
ls -la /dev/uinput
```

#### Configurar Regras para Dispositivos Seriais
```bash
# Criar regra para dispositivos ESP32
sudo tee /etc/udev/rules.d/99-esp32.rules << EOF
SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", MODE="0666", GROUP="dialout"
SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", MODE="0666", GROUP="dialout"
SUBSYSTEM=="tty", ATTRS{idProduct}=="6001", MODE="0666", GROUP="dialout"
EOF

sudo udevadm control --reload-rules
sudo udevadm trigger
```

### 5. Reiniciar para Aplicar Permissões

```bash
# Fazer logout e login novamente
# OU reiniciar completamente
sudo reboot
```

## 🔌 Configuração do Hardware

### 1. Montagem do Circuito

#### Componentes Necessários
- ESP32-DOIT-DEVKIT-V1
- MPU6050 (breakout board)
- LED 5mm (opcional, para feedback)
- Resistor 220Ω (para LED)
- Protoboard e jumpers

#### Diagrama de Conexão
```
ESP32        MPU6050
------       --------
3.3V    →    VCC
GND     →    GND
GPIO32  →    SDA
GPIO33  →    SCL

ESP32        LED
------       ------
GPIO14  →    Resistor 220Ω → LED → GND
```

#### Passos de Montagem
1. Conecte o MPU6050 na protoboard
2. Faça as conexões de alimentação (3.3V e GND)
3. Conecte SDA e SCL nos GPIO32 e GPIO33
4. Monte o circuito do LED no GPIO14
5. Verifique todas as conexões

### 2. Teste do Hardware

#### Teste de Conexão Serial
```bash
# Listar dispositivos seriais
ls -la /dev/tty*
# Procure por ttyACM0, ttyUSB0, etc.

# Testar comunicação (com ESP32 conectado)
sudo minicom -D /dev/ttyACM0 -b 115200
# Deverá ver "MPU6050 OK — aguardando cabecada..."
```

#### Teste do Sensor
```bash
# Com o firmware já gravado, mova o ESP32
# Deverá ver mensagens de BTN_SQUARE ou BTN_SQUARE_DOUBLE
```

## 💻 Instalação do Software

### 1. Clonar o Projeto

```bash
# Clonar repositório
git clone https://github.com/seu-usuario/iotgamepad.git
cd iotgamepad

# Criar link simbólico para o bridge
ln -s $(pwd)/../esp32_ds4_bridge_linux.py ~/iotgamepad-bridge.py
chmod +x ~/iotgamepad-bridge.py
```

### 2. Compilar Firmware ESP32

```bash
# Verificar configuração
cat platformio.ini

# Compilar
pio run

# Enviar para ESP32
pio run --target upload

# Monitor serial
pio device monitor
```

### 3. Configurar Bridge Python

#### Criar Script de Inicialização
```bash
# Criar script executável
sudo tee /usr/local/bin/iotgamepad-bridge << 'EOF'
#!/bin/bash
cd /home/victor/Documents/PlatformIO/Projects/gamer
python3 /home/victor/esp32_ds4_bridge_linux.py
EOF

sudo chmod +x /usr/local/bin/iotgamepad-bridge
```

#### Criar Serviço Systemd
```bash
sudo tee /etc/systemd/system/iotgamepad.service << EOF
[Unit]
Description=IoT GamePad Bridge Service
After=graphical-session.target
Wants=graphical-session.target

[Service]
Type=simple
User=victor
Group=victor
WorkingDirectory=/home/victor/Documents/PlatformIO/Projects/gamer
Environment=PYTHONPATH=/home/victor/iotgamepad-env/lib/python3.x/site-packages
ExecStart=/home/victor/iotgamepad-env/bin/python /home/victor/esp32_ds4_bridge_linux.py
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=graphical-session.target
EOF

# Habilitar e iniciar serviço
sudo systemctl daemon-reload
sudo systemctl enable iotgamepad.service
sudo systemctl start iotgamepad.service

# Verificar status
sudo systemctl status iotgamepad.service
```

## 🎮 Configuração do PCSX2

### 1. Instalar PCSX2

#### Ubuntu/Debian
```bash
# Adicionar repositório PCSX2
sudo add-apt-repository ppa:pcsx2-team/pcsx2-daily
sudo apt update
sudo apt install pcsx2
```

#### Outras Distribuições
```bash
# Baixar AppImage
wget https://github.com/PCSX2/pcsx2/releases/latest/download/pcsx2-linux-appimage-x64-Qt.AppImage
chmod +x pcsx2-linux-appimage-x64-Qt.AppImage
sudo mv pcsx2-linux-appimage-x64-Qt.AppImage /usr/local/bin/pcsx2
```

### 2. Configurar Controles

#### Iniciar Configuração
1. Abra o PCSX2
2. Vá em `Config → Controllers (PAD)`
3. Selecione a primeira aba (Pad 1)

#### Configurar Dispositivo
1. Clique em "Clear All"
2. Selecione "ESP32-DS4-Bridge" na lista de dispositivos
3. Mapeie os botões principais:
   - ⬜ Quadrado → Quadrado (para chutes)
   - ❌ Cruz    → Passes
   - 🔵 Círculo → Corridas
   - 🔺 Triângulo → Chutes longos
   - Analógico Esquerdo → Movimentação

#### Salvar Configuração
1. Clique em "Apply"
2. Clique em "OK"
3. Teste no menu principal

## 🧪 Teste de Funcionamento

### 1. Teste do Bridge

```bash
# Iniciar bridge manualmente
python3 /home/victor/esp32_ds4_bridge_linux.py

# Saída esperada:
[SERIAL] Conectado: /dev/ttyACM0 @ 115200
[DS4]    Encontrado: Wireless Controller (/dev/input/event3)
[VIRT]   Controle virtual: /dev/input/event17
[OK] Bridge rodando — Ctrl+C para sair.
```

### 2. Teste de Movimentos

```bash
# Em outro terminal, monitorar eventos
evtest /dev/input/event17

# Faça movimentos com o ESP32
# Deverá ver eventos BTN_WEST sendo gerados
```

### 3. Teste no PCSX2

1. Inicie um jogo de futebol (Winning Eleven/FIFA)
2. Entre em campo
3. Faça uma cabeçada leve com o ESP32
4. O jogador deve executar um chute normal (⬜)
5. Faça uma cabeçada forte
6. O jogador deve executar um chute forte (⬜⬜)

## 🔧 Scripts Auxiliares

### Script de Instalação Automática

```bash
#!/bin/bash
# install.sh - Instalação completa do IoT GamePad

set -e

echo "🚀 Instalando IoT GamePad..."

# Atualizar sistema
echo "📦 Atualizando sistema..."
sudo apt update && sudo apt upgrade -y

# Instalar dependências
echo "📦 Instalando dependências..."
sudo apt install -y python3 python3-pip platformio git build-essential linux-headers-$(uname -r) udev minicom evtest

# Configurar permissões
echo "🔧 Configurando permissões..."
sudo usermod -a -G input,dialout $USER
echo 'KERNEL=="uinput", MODE="0660", GROUP="input", OPTIONS+="static_node=uinput"' | sudo tee /etc/udev/rules.d/99-uinput.rules
sudo udevadm control --reload-rules && sudo udevadm trigger
sudo modprobe uinput

# Configurar ambiente Python
echo "🐍 Configurando ambiente Python..."
python3 -m venv ~/iotgamepad-env
source ~/iotgamepad-env/bin/activate
pip install pyserial evdev

echo "✅ Instalação concluída!"
echo "🔄 Faça logout e login novamente para aplicar as permissões."
```

### Script de Diagnóstico

```bash
#!/bin/bash
# diagnose.sh - Diagnóstico do sistema

echo "🔍 Diagnóstico do IoT GamePad"
echo "=============================="

# Verificar grupos
echo "👤 Grupos do usuário:"
groups $USER | grep -E "(input|dialout)" || echo "❌ Grupos não configurados"

# Verificar dispositivos
echo -e "\n📡 Dispositivos seriais:"
ls -la /dev/tty* | grep -E "(ACM|USB)" || echo "❌ Nenhum dispositivo serial encontrado"

echo -e "\n🎮 Dispositivos de input:"
ls -la /dev/input/by-id/ | head -10

# Verificar uinput
echo -e "\n💻 Dispositivo uinput:"
ls -la /dev/uinput && echo "✅ uinput disponível" || echo "❌ uinput não disponível"

# Verificar módulos
echo -e "\n🔧 Módulos kernel:"
lsmod | grep uinput && echo "✅ uinput carregado" || echo "❌ uinput não carregado"

# Verificar Python
echo -e "\n🐍 Ambiente Python:"
which python3 && python3 --version
pip3 list | grep -E "(pyserial|evdev)" || echo "❌ Dependências Python não instaladas"
```

## 📝 Verificação Final

### Checklist de Instalação

- [ ] Sistema atualizado
- [ ] Dependências instaladas
- [ ] Permissões configuradas
- [ ] Hardware montado e conectado
- [ ] Firmware compilado e enviado
- [ ] Bridge funcionando
- [ ] PCSX2 configurado
- [ ] Jogos testados

### Comandos de Verificação

```bash
# Verificar status completo
./diagnose.sh

# Testar bridge
python3 /home/victor/esp32_ds4_bridge_linux.py

# Verificar serviço
sudo systemctl status iotgamepad.service
```

## 🆘 Suporte

### Problemas Comuns e Soluções

1. **Permissões negadas**: Faça logout/login
2. **ESP32 não encontrado**: Verifique conexão USB
3. **DS4 não detectado**: Conecte via USB primeiro
4. **uinput não disponível**: Carregue módulo manualmente

### Logs do Sistema

```bash
# Logs do serviço
sudo journalctl -u iotgamepad.service -f

# Logs do kernel
dmesg | grep -E "(uinput|input|tty)"
```

---

**Próximo passo**: Após a instalação completa, consulte o [Guia de Uso](USAGE.md) para aprender a usar o sistema.
