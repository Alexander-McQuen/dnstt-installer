
#!/bin/bash

# Update and upgrade packages
sudo apt update && sudo apt upgrade -y

# Install dependencies
sudo apt install -y git golang iptables ip6tables screen

# Clone dnstt repository
if [ ! -d "dnstt" ]; then
    git clone https://www.bamsoftware.com/git/dnstt.git
fi

# Build dnstt server
cd dnstt/dnstt-server || exit
/go build

# Generate server keys
./dnstt-server -gen-key -privkey-file server.key -pubkey-file server.pub

# Setup port forwarding for UDP port 53 to 5300
sudo iptables -I INPUT -p udp --dport 5300 -j ACCEPT
sudo iptables -t nat -I PREROUTING -i eth0 -p udp --dport 53 -j REDIRECT --to-ports 5300
sudo ip6tables -I INPUT -p udp --dport 5300 -j ACCEPT
sudo ip6tables -t nat -I PREROUTING -i eth0 -p udp --dport 53 -j REDIRECT --to-ports 5300

# Run dnstt server in a detached screen session
screen -dmS dnstt ./dnstt-server -udp :5300 -privkey-file server.key t.example.com 127.0.0.1:8000

# Run a simple TCP listener on port 8000 for the tunnel server to connect to
# This is for demonstration, you can replace it with a proxy server or SSH forwarding
sudo apt install -y ncat
screen -dmS ncat ncat -l -k -v 127.0.0.1 8000

