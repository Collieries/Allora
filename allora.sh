#!/bin/bash

echo -e "\nПодписаться на канал Web3easy\n"

sleep 2

while true; do
    echo "1. Установить ноду Allora"
    echo "2. Проверить логи ноды Allora"
    echo "3. Проверить статус ноды Allora"
    echo "4. Проверить обновление ноды Allora"
    echo "5. Выйти из скрипта"
    read -p "Выберите опцию: " option

    case $option in
        1)
            echo "Установка ноды..."

            # Обновление пакетов
            echo "Происходит обновление пакетов..."
            if sudo apt update && sudo apt upgrade -y; then
                echo "Обновление пакетов: Успешно"
            else
                echo "Обновление пакетов: Ошибка"
                exit 1
            fi

            # Установка дополнительных пакетов
            echo "Происходит установка дополнительных пакетов..."
            if sudo apt install ca-certificates zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev curl git wget make -y; then
                echo "Установка дополнительных пакетов: Успешно"
            else
                echo "Установка дополнительных пакетов: Ошибка"
                exit 1
            fi

            # Установка Python
            echo "Происходит установка Python..."
            if sudo apt install python3 -y; then
                echo "Установка Python: Успешно"
            else
                echo "Установка Python: Ошибка"
                exit 1
            fi

            echo "Версия Python:"
            python3 --version

            if sudo apt install python3-pip -y; then
                echo "Установка pip для Python: Успешно"
            else
                echo "Установка pip для Python: Ошибка"
                exit 1
            fi

            echo "Версия pip для Python:"
            pip3 --version

            # Установка Docker
            echo "Происходит установка Docker..."
            if curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg &&
               echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null &&
               sudo apt-get update &&
               sudo apt-get install docker-ce docker-ce-cli containerd.io -y; then
                echo "Установка Docker: Успешно"
            else
                echo "Установка Docker: Ошибка"
                exit 1
            fi

            echo "Версия Docker:"
            docker version

            # Установка Docker Compose
            echo "Происходит установка Docker Compose..."
            VER=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
echo
execute_with_prompt 'sudo curl -L "https://github.com/docker/compose/releases/download/'"$VER"'/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose'
echo
execute_with_prompt 'sudo chmod +x /usr/local/bin/docker-compose'
echo
                echo "Установка Docker Compose: Успешно"
            else
                echo "Установка Docker Compose: Ошибка"
                exit 1
            fi

            echo "Версия Docker Compose:"
            docker-compose version

            # Установка разрешений
            echo "Происходит установка разрешений для Docker..."
            if sudo groupadd docker && sudo usermod -aG docker $USER; then
                echo "Установка разрешений для Docker: Успешно"
            else
                echo "Установка разрешений для Docker: Разрешение было применено по умолчанию"
            fi

            # Установка GO
            echo "Происходит установка GO..."
            if sudo rm -rf /usr/local/go &&
               curl -L https://go.dev/dl/go1.22.4.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local &&
               echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile &&
               echo 'export PATH=$PATH:$(go env GOPATH)/bin' >> $HOME/.bash_profile &&
               source $HOME/.bash_profile; then
                echo "Установка GO: Успешно"
            else
                echo "Установка GO: Ошибка"
                exit 1
            fi

            echo "Версия GO:"
            go version

            # Установка Allorad Wallet
            echo "Происходит установка Allorad Wallet..."
            if git clone https://github.com/allora-network/allora-chain.git &&
               cd allora-chain && make all; then
                echo "Установка Allorad Wallet: Успешно"
            else
                echo "Установка Allorad Wallet: Ошибка"
                exit 1
            fi

            echo "Версия Allorad Wallet:"
            allorad version

            # Ввод seed фразы и пароля от кошелька
            echo "Введите seed фразу и пароль от кошелька для Allorad..."
            if allorad keys add testkey --recover; then
                echo "Ввод seed фразы и пароля от кошелька: Успешно"
            else
                echo "Ввод seed фразы и пароля от кошелька: Ошибка"
                exit 1
            fi

            # Установка Worker
            echo "Происходит установка Worker..."
            if cd $HOME && git clone https://github.com/allora-network/basic-coin-prediction-node &&
               cd basic-coin-prediction-node; then
                echo "Установка Worker: Успешно"
            else
                echo "Установка Worker: Ошибка"
                exit 1
            fi

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

            echo "Запуск Allora Worker..."
            chmod +x init.config
            ./init.config
            cd ~/basic-coin-prediction-node
            docker compose up -d --build
            ;;

echo
