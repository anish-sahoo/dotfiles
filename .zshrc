alias ll='eza --bytes --header --long --color always --sort=type'
alias lla='eza -all --bytes --header --long --color always --sort=type'
alias ls='ls --color'
alias la='ls -a'

alias copy='pbcopy'

alias glog='git log --all --decorate --oneline --graph'

alias z='zed'
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home

export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools

export STARSHIP_CONFIG=~/.config/starship.toml
eval "$(starship init zsh)"

export GOPATH="$(go env GOPATH)"
export PATH="$PATH:$GOPATH/bin"

# docker stuff
fpath=(/Users/anish/.docker/completions $fpath)
autoload -Uz compinit
compinit

# nvm stuff
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completioni

# zsh completions (make, etc.)
#if type brew &>/dev/null; then
#    FPATH=$(brew --prefix)/share/zsh-completions:$FPATH
#
#    autoload -Uz compinit
#    compinit
#  fi

zstyle ':completion:*:*:make:*' tag-order 'targets'
autoload -U compinit && compinit

# bun completions
[ -s "/Users/anish/.bun/_bun" ] && source "/Users/anish/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
