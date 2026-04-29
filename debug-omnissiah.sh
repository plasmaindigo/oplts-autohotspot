#!/bin/bash


# Debugger Version 0.0.1
# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo ./debug-omnissiah.sh)"
  exit 1
fi

# Color codes for readability
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}==================================================${NC}"
echo -e "${YELLOW}   Omnissiah Network Diagnostic Tool              ${NC}"
echo -e "${YELLOW}==================================================${NC}"
echo ""

# 1. Check Network Interface
echo -e "${YELLOW}[1/5] Checking Wireless Interface...${NC}"
if ip link show wlan0 > /dev/null 2>&1; then
    echo -e "${GREEN}[OK] Interface wlan0 exists.${NC}"
    MAC_ADDR=$(cat /sys/class/net/wlan0/address)
    echo "      MAC Address: $MAC_ADDR"
else
    echo -e "${RED}[FAIL] Interface wlan0 not found! Check hardware or drivers.${NC}"
fi
echo ""

# 2. Check Required Packages
echo -e "${YELLOW}[2/5] Checking Required Packages...${NC}"
PACKAGES=("hostapd" "dnsmasq" "iw" "wpasupplicant" "isc-dhcp-client")
for pkg in "${PACKAGES[@]}"; do
    if dpkg -l | grep -qw "$pkg"; then
        echo -e "${GREEN}[OK] $pkg is installed.${NC}"
    else
        echo -e "${RED}[FAIL] $pkg is missing! Run: apt install $pkg${NC}"
    fi
done
echo ""

# 3. Check Configuration Files
echo -e "${YELLOW}[3/5] Checking Configuration Files...${NC}"

check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}[OK] File exists: $1${NC}"
    else
        echo -e "${RED}[FAIL] File missing: $1${NC}"
    fi
}

check_file "/etc/hostapd/hostapd.conf"
check_file "/etc/dnsmasq.conf"
check_file "/etc/wpa_supplicant/wpa_supplicant.conf"
check_file "/usr/local/bin/auto-wifi.sh"

# Check if script is executable
if [ -x "/usr/local/bin/auto-wifi.sh" ]; then
    echo -e "${GREEN}[OK] Script /usr/local/bin/auto-wifi.sh is executable.${NC}"
else
    echo -e "${RED}[FAIL] Script /usr/local/bin/auto-wifi.sh is NOT executable! Run: chmod +x /usr/local/bin/auto-wifi.sh${NC}"
fi

# Check hostapd default config linkage
if grep -q '^DAEMON_CONF="/etc/hostapd/hostapd.conf"' /etc/default/hostapd; then
    echo -e "${GREEN}[OK] hostapd DAEMON_CONF is correctly linked.${NC}"
else
    echo -e "${RED}[FAIL] hostapd DAEMON_CONF missing in /etc/default/hostapd!${NC}"
fi
echo ""

# 4. Check Systemd Service
echo -e "${YELLOW}[4/5] Checking Systemd Service...${NC}"
if systemctl is-enabled auto-wifi.service > /dev/null 2>&1; then
    echo -e "${GREEN}[OK] auto-wifi.service is ENABLED on boot.${NC}"
else
    echo -e "${RED}[FAIL] auto-wifi.service is DISABLED! Run: systemctl enable auto-wifi.service${NC}"
fi

SERVICE_STATE=$(systemctl is-active auto-wifi.service)
if [ "$SERVICE_STATE" = "active" ]; then
    echo -e "${GREEN}[OK] Service ran successfully (State: active/exited).${NC}"
else
    echo -e "${RED}[WARNING] Service state is: $SERVICE_STATE. Check 'journalctl -u auto-wifi.service' for logs.${NC}"
fi
echo ""

# 5. Check Current Active State
echo -e "${YELLOW}[5/5] Determining Current Network State...${NC}"

WLAN_IP=$(ip -4 addr show wlan0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

if pgrep -x "hostapd" > /dev/null; then
    echo -e "${GREEN}State: HOTSPOT MODE (Omnissiah Active)${NC}"
    echo "      hostapd is running."
    if pgrep -x "dnsmasq" > /dev/null; then
         echo "      dnsmasq is running."
    else
         echo -e "${RED}      WARNING: dnsmasq is NOT running. Clients won't get an IP!${NC}"
    fi
    echo "      Current IP: ${WLAN_IP:-None (Should be 10.0.0.1)}"
elif pgrep -x "wpa_supplicant" > /dev/null; then
    echo -e "${GREEN}State: CLIENT MODE (Connected to known Wi-Fi)${NC}"
    echo "      wpa_supplicant is running."
    echo "      Current IP: ${WLAN_IP:-Waiting for DHCP...}"
    
    # Try to get the SSID it's connected to
    CONNECTED_SSID=$(iw dev wlan0 link | grep "SSID:" | sed 's/^[ \t]*SSID: //')
    if [ ! -z "$CONNECTED_SSID" ]; then
        echo "      Connected Network: $CONNECTED_SSID"
    fi
else
    echo -e "${RED}State: UNKNOWN / DISCONNECTED${NC}"
    echo "      Neither hostapd nor wpa_supplicant are running."
    echo "      Try running the script manually: sudo /usr/local/bin/auto-wifi.sh${NC}"
fi

echo ""
echo -e "${YELLOW}==================================================${NC}"
echo -e "${YELLOW}   Diagnostics Complete                           ${NC}"
echo -e "${YELLOW}==================================================${NC}"