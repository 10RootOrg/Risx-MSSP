#!/bin/bash

# Define color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Arrays to track passed and failed checks
declare -a PASSED_CHECKS
declare -a FAILED_CHECKS

echo "Running Risx-MSSP/IR System Checks..."

# Section 1: Check Ubuntu version
echo -e "\n--- Checking Ubuntu Version ---"
ubuntu_version=$(lsb_release -rs)

if [[ $ubuntu_version =~ ^22\.04(\.[0-9]+)?$ ]]; then
    echo -e "${GREEN}✓${NC} Ubuntu version is $ubuntu_version (22.04 based)"
    PASSED_CHECKS+=("Ubuntu version (22.04)")
else
    echo -e "${RED}✗${NC} Ubuntu version is $ubuntu_version (not 22.04 based)"
    FAILED_CHECKS+=("Ubuntu version (22.04)")
fi

# Section 2: Check storage size and free space
echo -e "\n--- Checking Storage ---"
root_partition=$(df -h / | awk 'NR==2 {print $1}')
total_size_kb=$(df -k / | awk 'NR==2 {print $2}')
free_space_kb=$(df -k / | awk 'NR==2 {print $4}')

# Convert KB to GB
total_size_gb=$(echo "scale=2; $total_size_kb/1024/1024" | bc)
free_space_gb=$(echo "scale=2; $free_space_kb/1024/1024" | bc)

if (( $(echo "$total_size_gb >= 200" | bc -l) )); then
    echo -e "${GREEN}✓${NC} Total storage size: ${total_size_gb}GB (>= 200GB)"
    PASSED_CHECKS+=("Storage size (≥ 200GB)")
else
    echo -e "${RED}✗${NC} Total storage size: ${total_size_gb}GB (< 200GB)"
    FAILED_CHECKS+=("Storage size (≥ 200GB)")
fi

if (( $(echo "$free_space_gb >= 200" | bc -l) )); then
    echo -e "${GREEN}✓${NC} Free space available: ${free_space_gb}GB (>= 200GB)"
    PASSED_CHECKS+=("Free space (≥ 200GB)")
else
    echo -e "${RED}✗${NC} Free space available: ${free_space_gb}GB (< 200GB)"
    FAILED_CHECKS+=("Free space (≥ 200GB)")
fi

# Check if storage is SSD - using a more compatible method
echo -e "\n--- Checking Storage Type ---"
if command -v lsblk &> /dev/null; then
    # Try using lsblk to check if ROTA flag is 0 (SSD) or 1 (HDD)
    root_device=$(lsblk | grep -w "/" | awk '{print $1}' | sed 's/└─//' | sed 's/├─//')
    if [ -n "$root_device" ]; then
        is_ssd=$(lsblk -d -o name,rota | grep -w "$root_device" | awk '{print $2}')
        if [ "$is_ssd" = "0" ]; then
            echo -e "${GREEN}✓${NC} Storage is SSD"
            PASSED_CHECKS+=("SSD storage")
        else
            echo -e "${RED}✗${NC} Storage is not SSD (HDD detected)"
            FAILED_CHECKS+=("SSD storage")
        fi
    else
        echo -e "${YELLOW}?${NC} Unable to determine storage type"
        FAILED_CHECKS+=("SSD storage (unknown)")
    fi
else
    echo -e "${YELLOW}?${NC} Unable to determine storage type (lsblk command not found)"
    FAILED_CHECKS+=("SSD storage (unknown)")
fi

# Section 3: Check current user
echo -e "\n--- Checking Current User ---"
current_user=$(whoami)

if [ "$current_user" = "tenroot" ]; then
    echo -e "${GREEN}✓${NC} Current user is tenroot"
    PASSED_CHECKS+=("Current user (tenroot)")
else
    echo -e "${RED}✗${NC} Current user is $current_user (not tenroot)"
    FAILED_CHECKS+=("Current user (tenroot)")
fi

# Section 4: Check GitHub and Docker Hub connectivity
echo -e "\n--- Checking External Connectivity ---"

# GitHub connectivity
if curl -s --head https://github.com > /dev/null; then
    echo -e "${GREEN}✓${NC} GitHub connectivity: OK"
    PASSED_CHECKS+=("GitHub connectivity")
else
    echo -e "${RED}✗${NC} GitHub connectivity: Failed"
    FAILED_CHECKS+=("GitHub connectivity")
fi

# Docker Hub connectivity
if curl -s --head https://hub.docker.com > /dev/null; then
    echo -e "${GREEN}✓${NC} Docker Hub connectivity: OK"
    PASSED_CHECKS+=("Docker Hub connectivity")
else
    echo -e "${RED}✗${NC} Docker Hub connectivity: Failed"
    FAILED_CHECKS+=("Docker Hub connectivity")
fi

# Section 5: Check for static IP
echo -e "\n--- Checking for Static IP ---"
interface=$(ip route | grep default | awk '{print $5}')
ip_config=$(cat /etc/netplan/*.yaml 2>/dev/null | grep -A10 "$interface" | grep -E "dhcp4:|addresses:")

if [[ $ip_config == *"dhcp4: false"* ]] || [[ $ip_config == *"addresses:"* ]]; then
    echo -e "${GREEN}✓${NC} Static IP configured on $interface"
    PASSED_CHECKS+=("Static IP configuration")
else
    echo -e "${RED}✗${NC} No static IP found on $interface"
    FAILED_CHECKS+=("Static IP configuration")
fi

# Section 6: Check RAM
echo -e "\n--- Checking RAM Size ---"
total_ram_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
total_ram_gb=$(echo "scale=2; $total_ram_kb/1024/1024" | bc)

if (( $(echo "$total_ram_gb >= 16" | bc -l) )); then
    echo -e "${GREEN}✓${NC} RAM: ${total_ram_gb}GB (>= 16GB required)"
    PASSED_CHECKS+=("RAM size (≥ 16GB)")
else
    echo -e "${RED}✗${NC} RAM: ${total_ram_gb}GB (< 16GB, does not meet minimum requirement of 16GB)"
    FAILED_CHECKS+=("RAM size (≥ 16GB)")
fi

# Section 7: Check required ports
echo -e "\n--- Will work only after installation!"
echo -e "\n--- Checking Required Ports ---"
required_ports=(22 80 443 3003 5555 8000 8001 8443 8843 8844)
ports_status=0

# Check if netstat is available
if command -v netstat &> /dev/null; then
    for port in "${required_ports[@]}"; do
        # Check if the port is listening
        if netstat -tuln | grep -q ":$port "; then
            echo -e "${GREEN}✓${NC} Port $port is open"
        else
            echo -e "${RED}✗${NC} Port $port is not open"
            ports_status=1
        fi
    done
elif command -v ss &> /dev/null; then
    # Alternative using ss command
    for port in "${required_ports[@]}"; do
        if ss -tuln | grep -q ":$port "; then
            echo -e "${GREEN}✓${NC} Port $port is open"
        else
            echo -e "${RED}✗${NC} Port $port is not open"
            ports_status=1
        fi
    done
else
    echo -e "${YELLOW}?${NC} Cannot check ports: netstat and ss commands not found. Install net-tools or iproute2 package."
    ports_status=1
fi

if [ $ports_status -eq 0 ]; then
    PASSED_CHECKS+=("Required ports")
else
    FAILED_CHECKS+=("Required ports")
fi

# Summary section
echo -e "\n\n=== SYSTEM CHECK SUMMARY ==="
echo -e "\n${GREEN}PASSED CHECKS:${NC}"
if [ ${#PASSED_CHECKS[@]} -eq 0 ]; then
    echo -e "None"
else
    for check in "${PASSED_CHECKS[@]}"; do
        echo -e "${GREEN}✓${NC} $check"
    done
fi

echo -e "\n${RED}FAILED CHECKS:${NC}"
if [ ${#FAILED_CHECKS[@]} -eq 0 ]; then
    echo -e "None"
else
    for check in "${FAILED_CHECKS[@]}"; do
        echo -e "${RED}✗${NC} $check"
    done
fi

# Overall result
total_checks=$((${#PASSED_CHECKS[@]} + ${#FAILED_CHECKS[@]}))
pass_percentage=$((${#PASSED_CHECKS[@]} * 100 / total_checks))

echo -e "\n=== OVERALL RESULT ==="
echo -e "Total checks: $total_checks"
echo -e "Passed: ${#PASSED_CHECKS[@]} (${pass_percentage}%)"
echo -e "Failed: ${#FAILED_CHECKS[@]} ($((100 - pass_percentage))%)"

if [ ${#FAILED_CHECKS[@]} -eq 0 ]; then
    echo -e "\n${GREEN}All checks passed! The system meets all requirements for Risx-MSSP/IR.${NC}"
else
    echo -e "\n${YELLOW}Some checks failed. Please address the issues before proceeding with Risx-MSSP/IR installation.${NC}"
fi

echo -e "\nSystem check complete!"
