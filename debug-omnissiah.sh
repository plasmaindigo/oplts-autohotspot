#!/bin/bash


# Debugger Version 0.0.2
# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo ./debug-omnissiah.sh)"
  exit 1
fi

# Color codes for readability
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Log file setup
LOG_FILE="/var/log/omnissiah-problems.log"
PROBLEMS_FOUND=0

# Initialize the log file
echo "Omnissiah Diagnostic Report - $(date)" > "$LOG_FILE"
echo "==================================================" >> "$LOG_FILE"

# Logging Functions
log_success() {
    echo -e "${GREEN}[OK] $1${NC}"
}

log_error() {
    echo -e "${RED}[FAIL] $1${NC}"
    echo "[FAIL] $1" >> "$LOG_FILE"
    ((PROBLEMS_FOUND++))
}

log_warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
    echo "[WARNING] $1" >> "$LOG_FILE"
    ((PROBLEMS_FOUND++))
}

log_info() {
    echo -e "      $1"
}


echo -e "${CYAN}==================================================${NC}"
echo -e "${CYAN}   Omnissiah Network Diagnostic Tool              ${NC}"
echo -e "${CYAN}==================================================${NC}"
echo ""

# 1. Check Network Interface
echo -e "${CYAN}[1/5] Checking Wireless Interface...${NC}"
if ip link show wlan0 > /dev/null 2>&1; then
    log_success "Interface wlan0 exists."
    MAC_ADDR=$(cat /sys/class/net/wlan0/address)
    log_info "MAC Address: $MAC_ADDR"
else
    log_error "Interface wlan0 not found! Check hardware or drivers."
fi
echo ""

# 2. Check Required Packages
echo -e "${CYAN}[2/5] Checking Required Packages...${NC}"
PACKAGES=("hostapd" "dnsmasq" "iw" "wpasupplicant" "isc-dhcp-client")
for pkg in "${PACKAGES[@]}"; do
    if dpkg -l | grep -qw "$pkg"; then
        log_success "$pkg is installed."
    else
        log_error "$pkg is missing! Run: apt install $pkg"
    fi
done
echo ""

# 3. Check Configuration Files
echo -e "${CYAN}[3/5] Checking Configuration Files...${NC}"

check_file() {
    if [ -f "$1" ]; then
        log_success "File exists: $1"
    else
        log_error "File missing: $1"
    fi
}

check_file "/etc/hostapd/hostapd.conf"
check_file "/etc/dnsmasq.conf"
check_file "/etc/wpa_supplicant/wpa_supplicant.conf"
check_file "/usr/local/bin/auto-wifi.sh"

# Check if script is executable
if [ -x "/usr/local/bin/auto-wifi.sh" ]; then
    log_success "Script /usr/local/bin/auto-wifi.sh is executable."
else
    log_error "Script /usr/local/bin/auto-wifi.sh is NOT executable! Run: chmod +x /usr/local/bin/auto-wifi.sh"
fi

# Check hostapd default config linkage
if grep -q '^DAEMON_CONF="/etc/hostapd/hostapd.conf"' /etc/default/hostapd; then
    log_success "hostapd DAEMON_CONF is correctly linked."
else
    log_error "hostapd DAEMON_CONF missing in /etc/default/hostapd!"
fi
echo ""

# 4. Check Systemd Service
echo -e "${CYAN}[4/5] Checking Systemd Service...${NC}"
if systemctl is-enabled auto-wifi.service > /dev/null 2>&1; then
    log_success "auto-wifi.service is ENABLED on boot."
else
    log_error "auto-wifi.service is DISABLED! Run: systemctl enable auto-wifi.service"
fi

SERVICE_STATE=$(systemctl is-active auto-wifi.service)
if [ "$SERVICE_STATE" = "active" ]; then
    log_success "Service ran successfully (State: active/exited)."
else
    log_warning "Service state is: $SERVICE_STATE. Check 'journalctl -u auto-wifi.service' for logs."
fi
echo ""

# 5. Check Current Active State
echo -e "${CYAN}[5/5] Determining Current Network State...${NC}"

WLAN_IP=$(ip -4 addr show wlan0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

if pgrep -x "hostapd" > /dev/null; then
    echo -e "${GREEN}State: HOTSPOT MODE (Omnissiah Active)${NC}"
    log_info "hostapd is running."
    if pgrep -x "dnsmasq" > /dev/null; then
         log_info "dnsmasq is running."
    else
         log_error "dnsmasq is NOT running. Clients won't get an IP!"
    fi
    log_info "Current IP: ${WLAN_IP:-None (Should be 10.0.0.1)}"
elif pgrep -x "wpa_supplicant" > /dev/null; then
    echo -e "${GREEN}State: CLIENT MODE (Connected to known Wi-Fi)${NC}"
    log_info "wpa_supplicant is running."
    log_info "Current IP: ${WLAN_IP:-Waiting for DHCP...}"
    
    # Try to get the SSID it's connected to
    CONNECTED_SSID=$(iw dev wlan0 link | grep "SSID:" | sed 's/^[ \t]*SSID: //')
    if [ ! -z "$CONNECTED_SSID" ]; then
        log_info "Connected Network: $CONNECTED_SSID"
    fi
else
    echo -e "${RED}State: UNKNOWN / DISCONNECTED${NC}"
    log_error "Neither hostapd nor wpa_supplicant are running."
    log_info "Try running the script manually: sudo /usr/local/bin/auto-wifi.sh"
fi

echo ""
echo -e "${CYAN}==================================================${NC}"

# Final Report Summary
if [ "$PROBLEMS_FOUND" -gt 0 ]; then
    echo -e "${RED}Diagnostics Complete. $PROBLEMS_FOUND problem(s) found!${NC}"
    echo -e "${YELLOW}A detailed ledger of failures has been written to: $LOG_FILE${NC}"
else
    echo -e "${GREEN}Diagnostics Complete. All systems nominal.${NC}"
    echo "Status: Perfect Harmony" >> "$LOG_FILE"
    echo -e "A clean bill of health has been recorded in $LOG_FILE"
fi
echo -e "${CYAN}==================================================${NC}"