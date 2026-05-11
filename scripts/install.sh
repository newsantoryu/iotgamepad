#!/bin/bash
# install.sh - Instalação completa do IoT GamePad

set -e

echo "🚀 Instalando IoT GamePad PS2..."
echo "================================"

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

# Verificar se está rodando como root
if [ "$EUID" -eq 0 ]; then
    log_error "Não execute este script como root!"
    log_info "Execute como usuário normal: ./install.sh"
    exit 1
fi

# Detectar distribuição
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        VERSION=$VERSION_ID
    else
        log_error "Não foi possível detectar a distribuição"
        exit 1
    fi
    
    log_info "Distribuição detectada: $DISTRO $VERSION"
}

# Atualizar sistema
update_system() {
    log_info "Atualizando sistema..."
    
    case $DISTRO in
        ubuntu|debian)
            sudo apt update && sudo apt upgrade -y
            ;;
        fedora)
            sudo dnf update -y
            ;;
        arch|manjaro)
            sudo pacman -Syu --noconfirm
            ;;
        *)
            log_error "Distribuição não suportada: $DISTRO"
            exit 1
            ;;
    esac
    
    log_success "Sistema atualizado"
}

# Instalar dependências
install_dependencies() {
    log_info "Instalando dependências..."
    
    case $DISTRO in
        ubuntu|debian)
            sudo apt install -y \
                python3 python3-pip python3-venv \
                platformio \
                git \
                build-essential \
                linux-headers-$(uname -r) \
                udev \
                minicom \
                evtest \
                i2c-tools \
                curl \
                wget
            ;;
        fedora)
            sudo dnf install -y \
                python3 python3-pip \
                platformio \
                git \
                gcc gcc-c++ make \
                kernel-devel \
                systemd-udev \
                minicom \
                evtest \
                i2c-tools \
                curl \
                wget
            ;;
        arch|manjaro)
            sudo pacman -S --needed \
                python python-pip \
                platformio \
                git \
                base-devel \
                linux-headers \
                systemd-udev \
                minicom \
                evtest \
                i2c-tools \
                curl \
                wget
            ;;
    esac
    
    log_success "Dependências instaladas"
}

# Configurar ambiente Python
setup_python_env() {
    log_info "Configurando ambiente Python..."
    
    # Criar ambiente virtual
    if [ ! -d "$HOME/iotgamepad-env" ]; then
        python3 -m venv "$HOME/iotgamepad-env"
        log_success "Ambiente virtual criado"
    else
        log_warning "Ambiente virtual já existe"
    fi
    
    # Ativar ambiente e instalar dependências
    source "$HOME/iotgamepad-env/bin/activate"
    pip install --upgrade pip
    pip install pyserial evdev asyncio
    
    log_success "Ambiente Python configurado"
}

# Configurar permissões
setup_permissions() {
    log_info "Configurando permissões do sistema..."
    
    # Adicionar usuário aos grupos necessários
    if ! groups $USER | grep -q "input"; then
        sudo usermod -a -G input $USER
        log_success "Usuário adicionado ao grupo input"
    else
        log_warning "Usuário já está no grupo input"
    fi
    
    if ! groups $USER | grep -q "dialout"; then
        sudo usermod -a -G dialout $USER
        log_success "Usuário adicionado ao grupo dialout"
    else
        log_warning "Usuário já está no grupo dialout"
    fi
    
    # Configurar regras udev para uinput
    echo 'KERNEL=="uinput", MODE="0660", GROUP="input", OPTIONS+="static_node=uinput"' | \
        sudo tee /etc/udev/rules.d/99-uinput.rules
    
    # Configurar regras para dispositivos seriais
    sudo tee /etc/udev/rules.d/99-esp32.rules << EOF
SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", MODE="0666", GROUP="dialout"
SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", MODE="0666", GROUP="dialout"
SUBSYSTEM=="tty", ATTRS{idProduct}=="6001", MODE="0666", GROUP="dialout"
EOF
    
    # Recarregar regras udev
    sudo udevadm control --reload-rules
    sudo udevadm trigger
    
    # Carregar módulo uinput
    sudo modprobe uinput
    echo "uinput" | sudo tee /etc/modules-load.d/uinput.conf
    
    log_success "Permissões configuradas"
}

