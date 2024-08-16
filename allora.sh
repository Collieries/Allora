#!/bin/bash

# Функция для логгирования сообщений
log_message() {
    echo -e "\e[32m$1\e[0m"
}

# Функция для выполнения команд с обработкой ошибок
run_command() {
    local command="$1"
    local error_message="$2"
    
    log_message "Выполняется: $command"
    if eval "$command"; then
        log_message "Успешно выполнено: $command"
    else
        log_message "$error_message"
        exit 1
    fi
}

# Функция для перезагрузки Docker
restart_docker() {
    log_message "Перезагружаем Docker..."
    run_command "sudo systemctl restart docker" "Не удалось перезагрузить Docker. Проверьте состояние сервиса Docker."
}

# Функция для клонирования репозитория
clone_repository() {
    local repo_url="$1"
    local target_dir="$2"
    
    if [ -d "$target_dir" ]; then
        log_message "Удаление существующей директории $target_dir..."
        rm -rf "$target_dir"
    fi
    
    run_command "git clone $repo_url $target_dir" "Не удалось клонировать репозиторий $repo_url"
}

echo -e "\nПогрузись в мир Web3 вместе с https://web3easy.media\n"

sleep 2

# Основной цикл меню
while true; do
    echo "1. Установить ноду Allora"
    echo "2. Проверить логи ноды Allora"
    echo "3. Проверить статус ноды Allora"
    echo "4. Выйти из скрипта"
    read -p "Выберите опцию: " option

    case $option in
        1)
            log_message "Обновление и установка пакетов..."
            run_command "sudo apt update && sudo apt upgrade -y && sudo apt install jq" "Не удалось обновить и установить пакеты."
            run_command "sudo apt install ca-certificates zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev curl git wget make jq build-essential pkg-config lsb-release libssl-dev libreadline-dev libffi-dev gcc screen unzip lz4 -y" "Не удалось установить необходимые пакеты."

            log_message "Установка Python..."
            run_command "sudo apt install python3 -y" "Не удалось установить Python."

            log_message "Установка pip3..."
            run_command "sudo apt install python3-pip -y" "Не удалось установить pip3."

            log_message "Установка Docker..."
            run_command "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && echo 'deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable' | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null && sudo apt-get update && sudo apt-get install docker-ce docker-ce-cli containerd.io -y" "Не удалось установить Docker."

            log_message "Установка Docker Compose..."
            run_command "sudo apt-get install docker-compose -y" "Не удалось установить Docker Compose."
            run_command "VER=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)"
            run_command "sudo curl -L "https://github.com/docker/compose/releases/download/'"$VER"'/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose"
            run_command "sudo chmod +x /usr/local/bin/docker-compose"
                
            log_message "Установка GO..."
            run_command "sudo rm -rf /usr/local/go && curl -L https://go.dev/dl/go1.22.4.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local && echo 'export PATH=\$PATH:/usr/local/go/bin:\$HOME/go/bin' >> \$HOME/.bash_profile && echo 'export PATH=\$PATH:\$(go env GOPATH)/bin' >> \$HOME/.bash_profile && source \$HOME/.bash_profile" "Не удалось установить GO."

            log_message "Установка Allorad Wallet..."
            clone_repository "https://github.com/allora-network/allora-chain.git" "allora-chain"
            run_command "cd allora-chain && make all" "Не удалось установить Allorad Wallet."

            log_message "Запрос Seed Phrase у пользователя..."
            run_command "allorad keys add testkey --recover" "Не удалось запросить Seed Phrase."

            log_message "Установка Allora Worker..."
            run_command "cd \$HOME"
            run_command "git clone https://github.com/allora-network/basic-coin-prediction-node"
            run_command "cd basic-coin-prediction-node"

            rm -rf config.json
            
            # Запрос Seed Phrase
            read -p "Введите вашу Seed Phrase: " seed_phrase

            # Создание нового файла config.json
            cat <<EOF > config.json
{
    "wallet": {
        "addressKeyName": "testkey",
        "addressRestoreMnemonic": "$seed_phrase",
        "alloraHomeDir": "",
        "gas": "1000000",
        "gasAdjustment": 1.0,
        "nodeRpc": "https://sentries-rpc.testnet-1.testnet.allora.network/",
        "maxRetries": 1,
        "delay": 1,
        "submitTx": false
    },
    "worker": [
        {
            "topicId": 1,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 5,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "ETH"
            }
        },
        {
            "topicId": 2,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 5,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "ETH"
            }
        },
        {
            "topicId": 7,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 5,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "ETH"
            }
        }
    ]
}
EOF

            log_message "Запуск Allora Worker..."
            mkdir worker-data
            chmod +x init.config
            sleep 2
            ./init.config
            run_command "docker compose build"
            run_command "docker-compose up -d"
            ;;
        2)
            log_message "Проверка логов..."
            sleep 10
            run_command "docker compose logs -f worker" "Не удалось вывести логи контейнера. Проверьте состояние Docker."
            ;;
        3)
            log_message "Проверка цены Ethereum через ноду..."
            response=$(curl -s http://localhost:8000/inference/ETH)
            if [ -z "$response" ]; then
                log_message "Не удалось получить цену ETH. Проверьте состояние ноды."
            else
                log_message "Цена ETH: $response"
            fi
            ;;
        4)
            log_message "Выход из скрипта."
            exit 0
            ;;
        *)
            log_message "Неверный выбор. Пожалуйста, попробуйте снова."
            ;;
    esac
done
