
#!/bin/bash

# Configuration paths
DNSTT_DIR="./dnstt/dnstt-server"
CONFIG_FILE="$DNSTT_DIR/domain.conf"
PRIVATE_KEY="$DNSTT_DIR/server.key"
PUBLIC_KEY="$DNSTT_DIR/server.pub"

# Colors for better display
RED='[0;31m'
GREEN='[0;32m'
YELLOW='[1;33m'
BLUE='[0;34m'
NC='[0m' # No Color

function show_banner() {
    echo -e "${BLUE}"
    echo "========================================"
    echo "       dnstt Server Manager"
    echo "========================================"
    echo -e "${NC}"
}

function change_domain() {
    echo -e "${YELLOW}Current domain configuration:${NC}"
    if [ -f "$CONFIG_FILE" ]; then
        echo "Domain: $(cat $CONFIG_FILE)"
    else
        echo "No domain configured yet"
    fi
    echo

    echo -e "${YELLOW}Enter new domain name (example: mydomain.com):${NC}"
    read -p "> " new_domain

    if [ -z "$new_domain" ]; then
        echo -e "${RED}Domain name cannot be empty!${NC}"
        return
    fi

    # Validate domain format
    if [[ ! "$new_domain" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$ ]]; then
        echo -e "${RED}Invalid domain format!${NC}"
        return
    fi

    echo "$new_domain" > "$CONFIG_FILE"
    echo -e "${GREEN}✓ Domain changed to: $new_domain${NC}"
    echo
    echo -e "${YELLOW}DNS Records to set up:${NC}"
    echo "Type: A"
    echo "Name: tns.$new_domain"
    echo "Value: $(curl -s ifconfig.me 2>/dev/null || echo 'YOUR_SERVER_IP')"
    echo
    echo "Type: NS"
    echo "Name: t.$new_domain"
    echo "Value: tns.$new_domain"
    echo

    # Ask if user wants to restart server with new domain
    echo -e "${YELLOW}Restart server with new domain? (y/n):${NC}"
    read -p "> " restart_choice
    if [[ "$restart_choice" =~ ^[Yy]$ ]]; then
        restart_server
    fi
}

function show_key() {
    if [ ! -f "$PUBLIC_KEY" ]; then
        echo -e "${RED}❌ Public key file not found!${NC}"
        echo "Run the installer first to generate keys."
        return
    fi

    echo -e "${GREEN}📋 Server Public Key:${NC}"
    echo "================================================"
    cat "$PUBLIC_KEY"
    echo "================================================"
    echo
    echo -e "${BLUE}💡 Instructions:${NC}"
    echo "• Copy this key to your clients"
    echo "• Windows users: Save as 'server.pub'"
    echo "• Android users: Paste in app settings"
}

function show_server_status() {
    echo -e "${YELLOW}🔍 Checking server status...${NC}"

    # Check if dnstt server is running
    if screen -list | grep -q "dnstt"; then
        echo -e "${GREEN}✓ dnstt server is running${NC}"
    else
        echo -e "${RED}❌ dnstt server is not running${NC}"
    fi

    # Check if proxy is running
    if screen -list | grep -q "proxy"; then
        echo -e "${GREEN}✓ HTTP proxy is running${NC}"
    else
        echo -e "${RED}❌ HTTP proxy is not running${NC}"
    fi

    # Show current domain
    if [ -f "$CONFIG_FILE" ]; then
        echo -e "${BLUE}📍 Current domain: $(cat $CONFIG_FILE)${NC}"
    else
        echo -e "${YELLOW}⚠️ No domain configured${NC}"
    fi

    # Show server IP
    echo -e "${BLUE}🌐 Server IP: $(curl -s ifconfig.me 2>/dev/null || echo 'Unable to detect')${NC}"
}

function restart_server() {
    echo -e "${YELLOW}🔄 Restarting dnstt server...${NC}"

    # Stop existing servers
    screen -S dnstt -X quit 2>/dev/null
    screen -S proxy -X quit 2>/dev/null

    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${RED}❌ No domain configured! Use option 1 first.${NC}"
        return
    fi

    domain=$(cat "$CONFIG_FILE")

    # Start dnstt server
    cd "$DNSTT_DIR"
    screen -dmS dnstt ./dnstt-server -udp :5300 -privkey-file server.key "t.$domain" 127.0.0.1:8000

    # Start proxy
    screen -dmS proxy nc -l -p 8000 -k

    echo -e "${GREEN}✓ Server restarted with domain: $domain${NC}"
}

