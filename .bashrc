# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# don't put duplicate lines in the history. See bash(1) for more options
# ... or force ignoredups and ignorespace
HISTCONTROL=ignoredups:ignorespace

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

bind 'set bell-style none'

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
#if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
#    . /etc/bash_completion
#fi



TEXT_EDITOR="${FZFM_TEXT_EDITOR:-nvim}"
LIST_COMMAND="${FZFM_LIST_COMMAND:-eza}"
PREVIEW_COMMAND="${FZFM_PREVIEW_COMMAND:-batcat}"
MEDIA_OPENER="${FZFM_MEDIA_OPENER:-}"

# Stack to remember navigation for cursor memory
declare -a DIR_STACK=()

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Check and set up dependencies
setup_dependencies() {
    if ! command_exists "fzf"; then
        exit 1
    fi

    if ! command_exists "$LIST_COMMAND"; then
        LIST_COMMAND="ls"
        LIST_ARGS="-1A --color=always"
    else
        LIST_ARGS="-1a --icons --color=always"
    fi

    if ! command_exists "$PREVIEW_COMMAND"; then
        PREVIEW_COMMAND="cat"
    fi

    if ! command_exists "$TEXT_EDITOR"; then
        command_exists "nano" && TEXT_EDITOR="nano" || exit 1
    fi

    if [[ -z "$MEDIA_OPENER" ]]; then
        if command_exists "xdg-open"; then
            MEDIA_OPENER="xdg-open"
        elif command_exists "open"; then
            MEDIA_OPENER="open"
        else
            MEDIA_OPENER=""
        fi
    fi
}

# Open file based on MIME type
open_file() {
    local file="$1"
    local mime_type
    mime_type=$(file --mime-type -b "$file")

    case "$mime_type" in
        text/*|application/json|application/xml|application/javascript|application/x-shellscript)
            $TEXT_EDITOR "$file"
            clear
            ;;
        image/*|video/*|audio/*|application/pdf)
            if [[ -n "$MEDIA_OPENER" ]]; then
                $MEDIA_OPENER "$file" &>/dev/null &
            else
                echo "No media opener available. Cannot open $file"
                read -n 1 -s -r -p "Press any key to continue..."
                clear
            fi
            ;;
        *)
            if [ -B "$file" ]; then
                $TEXT_EDITOR "$file"
                clear
            else
                if [[ -n "$MEDIA_OPENER" ]]; then
                    $MEDIA_OPENER "$file" &>/dev/null || {
                        $TEXT_EDITOR "$file"
                        clear
                    }
                else
                    $TEXT_EDITOR "$file"
                    clear
                fi
            fi
            ;;
    esac
}

# Main fzfm function
fzfm() {
    local return_path=0
    local previous_selection=""
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -p|--path) return_path=1; shift ;;
            *) shift ;;
        esac
    done

    setup_dependencies
    local list_command="$LIST_COMMAND $LIST_ARGS"

    while true; do
        # Prepare fzf input
        local fzf_input
        if [ $return_path -eq 1 ]; then
            fzf_input=$(echo -e "..\n:get_path"; eval "$list_command")
        else
            fzf_input=$(echo ".."; eval "$list_command")
        fi

        # Determine index to preselect cursor if going back
        local start_pos=""
        if [[ "${#DIR_STACK[@]}" -gt 0 && "$previous_selection" == ".." ]]; then
            local parent_dir=$(pwd)
            local prev_dir="${DIR_STACK[-1]}"
            # Get the index of prev_dir in the list
            local items
            mapfile -t items < <(eval "$list_command" "$parent_dir")
            for i in "${!items[@]}"; do
                # Remove color codes for comparison
                local clean_item
                clean_item=$(echo "${items[$i]}" | sed 's/\x1b\[[0-9;]*m//g')
                if [[ "$clean_item" == "$prev_dir" ]]; then
                    start_pos="$i"
                    break
                fi
            done
        fi

        # Run fzf
        selection=$(echo "$fzf_input" | fzf \
            --ansi \
            --reverse \
            --height 100% \
            --info right \
            --prompt "󰥨 Search: " \
            --pointer ">" \
            --marker "󰄲" \
            --border "rounded" \
            --border-label=" 󱉭 $(pwd)/ " \
            --border-label-pos center \
            --color 'fg:#cdd6f4,fg+:#cdd6f4,bg+:#313244,border:#a5aac3,pointer:#cba6f7,label:#cdd6f4' \
            --bind "right:accept" \
            --bind "enter:accept" \
            --bind "shift-up:preview-up" \
            --bind "shift-down:preview-down" \
            --bind "ctrl-r:reload($list_command)" \
            --bind "alt-w:up" \
            --bind "alt-s:down" \
            --bind "alt-d:accept" \
            --bind "alt-a:change-query(..)+print-query" \
            --bind "alt-e:accept" \
            $( [[ -n "$start_pos" ]] && echo "--bind start:pos:$start_pos" ) \
            --preview-window="right:65%" \
            --preview "
                file={}
                if [[ \"\$file\" == \"..\" ]]; then
                    echo \"󱧰 Move up to parent directory\"
                elif [[ -d \"\$file\" ]]; then
                    echo \"󰉋 Folder: \$file\"
                    echo \"\"
                    $list_command \"\$file\" 2>/dev/null
                elif [[ -f \"\$file\" ]]; then
                    echo \"󰈙 File: \$file\"
                    echo \"\"
                    $PREVIEW_COMMAND --style=numbers --color=always --line-range :500 \"\$file\" 2>/dev/null || cat \"\$file\"
                else
                    echo \"Invalid selection: \$file\"
                fi
            ")

        [[ -z "$selection" ]] && break

        if [[ "$selection" == ".." ]]; then
            previous_selection=".."
            if [[ "${#DIR_STACK[@]}" -gt 0 ]]; then
                unset 'DIR_STACK[-1]'
            fi
            cd .. || break
        elif [[ "$selection" == ":get_path" ]]; then
            echo "$(pwd)"
            break
        elif [[ -d "$selection" ]]; then
            previous_selection="$selection"
            DIR_STACK+=("$selection")
            cd "$selection" || break
        elif [[ -f "$selection" ]]; then
            if [ $return_path -eq 1 ]; then
                echo "$(pwd)/$selection"
                break
            else
                open_file "$selection"
            fi
        else
            break
        fi
    done
}



test() {
    echo "new string!"
}


reload_dotfiles() {
    cd $HOME/dotfiles
    
    git fetch origin main
    
    git reset --hard origin/main
    
    bash install_dotfiles.sh
    
    exec bash -l
}


# bind fzfm to alt-r key combination
bind '"\er": "fzfm\n"'
