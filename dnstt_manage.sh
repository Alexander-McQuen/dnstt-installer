#!/bin/bash

# Simple DNSTT Server Management Menu
# Designed for complete beginners

clear
echo "Welcome to DNSTT Server Management Menu"
echo "========================================"

while true; do
  echo "Please select an option by typing the number and pressing Enter:"
  echo "1) Install DNSTT Server"
  echo "2) Change Domain"
  echo "3) Show Server Public Key"
  echo "4) Start DNSTT Server"
  echo "5) Stop DNSTT Server"
  echo "6) Uninstall DNSTT Server"
  echo "7) Exit"

  # Prompt user for choice
  read -p "Enter your choice (1-7): " choice

  case $choice in
    1)
      echo "Installing DNSTT server..."
      ./install_dnstt_server.sh
      echo "Installation finished. Please read documentation for next steps."
      ;;
    2)
      read -p "Enter your domain name (example.com): " domain
      echo "$domain" > ./dnstt/dnstt-server/domain.conf
      echo "Domain updated."
      ;;
    3)
      if [ -f ./dnstt/dnstt-server/server.pub ]; then
        echo "====== Server Public Key ======"
        cat ./dnstt/dnstt-server/server.pub
        echo "==============================="
      else
        echo "Public key not found. Please run the installer first."
      fi
      ;;
    4)
      echo "Starting DNSTT server..."
      screen -dmS dnstt ./dnstt/dnstt-server/dnstt-server -udp :5300 -privkey-file ./dnstt/dnstt-server/server.key t.$(cat ./dnstt/dnstt-server/domain.conf) 127.0.0.1:8000
      echo "Server started in screen session 'dnstt'."
      ;;
    5)
      echo "Stopping DNSTT server..."
      screen -S dnstt -X quit
      echo "Server stopped."
      ;;
    6)
      read -p "WARNING: This will remove the DNSTT server and all configuration. Continue? (y/n): " confirm
      if [[ $confirm == [yY] ]]; then
        screen -S dnstt -X quit
        rm -rf ./dnstt
        echo "DNSTT server uninstalled."
      else
        echo "Uninstall cancelled."
      fi
      ;;
    7)
      echo "Exiting. Goodbye!"
      exit 0
      ;;
    *)
      echo "Invalid option. Please enter a number between 1 and 7."
  esac
  echo ""
  read -p "Press Enter to return to the menu..."
  clear
  echo "Welcome to DNSTT Server Management Menu"
  echo "========================================"
done
