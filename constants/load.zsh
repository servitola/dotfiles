# Export every constant into the environment. Sourced from zsh/exports.sh, so
# it runs for interactive shells, `zsh -c`, launchd services and cron alike.

_constants_load() {
    local key value
    while IFS='=' read -r key value; do
        [[ -z $key || $key == \#* ]] && continue
        export "${key}=${value//\$HOME/$HOME}"
    done < "$HOME/projects/dotfiles/constants.env"
}

_constants_load
unfunction _constants_load
