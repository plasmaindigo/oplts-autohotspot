#!/bin/bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo ./install-omnissiah.sh)"
  exit 1
fi

echo "=================================================="
echo "   Initiating the Omnissiah Network Protocol...   "
echo "=================================================="
echo ""

# Gather user variables
read -p "Enter your primary Wi-Fi SSID: " WIFI_SSID
read -p "Enter your Wi-Fi Password: " WIFI_PASS
read -p "Enter your Wi-Fi Country Code [Default: TR]: " COUNTRY_CODE
COUNTRY_CODE=${COUNTRY_CODE:-TR}

echo ""
echo "Appeasing the machine spirits (updating and installing packages)..."
apt-get update
apt-get install -y hostapd dnsmasq iw wpasupplicant isc-dhcp-client

echo "Disabling default startup for hostapd and dnsmasq..."
systemctl disable hostapd dnsmasq
systemctl stop hostapd dnsmasq

echo "Configuring hostapd (Hotspot)..."
cat << EOF > /etc/hostapd/hostapd.conf
interface=wlan0
ssid=Omnissiah
hw_mode=g
channel=6
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=orangepi
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
EOF

sed -i 's|^#DAEMON_CONF=""|DAEMON_CONF="/etc/hostapd/hostapd.conf"|g' /etc/default/hostapd
# Catch the case where it might just be DAEMON_CONF= (without #)
sed -i 's|^DAEMON_CONF=.*|DAEMON_CONF="/etc/hostapd/hostapd.conf"|g' /etc/default/hostapd

echo "Configuring dnsmasq (DHCP)..."
if [ -f /etc/dnsmasq.conf ]; then
    mv /etc/dnsmasq.conf /etc/dnsmasq.conf.backup
fi

cat << EOF > /etc/dnsmasq.conf
interface=wlan0
dhcp-range=10.0.0.10,10.0.0.50,255.255.255.0,12h
EOF

echo "Configuring wpa_supplicant (Known Networks)..."
cat << EOF > /etc/wpa_supplicant/wpa_supplicant.conf
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=$COUNTRY_CODE

network={
    ssid="$WIFI_SSID"
    psk="$WIFI_PASS"
}
EOF

echo "Forging the logic script at /usr/local/bin/auto-wifi.sh..."
# Note: Using 'EOF' with quotes prevents variable expansion during file creation!
cat << 'EOF' > /usr/local/bin/auto-wifi.sh
#!/bin/bash

INTERFACE="wlan0"
WPA_CONF="/etc/wpa_supplicant/wpa_supplicant.conf"

# Give the hardware a moment to wake from sleep
sleep 5
ip link set $INTERFACE up
sleep 3

AVAILABLE_NETWORKS=$(iw dev $INTERFACE scan | grep "SSID:" | sed 's/^[ \t]*SSID: //')
KNOWN_NETWORKS=$(grep -oP '(?<=ssid=")[^"]*' $WPA_CONF)

MATCH_FOUND=false
for network in $KNOWN_NETWORKS; do
    if echo "$AVAILABLE_NETWORKS" | grep -qx "$network"; then
        MATCH_FOUND=true
        break
    fi
done

if [ "$MATCH_FOUND" = true ]; then
    echo "Known network found. Connecting as client..."
    systemctl stop hostapd
    systemctl stop dnsmasq

    ip addr flush dev $INTERFACE
    wpa_supplicant -B -i $INTERFACE -c $WPA_CONF
    dhclient $INTERFACE
else
    echo "No known networks found. Starting Omnissiah hotspot..."

    killall wpa_supplicant 2>/dev/null

    ip addr flush dev $INTERFACE
    ip addr add 10.0.0.1/24 dev $INTERFACE

    systemctl start dnsmasq
    systemctl start hostapd
fi
EOF

chmod +x /usr/local/bin/auto-wifi.sh

echo "Creating and enabling systemd service..."
cat << EOF > /etc/systemd/system/auto-wifi.service
[Unit]
Description=Auto Wi-Fi or Hotspot Setup
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/auto-wifi.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable auto-wifi.service

echo ""
echo "=================================================="
echo " Installation Complete! "
echo " You can safely reboot the Orange Pi now."
echo "=================================================="
