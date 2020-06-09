all: help


.PHONY: help
help:
	@printf '%s\n' \
	"Usage: $(notdir ${MAKE}) {PRODUCT} [options [...]]" \
	"Products: openwrt, rooter; {PRODUCT}-ibsdk, {PRODUCT}-buildroot" \
	"Output filename template (Image Builder/SDK): {PRODUCT}-ibsdk.{TARGET}.{ARCH}" \
	"Output filename template (buildroot): {PRODUCT}-buildroot.{ARCH}" \
	"Input directory for {PRODUCT}-ibsdk: {PRODUCT}-ibsdk.{TARGET}.src" \
	"  (must contain imagebuilder.tar.xz and sdk.tar.xz)" \
	"" \
	"General options:" \
	"  target={TARGET}-{SUBTARGET} (default: ${_DEFAULT_TARGET})" \
	"    The OpenWrt target for which to build" \
	"  version={VERSION_NUMBER|TAG|COMMIT|BRANCH} (default: empty)" \
	"    When building OpenWrt from a git repository (default for the \`openwrt\`" \
	"    products), check out the given version number or git tag, commit, or" \
	"    branch.  If empty, git HEAD or the contents of rooter.zip will be built." \
	"  stable=1 (default: 0)" \
	"    Build the latest stable version of OpenWrt.  Overrides the \`version\`" \
	"    option; equivalent to \`version=STABLE\`." \
	"  patch={PATCH_SCRIPT_FILE_OR_DIRECTORY} (default: none)" \
	"    If a file, a shell script to be executed in /buildroot before building" \
	"    OpenWrt.  If a directory, it will be mounted at /patch and the script" \
	"    /patch/Patchfile will be executed in /buildroot before building OpenWrt." \
	"  jobs={NUMBER_OF_CORES} (default: \`nproc\` + 1)" \
	"    Use the given number of cores when building OpenWrt." \
	"" \
	"Debugging options:" \
	"  warnings=0 (default: 1 if debug options absent; 0 otherwise)" \
	"    Do not pass \`V=w\` to make when building OpenWrt.  Overrides" \
	"    \`debug{,_parallel}=1\` with respect to verbosity." \
	"  debug=1 (default: 0)" \
	"    Pass \`-j 1 V=s\` to make when building OpenWrt and trace the build script." \
	"  debug_parallel=1 (default: 0)" \
	"    Pass \`V=s\` to make when building OpenWrt and trace the build script" \
	"    (not recommended)." \
	"  shell=1 (default: 0)" \
	"    Start a shell before the buildroot container exits." \
	; true

hep:
	@printf '%s\n' \
	"\"Hep!  Hep!  I'm covered in sawlder! ... Eh?  Nobody comes.\"" \
	"--Red Green, https://www.youtube.com/watch?v=qVeQWtVzkAQ#t=6m27s"


_DEFAULT_TARGET := $(shell cat src/default-target)

target := $(_DEFAULT_TARGET)
patch :=
jobs := 0
debug := 0
debug_parallel := 0
shell := 0
stable := 0
version :=
warnings :=


_COMMON_SRC := src/def-common.sh src/chuidgid.c
_BUILDROOT_SRC := ${_COMMON_SRC} src/buildroot.sh
_IBSDK_SRC := ${_COMMON_SRC} src/ibsdk.def src/ibsdk.sh

_arch := $(shell uname -m)

_jobs := $(filter-out 0,${jobs})
_jobs_flag := $(if ${_jobs},-j ${jobs},)

_debug := $(filter-out 0,${debug})
_debug_parallel := $(filter-out 0,${debug_parallel})
_debug_flags := $(if ${_debug}${_debug_parallel},$(if ${_jobs}${_debug_parallel},,-j 1 )-V,)

_stable := $(filter-out 0,${stable})
_version_flag := $(if ${_stable},-v "STABLE",$(if ${version},-v "${version}",))

_warnings := $(filter-out 0,$(if ${warnings},${warnings},$(if ${_debug_flags},0,1)))
_warnings_flag := $(if ${_warnings},-W,)


.PHONY: openwrt openwrt-buildroot openwrt-ibsdk openwrt-ibsdk.src
openwrt: openwrt-ibsdk.src openwrt-ibsdk

openwrt-ibsdk: openwrt-ibsdk.${target}.${_arch}
openwrt-ibsdk.%.${_arch}: _product := openwrt
openwrt-ibsdk.%.${_arch}: ${_IBSDK_SRC}
	[ -e "openwrt-ibsdk.${target}.src" ] || make openwrt-ibsdk.src
	$(make_ibsdk)

openwrt-ibsdk.src: openwrt-ibsdk.${target}.src
openwrt-ibsdk.%.src: openwrt-buildroot.${_arch}
	$(make_ibsdk_src)

openwrt-buildroot: openwrt-buildroot.${_arch}
openwrt-buildroot.${_arch}: _product := openwrt
openwrt-buildroot.${_arch}: ${_BUILDROOT_SRC} src/buildroot.openwrt.def
	$(make_buildroot)


.PHONY: rooter rooter-buildroot rooter-ibsdk rooter-ibsdk.src
rooter: rooter-ibsdk.src rooter-ibsdk

rooter-ibsdk: rooter-ibsdk.${target}.${_arch}
rooter-ibsdk.%.${_arch}: _product := rooter
rooter-ibsdk.%.${_arch}: ${_IBSDK_SRC}
	[ -e "rooter-ibsdk.${target}.src" ] || make rooter-ibsdk.src
	$(make_ibsdk)

rooter-ibsdk.src: rooter-ibsdk.${target}.src
rooter-ibsdk.%.src: rooter-buildroot.${_arch}
	$(make_ibsdk_src)

rooter-buildroot: rooter-buildroot.${_arch}
rooter-buildroot.${_arch}: _product := rooter
rooter-buildroot.${_arch}: ${_BUILDROOT_SRC} src/buildroot.rooter.def
	$(check_rooter_upstream)
	$(make_buildroot)


define make_buildroot =
	elements "src/buildroot.${_product}.def" "${_product}-buildroot.${_arch}"
endef

define make_ibsdk_src =
	rm -rf "$@.new"
	"./$<" $(if ${shell},-s,) ${_debug_flags} ${_warnings_flag} ${_jobs_flag} -t "$*" ${_version_flag} $(if ${patch},-p "${patch}",) "$@.new"
	rm -rf "$@" && mv "$@.new" "$@"
endef

define make_ibsdk =
	flock -nox ibsdk.src.lock rm -f ibsdk.src.lock
	ln -s "${_product}-ibsdk.$*.src" ibsdk.src.lock
	flock -nox ibsdk.src.lock \
	 elements "src/ibsdk.def" "${_product}-ibsdk.$*.${_arch}"
	rm -f ibsdk.src.lock
endef


define check_rooter_upstream =
	@if ! [ -f "rooter.zip" ]; then \
	 echo "$(lastword ${MAKEFILE_LIST}): error: rooter.zip does not exist" >&2; \
	 echo "  Upstream uses Google Drive to distribute this file.  Please download" >&2; \
	 echo "  the ROOter Build System from <https://www.ofmodemsandmen.com/other.html>" >&2; \
	 echo "  and place it at the above path." >&2; \
	 exit 2; \
	fi
endef
