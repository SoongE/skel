export ZSH="$HOME/.oh-my-zsh"
export CUDA_DEVICE_ORDER=PCI_BUS_ID
export LC_CTYPE="en_US.UTF-8"
export PATH=/usr/local/cuda-12.4/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda-12.4/lib64:$LD_LIBRARY_PATH

ZSH_THEME="agnoster"

# CASE_SENSITIVE="true"
HYPHEN_INSENSITIVE="true"

plugins=(git zsh-syntax-highlighting autojump)

source $ZSH/oh-my-zsh.sh
