#
# Executes commands at the start of an interactive session.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# Customize to your needs...

### エディタをneovimに設定
export EDITOR=neovim

### 文字コードをUTF-8に設定
export LANG=ja_JP.UTF-8

### KCODEにUTF-8を設定
export KCODE=u

# autotestでfeatureを動かす
export AUTOFEATURE=true

### キーバインドをvimモードに設定
bindkey -v

### node
export PATH=$HOME/.nodebrew/current/bin:$PATH

### rbenv
### export RBENV_ROOT=/usr/local/var/rbenv
### eval "$(rbenv init - zsh)"

### anyenv
export PATH="$HOME/.anyenv/bin:$PATH"
eval "$(anyenv init -)"

### gulpコマンドのpathを通す
export PATH=$PATH:./node_modules/.bin

### color設定
TERM=xterm-256color
autoload colors
colors
PROMPT="%{$fg[green]%}[%n]%(!.#.$) %{$reset_color%}"
PROMPT2="%{$fg[green]%}%_> %{$reset_color%}"
SPROMPT="%{$fg[red]%}correct: %R -> %r [nyae]? %{$reset_color%}"
RPROMPT="%{$fg[cyan]%}[%~]%{$reset_color%}"

############################################################ 以下zshプロンプトにモード表示

function zle-line-init zle-keymap-select {
  case $KEYMAP in
    vicmd)
    PROMPT="%{$fg[cyan]%}[%[cyan]%n/%{$fg_bold[blue]%}NOR%{$reset_color%}%{$fg[cyan]%}]%#%{$reset_color%} "
    ;;
    main|viins)
    PROMPT="%{$fg[blue]%}[%[blue]%n/%{$fg_bold[cyan]%}INS%{$reset_color%}%{$fg[blue]%}]%#%{$reset_color%} "
    ;;
  esac
  zle reset-prompt
}
zle -N zle-line-init
zle -N zle-keymap-select

############################################################ 以下iterm関連

case ${OSTYPE} in
  darwin*)
    function tp() {
      if [ $# -ne 1 ] ; then
        echo "    invalid argument."
        echo "    use 0 - 9"
      else
        echo "
          tell application \"iTerm\"
            activate -- make window active
            tell current session of current window
              set transparency to $1/10
            end tell
          end tell
        " | /usr/bin/osascript -
      fi
    }
    ;;
esac

############################################################ 以下zplug関連

source ~/.zplug/init.zsh

# プラグイン系
# prezto
zplug "sorin-ionescu/prezto"

# zsh-syntax-highlighting
zplug "zsh-users/zsh-syntax-highlighting"

# zsh-users/zsh-autosuggestions
zplug "zsh-users/zsh-autosuggestions"

# zsh-users/zsh-completions
zplug "zsh-users/zsh-completions"

zplug "junegunn/fzf-bin", \
    from:gh-r, \
    as:command, \
    rename-to:fzf, \
    use:"*darwin*amd64*"

zplug "b4b4r07/enhancd", use:init.sh

# コマンドをリンクして、PATH に追加し、プラグインは読み込む
zplug load --verbose

############################################################ 以下 tmux関連

function is_exists() { type "$1" >/dev/null 2>&1; return $?; }
function is_osx() { [[ $OSTYPE == darwin* ]]; }
function is_screen_running() { [ ! -z "$STY" ]; }
function is_tmux_runnning() { [ ! -z "$TMUX" ]; }
function is_screen_or_tmux_running() { is_screen_running || is_tmux_runnning; }
function shell_has_started_interactively() { [ ! -z "$PS1" ]; }
function is_ssh_running() { [ ! -z "$SSH_CONECTION" ]; }

function tmux_automatically_attach_session()
{
    if is_screen_or_tmux_running; then
        ! is_exists 'tmux' && return 1

        if is_tmux_runnning; then
            echo "${fg_bold[red]} _____ __  __ _   ___  __ ${reset_color}"
            echo "${fg_bold[red]}|_   _|  \/  | | | \ \/ / ${reset_color}"
            echo "${fg_bold[red]}  | | | |\/| | | | |\  /  ${reset_color}"
            echo "${fg_bold[red]}  | | | |  | | |_| |/  \  ${reset_color}"
            echo "${fg_bold[red]}  |_| |_|  |_|\___//_/\_\ ${reset_color}"
        elif is_screen_running; then
            echo "This is on screen."
        fi
    else
        if shell_has_started_interactively && ! is_ssh_running; then
            if ! is_exists 'tmux'; then
                echo 'Error: tmux command not found' 2>&1
                return 1
            fi

            if tmux has-session >/dev/null 2>&1 && tmux list-sessions | grep -qE '.*]$'; then
                # detached session exists
                tmux list-sessions
                echo -n "Tmux: attach? (y/N/num) "
                read
                if [[ "$REPLY" =~ ^[Yy]$ ]] || [[ "$REPLY" == '' ]]; then
                    tmux attach-session
                    if [ $? -eq 0 ]; then
                        echo "$(tmux -V) attached session"
                        return 0
                    fi
                elif [[ "$REPLY" =~ ^[0-9]+$ ]]; then
                    tmux attach -t "$REPLY"
                    if [ $? -eq 0 ]; then
                        echo "$(tmux -V) attached session"
                        return 0
                    fi
                fi
            fi

            if is_osx && is_exists 'reattach-to-user-namespace'; then
                # on OS X force tmux's default command
                # to spawn a shell in the user's namespace
                tmux_config=$(cat $HOME/.tmux.conf <(echo 'set-option -g default-command "reattach-to-user-namespace -l $SHELL"'))
                tmux -f <(echo "$tmux_config") new-session && echo "$(tmux -V) created new session supported OS X"
            else
                tmux new-session && echo "tmux created new session"
            fi
        fi
    fi
}
tmux_automatically_attach_session
