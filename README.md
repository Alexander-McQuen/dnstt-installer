
# dnstt Server Installer for Ubuntu 22+

This repository contains a simple script to install and run a dnstt DNS tunnel server on Ubuntu 22 or later. This helps bypass internet censorship by tunneling DNS traffic through secure channels.

## What is dnstt?

dnstt (DNS Tunnel) is a software to tunnel internet traffic using DNS, making it harder to block or filter by censorship systems.

## This Script Does:
- Installs all needed software
- Builds the dnstt server
- Generates server security keys
- Configures your system firewall
- Starts the dnstt server
- Runs a simple HTTP proxy for tunneling

## How to Use This Repository (Step-by-step)

### Step 1: Access Your Ubuntu Server

- You need an Ubuntu 22 or newer server. You must be able to connect to it via SSH.
- If you do not have a server, services like DigitalOcean, Linode, or Vultr offer affordable options.

### Step 2: Download This Installer Script

Run this command on your Ubuntu server terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/dnstt-installer/main/install_dnstt_server.sh -o install_dnstt_server.sh
```

### Step 3: Run The Installer Script

Make the script executable and run it:

```bash
chmod +x install_dnstt_server.sh
sudo ./install_dnstt_server.sh
```

The script will automatically install everything and start your dnstt server.

### Step 4: Configure Your DNS Records

- You need to set up domain DNS records for your server as follows:

| Type | Name | Value |
|------|------|-------|
| A | tns.yourdomain.com | Your VPS IPv4 address |
| AAAA | tns.yourdomain.com | Your VPS IPv6 address (if available) |
| NS | t.yourdomain.com | tns.yourdomain.com |

- Replace `yourdomain.com` with your actual domain.

### Step 5: Client Setup

- For Windows and Android, you can use dnstt client apps or tools like HTTP Injector with dnstt plugin.
- Detailed client setup instructions will be provided soon.

## Notes

- Keep your private keys secure.
- UDP mode is not recommended due to censorship detection.
- Use DNS over HTTPS (DoH) or DNS over TLS (DoT) for better security and reliability.

---

If you need help, please open an issue or contact me.
