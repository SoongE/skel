export ZSH="$HOME/.oh-my-zsh"
export CUDA_DEVICE_ORDER="PCI_BUS_ID"
export NCCL_P2P_LEVEL="NVL"
export LC_CTYPE="en_US.UTF-8"
export DISABLE_AUTO_TITLE="true"

ZSH_THEME="agnoster"

# CASE_SENSITIVE="true"
HYPHEN_INSENSITIVE="true"

plugins=(git zsh-syntax-highlighting autojump)

source $ZSH/oh-my-zsh.sh
