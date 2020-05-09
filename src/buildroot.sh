#!/bin/sh

if [ $_TRACE -ne 0 ]; then
 set -x
fi

root=/buildroot
cd "$root"


# Build products will not fit in RAM on most hosts
mkdir -p /tmp/out/buildroot/build_dir
ln -sf /tmp/out/buildroot/build_dir "$root/build_dir"

# Seed .config
printf '' > .config
echo CONFIG_TARGET_MULTI_PROFILE=y >> .config
echo CONFIG_TARGET_PER_DEVICE_ROOTFS=y >> .config
echo CONFIG_TARGET_ROOTFS_SQUASHFS=n >> .config
echo CONFIG_BUILDBOT=y >> .config
echo CONFIG_IB=y >> .config
echo CONFIG_SDK=y >> .config

# Set target
target=$(printf '%s\n' "${_TARGET:-$(cat /.default-target)}" | tr '_' '-')
target_main=${target%%-*}
printf 'CONFIG_TARGET_%s=y\n' "$target_main" >> .config
printf 'CONFIG_TARGET_%s=y\n' "$(printf '%s\n' "$target" | tr '-' '_')" >> .config

# Extra configuration from def file
extra_config

# config.seed
cp -p .config /tmp/out/config.seed


build() {
 # Update feeds
 ./scripts/feeds update -a
 ./scripts/feeds install -a
 
 # Configure
 make defconfig
 
 # Patch
 local patch="/patch"
 if [ -e "$patch" ]; then
  if [ -d "$patch" ]; then
   patch="/patch/Patchfile"
   if ! [ -e "$patch" ]; then
    echo "$ELEMENTS_ARGV0: error: provided patch script is a directory but does not have a Patchfile" >&2
    return 2
   fi
  fi
  /usr/local/bin/unroot sh -e -x "$patch"
  make defconfig
 fi
 
 # Build
 local make_V=
 if [ $_TRACE -ne 0 ]; then
  make_V='V=s'
 fi
 local n_cpus="$(grep '^processor' /proc/cpuinfo | wc -l)"
 /usr/local/bin/unroot make -j "${_MAKE_PARALLEL:-$((n_cpus + 1))}" $make_V
 
 # Move output
 mv "$root"/bin/* /out/
 rm -rf "$root/bin"
 ln -s /out "$root/bin"  # for -s / $_SHELL_AFTER
 
 # Create symlinks in output
 cd /out
 ln -s targets/*/*/*-imagebuilder-*.tar.xz imagebuilder.tar.xz || true
 ln -s targets/*/*/*-sdk-*.tar.xz sdk.tar.xz || true
 cd "$root"
 
 # About
 mkdir /out/about
 printf '%s\n' "$target" > /out/about/target
 cp -pr /patch /out/about/buildroot-patch-script
 cp -p /tmp/out/config.seed /out/about/config.seed
}
[ $_SHELL_ONLY -eq 0 ] && (set -e; build) || true; r=$?


# Shell after
if [ $_SHELL_AFTER -ne 0 ] || [ $_SHELL_ONLY -ne 0 ]; then
 export _PS1="$PS1"
 /usr/local/bin/unroot /sh -i -c 'exec bash'  # /sh uses --norc by default
fi


exit $r