function stop_server() {
    echo -e "${YELLOW}🛑 Stopping dnstt server...${NC}"
    screen -S dnstt -X quit 2>/dev/null
    screen -S proxy -X quit 2>/dev/null
    echo -e "${GREEN}✓ Server stopped${NC}"
}

function show_client_info() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${RED}❌ No domain configured!${NC}"
        return
    fi

    domain=$(cat "$CONFIG_FILE")
    server_ip=$(curl -s ifconfig.me 2>/dev/null || echo 'YOUR_SERVER_IP')

    echo -e "${GREEN}📱 Client Connection Information:${NC}"
    echo "================================================"
    echo -e "${BLUE}Server Domain:${NC} t.$domain"
    echo -e "${BLUE}DoH Server:${NC} https://1.1.1.1/dns-query"
    echo -e "${BLUE}Alternative DoH:${NC} https://8.8.8.8/dns-query"
    echo
    echo -e "${YELLOW}Windows Command:${NC}"
    echo "dnstt-client -doh https://1.1.1.1/dns-query -pubkey-file server.pub t.$domain 127.0.0.1:7000"
    echo
    echo -e "${YELLOW}HTTP Injector Settings:${NC}"
    echo "• Server: t.$domain"
    echo "• DoH URL: https://1.1.1.1/dns-query"
    echo "• Public Key: [Copy from option 2]"
    echo "================================================"
}

function uninstall_dnstt() {
    echo "⚠️ This will REMOVE the dnstt server from your system!"
    read -p "Are you sure you want to continue? (y/N): " answer
    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
        echo "Uninstall cancelled."
        return
    fi

    # Stop server (screen sessions)
    screen -S dnstt -X quit 2>/dev/null
    screen -S proxy -X quit 2>/dev/null

    # Remove dnstt directory (if in default location)
    if [ -d "./dnstt" ]; then
        rm -rf ./dnstt
        echo "✓ dnstt program files removed."
    fi

    # Optionally remove menu script itself
    # Uncomment this if you want to self-delete
    # rm -- "$0"

    # Optionally undo firewall rules (advanced users)
    echo "Removing firewall rules for dnstt (UDP port 5300 and 53 redirect)..."
    sudo iptables -D INPUT -p udp --dport 5300 -j ACCEPT 2>/dev/null
    sudo iptables -t nat -D PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300 2>/dev/null
    sudo netfilter-persistent save

    echo "✓ All relevant dnstt server components have been uninstalled."
    echo "If you installed Go, git, etc. solely for dnstt, you can uninstall them with:"
    echo "  sudo apt remove golang-go git screen netcat-openbsd"
    echo "Done!"
}

function main_menu() {
    while true; do
        show_banner
        echo -e "${BLUE}Choose an option:${NC}"
        echo "1. 🌐 Change Domain"
        echo "2. 🔑 Show Server Public Key"
        echo "3. 📊 Server Status"
        echo "4. 🔄 Restart Server"
        echo "5. 🛑 Stop Server"
        echo "6. 📱 Client Connection Info"
        echo "7. 🚪 Exit"
        echo "8. ❌ Uninstall / Remove dnstt Server"
        echo
        read -p "Select option (1-8): " choice

        case $choice in
            1) change_domain ;;
            2) show_key ;;
            3) show_server_status ;;
            4) restart_server ;;
            5) stop_server ;;
            6) show_client_info ;;
            7) 
                echo -e "${GREEN}👋 Goodbye!${NC}"
                exit 0 
                ;;
            8) uninstall_dnstt ;;
            *) 
                echo -e "${RED}❌ Invalid option! Please try again.${NC}"
                sleep 1
                ;;
        esac

        echo
        echo -e "${YELLOW}Press Enter to continue...${NC}"
        read
        clear
    done
}

# Check if dnstt directory exists
if [ ! -d "$DNSTT_DIR" ]; then
    echo -e "${RED}❌ dnstt not found! Please run the installer first.${NC}"
    exit 1
fi

# Start the menu
clear
main_menu
