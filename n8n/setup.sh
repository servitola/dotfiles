#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

DOTFILES_DIR="$HOME/projects/dotfiles/n8n"
N8N_PROJECT_DIR="$HOME/projects/services/n8n"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"

echo -e "${GREEN}Setting up n8n workflow automation with auto-startup...${NC}"

setup_project_directory() {
    if [ ! -d "$N8N_PROJECT_DIR" ]; then
        echo -e "${YELLOW}Setting up n8n project directory...${NC}"

        mkdir -p "$N8N_PROJECT_DIR"

        cp "$DOTFILES_DIR/docker-compose.yml" "$N8N_PROJECT_DIR/"
        cp "$DOTFILES_DIR/manage-startup.sh" "$N8N_PROJECT_DIR/"
        cp "$DOTFILES_DIR/askpass.sh" "$N8N_PROJECT_DIR/"
        chmod +x "$N8N_PROJECT_DIR/manage-startup.sh"
        chmod +x "$N8N_PROJECT_DIR/askpass.sh"
        if [ ! -f "$N8N_PROJECT_DIR/.env" ]; then
            cp "$DOTFILES_DIR/env.example" "$N8N_PROJECT_DIR/.env"
            echo -e "${GREEN}✅ Created .env file from example${NC}"
        fi

        echo -e "${GREEN}✅ Project directory configured${NC}"
    else
        echo -e "${YELLOW}n8n project directory already exists, skipping setup${NC}"
    fi
}

install_launch_agents() {
    if [ ! -f "$LAUNCH_AGENTS_DIR/com.colima.docker.plist" ]; then
        echo -e "${YELLOW}Installing LaunchAgents...${NC}"

        sed "s|/Users/servitola|$HOME|g" "$DOTFILES_DIR/com.colima.docker.plist" > "$LAUNCH_AGENTS_DIR/com.colima.docker.plist"
        sed "s|/Users/servitola|$HOME|g" "$DOTFILES_DIR/com.n8n.workflow.plist" > "$LAUNCH_AGENTS_DIR/com.n8n.workflow.plist"
        launchctl load "$LAUNCH_AGENTS_DIR/com.colima.docker.plist" 2>/dev/null || true
        launchctl load "$LAUNCH_AGENTS_DIR/com.n8n.workflow.plist" 2>/dev/null || true

        echo -e "${GREEN}✅ LaunchAgents installed and loaded${NC}"
    else
        echo -e "${YELLOW}LaunchAgents already installed, skipping${NC}"
    fi
}

start_services() {
    echo -e "${YELLOW}Starting n8n services...${NC}"

    if ! colima status &> /dev/null; then
        echo "Starting Colima..."
        colima start
    fi
    cd "$N8N_PROJECT_DIR"
    docker compose up -d

    echo -e "${GREEN}✅ n8n services started${NC}"
}

main() {
    setup_project_directory
    install_launch_agents
    start_services

    echo ""
    echo -e "${GREEN}✅ n8n setup complete!${NC}"
    echo -e "   Access n8n at: http://localhost:5678"
    echo -e "   Auto-startup enabled for macOS boot"
    echo -e "   Manage with: cd $N8N_PROJECT_DIR && ./manage-startup.sh"
}

main "$@"
