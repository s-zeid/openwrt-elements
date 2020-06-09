#!/bin/sh

if [ $_TRACE -ne 0 ]; then
 set -x
fi

root=/buildroot
cd "$root"


if [ x"$_VERSION" != x"" ]; then
 # Check out the given version number, commit, or branch
 # If the value is "STABLE", then check out the tag for the latest version
 if ! [ -d "$root/.git" ]; then
  echo "$ELEMENTS_ARGV0: error: version or git tag/commit/branch given, but" >&2
  echo "  this image is not based on a git repository" >&2
  exit 2
 fi
 checkout=
 if [ x"$_VERSION" = x"STABLE" ]; then
  checkout=$(git tag --list 'v*' --sort=version:refname | tail -n 1)
  if [ x"$checkout" = x"" ]; then
   echo "$ELEMENTS_ARGV0: error: could not find latest version tag" >&2
   exit 1
  fi
 elif (printf '%s\n' "$_VERSION" | head -n 1 | grep -q -e '^[0-9]\+\(\.[0-9]\+\)\+$'); then
  checkout="v$_VERSION"
 else
  checkout="$_VERSION"
 fi
 git checkout "$checkout"
fi


# Build products will not fit in RAM on most hosts
mkdir -p /tmp/out/buildroot/dl
ln -sf /tmp/out/buildroot/dl "$root/dl"
mkdir -p /tmp/out/buildroot/build_dir
ln -sf /tmp/out/buildroot/build_dir "$root/build_dir"
mkdir -p /tmp/out/buildroot/staging_dir
ln -sf /tmp/out/buildroot/staging_dir "$root/staging_dir"

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

# config.in
cp -p .config /tmp/out/config.in


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
 
 # Download sources
 /usr/local/bin/unroot make download
 
 # Build
 local make_V=
 if [ $_TRACE -ne 0 ]; then
  make_V='V=s'
 fi
 if [ $_WARNINGS -ne 0 ]; then
  make_V='V=w'
 fi
 /usr/local/bin/unroot time make -j "${_MAKE_PARALLEL:-$(($(nproc) + 1))}" $make_V
 
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
 cp -p /tmp/out/config.in /out/about/config.in
 cp -p /out/targets/*/*/*.buildinfo /out/about/ 2>/dev/null || true  # >= v19.07.0
 cp -p /out/targets/*/*/*.seed /out/about/ 2>/dev/null || true  # < v19.07.0
 if [ -d "$root/.git" ]; then
  git describe --tags --dirty --always 2>/dev/null > /out/about/git-describe
 fi
}
[ $_SHELL_ONLY -eq 0 ] && (set -e; build) || true; r=$?


# Shell after
if [ $_SHELL_AFTER -ne 0 ] || [ $_SHELL_ONLY -ne 0 ]; then
 export _PS1="$PS1"
 /usr/local/bin/unroot /sh -i -c 'exec bash'  # /sh uses --norc by default
fi


exit $r
