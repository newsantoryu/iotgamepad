# Troubleshooting Avançado - IoT GamePad PS2

Guia completo de diagnóstico e solução de problemas para o IoT GamePad.

## 🔍 Diagnóstico Rápido

### Script de Verificação Completa

```bash
#!/bin/bash
# diagnose_full.sh - Diagnóstico completo do sistema

echo "🔍 DIAGNÓSTICO COMPLETO - IoT GamePad"
echo "====================================="

# 1. Verificar ambiente do sistema
echo -e "\n📋 AMBIENTE DO SISTEMA"
echo "Kernel: $(uname -r)"
echo "Distribuição: $(lsb_release -d 2>/dev/null || echo 'Não detectado')"
echo "Arquitetura: $(uname -m)"
echo "Usuário: $USER"
echo "Diretório home: $HOME"

# 2. Verificar grupos do usuário
echo -e "\n👤 GRUPOS DO USUÁRIO"
groups $USER
if groups $USER | grep -q "input"; then
    echo "✅ Grupo input OK"
else
    echo "❌ Grupo input ausente"
fi
if groups $USER | grep -q "dialout"; then
    echo "✅ Grupo dialout OK"
else
    echo "❌ Grupo dialout ausente"
fi

# 3. Verificar dispositivos seriais
echo -e "\n📡 DISPOSITIVOS SERIAIS"
serial_devices=$(ls -la /dev/tty* 2>/dev/null | grep -E "(ACM|USB)" || echo "Nenhum encontrado")
echo "$serial_devices"

# 4. Verificar dispositivos input
echo -e "\n🎮 DISPOSITIVOS INPUT"
if [ -d /dev/input/by-id ]; then
    ls -la /dev/input/by-id/ | head -10
else
    echo "❌ Diretório /dev/input/by-id não encontrado"
fi

# 5. Verificar uinput
echo -e "\n💻 DISPOSITIVO UINPUT"
if [ -e /dev/uinput ]; then
    echo "✅ /dev/uinput existe"
    ls -la /dev/uinput
else
    echo "❌ /dev/uinput não encontrado"
fi

# 6. Verificar módulos kernel
echo -e "\n🔧 MÓDULOS KERNEL"
if lsmod | grep -q uinput; then
    echo "✅ Módulo uinput carregado"
    lsmod | grep uinput
else
    echo "❌ Módulo uinput não carregado"
fi

# 7. Verificar Python e dependências
echo -e "\n🐍 AMBIENTE PYTHON"
which python3 && echo "Python3: $(python3 --version)"
pip3 list | grep -E "(pyserial|evdev)" || echo "❌ Dependências Python não encontradas"

# 8. Verificar processos ativos
echo -e "\n⚙️ PROCESSOS ATIVOS"
if pgrep -f "esp32_ds4_bridge" > /dev/null; then
    echo "✅ Bridge rodando (PID: $(pgrep -f esp32_ds4_bridge))"
else
    echo "❌ Bridge não está rodando"
fi

# 9. Testar comunicação serial
echo -e "\n🔌 TESTE DE COMUNICAÇÃO SERIAL"
if [ -e /dev/ttyACM0 ]; then
    echo "✅ /dev/ttyACM0 disponível"
    echo "Testando leitura (5 segundos)..."
    timeout 5s cat /dev/ttyACM0 2>/dev/null | head -5 || echo "Sem dados recebidos"
else
    echo "❌ /dev/ttyACM0 não encontrado"
fi

echo -e "\n🏁 DIAGNÓSTICO CONCLUÍDO"
```

## 🚨 Problemas Comuns e Soluções

### 1. ESP32 Não Detectado

#### Sintomas
```
[SERIAL] AVISO: ESP32 não encontrado — gestos desativados.
```

#### Causas Possíveis
- ESP32 não conectado via USB
- Driver USB não instalado
- Permissões de acesso negadas
- Porta serial incorreta

#### Soluções

**Verificar Conexão Física**
```bash
# Listar dispositivos USB
lsusb | grep -i "esp32\|ch340\|cp210\|silabs"

# Verificar dispositivos seriais
ls -la /dev/tty* | grep -E "(ACM|USB)"

# Testar diferentes portas
for port in /dev/ttyACM* /dev/ttyUSB*; do
    if [ -e "$port" ]; then
        echo "Testando $port..."
        sudo chmod 666 "$port"
        timeout 3s cat "$port" 2>/dev/null && echo "✅ $port responde" || echo "❌ $port sem resposta"
    fi
done
```

**Instalar Drivers**
```bash
# Ubuntu/Debian
sudo apt install linux-headers-$(uname -r) build-essential
sudo modprobe usbserial

# Para CH340
sudo apt install brltty
sudo systemctl disable brltty
sudo systemctl stop brltty

# Para CP210x
sudo apt install cp210x-dkms
```

