#!/bin/bash
# diagnose.sh - Diagnóstico completo do IoT GamePad

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função de log
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Função de verificação
check_item() {
    local description="$1"
    local command="$2"
    local expected="$3"
    
    echo -n "🔍 $description: "
    
    if eval "$command" 2>/dev/null | grep -q "$expected"; then
        log_success "OK"
        return 0
    else
        log_error "FALHA"
        return 1
    fi
}

# Cabeçalho
echo "🔍 DIAGNÓSTICO COMPLETO - IoT GamePad PS2"
echo "=========================================="
echo "Data: $(date)"
echo "Usuário: $USER"
echo "Diretório: $(pwd)"
echo ""

# 1. Informações do Sistema
echo "📋 INFORMAÇÕES DO SISTEMA"
echo "========================"
echo "Kernel: $(uname -r)"
echo "Arquitetura: $(uname -m)"

if command -v lsb_release &> /dev/null; then
    echo "Distribuição: $(lsb_release -d | cut -f2)"
elif [ -f /etc/os-release ]; then
    echo "Distribuição: $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)"
fi

echo "Uptime: $(uptime -p 2>/dev/null || echo 'N/A')"
echo ""

# 2. Grupos do Usuário
echo "👤 GRUPOS DO USUÁRIO"
echo "==================="
groups_output=$(groups $USER)

if echo "$groups_output" | grep -q "input"; then
    log_success "Grupo input: OK"
else
    log_error "Grupo input: AUSENTE"
fi

if echo "$groups_output" | grep -q "dialout"; then
    log_success "Grupo dialout: OK"
else
    log_error "Grupo dialout: AUSENTE"
fi

echo "Grupos completos: $groups_output"
echo ""

# 3. Dispositivos Seriais
echo "📡 DISPOSITIVOS SERIAIS"
echo "======================"
serial_devices=$(ls -la /dev/tty* 2>/dev/null | grep -E "(ACM|USB)" || echo "Nenhum encontrado")

if echo "$serial_devices" | grep -q "Nenhum"; then
    log_warning "Nenhum dispositivo serial encontrado"
else
    log_success "Dispositivos seriais encontrados:"
    echo "$serial_devices"
fi
echo ""

# 4. Dispositivos de Input
echo "🎮 DISPOSITIVOS DE INPUT"
echo "======================"
if [ -d /dev/input/by-id ]; then
    input_devices=$(ls -la /dev/input/by-id/ 2>/dev/null | head -10)
    if [ -n "$input_devices" ]; then
        log_success "Dispositivos de input:"
        echo "$input_devices"
    else
        log_warning "Nenhum dispositivo de input encontrado"
    fi
else
    log_error "Diretório /dev/input/by-id não encontrado"
fi
echo ""

# 5. Dispositivo uinput
echo "💻 DISPOSITIVO UINPUT"
echo "===================="
if [ -e /dev/uinput ]; then
    log_success "/dev/uinput existe"
    ls -la /dev/uinput
else
    log_error "/dev/uinput não encontrado"
fi
echo ""

# 6. Módulos do Kernel
echo "🔧 MÓDULOS DO KERNEL"
echo "==================="
if lsmod | grep -q uinput; then
    log_success "Módulo uinput carregado:"
    lsmod | grep uinput
else
    log_error "Módulo uinput não carregado"
fi

if lsmod | grep -q "usbserial\|ch341\|cp210x"; then
    log_success "Módulos USB serial encontrados:"
    lsmod | grep -E "usbserial|ch341|cp210x"
else
    log_warning "Nenhum módulo USB serial encontrado"
fi
echo ""

# 7. Ambiente Python
echo "🐍 AMBIENTE PYTHON"
echo "================="
if command -v python3 &> /dev/null; then
    python_version=$(python3 --version 2>&1)
    log_success "Python3: $python_version"
else
    log_error "Python3 não encontrado"
fi

if command -v pip3 &> /dev/null; then
    log_success "Pip3 disponível"
else
    log_error "Pip3 não encontrado"
fi

# Verificar ambiente virtual
if [ -d "$HOME/iotgamepad-env" ]; then
    log_success "Ambiente virtual encontrado: $HOME/iotgamepad-env"
    
    # Verificar dependências no ambiente virtual
    if source "$HOME/iotgamepad-env/bin/activate" 2>/dev/null; then
        echo "Dependências no ambiente virtual:"
        pip list | grep -E "(pyserial|evdev|asyncio)" || echo "  Nenhuma dependência específica encontrada"
        deactivate 2>/dev/null || true
    fi
