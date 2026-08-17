export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8

export CUDA_DEVICE_ORDER=PCI_BUS_ID
export TORCH_NCCL_ASYNC_ERROR_HANDLING=1
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
export VLLM_WORKER_MULTIPROC_METHOD="spawn"
export TOKENIZERS_PARALLELISM=false
export HF_HUB_ENABLE_HF_TRANSFER=1

export VIRTUAL_ENV_DISABLE_PROMPT=1

# ── history ──────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt HIST_IGNORE_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS
setopt EXTENDED_HISTORY INC_APPEND_HISTORY
setopt AUTO_CD INTERACTIVE_COMMENTS

# 화살표 위/아래 = 입력한 접두어로 히스토리 검색
autoload -U up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
for _km in emacs viins; do
  bindkey -M $_km '^[[A' up-line-or-beginning-search
  bindkey -M $_km '^[OA' up-line-or-beginning-search
  bindkey -M $_km '^[[B' down-line-or-beginning-search
  bindkey -M $_km '^[OB' down-line-or-beginning-search
  [[ -n ${terminfo[kcuu1]} ]] && bindkey -M $_km "${terminfo[kcuu1]}" up-line-or-beginning-search
  [[ -n ${terminfo[kcud1]} ]] && bindkey -M $_km "${terminfo[kcud1]}" down-line-or-beginning-search
done
unset _km

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

zinit light zsh-users/zsh-completions
autoload -Uz compinit && compinit -d ~/.cache/zcompdump
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z-_}={A-Za-z_-}' 'r:|=*' 'l:|=* r:|=*'

# ── autojump ─────────────────────────────────────────
[[ -f /usr/share/autojump/autojump.sh ]] && \
  source /usr/share/autojump/autojump.sh

_venv_prompt() {
  emulate -L zsh
  setopt extended_glob

  if [[ -z "$VIRTUAL_ENV" ]]; then
    unset VENV_PROMPT _venv_cached_path _venv_cached_name
    return
  fi
  if [[ "$VIRTUAL_ENV" != "$_venv_cached_path" ]]; then
    _venv_cached_path="$VIRTUAL_ENV"
    _venv_cached_name=""
    if [[ -r "$VIRTUAL_ENV/pyvenv.cfg" ]]; then
      local -a _lines _match
      _lines=("${(@f)$(<$VIRTUAL_ENV/pyvenv.cfg)}")
      _match=("${(@M)_lines:#(#i)prompt[[:space:]]#=*}")
      if (( $#_match )); then
        local v="${_match[1]#*=}"
        v="${v##[[:space:]]#}"
        v="${v%%[[:space:]]#}"
        v="${v#[\"\']}"; v="${v%[\"\']}"
        _venv_cached_name="$v"
      fi
    fi
    [[ -z "$_venv_cached_name" ]] && _venv_cached_name="${VIRTUAL_ENV:t}"
  fi
  export VENV_PROMPT="$_venv_cached_name"
}
autoload -Uz add-zsh-hook
add-zsh-hook precmd _venv_prompt

eval "$(starship init zsh)"

zinit light zdharma-continuum/fast-syntax-highlighting