**Configurar Permissões**
```bash
# Adicionar ao grupo dialout
sudo usermod -a -G dialout $USER

# Criar regra udev
sudo tee /etc/udev/rules.d/99-usb-serial.rules << EOF
SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", MODE="0666", GROUP="dialout"
SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", MODE="0666", GROUP="dialout"
EOF

sudo udevadm control --reload-rules
sudo udevadm trigger
```

### 2. MPU6050 Não Encontrado

#### Sintomas
```
ERRO: MPU6050 nao encontrado!
```

#### Causas Possíveis
- Conexões I2C incorretas
- MPU6050 defeituoso
- Endereço I2C conflitante
- Falha de alimentação

#### Soluções

**Verificar Conexões I2C**
```bash
# Scanner I2C (se disponível)
sudo apt install i2c-tools
sudo i2cdetect -y 0  # ou i2cdetect -y 1 para alguns ESP32

# Esperado: MPU6050 no endereço 0x68
```

**Teste de Hardware**
```cpp
// Adicionar ao firmware para debug
void scan_i2c() {
    byte error, address;
    int nDevices = 0;
    
    Serial.println("Scanning I2C...");
    for(address = 1; address < 127; address++) {
        Wire.beginTransmission(address);
        error = Wire.endTransmission();
        
        if (error == 0) {
            Serial.print("I2C device found at address 0x");
            Serial.println(address, HEX);
            nDevices++;
        }
    }
    
    if (nDevices == 0) {
        Serial.println("No I2C devices found");
    }
}
```

**Verificar Conexões Físicas**
```
Verifique:
- VCC → 3.3V (não 5V!)
- GND → GND
- SDA → GPIO32
- SCL → GPIO33
- Resistores pull-up (se necessário)
```

### 3. DualShock 4 Não Detectado

#### Sintomas
```
[DS4] Controle não encontrado!
```

#### Causas Possíveis
- DS4 não conectado
- Driver Bluetooth não funcionando
- Dispositivo bloqueado pelo sistema
- Conflito com outros programas

#### Soluções

**Verificar Conexão**
```bash
# Listar dispositivos de input
evdev-list-devices 2>/dev/null || python3 -c "
import evdev
for path in evdev.list_devices():
    try:
        dev = evdev.InputDevice(path)
        print(f'{path}: {dev.name}')
    except:
        pass
"

# Procurar especificamente por DS4
python3 -c "
import evdev
for path in evdev.list_devices():
    try:
        dev = evdev.InputDevice(path)
        if any(k in dev.name.lower() for k in ['sony', 'dualshock', 'wireless']):
            print(f'✅ {path}: {dev.name}')
    except:
        pass
"
```

**Conectar via USB**
```bash
# Conectar DS4 via USB primeiro
# Depois tentar detectar
ls -la /dev/input/by-id/ | grep -i sony
```

**Configurar Bluetooth**
```bash
# Instalar ferramentas Bluetooth
sudo apt install bluetooth bluez

# Ativar serviço
sudo systemctl enable bluetooth
sudo systemctl start bluetooth

# Emparelhar DS4
bluetoothctl
scan on
# Aguarde encontrar o DS4
pair XX:XX:XX:XX:XX:XX
connect XX:XX:XX:XX:XX:XX
trust XX:XX:XX:XX:XX:XX
exit
```

### 4. Permissões uinput Negadas

#### Sintomas
```
PermissionError: [Errno 13] Permission denied
```

#### Causas Possíveis
- Usuário não no grupo input
- Módulo uinput não carregado
- Regras udev incorretas
- SELinux/AppArmor bloqueando

#### Soluções

**Verificar e Configurar Permissões**
```bash
# Verificar grupo input
groups $USER | grep input || sudo usermod -a -G input $USER

# Carregar módulo uinput
sudo modprobe uinput
echo "uinput" | sudo tee /etc/modules-load.d/uinput.conf

# Configurar regra udev
sudo tee /etc/udev/rules.d/99-uinput.rules << EOF
KERNEL=="uinput", MODE="0660", GROUP="input", OPTIONS+="static_node=uinput"
EOF

# Recarregar regras
sudo udevadm control --reload-rules
sudo udevadm trigger

# Verificar dispositivo
ls -la /dev/uinput
```

**Verificar SELinux/AppArmor**
```bash
# Verificar status SELinux
sestatus 2>/dev/null || echo "SELinux não encontrado"

# Verificar AppArmor
sudo aa-status | grep uinput || echo "AppArmor não bloqueando uinput"

# Desabilitar temporariamente para teste
sudo setenforce 0 2>/dev/null || echo "SELinux não ativo"
```

