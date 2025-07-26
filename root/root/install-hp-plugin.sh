#!/usr/bin/env bash

export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - bash)"

pyenv shell 3.11 && echo -ne '\n' | hp-plugin -p /plugin-files/
