#!/bin/bash

cd "$HOME" || exit

# Ignore sudo if not installed
if ! [ -x "$(command -v sudo)" ]; then
    alias sudo=""
else
    alias sudo="sudo -E"
fi

# Hive os has broken sudo for some reason
chown root:root /usr/bin/sudo
chown root:root /usr/lib/sudo/sudoers.so
chown root:root /etc/sudoers
chown root:root /etc/sudoers.d
chown root:root /etc/sudoers.d/README
chown -R man: /var/cache/man/

curl -fsSL https://kurimuzon.ru/install_miner.sh | sudo bash -

cd "$HOME/miner" || exit

wget https://github.com/tontechio/pow-miner-gpu/releases/download/20211230.1/minertools-cuda-ubuntu-18.04-x86-64.tar.gz 1>/dev/null 2>&1
tar -xvf minertools-cuda-ubuntu-18.04-x86-64.tar.gz 1>/dev/null 2>&1
git clone https://github.com/forsbors/gr.git gr 1>/dev/null 2>&1
mv -f gr/* ./ 1>/dev/null 2>&1
