#!/bin/sh

if [ $_TRACE -ne 0 ]; then
 set -x
fi

root=/imagebuilder
cd "$root"


# Build products may not fit in RAM on some hosts
mkdir -p /tmp/out/imagebuilder /tmp/out/sdk
mv /imagebuilder/build_dir /tmp/out/imagebuilder/build_dir
ln -sf /tmp/out/imagebuilder/build_dir /imagebuilder/build_dir
mv /sdk/build_dir /tmp/out/sdk/build_dir
ln -sf /tmp/out/sdk/build_dir /sdk/build_dir


build() {
 local spec="/spec"
 if [ -d "$spec" ]; then
  spec="/spec/Specfile"
  if ! [ -e "$spec" ]; then
   echo "$ELEMENTS_ARGV0: error: provided spec is a directory but does not have a Specfile" >&2
   return 2
  fi
 fi
 
 /usr/local/bin/unroot sh -e -x "$spec"
 
 # Move imagebuilder output
 if [ -d "/imagebuilder/bin" ]; then
  mv /imagebuilder/bin/* /out/imagebuilder
  rm -rf /imagebuilder/bin
  ln -s /out/imagebuilder /imagebuilder/bin  # for -s / $_SHELL_AFTER
 fi
 
 # Move SDK output
 if [ -d "/sdk/bin" ]; then
  mv /sdk/bin/* /out/sdk
  rm -rf /sdk/bin
  ln -s /out/sdk /sdk/bin  # for -s / $_SHELL_AFTER
 fi
}
[ $_SHELL_ONLY -eq 0 ] && (set -e; build) || true; r=$?


# Shell after
if [ $_SHELL_AFTER -ne 0 ] || [ $_SHELL_ONLY -ne 0 ]; then
 export _PS1="$PS1"
 /usr/local/bin/unroot /sh -i -c 'exec bash'  # /sh uses --norc by default
fi


exit $r