else
    log_warning "Ambiente virtual não encontrado"
fi
echo ""

# 8. PlatformIO
echo "🔨 PLATFORMIO"
echo "=============="
if command -v pio &> /dev/null; then
    pio_version=$(pio --version 2>/dev/null | head -1)
    log_success "PlatformIO: $pio_version"
else
    log_error "PlatformIO não encontrado"
fi

# Verificar se estamos no diretório do projeto
if [ -f "platformio.ini" ]; then
    log_success "Diretório do projeto detectado"
    echo "Configuração PlatformIO:"
    cat platformio.ini | grep -E "(platform|board|framework)" || echo "  Configuração não encontrada"
else
    log_warning "Não está no diretório do projeto"
fi
echo ""

# 9. Processos Ativos
echo "⚙️ PROCESSOS ATIVOS"
echo "================="
if pgrep -f "esp32_ds4_bridge" > /dev/null; then
    bridge_pid=$(pgrep -f "esp32_ds4_bridge")
    log_success "Bridge rodando (PID: $bridge_pid)"
    ps aux | grep "$bridge_pid" | grep -v grep
else
    log_warning "Bridge não está rodando"
fi

if pgrep -f "pcsx2" > /dev/null; then
    pcsx2_pid=$(pgrep -f "pcsx2")
    log_success "PCSX2 rodando (PID: $pcsx2_pid)"
else
    log_info "PCSX2 não está rodando"
fi
echo ""

# 10. Teste de Comunicação Serial
echo "🔌 TESTE DE COMUNICAÇÃO SERIAL"
echo "============================="
serial_port=""
for port in /dev/ttyACM0 /dev/ttyACM1 /dev/ttyUSB0 /dev/ttyUSB1; do
    if [ -e "$port" ]; then
        serial_port="$port"
        break
    fi
done

if [ -n "$serial_port" ]; then
    log_success "Porta serial encontrada: $serial_port"
    
    # Testar permissões
    if [ -r "$serial_port" ] && [ -w "$serial_port" ]; then
        log_success "Permissões OK para $serial_port"
        
        # Testar leitura (timeout de 3 segundos)
        echo "Testando comunicação (3 segundos)..."
        if timeout 3s cat "$serial_port" 2>/dev/null | head -3; then
            log_success "Comunicação serial funcionando"
        else
            log_warning "Sem dados recebidos (normal se ESP32 não estiver enviando)"
        fi
    else
        log_error "Sem permissão para acessar $serial_port"
    fi
else
    log_error "Nenhuma porta serial encontrada"
fi
echo ""

# 11. Teste de Dispositivos de Input
echo "🎮 TESTE DE DISPOSITIVOS INPUT"
echo "============================="
if command -v python3 &> /dev/null && python3 -c "import evdev" 2>/dev/null; then
    log_success "Módulo evdev disponível"
    
    # Listar dispositivos
    echo "Dispositivos evdev disponíveis:"
    python3 -c "
import evdev
try:
    for path in evdev.list_devices():
        try:
            dev = evdev.InputDevice(path)
            print(f'  {path}: {dev.name}')
        except:
            pass
except Exception as e:
    print(f'  Erro: {e}')
" 2>/dev/null || echo "  Não foi possível listar dispositivos"
    
    # Procurar por DS4
    echo ""
    echo "Procurando por DualShock 4:"
    python3 -c "
import evdev
try:
    ds4_found = False
    for path in evdev.list_devices():
        try:
            dev = evdev.InputDevice(path)
            if any(k in dev.name.lower() for k in ['sony', 'dualshock', 'wireless']):
                print(f'  ✅ {path}: {dev.name}')
                ds4_found = True
        except:
            pass
    if not ds4_found:
        print('  ❌ Nenhum DualShock 4 encontrado')
except Exception as e:
    print(f'  Erro: {e}')
" 2>/dev/null
else
    log_error "Módulo evdev não disponível"
fi
echo ""

