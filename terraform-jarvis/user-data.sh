#!/bin/bash
sudo apt update -y
sudo apt install -y git python3 python3-pip

cd /home/ubuntu
git clone https://github.com/Maheshshelke05/Jarvis-Desktop-Voice-Assistant.git
cd Jarvis-Desktop-Voice-Assistant

pip3 install -r requirements.txt

sudo cat <<EOF > /etc/systemd/system/jarvis.service
[Unit]
Description=Jarvis Voice Assistant
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/home/ubuntu/Jarvis-Desktop-Voice-Assistant
ExecStart=/usr/bin/python3 /home/ubuntu/Jarvis-Desktop-Voice-Assistant/jarvis.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable jarvis
sudo systemctl start jarvis
