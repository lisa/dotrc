#!/bin/bash                                 #
##       Written by and for Lisa Seelye    ##
###      lisa@thedoh.com                  ###
####     Sept 2004-                      ####


[ "${-/i/}" != "${-}" ] && INTERACTIVE=1 || INTERACTIVE=0 # interactive term?
unset PATH
PATH="/usr/local/bin:/usr/local/git/bin:/opt/local/bin:/bin:/sbin:/usr/bin:/usr/sbin"
export PATH

# yeah, america/toronto...
TZ='America/Toronto'; export TZ

[ -f /Applications/TextMate.app/Contents/Resources/mate ] && export PATH="${PATH}:/Applications/TextMate.app/Contents/Resources/"

PROJDIR="${HOME}/github"
UNAME_S="$(uname -s)"
HNAME="$(uname -n)"
PAGER=less
GPGKEYUSER="Lisa Seelye"
PASSWORDSRC="$HOME/passwords"


[ -x /usr/xpg4/bin/id ] && ID="/usr/xpg4/bin/id" || ID="/usr/bin/id" #solaris should prefer /usr/xpg4/bin/id

###########################################################
######## Colorise
###########################################################

PREFIX='\033['
SEP=";"
FG_BLACK="0;30m"
FG_BLUE="0;34m"
FG_GREEN="0;32m"
FG_CYAN="0;36m"
FG_RED="0;31m"
FG_PURPLE="0;35m"
FG_BROWN="0;33m"
FG_LGRAY="0;37m"
FG_WHITE="1;37m"
FG_LBLUE="1;34m"
FG_LGREEN="1;32m"
FG_LCYAN="1;36m"
FG_LRED="1;31m"
FG_PINK="1;35m"
FG_YELLOW="1;33m"
FG_DGRAY="1;30m"

BG_RED=41
BG_GREEN=42
BG_BROWN=43
BG_BLUE=44
BG_PURPLE=45
BG_CYAN=46
BG_GRAY=47

OPT_UNDERLINE=4
OPT_BLINK=5
OPT_REVERSE=7
OPT_CONSEAL=8

DEFAULT="${PREFIX}${FG_LGRAY}"
 

colorise() {
  local flag s= fg= bg= suff="${DEFAULT}" opts= str="${PREFIX}"
     
  for flag in ${*}
  do
    case ${flag} in
      -fg=* )
        fg="\$FG_$(echo "${flag/-fg=/}" | tr [a-z] [A-Z])"
        
      ;;        
      -bg=* )
        bg="\$BG_$(echo "${flag/-bg=/}" | tr [a-z] [A-Z])"
      ;;
      -blink )
        if [ -z ${opts} ]
        then
          opts="${OPT_BLINK}"
        else
          opts="${opts}${SEP}${OPT_BLINK}"
        fi
      ;;
      -underline )
        if [ -z ${opts} ]
        then
          opts="${OPT_UNDERLINE}"
        else
          opts="${opts}${SEP}${OPT_UNDERLINE}"
        fi
      ;;
      -reverse )
        if [ -z ${opts} ]
        then
          opts="${OPT_REVERSE}"
        else
          opts="${opts}${SEP}${OPT_REVERSE}"
        fi
      ;;
      -conseal )
        if [ -z ${opts} ]
        then
          opts="${OPT_CONSEAL}"
        else
          opts="${opts}${SEP}${OPT_CONSEAL}"
        fi
      ;;
      -nodefault )
        suff=''
      ;;
      * )
        if [ -z "${s}" ]
        then
          s="$(echo $flag | sed -e "s:'::g" -e 's:"::g')" 
        else
          s="${s} $(echo $flag | sed -e "s:'::g" -e 's:"::g')"
        fi
      ;;
     esac
  done
  

  bg=$(eval echo ${bg})
  fg=$(eval echo ${fg})
  
  
  if [ -z "${fg}" ]
  then
    echo ${s}
    return
  fi

  if [ -n "${opts}" ]
  then
    str="${str}${opts}${SEP}"
  fi

  if [ -n "${bg}" ]
  then
    str="${str}${bg}${SEP}"
  fi

  str="${str}${fg}"  
 
  #caller is responsible for final formatting (echo -ne)
  echo "${str}${s}${suff}"
  return
}
COLOR=1

###########################################################
######## Straight on Functions
###########################################################

ensure_ssh_configd() {
  mkdir -p $HOME/.ssh/ssh_config.d
  chmod 700 $HOME/.ssh
  chmod 700 $HOME/.ssh/ssh_config.d
}

