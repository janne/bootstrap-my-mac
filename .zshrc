# Setup
# brew install nvim fzf starship asdf zoxide direnv eza bat ripgrep git
# brew install zsh-autosuggestions zsh-syntax-highlighting

# ----- Homebrew -----
eval "$(/opt/homebrew/bin/brew shellenv)"
export HOMEBREW_BUNDLE_FILE="~/.config/homebrew/Brewfile"

# ----- Zsh options -----
setopt autocd correct share_history hist_ignore_dups hist_reduce_blanks
bindkey -v                  # vi-läge (ta bort om du föredrar emacs)
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000

# ----- Completion -----
autoload -Uz compinit; compinit

# ----- Zsh plugins -----
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
bindkey '^ ' autosuggest-accept
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ----- Starship (prompt) -----
eval "$(starship init zsh)"

# ----- fzf (Fuzzy finder) -----
eval "$(fzf --zsh)"

# ----- Eza (better ls) -----
alias ls='eza --group-directories-first --icons=auto'
alias ll='eza -lh --group-directories-first --git --icons=auto'

# ----- asdf (install dependencies) -----
. $HOME/.asdf/asdf.sh
. $HOME/.asdf/plugins/java/set-java-home.zsh

# ----- Zoxide (better cd) -----
eval "$(zoxide init zsh)"
alias cd=z

# ----- nvim ------
export EDITOR="nvim"
export VISUAL="nvim"
alias vim="nvim"
alias v="nvim ."
alias zrc="nvim ~/.config/zsh/.zshrc"
alias vrc="nvim ~/.config/nvim/"

# ----- local zsh customizations -----
if [ -f "$HOME/.config/zsh/zshrc" ]; then
    source "$HOME/.config/zsh/zshrc"
fi
