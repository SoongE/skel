if [ -f "$HOME/.zshrc" ]; then
    . "$HOME/.zshrc"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

if [ -d "/usr/local/cuda-12.3/bin" ] ; then
        PATH="/usr/local/cuda-12.3/bin:$PATH"
fi

if [ -d "/usr/local/cuda-12.3/lib64" ] ; then
        LD_LIBRARY_PATH="/usr/local/cuda-12.3/lib64:$LD_LIBRARY_PATH"
fi

if [ -f ~/.aliases ]; then
    . ~/.aliases
fi