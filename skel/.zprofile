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

if [ -d "/usr/local/cuda/bin" ] ; then
        PATH="/usr/local/cuda/bin:$PATH"
fi

if [ -f ~/.aliases ]; then
    . ~/.aliases
fi