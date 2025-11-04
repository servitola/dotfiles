#!/bin/zsh

# Function to set plist value using PlistBuddy, only if different from current value
set_plist_value_if_different() {
    local plist_path=$1
    local key_path=$2
    local new_value=$3
    
    current_value=$(/usr/libexec/PlistBuddy -c "Print :$key_path" "$plist_path" 2>/dev/null)
    
    # Normalize numeric values (remove decimal points if they're .0 or .000000)
    local current_normalized="$current_value"
    local new_normalized="$new_value"
    
    # If values look numeric, compare them as numbers
    if [[ "$current_value" =~ ^[0-9]+\.?[0-9]*$ ]] && [[ "$new_value" =~ ^[0-9]+\.?[0-9]*$ ]]; then
        # Convert to integers for comparison if they're essentially the same number
        current_int=$(printf "%.0f" "$current_value" 2>/dev/null)
        new_int=$(printf "%.0f" "$new_value" 2>/dev/null)
        
        if [[ "$current_int" == "$new_int" ]]; then
            return 1  # Values are the same, no change needed
        fi
    fi
    
    if [[ "$current_value" != "$new_value" ]] || [[ -z "$current_value" ]]; then
        /usr/libexec/PlistBuddy -c "Set :$key_path $new_value" "$plist_path" 2>/dev/null
        echo "${GREEN}✓ Changed${NC} $(basename $plist_path) → $key_path: ${YELLOW}$current_value${NC} → ${GREEN}$new_value${NC}"
        ((CHANGES_MADE++))
        return 0
    fi
    return 1
}
