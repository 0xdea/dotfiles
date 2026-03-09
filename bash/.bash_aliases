alias ls='ls -F --color=auto'
alias fd='fdfind'
alias up='sudo -i'
alias script='SCRIPT=yes script -af'
alias vi='nvim'

if [ "$SCRIPT" = yes ]; then
	PS1='\t:\w\$ '
	alias ls='ls -F'
fi