# Criar scripts auxiliares
create_scripts() {
    log_info "Criando scripts auxiliares..."
    
    # Script de diagnóstico
    sudo tee /usr/local/bin/iotgamepad-diagnose << 'EOF'
#!/bin/bash
echo "🔍 Diagnóstico IoT GamePad"
echo "========================"
echo "Usuário: $USER"
echo "Grupos: $(groups $USER)"
echo "Kernel: $(uname -r)"
echo ""
echo "Dispositivos seriais:"
ls -la /dev/tty* | grep -E "(ACM|USB)" || echo "Nenhum encontrado"
echo ""
echo "Dispositivos input:"
ls -la /dev/input/by-id/ | head -5
echo ""
echo "Módulo uinput:"
lsmod | grep uinput && echo "✅ uinput carregado" || echo "❌ uinput não carregado"
echo ""
echo "Dispositivo uinput:"
ls -la /dev/uinput && echo "✅ uinput disponível" || echo "❌ uinput não disponível"
EOF
    
    # Script de inicialização
    sudo tee /usr/local/bin/iotgamepad-start << 'EOF'
#!/bin/bash
echo "🚀 Iniciando IoT GamePad Bridge..."
cd /home/victor/Documents/PlatformIO/Projects/gamer
source /home/victor/iotgamepad-env/bin/activate
python3 /home/victor/esp32_ds4_bridge_linux.py
EOF
    
    # Script de parada
    sudo tee /usr/local/bin/iotgamepad-stop << 'EOF'
#!/bin/bash
echo "🛑 Parando IoT GamePad Bridge..."
pkill -f esp32_ds4_bridge_linux.py
sudo systemctl stop iotgamepad.service 2>/dev/null || true
EOF
    
    # Tornar scripts executáveis
    sudo chmod +x /usr/local/bin/iotgamepad-*
    
    log_success "Scripts auxiliares criados"
}

# Criar serviço systemd
create_service() {
    log_info "Configurando serviço systemd..."
    
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
    
    # Recarregar systemd
    sudo systemctl daemon-reload
    
    log_success "Serviço systemd configurado"
}

# Verificar instalação
verify_installation() {
    log_info "Verificando instalação..."
    
    # Verificar Python
    if command -v python3 &> /dev/null; then
        log_success "Python3: $(python3 --version)"
    else
        log_error "Python3 não encontrado"
        return 1
    fi
    
    # Verificar ambiente virtual
    if [ -d "$HOME/iotgamepad-env" ]; then
        log_success "Ambiente virtual Python criado"
    else
        log_error "Ambiente virtual não encontrado"
        return 1
    fi
    
    # Verificar PlatformIO
    if command -v pio &> /dev/null; then
        log_success "PlatformIO instalado"
    else
        log_error "PlatformIO não encontrado"
        return 1
    fi
    
    # Verificar uinput
    if [ -e /dev/uinput ]; then
        log_success "Dispositivo uinput disponível"
    else
        log_warning "Dispositivo uinput não disponível (pode precisar de reboot)"
    fi
    
    # Verificar módulo
    if lsmod | grep -q uinput; then
        log_success "Módulo uinput carregado"
    else
        log_warning "Módulo uinput não carregado (pode precisar de reboot)"
    fi
    
    log_success "Verificação concluída"
}

# Mensagem final
show_final_message() {
    echo ""
    echo "🎉 INSTALAÇÃO CONCLUÍDA!"
    echo "======================"
    echo ""
    echo "📋 Próximos passos:"
    echo "1. Faça logout e login novamente para aplicar as permissões"
    echo "2. Conecte o ESP32 com MPU6050"
    echo "3. Compile o firmware: pio run --target upload"
    echo "4. Inicie o bridge: iotgamepad-start"
    echo "5. Configure o PCSX2 para usar 'ESP32-DS4-Bridge'"
    echo ""
    echo "🔧 Scripts disponíveis:"
    echo "- iotgamepad-diagnose  : Diagnóstico do sistema"
    echo "- iotgamepad-start     : Iniciar bridge manualmente"
    echo "- iotgamepad-stop      : Parar bridge"
    echo ""
    echo "📚 Documentação:"
    echo "- docs/INSTALL.md       : Guia de instalação detalhado"
    echo "- docs/USAGE.md         : Guia de uso"
    echo "- docs/TROUBLESHOOTING.md: Solução de problemas"
    echo ""
    echo "⚠️  IMPORTANTE: Faça logout e login para aplicar as permissões!"
}

# Função principal
main() {
    echo "Iniciando instalação do IoT GamePad PS2..."
    echo ""
    
    detect_distro
    update_system
    install_dependencies
    setup_python_env
    setup_permissions
    create_scripts
    create_service
    verify_installation
    show_final_message
    
    echo ""
    log_success "Instalação concluída com sucesso!"
}

# Executar função principal
main "$@"