### 5. Bridge Não Inicia

#### Sintomas
```
python3 /home/victor/esp32_ds4_bridge_linux.py
[ERRO] Falha ao iniciar bridge
```

#### Causas Possíveis
- Dependências Python faltando
- Conflito de portas
- Processo já rodando
- Erro de sintaxe no código

#### Soluções

**Verificar Dependências**
```bash
# Verificar instalação
python3 -c "
import sys
try:
    import serial
    print('✅ pyserial OK')
except ImportError:
    print('❌ pyserial faltando')

try:
    import evdev
    print('✅ evdev OK')
except ImportError:
    print('❌ evdev faltando')

try:
    import asyncio
    print('✅ asyncio OK')
except ImportError:
    print('❌ asyncio faltando')
"

# Instalar dependências
pip3 install pyserial evdev
```

**Verificar Processos**
```bash
# Verificar se bridge já está rodando
ps aux | grep esp32_ds4_bridge

# Matar processos antigos
pkill -f esp32_ds4_bridge

# Verificar portas em uso
sudo netstat -tulpn | grep :22  # SSH apenas como referência
```

**Testar Bridge Manualmente**
```bash
# Modo debug
python3 -c "
import evdev
print('Dispositivos disponíveis:')
for path in evdev.list_devices():
    try:
        dev = evdev.InputDevice(path)
        print(f'  {path}: {dev.name}')
    except:
        pass
"

# Testar bridge com verbose
python3 /home/victor/esp32_ds4_bridge_linux.py 2>&1 | tee bridge.log
```

### 6. Movimentos Não São Reconhecidos

#### Sintomas
```
Movimentos físicos não geram comandos no jogo
```

#### Causas Possíveis
- Sensibilidade muito alta/baixa
- MPU6050 calibrado incorretamente
- Movimentos muito suaves
- Anti-spam muito restritivo

#### Soluções

**Ajustar Sensibilidade**
```cpp
// Editar src/main.cpp
#define CABECADA_LEVE_MIN  1.5f   // Reduzir para mais sensível
#define CABECADA_LEVE_MAX  6.0f   // Aumentar range
#define CABECADA_FORTE_MIN 4.0f   // Reduzir threshold
#define ANTI_SPAM_MS       300    // Reduzir para testes
```

**Testar com Debug**
```cpp
// Adicionar ao loop() para debug
void loop() {
    sensors_event_t a, g, temp;
    mpu.getEvent(&a, g, &temp);
    
    float ax = a.acceleration.x;
    float ay = a.acceleration.y;
    float az = a.acceleration.z;
    float total = sqrt(ax*ax + ay*ay + az*az);
    float movimento = abs(total - 9.8f);
    
    // Debug output
    Serial.print("Movimento: ");
    Serial.print(movimento);
    Serial.print(" m/s² - ");
    
    // ... resto do código original
}
```

**Calibrar MPU6050**
```cpp
// Adicionar função de calibração
void calibrate_mpu() {
    Serial.println("Calibrando MPU6050...");
    delay(1000);
    
    float sum_x = 0, sum_y = 0, sum_z = 0;
    int samples = 100;
    
    for(int i = 0; i < samples; i++) {
        sensors_event_t a, g, temp;
        mpu.getEvent(&a, &g, &temp);
        sum_x += a.acceleration.x;
        sum_y += a.acceleration.y;
        sum_z += a.acceleration.z;
        delay(10);
    }
    
    Serial.print("Offset X: "); Serial.println(sum_x / samples);
    Serial.print("Offset Y: "); Serial.println(sum_y / samples);
    Serial.print("Offset Z: "); Serial.println(sum_z / samples);
}
```

### 7. Latência Excessiva

#### Sintomas
```
Demora > 100ms entre movimento e ação no jogo
```

#### Causas Possíveis
- Sistema sobrecarregado
- USB com problemas
- Bridge com CPU alta
- Configuração de timing incorreta

#### Soluções

**Otimizar Sistema**
```bash
# Verificar uso de CPU
top -p $(pgrep -f esp32_ds4_bridge)

# Prioridade do processo
sudo renice -10 $(pgrep -f esp32_ds4_bridge)

# Verificar latência USB
sudo lsusb -t
```

**Ajustar Timing**
```python
# Reduzir latência no bridge
PULSE_DURATION = 0.05      # Reduzir para 50ms
GESTURE_LOOP_FREQ = 120     # Aumentar para 120Hz
```

**Testar Porta USB**
```bash
# Testar diferentes portas USB
for port in /dev/ttyACM*; do
    if [ -e "$port" ]; then
        echo "Testando $port..."
        # Modificar bridge para usar porta específica
        SERIAL_PORT = "$port" python3 /home/victor/esp32_ds4_bridge_linux.py
    fi
done
```

