#!/bin/zsh

# Function to set macOS default only if different from current value
# Usage: set_macos_default_if_different "Title" "domain" "key" "type" "value"
set_macos_default_if_different() {
    local title=$1
    local domain=$2
    local key=$3
    local type=$4
    local new_value=$5

    # Print bullet point
    echo "  ${DIM}•${NC} $title"

    # Get current value
    current_value=$(sudo defaults read "$domain" "$key" 2> /dev/null)

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

        if [[ "$domain" == /Library/* ]]; then
            sudo defaults write "$domain" "$key" "$type" "$new_value"
        else
            defaults write "$domain" "$key" "$type" "$new_value"
        fi

        if [[ -n "$current_value" ]]; then
            echo "  ${GREEN}✓${NC} Changed: ${YELLOW}$current_normalized${NC} → ${GREEN}$new_normalized${NC}"
        else
            echo "  ${GREEN}✓${NC} Set: ${GREEN}$new_normalized${NC}"
        fi
        ((CHANGES_MADE++))
        return 0
    fi

    echo "  ${YELLOW}○${NC} Already set: ${CYAN}$current_normalized${NC}"
    ((SKIPPED_COUNT++))
    return 1
}
