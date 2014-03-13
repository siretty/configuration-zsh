source ~/.shrc_common

# load math functions
zmodload zsh/mathfunc

HISTFILE=~/.zsh_history
HISTSIZE=1000
SAVEHIST=1000

setopt appendhistory hist_ignore_all_dups
setopt autocd beep extendedglob nomatch
unsetopt notify
unsetopt hist_beep  # no bell on error in history
unsetopt list_beep  # no bell on ambigous completion

# load color support
autoload -U colors && colors


###
# keys
bindkey -e

typeset -A keys
if [[ "$TERM" =~ ".*screen.*" ]] ; then
  keys[Insert]='^[[2~';
  keys[Delete]='^[[3~';
  keys[Home]='^[[1~'
  keys[HomeAlt]='^[[1~'
  keys[End]='^[[4~'
  keys[EndAlt]='^[[4~'

  keys[Up]='^[[A';    keys[C_Up]='^[[1;5A';
  keys[Down]='^[[B';  keys[C_Down]='^[[1;5B';
  keys[Right]='^[[C'; keys[C_Right]='^[[1;5C';
  keys[Left]='^[[D';  keys[C_Left]='^[[1;5D';
fi
if [[ "$TERM" =~ ".*xterm.*" ]] ; then
  keys[Insert]='^[[2~';
  keys[Delete]='^[[3~';
  keys[Home]='^[OH';
  keys[HomeAlt]='^[[H';
  keys[End]='^[OF';
  keys[EndAlt]='^[[F';

  keys[Up]='^[[A';    keys[C_Up]='^[[1;5A';
  keys[Down]='^[[B';  keys[C_Down]='^[[1;5B';
  keys[Right]='^[[C'; keys[C_Right]='^[[1;5C';
  keys[Left]='^[[D';  keys[C_Left]='^[[1;5D';
fi

bindkey $keys[Up]       up-line-or-history
bindkey $keys[Down]     down-line-or-history
bindkey $keys[Insert]   overwrite-mode
bindkey $keys[Delete]   delete-char
bindkey $keys[C_Left]   emacs-backward-word
bindkey $keys[C_Right]  emacs-forward-word
bindkey $keys[Home] beginning-of-line $keys[HomeAlt] beginning-of-line
bindkey $keys[End] end-of-line $keys[EndAlt] end-of-line


###
# completion

# zstyle :compinstall filename '/home/daniel/.zshrc'
zstyle ':completion:*' menu select

#zstyle ':completion:*:descriptions' format '%U%B%d%b%u'
zstyle ':completion:*:warnings' format '%Bsorry, no matches for: %d%b'

# show process forest for kill completion
#zstyle ":completion:*:*:kill:*:processes" command 'ps --forest -e -o pid,user,tty,cmd'

autoload -Uz compinit
compinit

setopt completealiases
#setopt correctall


###
# shell prompt

function prompt_vcs {
  prompt_vcs_git
}

function prompt_vcs_git {
  # vcsh provides a "vitual" git repository, this interferes with the prompt
  if [ -n "${VCSH_REPO_NAME}" ] ; then
    echo -n " %F{magenta}[vcsh:${VCSH_REPO_NAME}]%f%k"
    return 
  fi

  local isgitwt="$(git rev-parse --is-inside-work-tree 2>/dev/null)" isgitrc="$?"

  # git rev-parse --is-inside-work-tree
  #   exit code zero:     if inside of an git repo
  #     output "true":      if we're in the working directory
  #     output "false":     else
  #   exit code non-zero: if outside of a git repo
  [ "$isgitrc" != "0" ] && return

  local git_df=""       # dirty flags

  # check for (unignored) (unstaged) untracked files
  [[ -n "$(git ls-files --exclude-standard --others 2>/dev/null)" ]] && git_df="${git_df}u"

  # check for (unignored) (unstaged) deleted files
  [[ -n "$(git ls-files --exclude-standard --deleted 2>/dev/null)" ]] && git_df="${git_df}d"

  # check for (unignored) (unstaged) modified files
  [[ -n "$(git ls-files --exclude-standard --modified 2>/dev/null)" ]] && git_df="${git_df}m"

  # check for (unignored) (staged) files
  if git diff-index --quiet --cached HEAD 2>/dev/null ; then ; else
    git_df="${git_df}s"
  fi

  # select color (based on dirty flags)
  local git_col='%F{green}'
  [[ "${git_df}" =~ 's' ]] && git_col='%F{yellow}'
  [[ "${git_df}" =~ '[^s]' ]] && git_col='%F{red}'

  echo -n " ${git_col}["
  echo -n 'git:'
  echo -n $(git branch | sed -n '/\* /s///p')
  
  [ -n "${git_df}" ] && echo -n " ${git_df}"
  
  echo -n ']%f%k'
}

function prompt_bat {
  # find the first battery (this could be extended to _all_ batteries, but
  # im a lazy man and this laptop has no second battery so ...)
  local dir=$([ -d /sys/class/power_supply ] && find /sys/class/power_supply -type l -iname 'BAT*' | head -n1)

  # if no battery is present we return
  [ -z "$dir" ] && return

  local max=$(cat $dir/charge_full)
  local cur=$(cat $dir/charge_now)
  local cur_per=$(( int( 100.0 * cur / max ) ))
  local sta=$(cat $dir/status)

  local col=''
  if (( $cur_per <= 25 )) ; then
    col='%F{red}%B'
  elif (( $cur_per <= 50 )) ; then
    col='%F{yellow}'
  else
    col='%F{green}'
  fi

  local sta_chr=''
  case $sta in
  [Cc]harg*)
    sta_chr='C' ;;
  [Dd]ischarg*)
    sta_chr='D' ;;
  *)
    sta_chr='U' ;;
  esac

  echo -n " ${col}["
  echo -n "$cur_per%% $sta_chr"
  echo -n ']%b%f'
}

setopt promptsubst
setopt promptpercent

export PROMPT='┌ %F{green}%n%f%B@%b%F{yellow}%m%f %F{cyan}%2~%f$(prompt_vcs)$(prompt_bat)
└ %B%#%b '

export RPROMPT=''


bindkey "\eOH" beginning-of-line
bindkey "\eOF" end-of-line

chpwd_functions+=(__vte_osc7)

