#!/bin/bash
##       Written by and for Lisa Seelye    ##
###      lisa@thedoh.com                  ###
####     Sept 2004-                      ####

unset PATH
export PATH="$HOME:/bin:/usr/local/bin:/usr/local/git/bin:/opt/local/bin:/bin:/sbin:/usr/bin:/usr/sbin:"

[[ -x /Applications/TextMate.app/Contents/Resources/mate ]] && export PATH="${PATH}:/Applications/TextMate.app/Contents/Resources"
[[ -x ${HOME}/go/bin ]] && export PATH="${HOME}/go/bin:${PATH}"
[[ -x ${HOME}/bin ]] && export PATH="${HOME}/bin:${PATH}"

export PS1='\[\033[01;32m\]\u@\h \[\033[01;34m\]\W \$ \[\033[00m\]'
export LSCOLORS="exfxcxdxbxegedabagacad"
export TZ="America/Toronto"
export HISTCONTROL=ignorespace
export GOPROXY=https://proxy.golang.org/
export GO111MODULE=on
export EDITOR=vim

## Set up prompt
case $TERM in
  xterm*|rxvt|eterm|Eterm)
    PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HNAME}:${PWD/$HOME/~}\007"'
  ;;
  screen)
    PROMPT_COMMAND='echo -ne "\033[0;35mscreen\033[0;37m:"'
  ;;
esac

source ~/.bash_profile.d/secure_start.sh 2>/dev/null
source ~/.bash_profile.d/local_start.sh 2>/dev/null

# Perl-style
if [[ $(which perl 2>/dev/null) ]]; then
makepasswords() {
  perl <<PERL
  my @a = ("a".."z","A".."Z","0".."9",(split //, q{#@,.<>$%&()*^}));
  for (1..10) {
    print join "", map { \$a[rand @a] } (1..rand(3)+7);
    print qq{\n}
  }
PERL
}
fi

# Ruby-style
if [[ -f /usr/share/dict/words && -x $(which ruby 2>/dev/null) ]]; then
  mkpwds() {
    local dictsrc=/usr/share/dict/words dicttmp=$(mktemp -t XXXXXX) words= iterations=${1:=4}
    
    touch $dicttmp
    chmod 0600 $dicttmp
    grep -E '[a-z]{3,5}' $dictsrc > $dicttmp
    
    for i in $(seq 1 $iterations)
    do
      words="${words} $(ruby -e "puts File.read('$dicttmp').lines.select {|w| w.length >= 3 && w.length <= 5 }.sample.downcase")"
    done

    echo $words
    # Do cleanup now 
    /bin/rm -f -- $dicttmp 1>/dev/null
  }
fi

## Aliases
alias cp="/bin/cp -ivr"
alias rm="/bin/rm -iv"
alias mv="/bin/mv -iv"
case $(uname -s | tr A-Z a-z) in
  linux )
    alias ls="/bin/ls --color=auto"
    alias ll="/bin/ls --color -l"
  ;;
  darwin )
    alias ll="/bin/ls -lG"
  ;;
  * )
    alias ll="/bin/ls -l"
  ;;
esac

if [[ -x /usr/local/opt/fzf/bin/fzf && $- == *i* ]]; then
  export PATH="/usr/local/opt/fzf/bin:${PATH}"
  source /usr/local/opt/fzf/shell/completion.bash 2>/dev/null
  source /usr/local/opt/fzf/shell/key-bindings.bash 2>/dev/null
fi

# Git stuff
if [[ $(which git 2>/dev/null) ]]; then
  # Bash completion for git
  for b in /usr/local/etc/bash_completion.d/git-completion.bash /Library/Developer/CommandLineTools/usr/share/git-core/git-completion.bash /usr/share/doc/git-$(git --version | cut -d " " -f 3)/contrib/completion/git-completion.bash
  do
    if [[ -r $b ]]; then
      source $b 2>/dev/null
      break
    fi
  done
fi

if [[ $(which oc 2>/dev/null) || $(which kubectl 2>/dev/null) ]]; then
  # Set up k alias to oc if it's there, kubectl otherwise
  alias k=$(which oc kubectl 2>/dev/null | head -n1)
fi

if [[ $(which gpg 2>/dev/null)  ]]; then
  export GPG_TTY=$(tty)
  # If keychain is running let's get the agents into our environment.
  [[ -f "${HOME}/.keychain/${HOSTNAME}-sh" ]] && . "${HOME}/.keychain/${HOSTNAME}-sh"
  [[ -f "${HOME}/.keychain/${HOSTNAME}-sh-gpg" ]] && . "${HOME}/.keychain/${HOSTNAME}-sh-gpg"
fi

if [[ $(which docker 2>/dev/null) ]]; then
  mquery() {
    local target=$1
    docker run --rm -ti mplatform/mquery ${target}
  }
fi

for s in "$HOME/.rvm/scripts/rvm" "$HOME/.gvm/scripts/gvm" "$HOME/uhc-complete.bash" /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.bash.inc /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.bash.inc
do
  [[ -s $s ]] && source $s 2>/dev/null
done

if [[ -s /usr/local/opt/kube-ps1/share/kube-ps1.sh ]]; then
  source /usr/local/opt/kube-ps1/share/kube-ps1.sh 2>/dev/null
  PS1='$(kube_ps1)'$PS1
fi

# Anything from a secured end?
source ~/.bash_profile.d/secure_end.sh 2>/dev/null
source ~/.bash_profile.d/local_end.sh 2>/dev/null