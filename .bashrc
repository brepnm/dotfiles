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
    alias cls="clear"
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

# bind fzfm to alt-r key combination
bind '"\er": "fzfm\n"'

# bind sc to alt-q key combination
bind '"\eq": "sc\n"'


# bind '"\ea": "cd ..\n"'

# bind '"\ed": "cd - \n"'



# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
#if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
#    . /etc/bash_completion
#fi

# Configuration variables with defaults
# MEDIA_OPENER="wslview"
TEXT_EDITOR="nvim"
LIST_COMMAND="eza"
PREVIEW_COMMAND="batcat"

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Check and set up dependencies
setup_dependencies() {
    # Check for fzf as it's required
    if ! command_exists "fzf"; then
        # echo "Error: fzf is required but not installed"
        exit 1
    fi

    # Check and set list command (eza or ls)
    if ! command_exists "$LIST_COMMAND"; then
        # echo "Warning: $LIST_COMMAND not found, falling back to ls"
        LIST_COMMAND="ls"
        LIST_ARGS="-1A --color=always"  # ls arguments
    else
        LIST_ARGS="-1a --icons --color=always"  # eza arguments
    fi

    # Check and set preview command
    if ! command_exists "$PREVIEW_COMMAND"; then
        # echo "Warning: $PREVIEW_COMMAND not found, falling back to cat"
        PREVIEW_COMMAND="cat"
    fi

    # Check and set text editor
    if ! command_exists "$TEXT_EDITOR"; then
        # echo "Warning: $TEXT_EDITOR not found, falling back to nano"
        command_exists "nano" && TEXT_EDITOR="nano" || {
            # echo "Error: No suitable text editor found"
            exit 1
        }
    fi

    # Check and set media opener
    if ! command_exists "$MEDIA_OPENER"; then
        if command_exists "xdg-open"; then
            # echo "Warning: $MEDIA_OPENER not found, falling back to xdg-open"
            MEDIA_OPENER="xdg-open"
        elif command_exists "open"; then
            # echo "Warning: $MEDIA_OPENER not found, falling back to open"
            MEDIA_OPENER="open"
        else
            # echo "Warning: No suitable media opener found, multimedia files won't be opened"
            MEDIA_OPENER=""
        fi
    fi
}

