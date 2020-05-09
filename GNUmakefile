all: help


.PHONY: help
help:
	@echo "Usage: $(notdir ${MAKE}) {PRODUCT} [options [...]]"
	@echo "Products: openwrt, rooter; {PRODUCT}-ibsdk, {PRODUCT}-buildroot"
	@echo "Output filename template (Image Builder and SDK): {PRODUCT}-ibsdk.{TARGET}"
	@echo "Output filename template (buildroot): {PRODUCT}-buildroot"
	@echo "Input directory for {PRODUCT}-ibsdk: {PRODUCT}-ibsdk.{TARGET}.src"
	@echo "  (must contain imagebuilder.tar.xz and sdk.tar.xz)"
	@echo ""
	@echo "General options:"
	@echo "  target={TARGET}-{SUBTARGET}"
	@echo "    The OpenWrt target for which to build"
	@echo "    (default: ${_DEFAULT_TARGET})"
	@echo "  version={VERSION_NUMBER|TAG|COMMIT|BRANCH}"
	@echo "    When building OpenWrt from a git repository (default for the \`openwrt\`"
	@echo "    products), check out the given version number or git tag, commit,"
	@echo "    or branch."
	@echo "    (default: empty; build git head or contents of rooter.zip)"
	@echo "  stable=1"
	@echo "    Build the latest stable version of OpenWrt.  Overrides the \`version\`"
	@echo "    option; equivalent to \`version=STABLE\`."
	@echo "    (default: 0)"
	@echo "  patch={PATCH_SCRIPT_FILE_OR_DIRECTORY}"
	@echo "    If a file, a shell script to be executed in /buildroot before building"
	@echo "    OpenWrt.  If a directory, it will be mounted at /patch and the script"
	@echo "    /patch/Patchfile will be executed in /buildroot before building OpenWrt."
	@echo "    (default: none)"
	@echo ""
	@echo "Debugging options:"
	@echo "  debug=1"
	@echo "    Pass \`-j 1 V=s\` to make when building OpenWrt."
	@echo "    (default: 0)"
	@echo "  debug_parallel=1 (not recommended)"
	@echo "    Pass \`V=s\` to make when building OpenWrt."
	@echo "    (default: 0)"
	@echo "  shell=1"
	@echo "    Start a shell before the buildroot container exits."
	@echo "    (default: 0)"


_DEFAULT_TARGET := $(shell cat src/default-target)

target := $(_DEFAULT_TARGET)
patch :=
debug := 0
debug_parallel := 0
shell := 0


_COMMON_SRC := src/def-common.sh src/chuidgid.c
_BUILDROOT_SRC := ${_COMMON_SRC} src/buildroot.sh
_IBSDK_SRC := ${_COMMON_SRC} src/ibsdk.def src/ibsdk.sh

_debug := $(filter-out 0,${debug})
_debug_parallel := $(filter-out 0,${debug_parallel})
_debug_flags := $(if ${_debug}${_debug_parallel},$(if ${_debug_parallel},,-j 1 )-V,)

_stable := $(filter-out 0,${stable})
_version_flag := $(if ${_stable},-v "STABLE",$(if ${version},-v "${version}",))


.PHONY: openwrt openwrt-ibsdk openwrt-ibsdk.src
openwrt: openwrt-ibsdk.src openwrt-ibsdk
openwrt-ibsdk: openwrt-ibsdk.${target}
openwrt-ibsdk.src: openwrt-ibsdk.${target}.src

openwrt-ibsdk.%: _product := openwrt
openwrt-ibsdk.%: ${_IBSDK_SRC}
	$(make_ibsdk)

openwrt-ibsdk.%.src: openwrt-buildroot
	$(make_ibsdk_src)

openwrt-buildroot: _product := openwrt
openwrt-buildroot: ${_BUILDROOT_SRC} src/buildroot.openwrt.def
	$(make_buildroot)


.PHONY: rooter rooter-ibsdk rooter-ibsdk.src
rooter: rooter-ibsdk.src rooter-ibsdk
rooter-ibsdk: rooter-ibsdk.${target}
rooter-ibsdk.src: rooter-ibsdk.${target}.src

rooter-ibsdk.%: _product := rooter
rooter-ibsdk.%: ${_IBSDK_SRC}
	$(make_ibsdk)

rooter-ibsdk.%.src: rooter-buildroot
	$(make_ibsdk_src)

rooter-buildroot: _product := rooter
rooter-buildroot: ${_BUILDROOT_SRC} src/buildroot.rooter.def
	$(check_rooter_upstream)
	$(make_buildroot)


define make_buildroot =
	elements "src/buildroot.${_product}.def" "${_product}-buildroot"
endef

define make_ibsdk_src =
	rm -rf "$@.new"
	"./$<" $(if ${shell},-s,) ${_debug_flags} -t "$*" ${_version_flag} $(if ${patch},-p "${patch}",) "$@"
	rm -rf "$@" && mv "$@.new" "$@"
endef

define make_ibsdk =
	flock -nox ibsdk.src.lock rm -f ibsdk.src.lock
	ln -s "${_product}-ibsdk.$*.src" ibsdk.src.lock
	flock -nox ibsdk.src.lock \
	 elements "src/ibsdk.def" "${_product}-ibsdk.$*"
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
