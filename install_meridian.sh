#!/bin/bash

if [ ! -d "/root/JettonGramGpuMiner" ]; then
    echo "Miner not installed. Installing."
    apt install nano

    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - && sudo apt-get install -y nodejs

    cd /root || exit
    git clone https://github.com/WildCake/JettonGramGpuMiner.git

    cd JettonGramGpuMiner || exit
else
    cd /root/JettonGramGpuMiner || exit
    echo "Miner installed. Updating."
    git pull
fi

GPU_COUNT=$(nvidia-smi --query-gpu=name --format=csv,noheader | wc -l)

if [ "$GPU_COUNT" = "" ]; then
echo "Cant get GPU count. Aborting."
exit 1
elif [ "$GPU_COUNT" = "1" ]; then
echo "One GPU detected. Creating start file"
    cat > 1000.sh << EOL
    #!/bin/bash
    npm install


    while true; do
    node send_meridian.js --api lite --bin ./pow-miner-cuda --givers 1000 -c https://raw.githubusercontent.com/john-phonk/config/main/config.json
    sleep 0.5;
    done;
EOL
else
    cat > 1000.sh << EOL
    #!/bin/bash
    npm install


    while true; do
    node send_multigpu_meridian.js --api lite --bin ./pow-miner-cuda --givers 1000 --gpu-count ${GPU_COUNT} -c https://raw.githubusercontent.com/john-phonk/config/main/config.json
    sleep 0.5;
    done;
EOL
fi

chmod +x 1000.sh

echo "Installed! Start mining with ./1000.sh"
printf "\x1B[31mDONT FORGET TO CREATE config.txt BEFORE START!!!\x1B[0m\n"
