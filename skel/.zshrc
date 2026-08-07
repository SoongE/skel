export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
export ZSH="$HOME/.oh-my-zsh"
export DISABLE_AUTO_TITLE="true"

export CUDA_DEVICE_ORDER=PCI_BUS_ID
export TORCH_NCCL_ASYNC_ERROR_HANDLING=1
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

export VLLM_WORKER_MULTIPROC_METHOD="spawn"
export TOKENIZERS_PARALLELISM=false
export HF_HUB_ENABLE_HF_TRANSFER=1

ZSH_THEME="agnoster"
# CASE_SENSITIVE="true"
HYPHEN_INSENSITIVE="true"

plugins=(git autojump virtualenv zsh-syntax-highlighting)

zstyle ':omz:update' verbose silent
zstyle ':omz:update' mode disabled

source $ZSH/oh-my-zsh.sh

# For virtualenv prompt naming
prompt_virtualenv() {
  [[ -n "$VIRTUAL_ENV" && -n "$VIRTUAL_ENV_DISABLE_PROMPT" ]] || return

  if [[ "$VIRTUAL_ENV" != "$_venv_cached_path" ]]; then
    _venv_cached_path="$VIRTUAL_ENV"
    _venv_cached_name=""
    if [[ -f "$VIRTUAL_ENV/pyvenv.cfg" ]]; then
      local line="${${(M)${(f)"$(<$VIRTUAL_ENV/pyvenv.cfg)"}:#(#i)prompt*}[1]}"
      _venv_cached_name="${${line#*=}## #}"
      _venv_cached_name="${_venv_cached_name%% #}"
    fi
    [[ -z "$_venv_cached_name" ]] && _venv_cached_name="${VIRTUAL_ENV:t}"
  fi

  prompt_segment blue black "(${_venv_cached_name:gs/%/%%})"
}
