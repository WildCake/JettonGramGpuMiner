#!/bin/bash

cd "$HOME" || exit

# Ignore sudo if not installed
if ! [ -x "$(command -v sudo)" ]; then
    alias sudo=""
else
    alias sudo="sudo -E"
fi

# Get distro and version info
if [ -x "$(command -v lsb_release)" ]; then
    distro=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
    version=$(lsb_release -rs)
else
    distro=$(/etc/os-release | grep "^ID=" | cut -d'=' -f2 | tr -d '"' | tr '[:upper:]' '[:lower:]')
    version=$(/etc/os-release | grep "^VERSION_ID=" | cut -d'=' -f2 | tr -d '"')
fi

# Set colors for beautiful output
RED=""
GREEN=""
YELLOW=""
NC=""

if [ -t 1 ]; then
    ncolors=$(tput colors)
    if [ -n "$ncolors" ] && [ "$ncolors" -ge 8 ]; then
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        YELLOW='\033[0;33m'
        NC='\033[0m'
    fi
fi

# install dependencies
echo "Installing dependencies..."
sudo apt update
sudo apt install git -y
sudo apt install openssl -y
sudo apt install nano -y
sudo apt install libc6 -y

wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2_amd64.deb
sudo dpkg -i libssl1.1_1.1.1f-1ubuntu2_amd64.deb || echo "Can't install libssl1.1"
rm libssl1.1_1.1.1f-1ubuntu2_amd64.deb

# Install nodejs
if ! [ -x "$(command -v node)" ]; then
    if [ "$distro" = "ubuntu" ] && { [ "$version" = "18.04" ] || [ "$version" = "18.10" ]; }; then
        curl -fsSL https://kurimuzon.ru/setup_node_17.x | sudo bash - && apt-get install -y nodejs
    else
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash - && apt-get install -y nodejs
    fi
fi

# Check if miner is installed
if [ ! -d "$HOME/miner" ]; then
    echo "Miner not installed. Installing."
    git clone https://github.com/TrueCarry/JettonGramGpuMiner.git miner

    cd miner || exit
    echo "Installing miner..."
else
    cd "$HOME/miner" || exit
    echo "Miner installed. Updating."
    git pull
    echo "Updating miner..."
fi


# Create test file
cat > test.sh << EOL
#!/bin/bash

"$HOME"/miner/pow-miner-cuda -g 0 -F 128 -t 5 kQBWkNKqzCAwA9vjMwRmg7aY75Rf8lByPA9zKXoqGkHi8SM7 229760179690128740373110445116482216837 53919893334301279589334030174039261347274288845081144962207220498400000000000 10000000000 kQBWkNKqzCAwA9vjMwRmg7aY75Rf8lByPA9zKXoqGkHi8SM7 mined.boc
EOL

# Create start file
cat > mine.sh << EOL
#!/bin/bash

GIVERS=1000
TIMEOUT=4
API="tonapi"

GPU_COUNT=\$(nvidia-smi --query-gpu=name --format=csv,noheader | wc -l) > /dev/null 2>&1

if [ "\$GPU_COUNT" = "0" ] || [ "\$GPU_COUNT" = "" ]; then
    echo "Cant get GPU count. Aborting."
    exit 1
fi

echo "Detected \${GPU_COUNT} GPUs"

if [ "\$1" = "gram" ]; then
    echo "Starting GRAM miner"
    if [ "\$GPU_COUNT" = "1" ]; then
        CMD="node send_universal.js --api \${API} --bin ./pow-miner-cuda --givers \${GIVERS} --timeout \${TIMEOUT}"
    else
        CMD="node send_multigpu.js --api \${API} --bin ./pow-miner-cuda --givers \${GIVERS} --gpu-count \${GPU_COUNT} --timeout \${TIMEOUT}"
    fi
elif [ "\$1" = "mrdn" ]; then
    echo "Starting Meridian miner"
    if [ "\$GPU_COUNT" = "1" ]; then
        CMD="node send_meridian.js --api \${API} --bin ./pow-miner-cuda --givers \${GIVERS} --timeout \${TIMEOUT}"
    else
        CMD="node send_multigpu_meridian.js --api \${API} --bin ./pow-miner-cuda --givers \${GIVERS} --gpu-count \${GPU_COUNT} --timeout \${TIMEOUT}"
    fi
else
    echo -e "Invalid argument. Use \${GREEN}./mine.sh mrdn\${NC} or \${GREEN}./mine.sh gram\${NC} to start miner."
    exit 1
fi


npm install

while true; do
    \$CMD
    sleep 1;
done;
EOL

chmod +x test.sh
chmod +x mine.sh

if [ ! -f config.txt ]; then
    cat > config.txt << EOL
SEED=
TONAPI_TOKEN=
TARGET_ADDRESS=
EOL
fi

echo ""
echo    "+------------------------------------------------------------------------+"
echo -e "|                         ${GREEN}Installation complete!${NC}                         |"
echo -e "|                                                                        |"
echo -e "| Start mining with ${GREEN}./mine.sh mrdn${NC} or ${GREEN}./mine.sh gram${NC}                     |"
echo -e "| ${RED}DONT FORGET TO CREATE config.txt WITH ${GREEN}nano config.txt${NC} ${RED}BEFORE START!!!${NC}  |"
echo -e "| ${YELLOW}Donations are welcome: kurimuzonakuma.ton${NC}                              |"
echo    "+------------------------------------------------------------------------+"
