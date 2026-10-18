# Agent Hub bootstrap. Source it in Bash; do not execute it:
#   source "${AGENT_HUB_HOME:-$HOME/.agent-hub}/bootstrap.sh"
# It activates existing Hub configuration only and writes no files.

__agent_hub_home="${AGENT_HUB_HOME:-$HOME/.agent-hub}"

if [ -d "$__agent_hub_home/bin" ]; then
    case ":${PATH-}:" in
        *":$__agent_hub_home/bin:"*) ;;
        *) PATH="$__agent_hub_home/bin${PATH:+:$PATH}"; export PATH ;;
    esac
fi

if [ -n "${BASH_VERSION-}" ]; then
    shopt -s expand_aliases
fi

if [ -f "$__agent_hub_home/aliases.sh" ]; then
    . "$__agent_hub_home/aliases.sh"
fi

unset __agent_hub_home
