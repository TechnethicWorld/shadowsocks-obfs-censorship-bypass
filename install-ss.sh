
#!/bin/bash

read -p "Enter the Shadowsocks server port (e.g. 8388): " SERVER_PORT
read -p "Enter the Shadowsocks password: " PASSWORD

# Update packages
sudo apt update && sudo apt upgrade -y

# Install shadowsocks-libev and simple-obfs
sudo apt install -y shadowsocks-libev simple-obfs

# Create configuration file
cat > /etc/shadowsocks-libev/config.json <<EOF
{
    "server":"0.0.0.0",
    "server_port":${SERVER_PORT},
    "password":"${PASSWORD}",
    "timeout":300,
    "method":"aes-256-gcm",
    "plugin":"obfs-server",
    "plugin_opts":"obfs=tls"
}
EOF

# Stop existing service if running
sudo systemctl stop shadowsocks-libev || true
sudo pkill -f ss-server || true

# Run ss-server in background
nohup ss-server -c /etc/shadowsocks-libev/config.json > /var/log/ss-server.log 2>&1 &

# Open firewall ports if ufw is enabled
if sudo ufw status | grep -q "inactive"; then
    echo "Firewall (ufw) is not active. Enabling it now."
    sudo ufw enable
fi
sudo ufw allow ${SERVER_PORT}/tcp
sudo ufw allow ${SERVER_PORT}/udp

# Output result
echo "-------------------------------------------------"
echo "Shadowsocks-libev with simple-obfs (obfs=tls) has been started."
echo "Port: ${SERVER_PORT}"
echo "Password: ${PASSWORD}"
echo "Firewall ports ${SERVER_PORT}/tcp and /udp are open."
echo "-------------------------------------------------"
