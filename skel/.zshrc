export ZSH="$HOME/.oh-my-zsh"
export LC_CTYPE="en_US.UTF-8"
export DISABLE_AUTO_TITLE="true"

export CUDA_DEVICE_ORDER=PCI_BUS_ID
export NCCL_IB_DISABLE=1
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
export NCCL_ASYNC_ERROR_HANDLING=1

export VLLM_WORKER_MULTIPROC_METHOD="spawn"

ZSH_THEME="agnoster"

# CASE_SENSITIVE="true"
HYPHEN_INSENSITIVE="true"

plugins=(git zsh-syntax-highlighting autojump)
zstyle ':omz:update' verbose silent

source $ZSH/oh-my-zsh.sh
