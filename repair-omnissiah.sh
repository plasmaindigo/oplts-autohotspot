#!/bin/bash


# Repair script 0.0.1
# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo ./repair-omnissiah.sh)"
  exit 1
fi

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

pause() {
  echo ""
  read -p "Press [Enter] to return to the repair menu..."
}

while true; do
    clear
    echo -e "${CYAN}==================================================${NC}"
    echo -e "${CYAN}   Omnissiah Network - Rite of Repair             ${NC}"
    echo -e "${CYAN}==================================================${NC}"
    echo "Select a diagnostic or repair protocol:"
    echo ""
    echo -e "  ${YELLOW}1.${NC} Reinstall and Update Required Packages"
    echo -e "  ${YELLOW}2.${NC} Hard Reset Network Interfaces (Flush IP & Kill Processes)"
    echo -e "  ${YELLOW}3.${NC} Fix Permissions & Config Links"
    echo -e "  ${YELLOW}4.${NC} Restart the Auto-WiFi Systemd Service"
    echo -e "  ${YELLOW}5.${NC} View Recent Sacred Logs (Service Errors)"
    echo -e "  ${YELLOW}6.${NC} Exit Protocol"
    echo -e "${CYAN}==================================================${NC}"
    read -p "Enter your choice [1-6]: " choice

    case $choice in
        1)
            echo -e "\n${GREEN}Initiating Package Re-blessing...${NC}"
            apt-get update
            apt-get install --reinstall -y hostapd dnsmasq iw wpasupplicant isc-dhcp-client
            echo -e "${GREEN}Packages reinstalled successfully.${NC}"
            pause
            ;;
        2)
            echo -e "\n${GREEN}Purging corrupted states from the network interface...${NC}"
            echo "Killing rogue processes..."
            killall wpa_supplicant hostapd dnsmasq dhclient 2>/dev/null
            
            echo "Taking wlan0 down..."
            ip link set wlan0 down
            sleep 2
            
            echo "Flushing old IP addresses..."
            ip addr flush dev wlan0
            
            echo "Bringing wlan0 back up..."
            ip link set wlan0 up
            echo -e "${GREEN}Network interface has been fully reset.${NC}"
            pause
            ;;
        3)
            echo -e "\n${GREEN}Restoring holy permissions and system links...${NC}"
            
            if [ -f "/usr/local/bin/auto-wifi.sh" ]; then
                chmod +x /usr/local/bin/auto-wifi.sh
                echo "[OK] Fixed permissions on /usr/local/bin/auto-wifi.sh"
            else
                echo -e "${RED}[FAIL] Script /usr/local/bin/auto-wifi.sh not found!${NC}"
            fi

            # Re-link hostapd config just in case it was overwritten by an update
            sed -i 's|^#DAEMON_CONF=""|DAEMON_CONF="/etc/hostapd/hostapd.conf"|g' /etc/default/hostapd
            sed -i 's|^DAEMON_CONF=.*|DAEMON_CONF="/etc/hostapd/hostapd.conf"|g' /etc/default/hostapd
            echo "[OK] Verified hostapd config linkage."
            
            systemctl daemon-reload
            echo "[OK] Reloaded systemd daemons."
            pause
            ;;
        4)
            echo -e "\n${GREEN}Restarting the core automation service...${NC}"
            systemctl reset-failed auto-wifi.service
            systemctl restart auto-wifi.service
            
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}Service restarted successfully.${NC}"
            else
                echo -e "${RED}Service failed to restart. Use Option 5 to check the logs.${NC}"
            fi
            pause
            ;;
        5)
            echo -e "\n${GREEN}Reading the last 20 lines of the service journal...${NC}"
            echo -e "${CYAN}--------------------------------------------------${NC}"
            journalctl -u auto-wifi.service -n 20 --no-pager
            echo -e "${CYAN}--------------------------------------------------${NC}"
            pause
            ;;
        6)
            echo -e "\n${CYAN}May the Omnissiah watch over your hardware. Exiting...${NC}"
            exit 0
            ;;
        *)
            echo -e "\n${RED}Invalid protocol selected. Please enter a number between 1 and 6.${NC}"
            sleep 2
            ;;
    esac
done