## 🛠️ Ferramentas de Debug

### Script de Monitoramento

```bash
#!/bin/bash
# monitor.sh - Monitoramento em tempo real

echo "🔍 MONITORAMENTO IOT GAMEPAD"
echo "=========================="

# Monitor serial
echo "📡 Monitor Serial (Ctrl+C para sair):"
sudo minicom -D /dev/ttyACM0 -b 115200 &
SERIAL_PID=$!

# Monitor eventos input
echo "🎮 Monitor Eventos Input:"
sudo evtest /dev/input/by-id/*ESP32* 2>/dev/null &
EVENT_PID=$!

# Monitor processo bridge
echo "⚙️ Monitor Bridge:"
watch -n 1 'ps aux | grep esp32_ds4_bridge | grep -v grep' &
WATCH_PID=$!

# Aguardar interrupção
trap "kill $SERIAL_PID $EVENT_PID $WATCH_PID 2>/dev/null; exit" INT
wait
```

### Script de Teste de Movimento

```bash
#!/bin/bash
# test_movement.sh - Teste de movimentos

echo "🏃‍♂️ TESTE DE MOVIMENTOS"
echo "===================="

# Iniciar monitoramento
sudo minicom -D /dev/ttyACM0 -b 115200 &
MINICOM_PID=$!

echo "Faça os seguintes movimentos:"
echo "1. Cabeçada leve (aguarde 3 segundos)"
sleep 3
echo "2. Cabeçada forte (aguarde 3 segundos)"
sleep 3
echo "3. Repita cabeçada leve"
sleep 3
echo "4. Repita cabeçada forte"
sleep 3

# Parar monitoramento
kill $MINICOM_PID 2>/dev/null

echo "✅ Teste concluído. Verifique o output acima."
```

### Script de Performance

```bash
#!/bin/bash
# performance.sh - Teste de performance

echo "⚡ TESTE DE PERFORMANCE"
echo "====================="

# Testar latência
echo "📊 Medindo latência..."
start_time=$(date +%s%N)
python3 -c "
import serial
import time
ser = serial.Serial('/dev/ttyACM0', 115200, timeout=1)
time.sleep(0.1)
ser.close()
"
end_time=$(date +%s%N)
latency=$((($end_time - $start_time) / 1000000))
echo "Latência serial: ${latency}ms"

# Testar throughput
echo "📊 Medindo throughput..."
python3 -c "
import serial
import time
ser = serial.Serial('/dev/ttyACM0', 115200, timeout=1)
start = time.time()
for i in range(100):
    ser.write(b'test\n')
    ser.readline()
end = time.time()
ser.close()
print(f'Throughput: {100/(end-start):.1f} msg/s')
"

# Testar CPU
echo "📊 Uso de CPU:"
ps aux | grep esp32_ds4_bridge | grep -v grep | awk '{print "CPU: " $3 "%, MEM: " $4 "%"}'
```

## 📞 Suporte e Comunidade

### Coleta de Logs

```bash
#!/bin/bash
# collect_logs.sh - Coletar logs para suporte

LOG_DIR="iotgamepad_logs_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$LOG_DIR"

echo "📋 Coletando logs para suporte..."

# Informações do sistema
uname -a > "$LOG_DIR/system_info.txt"
lsb_release -a >> "$LOG_DIR/system_info.txt" 2>/dev/null

# Logs do bridge
journalctl -u iotgamepad.service --since "1 hour ago" > "$LOG_DIR/bridge.log"

# Configurações atuais
cp platformio.ini "$LOG_DIR/"
cp src/main.cpp "$LOG_DIR/"

# Diagnóstico completo
./diagnose_full.sh > "$LOG_DIR/diagnosis.txt"

# Empacotar
tar -czf "${LOG_DIR}.tar.gz" "$LOG_DIR"
echo "✅ Logs coletados em ${LOG_DIR}.tar.gz"
```

### Relatório de Problemas

Ao reportar problemas, inclua:

1. **Descrição detalhada** do problema
2. **Logs coletados** com o script acima
3. **Passos para reproduzir** o erro
4. **Configurações** do sistema
5. **Hardware** utilizado

### Canais de Suporte

- **GitHub Issues**: Reportar bugs e solicitar features
- **Discord**: Suporte em tempo real
- **Email**: Para problemas críticos
- **Wiki**: Documentação atualizada

---

**Lembre-se**: A maioria dos problemas pode ser resolvida seguindo os passos de diagnóstico acima. Se o problema persistir, colete os logs e entre em contato com a comunidade.
