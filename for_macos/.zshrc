export ZSH="$HOME/.oh-my-zsh"
export PATH=/opt/homebrew/bin:$PATH
if [ -d "/opt/homebrew/opt/ruby/bin" ]; then
  export PATH=/opt/homebrew/opt/ruby/bin:$PATH
  export PATH=`gem environment gemdir`/bin:$PATH
fi

ZSH_THEME=""
plugins=(git autojump)
source "$ZSH/oh-my-zsh.sh"

# Starship 프롬프트 (oh-my-zsh 이후에 로드해야 테마가 덮어쓰이지 않음)
eval "$(starship init zsh)"

# zinit
source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

zinit light zdharma-continuum/fast-syntax-highlighting    # 명령어 구문 강조
zinit light zsh-users/zsh-completions                      # 추가 자동 완성 정의

alias ls="lsd"
alias ll="lsd -la"
alias lt="lsd --tree"
alias grep="rg"
alias top="btop"
alias df="duf"
alias vim="nvim"

alias nv='watch -c -n 1 nvidia-htop.py -c -l'
alias dai='docker attach seungminDockImp'
alias das='docker attach seungminDock'
alias dim='docker images'
alias dps='docker ps -a'
alias tl='tmux ls'
alias ta='tmux attach -t'
alias tn='tmux new -s'
alias tk='tmux kill-session'
alias til='watch -c -n 1 view_tmux'
alias gs='git status'
alias gm='git commit -m'
alias gp='git push'
alias ga='git add'
alias gal='git add .'
alias gd='git diff'
alias pt='python3'
alias xl='tmuxp load'
alias jp='jupyter notebook --NotebookApp.token="" --NotebookApp.password=""'
alias rs='rsync -ahvL'