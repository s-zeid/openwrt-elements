post_common() {
 chmod +x /.main.sh
 
 apt -y update && apt -y upgrade
 
 # OpenWRT deps
 # <https://openwrt.org/docs/guide-developer/quickstart-build-images>
 apt -y install --no-install-recommends \
  subversion g++ zlib1g-dev build-essential git python python3 \
  libncurses5-dev gawk gettext unzip file libssl-dev wget \
  libelf-dev ecj fastjar java-propose-classpath \
  python3-distutils \
  || true  # ignore errors about man pages
 
 # OpenWRT imagebuilder deps
 # <https://openwrt.org/docs/guide-user/additional-software/imagebuilder>
 apt -y install --no-install-recommends \
  build-essential libncurses5-dev libncursesw5-dev zlib1g-dev gawk git gettext libssl-dev xsltproc wget unzip python \
  || true  # ignore errors about man pages
 
 # extra OpenWRT deps that are not listed in the OpenWRT wiki
 apt -y install --no-install-recommends \
  libncurses5 libncursesw5 time \
  || true  # ignore errors about man pages
 
 # Our deps, including some utilities for use in interactive shells.
 # Some OpenWRT deps are duplicated here for easier copy/pasting of the above
 # list from the OpenWRT wiki in case they remove some deps from their list.
 apt -y install --no-install-recommends \
  strace procps ca-certificates curl rsync wget build-essential \
  autoconf automake intltool libtool pkg-config \
  gcc binutils file git jq python3 python3-pip python2 python-pip \
  p7zip-full tar unzip xz-utils zip \
  less vim-tiny \
  || true  # ignore errors about man pages
 
 apt -y clean
 
 # (a) fakeroot, (b) shut up about modified conf files
 cat > /usr/local/bin/apt <<"SH"
#!/bin/sh

export DEBIAN_FRONTEND=noninteractive

exec unshare -U -r strace -f -o /dev/null \
 -e inject=setgroups,chown,fchown,fchownat,lchown,setresuid,setresgid:retval=0 \
 /usr/bin/apt -o Debug::NoDropPrivs=true \
  -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
  "$@"
SH
 chmod +x /usr/local/bin/apt
 
 # Compile unroot
 gcc /usr/local/bin/chuidgid.c -o /usr/local/bin/chuidgid
 ln -s /usr/local/bin/chuidgid /usr/local/bin/unroot
 
 # .bashrc
 sed -i -e 's/^PS1=.*$/#\0/#\0/g' /etc/bash.bashrc
 printf '%s\n' "" \
  'export PS1="${_PS1:-PS1}"; unset _PS1' \
  "export LS_OPTIONS='--color=auto'" \
  'eval "`dircolors --sh`"' \
  "alias ls='ls \$LS_OPTIONS'" \
  >> /root/.bashrc
}


# vim: set ft=sh fdm=marker:
