#!/bin/bash

# n8n Service Management Script
# Manages the n8n LaunchAgent for auto-starting n8n

set -e

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PLIST_SOURCE="$HOME/projects/dotfiles/n8n/com.n8n.service.plist"
PLIST_DEST="$HOME/Library/LaunchAgents/com.n8n.service.plist"

SERVICE_NAME="com.n8n.service"

# Function to check service status
check_status() {
    echo -e "${BLUE}Checking n8n service status...${NC}"
    echo ""

    # Check if plist exists
    printf "LaunchAgent plist file: "
    if [ -f "$PLIST_DEST" ]; then
        printf "${GREEN}✓ Exists${NC}\n"
    else
        printf "${RED}✗ Not found${NC}\n"
        echo "  Expected at: $PLIST_DEST"
        return 1
    fi

    # Check if service is loaded
    printf "Service loaded: "
    if launchctl list | grep -q "$SERVICE_NAME"; then
        printf "${GREEN}✓ Loaded${NC}\n"
        PID=$(launchctl list | grep "$SERVICE_NAME" | awk '{print $1}')
        if [ "$PID" != "-" ]; then
            printf "  PID: ${GREEN}$PID${NC}\n"
        fi
    else
        printf "${RED}✗ Not loaded${NC}\n"
        return 1
    fi

    # Check if n8n process is running
    printf "n8n process: "
    if pgrep -f "node.*n8n.*start" > /dev/null; then
        PID=$(pgrep -f "node.*n8n.*start")
        printf "${GREEN}✓ Running (PID: $PID)${NC}\n"
    else
        printf "${RED}✗ Not running${NC}\n"
    fi

    # Check if n8n is accessible
    printf "n8n web interface: "
    if curl -s -o /dev/null -w "%{http_code}" "http://localhost:5678" | grep -q "200\|302"; then
        printf "${GREEN}✓ Accessible at http://localhost:5678${NC}\n"
    else
        printf "${YELLOW}⚠ Not accessible${NC}\n"
    fi

    echo ""
    echo -e "${BLUE}Log files:${NC}"
    echo "  Logs: $HOME/projects/services/n8n/n8n.log"
    echo "  Errors: $HOME/projects/services/n8n/n8n-error.log"
}

# Function to install/load service
install_service() {
    echo -e "${BLUE}Installing n8n LaunchAgent...${NC}"

    # Copy plist to LaunchAgents
    if [ ! -f "$PLIST_SOURCE" ]; then
        echo -e "${RED}✗ Source plist not found: $PLIST_SOURCE${NC}"
        exit 1
    fi

    cp "$PLIST_SOURCE" "$PLIST_DEST"
    echo -e "${GREEN}✓ Copied plist to $PLIST_DEST${NC}"

    # Unload if already loaded
    if launchctl list | grep -q "$SERVICE_NAME"; then
        echo "Unloading existing service..."
        launchctl unload "$PLIST_DEST" 2>/dev/null || true
    fi

    # Load the service
    launchctl load "$PLIST_DEST"
    echo -e "${GREEN}✓ Service loaded${NC}"

    sleep 2
    echo ""
    check_status
}

# Function to uninstall service
uninstall_service() {
    echo -e "${BLUE}Uninstalling n8n LaunchAgent...${NC}"

    if launchctl list | grep -q "$SERVICE_NAME"; then
        launchctl unload "$PLIST_DEST"
        echo -e "${GREEN}✓ Service unloaded${NC}"
    else
        echo "Service not loaded"
    fi

    if [ -f "$PLIST_DEST" ]; then
        rm "$PLIST_DEST"
        echo -e "${GREEN}✓ Plist removed${NC}"
    fi
}

# Function to restart service
restart_service() {
    echo -e "${BLUE}Restarting n8n service...${NC}"

    if launchctl list | grep -q "$SERVICE_NAME"; then
        launchctl unload "$PLIST_DEST"
        echo "Stopped service"
    fi

    sleep 2

    launchctl load "$PLIST_DEST"
    echo -e "${GREEN}✓ Service restarted${NC}"

    sleep 2
    check_status
}

# Function to view logs
view_logs() {
    echo -e "${BLUE}Recent n8n logs:${NC}"
    echo "================================"
    tail -50 "$HOME/projects/services/n8n/n8n.log" 2>/dev/null || echo "No logs found"
    echo ""
    echo -e "${BLUE}Recent errors:${NC}"
    echo "================================"
    tail -20 "$HOME/projects/services/n8n/n8n-error.log" 2>/dev/null || echo "No errors found"
}

# Function to fix common issues
fix_issues() {
    echo -e "${BLUE}Fixing common n8n service issues...${NC}"
    echo ""

    # Stop any rogue n8n processes
    echo "1. Stopping any rogue n8n processes..."
    pkill -f "node.*n8n.*start" 2>/dev/null || true
    sleep 2

    # Unload service
    echo "2. Unloading service..."
    launchctl unload "$PLIST_DEST" 2>/dev/null || true
    sleep 1

    # Remove extended attributes
    echo "3. Removing extended attributes..."
    xattr -c "$PLIST_DEST" 2>/dev/null || true

    # Reload service
    echo "4. Reloading service..."
    launchctl load "$PLIST_DEST"

    sleep 3
    echo ""
    echo -e "${GREEN}✓ Fix complete${NC}"
    echo ""
    check_status
}

# Main menu
case "${1:-}" in
    status)
        check_status
        ;;
    install)
        install_service
        ;;
    uninstall)
        uninstall_service
        ;;
    restart)
        restart_service
        ;;
    logs)
        view_logs
        ;;
    fix)
        fix_issues
        ;;
    *)
        echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║  n8n Service Management                ║${NC}"
        echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
        echo ""
        echo "Usage: $0 {status|install|uninstall|restart|logs|fix}"
        echo ""
        echo "Commands:"
        echo "  status     - Check n8n service status"
        echo "  install    - Install and load LaunchAgent"
        echo "  uninstall  - Unload and remove LaunchAgent"
        echo "  restart    - Restart n8n service"
        echo "  logs       - View recent logs"
        echo "  fix        - Fix common issues"
        echo ""
        echo "Quick diagnostics:"
        check_status
        ;;
esac
