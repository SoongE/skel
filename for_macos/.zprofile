PATH=/opt/homebrew/bin:/opt/homebrew/sbin:$PATH

if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

if [ -f ~/.aliases ]; then
    . ~/.aliases
fi

if [ -d "/opt/homebrew/opt/ruby/bin" ]; then
  export PATH=/opt/homebrew/opt/ruby/bin:$PATH
  if [ ! -s ~/.cache/gemdir ]; then
    mkdir -p ~/.cache
    gem environment gemdir >| ~/.cache/gemdir 2>/dev/null
  fi
  [ -s ~/.cache/gemdir ] && export PATH="$(<~/.cache/gemdir)/bin:$PATH"
fi
