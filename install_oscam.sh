#!/bin/bash

# Função para verificar se o script está sendo executado como root
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        echo "Por favor, execute como root"
        exit
    fi
}

# Função para instalar todas as dependências e compilar o OSCam sem copiar arquivos de configuração
install_oscam_without_config() {
    echo "Atualizando os pacotes..."
    apt update && apt upgrade -y
    echo "Instalando as dependências necessárias, incluindo PCSC..."
    apt install opensc -y
    apt install -y build-essential cmake libssl-dev libusb-1.0-0-dev libpcsclite-dev libreadline-dev libncurses5-dev libcrypto++-dev git pkg-config pcscd
    echo "Clonando o repositório OSCam..."
    git clone https://git.streamboard.tv/common/oscam.git /opt/oscam
    cd /opt/oscam
    echo "Iniciando a compilação do OSCam..."
    mkdir build && cd build
    cmake ..
    make -j$(nproc)
    if [ $? -ne 0 ]; then
        echo "Erro na compilação do OSCam"
        exit 1
    fi
    echo "Movendo o binário compilado para /usr/local/bin/..."
    cp /opt/oscam/build/oscam /usr/local/bin/oscam
    echo "Ajustando permissões..."
    chmod +x /usr/local/bin/oscam
    echo "Ativando o serviço pcscd (suporte a smartcards)..."
    systemctl enable pcscd
    systemctl start pcscd
    echo "Instalação do OSCam finalizada sem copiar arquivos de configuração."
}

# Função para instalar todas as dependências e compilar o OSCam com arquivos de configuração
install_complete_oscam() {
    install_oscam_without_config

    echo "Baixando arquivos de configuração e o script restart-oscam.sh do repositório..."
    git clone https://github.com/tauelektronik/auto_oscam.git /tmp/auto_oscam_temp
    echo "Copiando arquivos de configuração para /usr/local/etc/..."
    cp -r /tmp/auto_oscam_temp/etc/* /usr/local/etc/
    echo "Movendo restart-oscam.sh para a raiz do Linux e dando permissão de execução..."
    cp /tmp/auto_oscam_temp/restart-oscam.sh /restart-oscam.sh
    chmod +x /restart-oscam.sh
    echo "Limpando os arquivos temporários..."
    rm -rf /tmp/auto_oscam_temp
    echo "Instalação completa do OSCam finalizada com sucesso."
}

# Função para baixar apenas os scripts install_oscam.sh e restart-oscam.sh
download_scripts_only() {
    echo "Baixando os scripts do repositório..."
    git clone https://github.com/tauelektronik/auto_oscam.git /tmp/auto_oscam_temp
    echo "Movendo restart-oscam.sh para a raiz do Linux e dando permissão de execução..."
    cp /tmp/auto_oscam_temp/restart-oscam.sh /restart-oscam.sh
    chmod +x /restart-oscam.sh
    echo "Movendo install_oscam.sh para o diretório atual e dando permissão de execução..."
    cp /tmp/auto_oscam_temp/install_oscam.sh ./install_oscam.sh
    chmod +x ./install_oscam.sh
    echo "Limpando os arquivos temporários..."
    rm -rf /tmp/auto_oscam_temp
    echo "Scripts baixados e prontos para uso."
}

# Função para perguntar qual tipo de instalação o usuário deseja
menu() {
    echo "Deseja fazer uma instalação completa do OSCam (incluindo arquivos de configuração)? [s/n]"
    read -p "Escolha [s/n]: " option
    case $option in
        s|S)
            install_complete_oscam
            ;;
        n|N)
            install_oscam_without_config
            ;;
        *)
            echo "Opção inválida!"
            menu
            ;;
    esac
    # Removendo o arquivo install_oscam.sh após a instalação
    echo "Removendo o arquivo install_oscam.sh..."
    rm -f ./install_oscam.sh
    echo "Arquivo install_oscam.sh removido."
}

# Execução principal
check_root
menu