# Check and open file based on mime type
open_file() {
    local file="$1"
    local mime_type=$(file --mime-type -b "$file")
   
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


create_directory() {
    read -p "Enter directory name: " directory_name
    
    #if directory_name exists or is empty, enter while loop until valid name is given
    while [ -z "$directory_name" ] || [ -d "$directory_name" ];
    do
        echo "Invalid or existing directory name. Please try again."
        read -p "Enter directory name: " directory_name
    done
    
    mkdir "$directory_name"
    cd "$directory_name" || return 1
}
export -f create_directory


create_file() {
    read -p "Enter file name: " file_name
    
    #if directory_name exists or is empty, enter while loop until valid name is given
    while [ -z "$file_name" ] || [ -f "$file_name" ];
    do
        echo "Invalid or existing file name. Please try again."
        read -p "Enter file name: " file_name
    done
    
    touch "$file_name"
    return 1
}
export -f create_file



copy_files_from_temp() {
    local temp_file="/tmp/fzfm_clipboard.txt"
    if [[ -f "$temp_file" ]]; then
        while IFS= read -r filepath; do
            if [[ -f "$filepath" || -d "$filepath" ]]; then
                local filename=$(basename "$filepath")
                local basename="${filename%.*}"
                local extension="${filename##*.}"
                if [[ "$filename" == "$extension" ]]; then
                    extension=""
                else
                    extension=".$extension"
                fi

                # If original file exists, start with _1
                if [[ -e "$filename" ]]; then
                    local i=1
                    while [[ -e "${basename}_${i}${extension}" ]]; do
                        ((i++))
                    done
                    local destfile="${basename}_${i}${extension}"
                else
                    local destfile="$filename"
                fi

                if [[ -f "$filepath" ]]; then
                    cp "$filepath" "$destfile"
                elif [[ -d "$filepath" ]]; then
                    cp -r "$filepath" "$destfile"
                fi
            fi
        done < "$temp_file"
    fi
}
export -f copy_files_from_temp


fzfm() {
    local return_path=0
    local temp_file="/tmp/fzfm_clipboard.txt"
    
    # Parse parameters
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -p|--path) return_path=1; shift ;;
            *) shift ;;
        esac
    done
    
    setup_dependencies

    local list_command="$LIST_COMMAND $LIST_ARGS"
    local previous_dir_name=""
    local moving_back=false

    while true; do
        # Add :get_path option if -p flag is set
        local fzf_input
        if [ $return_path -eq 1 ]; then
            fzf_input=$(echo -e "..\n:get_path"; eval "$list_command")
        else
            fzf_input=$(eval "$list_command"; echo "..")
        fi
        
        # BUILD FZF POSITION BIND ONLY IF MOVING BACK AND HAVE PREVIOUS DIR
        local pos_bind=""
        if [ "$moving_back" = true ] && [ -n "$previous_dir_name" ]; then
            # Get the list without .. and :get_path
            local dir_list=$(eval "$list_command")
            
            # Find the index of previous_dir_name in the actual list
            local index=0
            while IFS= read -r line; do
                # Remove ANSI escape codes and any non-filename characters
                local clean_line=$(echo "$line" | sed 's/\x1b\[[0-9;]*m//g' | tr -cd '[:alnum:]._-')
                local clean_prev=$(echo "$previous_dir_name" | tr -cd '[:alnum:]._-')
                
                if [[ "$clean_line" == "$clean_prev" ]]; then
                    pos_bind="--bind=start:pos($((index+1)))"
                    break
                fi
                ((index++))
            done <<< "$dir_list"
            
            moving_back=false
        fi
        
        selection=$(echo "$fzf_input" | fzf $pos_bind \
            --ansi \
            --multi \
            --height 100% \
            --pointer ">" \
            --header=" $(pwd)/ " \
            --color 'fg:#cdd6f4,fg+:#cdd6f4,bg+:#313244,border:#a5aac3,pointer:#cba6f7,label:#cdd6f4' \
            --bind "right:accept" \
            --bind "enter:accept" \
            --bind "shift-up:preview-up" \
            --bind "shift-down:preview-down" \
            --bind "alt-w:up" \
            --bind "alt-s:down" \
            --bind "alt-d:accept" \
            --bind "alt-a:change-query(..)+print-query" \
            --bind "ctrl-n:execute(create_directory {})+reload($list_command)" \
            --bind "alt-n:execute(create_file {})+reload($list_command)" \
            --bind "alt-x:execute-silent(gio trash {})+reload($list_command)" \
            --bind "ctrl-a:clear-query" \
            --bind "change:top" \
            --bind "ctrl-c:execute(printf '%s\n' {+} | while read -r file; do [[ \$file != '..' && \$file != ':get_path' ]] && echo '$(pwd)/'\$file; done > $temp_file)"+clear-selection \
            --bind "ctrl-r:execute(copy_files_from_temp)+reload($list_command)+refresh-preview" \
            --bind "alt-q:change-query(sc)+print-query" \
            --preview-window="right:65%" \
            --preview "
                file={}
                if [[ \"\$file\" == \"..\" ]]; then
                    echo \"Move up to parent directory\"
                elif [[ -d \"\$file\" ]]; then
                    echo \"Folder: \$file\"
                    echo \"\"
                    $list_command \"\$file\" 2>/dev/null
                elif [[ -f \"\$file\" ]]; then
                    echo \"File: \$file\"
                    echo \"\"
                    $PREVIEW_COMMAND --style=numbers --color=always --line-range :500 \"\$file\" 2>/dev/null || cat \"\$file\"
                else
                    echo \"Invalid selection: \$file\"
                fi
            ")

        [[ -z "$selection" ]] && break

        if [[ "$selection" == ".." ]]; then
            previous_dir_name="$(basename "$(pwd)")"
            cd .. || break
            moving_back=true

        elif [[ "$selection" == "sc" ]]; then
            sc
            break
            
        elif [[ "$selection" == ":get_path" ]]; then
            echo "$(pwd)"
            break
        elif [[ -d "$selection" ]]; then
            previous_dir_name=""
            moving_back=false
            cd "$selection" || break
        elif [[ -f "$selection" ]]; then
            if [ $return_path -eq 1 ]; then
                echo "$(pwd)/$selection"
                break
            else
                open_file "$selection"
            fi
        else
            echo "Invalid selection: $selection"
            break
        fi
    done
}

# Allow configuration through environment variables
[[ -n "$FZFM_MEDIA_OPENER" ]] && MEDIA_OPENER="$FZFM_MEDIA_OPENER"
[[ -n "$FZFM_TEXT_EDITOR" ]] && TEXT_EDITOR="$FZFM_TEXT_EDITOR"
[[ -n "$FZFM_LIST_COMMAND" ]] && LIST_COMMAND="$FZFM_LIST_COMMAND"
[[ -n "$FZFM_PREVIEW_COMMAND" ]] && PREVIEW_COMMAND="$FZFM_PREVIEW_COMMAND"


test() {
    echo "new!"
}


reload_dotfiles() {
    cd $HOME/dotfiles
    
    git fetch origin main
    
    git reset --hard origin/main
    
    bash install_dotfiles.sh
    
    exec bash -l
}



sc() {
    local shortcuts_file="$HOME/.shortcuts.json"  # Define your path
    local key=""
    local create=false
    local list=false
    local delete=false
    local path=""
    local folder=""
    local use_fzf=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c) create=true ;;
            -l) list=true ;;
            -d) delete=true ;;
            -p) path="$2"; shift ;;
            -f) folder="$2"; shift ;;
            -fzf) use_fzf=true ;;
            *) key="$1" ;;
        esac
        shift
    done

    local fzf_bind="alt-c:execute(code .)+abort,\
alt-w:up,\
alt-s:down,\
alt-d:accept,\
ctrl-space:accept,\
alt-a:change-query(📜)+print-query,\
alt-q:change-query(📜)+print-query,\
ctrl-a:change-query()"

    invoke_shortcut() {
        local target="$1"
        
        if [[ "$target" == *.py ]]; then
            python3 "$target"
        elif [[ -f "$target" ]]; then
            if command -v xdg-open &> /dev/null; then
                xdg-open "$target"
            else
                open "$target"
            fi
        elif [[ "$target" =~ ^https?:// ]]; then
            if command -v xdg-open &> /dev/null; then
                xdg-open "$target"
            else
                open "$target"
            fi
        elif [[ -d "$target" ]]; then
            cd "$target"
            fzfm
            # echo "Navigated to: $target"
        else
            eval "$target"
        fi
    }

    # Main shortcut selection logic
    if [[ -z "$key" && "$create" == false && "$list" == false && "$delete" == false ]]; then
        # Read all shortcuts and their values
        local entries=$(jq -r 'to_entries | .[] | if .value | type == "object" then "\(.key) : [Folder]" else "\(.key) : \(.value)" end' "$shortcuts_file")
        
        # Use fzf to select a shortcut
        local selected=$(echo "$entries" | fzf -i --bind="$fzf_bind" --bind=change:first)
        [[ -z "$selected" ]] && return

        # Extract the key from the selection
        key=$(echo "$selected" | cut -d ':' -f1 | tr -d ' ')
    fi

    # Create operation
    if [[ "$create" == true ]]; then
        if [[ "$use_fzf" == true ]]; then
            path=$(find . -type d | fzf)
        fi
        path="${path:-$(pwd)}"

        if [[ -n "$folder" ]]; then
            jq --arg k "$key" --arg v "$path" --arg f "$folder" \
            'if has($f) then . else . + {($f): {}} end | .[$f][$k] = $v' \
            "$shortcuts_file" > "$shortcuts_file.tmp" && 
            mv "$shortcuts_file.tmp" "$shortcuts_file"
            echo "Shortcut $key was added to folder $folder"
        else
            jq --arg k "$key" --arg v "$path" '.[$k] = $v' \
            "$shortcuts_file" > "$shortcuts_file.tmp" && 
            mv "$shortcuts_file.tmp" "$shortcuts_file"
            echo "Shortcut $key was created"
        fi
        return
    fi

    # List operation
    if [[ "$list" == true ]]; then
        jq -r 'to_entries | .[] | "\(.key)\t\(.value | if type == "object" then "[Folder]" else . end)"' "$shortcuts_file" | 
        column -t -s $'\t'
        return
    fi

    # Delete operation
    if [[ "$delete" == true ]]; then
        if jq -e "has(\"$key\")" "$shortcuts_file" >/dev/null; then
            jq "del(.[\"$key\"])" "$shortcuts_file" > "$shortcuts_file.tmp" && 
            mv "$shortcuts_file.tmp" "$shortcuts_file"
            echo "Shortcut $key was deleted"
        else
            echo "Shortcut not found"
        fi
        return
    fi

    # Execute shortcut
    if [[ -n "$key" ]]; then
        # Check if the key exists in the shortcuts
        if jq -e "has(\"$key\")" "$shortcuts_file" >/dev/null; then
            # Get the value for the key
            local value=$(jq -r ".[\"$key\"]" "$shortcuts_file")
            
            # Check if the value is an object (folder)
            if jq -e ".[\"$key\"] | type == \"object\"" "$shortcuts_file" >/dev/null; then
                # Handle folder case
                local folder_entries=$(jq -r ".[\"$key\"] | to_entries | .[] | \"\(.key) : \(.value)\"" "$shortcuts_file")
                local selected=$(echo -e "${folder_entries}\n📜" | fzf -i --bind="$fzf_bind" --bind=change:first)
                [[ -z "$selected" ]] && return
                
                if [[ "$selected" == "📜" ]]; then
                    sc
                    return
                fi
                
                value=$(echo "$selected" | cut -d ':' -f2- | tr -d ' ')
            fi
            
            # Execute the shortcut
            invoke_shortcut "$value"
        else
            echo "Shortcut not found: $key"
        fi
    fi
}


# Initialize stacks as arrays
declare -a forward_stack=()
declare -a backward_stack=()

# Main navigation function
nav_dirs() {
    local direction=$1
    local current_dir=$(pwd)
    
    case $direction in
        "back")
            if [ "$PWD" != "/" ]; then
                forward_stack+=("$current_dir")
                cd ..
                # update bash prompt to show current dir
                echo -e "\e]0;$(pwd)\a"
                
                
            fi
            ;;
            
        "forward")
            if [ ${#forward_stack[@]} -gt 0 ]; then
                local next_dir="${forward_stack[-1]}"
                unset 'forward_stack[-1]'
                cd "$next_dir"
                # update prompt
                echo -e "\e]0;$(pwd)\a"
                
            fi
            ;;
    esac
}


bind -x '"\ea": nav_dirs back'
bind -x '"\ed": nav_dirs forward'


# bind -x '"\201": nav_dirs back'
# bind -x '"\ea":"\201\C-m"'

# bind -x '"\205": nav_dirs forward'
# bind -x '"\ed":"\205\C-m"'