create_ssh_config() {
  ensure_ssh_configd
  # What could possibly go wrong with this?
  cat $HOME/.ssh/ssh_config.d/* > $HOME/.ssh/config
}

is_root() {

  if [ "$(${ID} -u)" == "0" ]; then
    echo "1"
  fi
}

makepasswords() {
  perl <<PERL
  my @a = ("a".."z","A".."Z","0".."9",(split //, q{#@,.<>$%&()*^}));
  for (1..10) {
    print join "", map { \$a[rand @a] } (1..rand(3)+7);
    print qq{\n}
  }
PERL
}


rand() {
  ruby -e 'puts rand.to_s'
}

echo1() {
  echo "${1}"
}

###########################################################
######## Conditional Stuff 
###########################################################

if [ "${UNAME_S}" == "Linux" ]; then
  alias ls="ls --color=auto"
  alias ll="ls --color -l"
  alias cp="cp -irv"
  alias mv="mv -iv"
  alias rm="rm -iv"
elif [ "${UNAME_S}" == "Darwin" ]; then
  alias ll="ls -lG"
  alias cp="cp -ivr"
  alias rm="rm -iv"
  alias mv="mv -iv"
else
  alias ll="ls -l"
  alias cp="cp -ivr"
  alias rm="rm -iv"
  alias mv="mv -iv"
fi

# These only matter if we have gpg available and we're an interactive shell.
if [[ "x$(which gpg)" != "x" && $INTERACTIVE == "1" ]]; then
  # If keychain is running let's get the agents into our environment.
  [[ -f "${HOME}/.keychain/${HOSTNAME}-sh" ]] && . "${HOME}/.keychain/${HOSTNAME}-sh"
  [[ -f "${HOME}/.keychain/${HOSTNAME}-sh-gpg" ]] && . "${HOME}/.keychain/${HOSTNAME}-sh-gpg"
  
  # Ensure we have a real place to stash passwords
  mkdir -m 700 -p $PASSWORDSRC 2>/dev/null
  # Ensure permissions are as I want
  chmod 700 $PASSWORDSRC 2>/dev/null
  chown $(id -u):$(id -g) $PASSWORDSRC 2>/dev/null
  
  e() {
    local src=$1
    gpg --batch --yes -r "$GPGKEYUSER" -a -e $src
  }
  
  d() {
    local src=$1
    gpg -d $PASSWORDSRC/${src/\.asc/}.asc
  }
fi

if [[ -f /usr/share/dict/words && -x $(which ruby) ]]; then
  mkpwds() {
    DICTSRC="/usr/share/dict/words"
    DICTTMP="$(mktemp -t XXXXXX)"
    WORDS=""
    ITERATIONS=8
    
    touch $DICTTMP
    chmod 0600 $DICTTMP
    grep -E '[a-z]{6,}' $DICTSRC > $DICTTMP
    
    for i in $(seq 1 $ITERATIONS)
    do
      WORDS="${WORDS} $(ruby -e "puts File.read('$DICTTMP').lines.select {|w| w.length >=6 }.sample.downcase")"
    done

    echo $WORDS
    # Do cleanup now 
    rm -f -- $DICTTMP 1>/dev/null
    unset WORDS DICTSRC DICTTMP ITERATIONS
  }
fi


if [ -x /usr/bin/screen ]; then
  o_screen() {
    local dead attached detached total
    dead="$(/usr/bin/screen -list | grep -c \(Dead)"
    attached="$(/usr/bin/screen -list | grep -c \(Attached)"
    detached="$(/usr/bin/screen -list | grep -c \(Detached)"
    total=$(( $dead + $attached + $detached ))

    echo -ne "Screens: Attached " 
    echo -ne $(colorise -fg=green ${attached}) 
    echo -ne ", Detached " 
    echo -ne $(colorise -fg=green ${detached})
    echo -ne ", Dead "
    echo -ne $(colorise -fg=red ${dead})
    echo -ne ", Total: "
    echo -ne $(colorise -fg=cyan ${total})
    echo
  }
  else
  o_screen() {
    echo
  }
fi

if [[ -x /usr/local/bin/docker && -d $HOME/Kitematic ]]; then
  export DOCKER_HOST=tcp://192.168.99.100:2376
  export DOCKER_CERT_PATH=/Users/lisas/.docker/machine/machines/dev
  export DOCKER_TLS_VERIFY=1
fi

# Redefine colorise if we're not supposed to use color

if [ ${COLOR} != "1" ]; then
  colorise() {
    local token line=''
    for token in ${*}
    do
      case ${token} in
        -* ) ;; # Skip all flags
        * ) 
          line="${line} ${token}"
        ;;
      esac
    done
    echo "${line}"
  }
fi


### Generic Stuff
case $TERM in
  xterm*|rxvt|eterm|Eterm)
    PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HNAME}:${PWD/$HOME/~}\007"'
  ;;
  screen)
    PROMPT_COMMAND='echo -ne "\033[0;35mscreen\033[0;37m:"'
  ;;
esac


###########################################################
#########   Aliases
###########################################################

export PS1='\[\033[01;32m\]\u@\h \[\033[01;34m\]\W \$ \[\033[00m\]'

###########################################################
#########   Run on interactive terminal
###########################################################

if [ "${INTERACTIVE}" == 1 ]; then
  
  # Concatenate ssh config fragments into ~/.ssh/ssh_config
  # ssh does not allow including of subfiles so we're left with this hack
  # Perhaps ensure a ~/.ssh/ssh_config.d (700) and use numbering of files for 
  # order.
  ensure_ssh_configd
  create_ssh_config
  
  if [ -n "${PROJDIR}" ]; then
    alias pd="cd ${PROJDIR}"
  fi
  
	if [ "${UNAME_S}" != Darwin ]; then
  	last -aid -n 2 | grep -v "wtmp" | grep -v ^$
	fi
  uptime
  tt="$(tty | sed -e 's:/dev/::' -e 's:/: :')"
  line="$(colorise -fg=green '+') You are $(colorise -fg=cyan ${USER}) on"
  line="${line} $(colorise -fg=cyan "${HNAME}") using $(colorise -fg=cyan ${tt})"
  line="${line//  / }"
  echo -e "${line}"
  echo $(o_screen)
fi
export EDITOR=vim


#Ignore .svn, .git, .hg files
FIGNORE=.svn:.git:.hg

export PATH="/usr/local/bin:$PATH:/Users/lisas/.gem/ruby/1.8/bin"

if [[ "x$(which rbenv 2>/dev/null)" != "x" ]]; then
  eval "$(rbenv init -)"
fi