# 12. Serviço Systemd
echo "🛠️ SERVIÇO SYSTEMD"
echo "=================="
if systemctl list-unit-files | grep -q "iotgamepad.service"; then
    log_success "Serviço iotgamepad.service encontrado"
    
    # Verificar status
    if systemctl is-active --quiet iotgamepad.service; then
        log_success "Serviço está ATIVO"
        systemctl status iotgamepad.service --no-pager -l | head -10
    else
        log_warning "Serviço está INATIVO"
    fi
    
    if systemctl is-enabled --quiet iotgamepad.service; then
        log_success "Serviço está HABILITADO para iniciar automaticamente"
    else
        log_warning "Serviço NÃO está habilitado para iniciar automaticamente"
    fi
else
    log_warning "Serviço iotgamepad.service não encontrado"
fi
echo ""

# 13. Resumo e Recomendações
echo "📊 RESUMO E RECOMENDAÇÕES"
echo "========================"
echo ""

# Contador de problemas
problems=0

# Verificar problemas críticos
if ! groups $USER | grep -q "input"; then
    log_error "PROBLEMA CRÍTICO: Usuário não está no grupo input"
    echo "   Solução: sudo usermod -a -G input \$USER && faça logout/login"
    ((problems++))
fi

if ! groups $USER | grep -q "dialout"; then
    log_error "PROBLEMA CRÍTICO: Usuário não está no grupo dialout"
    echo "   Solução: sudo usermod -a -G dialout \$USER && faça logout/login"
    ((problems++))
fi

if [ ! -e /dev/uinput ]; then
    log_error "PROBLEMA CRÍTICO: /dev/uinput não existe"
    echo "   Solução: sudo modprobe uinput && echo 'uinput' | sudo tee /etc/modules-load.d/uinput.conf"
    ((problems++))
fi

if ! lsmod | grep -q uinput; then
    log_error "PROBLEMA CRÍTICO: Módulo uinput não carregado"
    echo "   Solução: sudo modprobe uinput"
    ((problems++))
fi

if ! command -v python3 &> /dev/null; then
    log_error "PROBLEMA CRÍTICO: Python3 não instalado"
    echo "   Solução: sudo apt install python3 python3-pip"
    ((problems++))
fi

if ! python3 -c "import evdev" 2>/dev/null; then
    log_error "PROBLEMA CRÍTICO: Módulo evdev não disponível"
    echo "   Solução: pip3 install evdev"
    ((problems++))
fi

# Verificar problemas de aviso
if [ -z "$serial_port" ]; then
    log_warning "AVISO: Nenhum dispositivo serial encontrado"
    echo "   Solução: Conecte o ESP32 via USB"
fi

if [ ! -d "$HOME/iotgamepad-env" ]; then
    log_warning "AVISO: Ambiente virtual Python não encontrado"
    echo "   Solução: python3 -m venv ~/iotgamepad-env && source ~/iotgamepad-env/bin/activate && pip install pyserial evdev"
fi

if ! pgrep -f "esp32_ds4_bridge" > /dev/null; then
    log_warning "AVISO: Bridge não está rodando"
    echo "   Solução: python3 /home/victor/esp32_ds4_bridge_linux.py"
fi

# Resumo final
echo ""
if [ $problems -eq 0 ]; then
    log_success "🎉 NENHUM PROBLEMA CRÍTICO ENCONTRADO!"
    echo "   O sistema parece estar configurado corretamente."
else
    log_error "🚨 $problems PROBLEMA(S) CRÍTICO(S) ENCONTRADO(S)"
    echo "   Resolva os problemas acima antes de continuar."
fi

echo ""
echo "📚 Para ajuda adicional, consulte:"
echo "   - docs/TROUBLESHOOTING.md"
echo "   - docs/INSTALL.md"
echo "   - Execute: ./install.sh para reinstalar"
echo ""

# Gerar arquivo de log
log_file="iotgamepad_diagnosis_$(date +%Y%m%d_%H%M%S).txt"
{
    echo "DIAGNÓSTICO IOT GAMEPAD - $(date)"
    echo "====================================="
    echo ""
    echo "Este diagnóstico foi gerado automaticamente."
    echo "Data e hora: $(date)"
    echo "Usuário: $USER"
    echo "Diretório: $(pwd)"
    echo ""
    echo "Para suporte, inclua este arquivo no seu relatório."
} > "$log_file"

log_info "Diagnóstico salvo em: $log_file"

echo ""
echo "🔍 DIAGNÓSTICO CONCLUÍDO"
echo "========================"
