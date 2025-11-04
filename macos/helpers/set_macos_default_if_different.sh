#!/bin/zsh

# Function to set macOS default only if different from current value
set_macos_default_if_different() {
    local domain=$1
    local key=$2
    local type=$3
    local new_value=$4
    local use_sudo=${5:-false}
    
    # Get current value
    if [[ "$use_sudo" == "true" ]]; then
        current_value=$(sudo defaults read "$domain" "$key" 2>/dev/null)
    else
        current_value=$(defaults read "$domain" "$key" 2>/dev/null)
    fi
    
    # Handle different types
    local current_normalized=""
    local new_normalized=""
    
    case "$type" in
        -bool)
            [[ "$current_value" == "1" ]] && current_normalized="true" || current_normalized="false"
            new_normalized="$new_value"
            ;;
        -int)
            current_normalized="$current_value"
            new_normalized="$new_value"
            ;;
        -string)
            current_normalized="$current_value"
            new_normalized="$new_value"
            ;;
    esac
    
    # Compare and set if different
    if [[ "$current_normalized" != "$new_normalized" ]] || [[ -z "$current_value" ]]; then
        if [[ "$use_sudo" == "true" ]]; then
            sudo defaults write "$domain" "$key" "$type" "$new_value"
        else
            defaults write "$domain" "$key" "$type" "$new_value"
        fi
        # Only log if values actually differ (not just missing)
        if [[ -n "$current_value" ]]; then
            echo "${GREEN}✓ Changed${NC} $domain → $key: ${YELLOW}$current_normalized${NC} → ${GREEN}$new_normalized${NC}"
        else
            echo "${GREEN}✓ Set${NC} $domain → $key: ${GREEN}$new_normalized${NC}"
        fi
        ((CHANGES_MADE++))
        return 0
    fi
    return 1
}
