#!/bin/bash

#define Hostname
varHostname="secedu-srv-01"


#VIM Settings
cat << EOF > /root/.vimrc
set nocompatible        " Use Vim defaults (much better!)
set bs=indent,eol,start         " allow backspacing over everything in insert mode
"set ai                 " always set autoindenting on
"set backup             " keep a backup file
set viminfo='20,\"50    " read/write a .viminfo file, don't store more
" than 50 lines of registers
set history=50          " keep 50 lines of command line history
set ruler               " show the cursor position all the time

set background=dark
"syntax=on
EOF


#enable DHCP for second interface
sed -i 's/^USE_DHCP\[1\]=.*/USE_DHCP\[1\]="yes"/g' /etc/rc.d/rc.inet1.conf

#set profilesettings
cat << EOF > /root/.bashrc
export PATH=$PATH:~/bin:
source /root/.bash_profile
EOF

cat << EOF >/root/.bash_profile
export PATH=$PATH:~/bin
alias ll='ls -l'
alias grep='grep --color'
alias ls='ls --color=auto'	
alias wget='wget --no-check-certificate'
EOF

#ssh settings regarding login timeout -> disable DNS resolution
sed -i 's/.*UseDNS.*/UseDNS no/g' /etc/ssh/sshd_config

#restart SSHD
/etc/rc.d/rc.sshd restart

#change Hostname
echo $varHostname".local" > /etc/HOSTNAME


#restart system to make sure all changes become active
reboot
