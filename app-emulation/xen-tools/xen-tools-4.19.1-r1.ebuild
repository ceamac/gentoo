# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..12} )
PYTHON_REQ_USE='ncurses,xml(+),threads(+)'

inherit bash-completion-r1 flag-o-matic multilib python-single-r1 readme.gentoo-r1 toolchain-funcs

if [[ ${PV} == *9999 ]]; then
	inherit git-r3
	REPO="xen.git"
	EGIT_REPO_URI="https://xenbits.xen.org/git-http/${REPO}"
	S="${WORKDIR}/${REPO}"
else
	KEYWORDS="amd64 ~arm ~arm64 x86"

	SEABIOS_VER="1.16.0"
	EDK2_COMMIT="b16284e2a0011489f6e16dfcc6af7623c3cbaf0b"
	EDK2_OPENSSL_VERSION="1_1_1t"
	EDK2_SOFTFLOAT_COMMIT="b64af41c3276f97f0e181920400ee056b9c88037"
	EDK2_BROTLI_COMMIT="f4153a09f87cbb9c826d8fc12c74642bb2d879ea"
	IPXE_COMMIT="1d1cf74a5e58811822bee4b3da3cff7282fcdfca"

	XEN_GENTOO_PATCHSET_NUM=2
	XEN_GENTOO_PATCHSET_BASE=4.17.0
	XEN_PRE_PATCHSET_NUM=
	XEN_PRE_VERSION_BASE=

	XEN_BASE_PV="${PV}"
	if [[ -n "${XEN_PRE_VERSION_BASE}" ]]; then
		XEN_BASE_PV="${XEN_PRE_VERSION_BASE}"
	fi

	SRC_URI="
	https://downloads.xenproject.org/release/xen/${XEN_BASE_PV}/xen-${XEN_BASE_PV}.tar.gz
	https://www.seabios.org/downloads/seabios-${SEABIOS_VER}.tar.gz
	ipxe? ( https://xenbits.xen.org/xen-extfiles/ipxe-git-${IPXE_COMMIT}.tar.gz )
	ovmf? ( https://github.com/tianocore/edk2/archive/${EDK2_COMMIT}.tar.gz -> edk2-${EDK2_COMMIT}.tar.gz
		https://github.com/openssl/openssl/archive/OpenSSL_${EDK2_OPENSSL_VERSION}.tar.gz
		https://github.com/ucb-bar/berkeley-softfloat-3/archive/${EDK2_SOFTFLOAT_COMMIT}.tar.gz -> berkeley-softfloat-${EDK2_SOFTFLOAT_COMMIT}.tar.gz
		https://github.com/google/brotli/archive/${EDK2_BROTLI_COMMIT}.tar.gz -> brotli-${EDK2_BROTLI_COMMIT}.tar.gz
	)
	"

	if [[ -n "${XEN_PRE_PATCHSET_NUM}" ]]; then
		XEN_UPSTREAM_PATCHES_TAG="$(ver_cut 1-3)-pre-patchset-${XEN_PRE_PATCHSET_NUM}"
		XEN_UPSTREAM_PATCHES_NAME="xen-upstream-patches-${XEN_UPSTREAM_PATCHES_TAG}"
		SRC_URI+=" https://gitweb.gentoo.org/proj/xen-upstream-patches.git/snapshot/${XEN_UPSTREAM_PATCHES_NAME}.tar.bz2"
		XEN_UPSTREAM_PATCHES_DIR="${WORKDIR}/${XEN_UPSTREAM_PATCHES_NAME}"
	fi
	if [[ -n "${XEN_GENTOO_PATCHSET_NUM}" ]]; then
		XEN_GENTOO_PATCHES_TAG="$(ver_cut 1-3 ${XEN_GENTOO_PATCHSET_BASE})-gentoo-patchset-${XEN_GENTOO_PATCHSET_NUM}"
		XEN_GENTOO_PATCHES_NAME="xen-gentoo-patches-${XEN_GENTOO_PATCHES_TAG}"
		SRC_URI+=" https://gitweb.gentoo.org/proj/xen-gentoo-patches.git/snapshot/${XEN_GENTOO_PATCHES_NAME}.tar.bz2"
		XEN_GENTOO_PATCHES_DIR="${WORKDIR}/${XEN_GENTOO_PATCHES_NAME}"
	fi
fi

DESCRIPTION="Xen tools including QEMU and xl"
HOMEPAGE="https://xenproject.org"
DOCS=( README )

S="${WORKDIR}/xen-$(ver_cut 1-3 ${XEN_BASE_PV})"

LICENSE="GPL-2"
SLOT="0/$(ver_cut 1-2)"
# Inclusion of IUSE ocaml on stabalizing requires maintainer of ocaml to (get off his hands and) make
# >=dev-lang/ocaml-4 stable
# Masked in profiles/eapi-5-files instead
IUSE="api debug doc +hvm +ipxe lzma ocaml ovmf pygrub python +qemu +qemu-traditional +rombios screen selinux sdl static-libs system-ipxe system-qemu system-seabios systemd zstd"

REQUIRED_USE="
	${PYTHON_REQUIRED_USE}
	ipxe? ( rombios )
	ovmf? ( hvm )
	pygrub? ( python )
	rombios? ( hvm )
	system-ipxe? ( rombios )
	?? ( ipxe system-ipxe )
	?? ( qemu system-qemu )"

COMMON_DEPEND="
	lzma? ( app-arch/xz-utils )
	qemu? (
		dev-libs/glib:2
		sys-libs/pam
	)
	zstd? ( app-arch/zstd )
	app-arch/bzip2
	app-arch/zstd
	dev-libs/libnl:3
	dev-libs/lzo:2
	dev-libs/yajl
	sys-apps/util-linux
	sys-fs/e2fsprogs
	sys-libs/ncurses
	sys-libs/zlib
	${PYTHON_DEPS}
"

RDEPEND="${COMMON_DEPEND}
	sys-apps/iproute2[-minimal]
	net-misc/bridge-utils
	screen? (
		app-misc/screen
		app-admin/logrotate
	)
	selinux? ( sec-policy/selinux-xen )"

DEPEND="${COMMON_DEPEND}
	app-misc/pax-utils
	>=sys-kernel/linux-headers-4.11
	x11-libs/pixman
	$(python_gen_cond_dep '
		dev-python/lxml[${PYTHON_USEDEP}]
	')
	x86? ( sys-devel/dev86
		system-ipxe? ( sys-firmware/ipxe[qemu] )
		sys-power/iasl )
	api? ( dev-libs/libxml2:=
		net-misc/curl )

	ovmf? (
		!arm? ( !arm64? ( dev-lang/nasm ) )
		$(python_gen_impl_dep sqlite)
		)
	!amd64? ( >=sys-apps/dtc-1.4.0 )
	amd64? ( sys-power/iasl
		system-seabios? (
			|| (
				sys-firmware/seabios
				sys-firmware/seabios-bin
			)
		)
		system-ipxe? ( sys-firmware/ipxe[qemu] )
		rombios? ( sys-devel/bin86 sys-devel/dev86 ) )
	arm64? ( sys-power/iasl
		rombios? ( sys-devel/bin86 sys-devel/dev86 ) )
	doc? (
		app-text/ghostscript-gpl
		$(python_gen_cond_dep '
			dev-python/markdown[${PYTHON_USEDEP}]
		')
		dev-texlive/texlive-latexextra
		>=media-gfx/fig2dev-3.2.9-r1
		virtual/pandoc
	)
	hvm? ( x11-base/xorg-proto )
	qemu? (
		app-arch/snappy:=
		dev-build/meson
		sdl? (
			media-libs/libsdl[X]
			media-libs/libsdl2[X]
		)
	)
	system-qemu? ( app-emulation/qemu[xen] )
	ocaml? ( dev-ml/findlib
		dev-lang/ocaml[ocamlopt] )
	python? ( >=dev-lang/swig-4.0.0 )"

BDEPEND="dev-lang/perl
	app-alternatives/yacc
	sys-devel/gettext
	ipxe? ( sys-devel/gcc:* )
	!system-seabios? ( sys-devel/gcc:* )"

# hvmloader is used to bootstrap a fully virtualized kernel
# Approved by QA team in bug #144032
QA_WX_LOAD="
	usr/libexec/xen/boot/hvmloader
	usr/libexec/xen/boot/ovmf.bin
	usr/libexec/xen/boot/xen-shim
	usr/share/qemu-xen/qemu/hppa-firmware.img
	usr/share/qemu-xen/qemu/opensbi-riscv32-generic-fw_dynamic.elf
	usr/share/qemu-xen/qemu/opensbi-riscv64-generic-fw_dynamic.elf
	usr/share/qemu-xen/qemu/s390-ccw.img
	usr/share/qemu-xen/qemu/u-boot.e500
"

QA_EXECSTACK="
	usr/share/qemu-xen/qemu/hppa-firmware.img
"

QA_PREBUILT="
	usr/libexec/xen/bin/elf2dmp
	usr/libexec/xen/bin/ivshmem-client
	usr/libexec/xen/bin/ivshmem-server
	usr/libexec/xen/bin/qemu-edid
	usr/libexec/xen/bin/qemu-img
	usr/libexec/xen/bin/qemu-io
	usr/libexec/xen/bin/qemu-keymap
	usr/libexec/xen/bin/qemu-nbd
	usr/libexec/xen/bin/qemu-pr-helper
	usr/libexec/xen/bin/qemu-storage-daemon
	usr/libexec/xen/bin/qemu-system-i386
	usr/libexec/xen/bin/virtfs-proxy-helper
	usr/libexec/xen/boot/ovmf.bin
	usr/libexec/xen/boot/xen-shim
	usr/libexec/xen/libexec/qemu-pr-helper
	usr/libexec/xen/libexec/virtfs-proxy-helper
	usr/libexec/xen/libexec/virtiofsd
	usr/libexec/xen/libexec/xen-bridge-helper
	usr/share/qemu-xen/qemu/s390-ccw.img
	usr/share/qemu-xen/qemu/s390-netboot.img
	usr/share/qemu-xen/qemu/u-boot.e500
"

RESTRICT="test"

PATCHES=(
	"${FILESDIR}"/${PN}-4.19.1-gnu17.patch
)

pkg_setup() {
	python_setup
	export "CONFIG_LOMOUNT=y"

	#bug 522642, disable compile tools/tests
	export "CONFIG_TESTS=n"

	if [[ -z ${XEN_TARGET_ARCH} ]] ; then
		if use x86 && use amd64; then
			die "Confusion! Both x86 and amd64 are set in your use flags!"
		elif use x86; then
			export XEN_TARGET_ARCH="x86_32"
		elif use amd64 ; then
			export XEN_TARGET_ARCH="x86_64"
		elif use arm; then
			export XEN_TARGET_ARCH="arm32"
		elif use arm64; then
			export XEN_TARGET_ARCH="arm64"
		else
			die "Unsupported architecture!"
		fi
	fi
}

src_prepare() {
	# move before Gentoo patch, one patch should apply to seabios, to fix gcc-4.5.x build err
	mv ../seabios-${SEABIOS_VER} tools/firmware/seabios-dir-remote || die
	pushd tools/firmware/ > /dev/null
	ln -s seabios-dir-remote seabios-dir || die
	popd > /dev/null

	if [[ -v XEN_UPSTREAM_PATCHES_DIR ]]; then
		eapply "${XEN_UPSTREAM_PATCHES_DIR}"
	fi

	if [[ -v XEN_GENTOO_PATCHES_DIR ]]; then
		eapply "${XEN_GENTOO_PATCHES_DIR}"
	fi

	# Rename qemu-bridge-helper to xen-bridge-helper to avoid file
	# collisions with app-emulation/qemu.
	sed -i 's/qemu-bridge-helper/xen-bridge-helper/g' \
		tools/qemu-xen/include/net/net.h \
		tools/qemu-xen/meson.build \
		tools/qemu-xen/qemu-bridge-helper.c \
		tools/qemu-xen/qemu-options.hx \
		|| die
	mv tools/qemu-xen/qemu-bridge-helper.c tools/qemu-xen/xen-bridge-helper.c || die

	if use ovmf; then
		mv ../edk2-${EDK2_COMMIT} tools/firmware/ovmf-dir-remote || die
		rm -r tools/firmware/ovmf-dir-remote/CryptoPkg/Library/OpensslLib/openssl || die
		rm -r tools/firmware/ovmf-dir-remote/ArmPkg/Library/ArmSoftFloatLib/berkeley-softfloat-3 || die
		rm -r tools/firmware/ovmf-dir-remote/BaseTools/Source/C/BrotliCompress/brotli || die
		rm -r tools/firmware/ovmf-dir-remote/MdeModulePkg/Library/BrotliCustomDecompressLib/brotli || die
		mv ../openssl-OpenSSL_${EDK2_OPENSSL_VERSION} tools/firmware/ovmf-dir-remote/CryptoPkg/Library/OpensslLib/openssl || die
		mv ../berkeley-softfloat-3-${EDK2_SOFTFLOAT_COMMIT} tools/firmware/ovmf-dir-remote/ArmPkg/Library/ArmSoftFloatLib/berkeley-softfloat-3 || die
		cp -r ../brotli-${EDK2_BROTLI_COMMIT} tools/firmware/ovmf-dir-remote/BaseTools/Source/C/BrotliCompress/brotli || die
		cp -r ../brotli-${EDK2_BROTLI_COMMIT} tools/firmware/ovmf-dir-remote/MdeModulePkg/Library/BrotliCustomDecompressLib/brotli || die
		cp tools/firmware/ovmf-makefile tools/firmware/ovmf-dir-remote/Makefile || die
	fi

	# ipxe
	if use ipxe; then
		cp "${DISTDIR}/ipxe-git-${IPXE_COMMIT}.tar.gz" tools/firmware/etherboot/ipxe.tar.gz || die

		# gcc 11
		cp "${XEN_GENTOO_PATCHES_DIR}/ipxe/${PN}-4.15.0-ipxe-gcc11.patch" tools/firmware/etherboot/patches/ipxe-gcc11.patch || die
		cp "${FILESDIR}/ipxe-force-gcc.patch" tools/firmware/etherboot/patches/ || die
		echo ipxe-gcc11.patch >> tools/firmware/etherboot/patches/series || die
		echo ipxe-force-gcc.patch >> tools/firmware/etherboot/patches/series || die
	fi

	# Fix texi2html build error with new texi2html, qemu.doc.html
	sed -i -e "/texi2html -monolithic/s/-number//" tools/qemu-xen-traditional/Makefile || die

	# Drop .config, fixes to gcc-4.6
	sed -e '/-include $(XEN_ROOT)\/.config/d' -i Config.mk || die "Couldn't	drop"

	# drop flags
	unset CFLAGS
	unset LDFLAGS
	unset ASFLAGS
	unset CPPFLAGS

	if ! use pygrub; then
		sed -e '/^SUBDIRS-y += pygrub/d' -i tools/Makefile || die
	fi

	if ! use python; then
		sed -e '/^SUBDIRS-y += python$/d' -i tools/Makefile || die
	fi

	if ! use hvm; then
		sed -e '/SUBDIRS-$(CONFIG_X86) += firmware/d' -i tools/Makefile || die
	# Bug 351648
	elif ! use x86 && ! has x86 $(get_all_abis); then
		mkdir -p "${WORKDIR}"/extra-headers/gnu || die
		touch "${WORKDIR}"/extra-headers/gnu/stubs-32.h || die
		export CPATH="${WORKDIR}"/extra-headers
	fi

	if use qemu; then
		if use sdl; then
			sed -i -e "s:\$\$source/configure:\0 --enable-sdl:" \
				tools/Makefile || die
		else
			sed -i -e "s:\${QEMU_ROOT\:\-\.}/configure:\0 --disable-sdl:" \
				tools/qemu-xen-traditional/xen-setup || die
			sed -i -e "s:\$\$source/configure:\0 --disable-sdl:" \
				tools/Makefile || die
		fi
	else
		# Don't bother with qemu, only needed for fully virtualised guests
		sed -i '/SUBDIRS-$(CONFIG_QEMU_XEN)/s/^/#/g' tools/Makefile || die
	fi

	# Reset bash completion dir; Bug 472438
	sed -e "s;^BASH_COMPLETION_DIR      :=.*;BASH_COMPLETION_DIR := $(get_bashcompdir);" \
		-i config/Paths.mk.in || die

	# xencommons, Bug #492332, sed lighter weight than patching
	sed -e 's:\$QEMU_XEN -xen-domid:test -e "\$QEMU_XEN" \&\& &:' \
		-i tools/hotplug/Linux/init.d/xencommons.in || die

	# fix bashishm
	sed -e '/Usage/s/\$//g' \
		-i tools/hotplug/Linux/init.d/xendriverdomain.in || die

	# respect multilib, usr/lib/libcacard.so.0.0.0
	sed -e "/^libdir=/s/\/lib/\/$(get_libdir)/" \
		-i tools/qemu-xen/configure || die

	#bug 518136, don't build 32bit exactuable for nomultilib profile
	if [[ "${ARCH}" == 'amd64' ]] && ! has_multilib_profile; then
		sed -i -e "/x86_emulator/d" tools/tests/Makefile || die
	fi

	# uncomment lines in xl.conf
	sed -e 's:^#autoballoon=:autoballoon=:' \
		-e 's:^#lockfile=:lockfile=:' \
		-e 's:^#vif.default.script=:vif.default.script=:' \
		-i tools/examples/xl.conf  || die

	# disable capstone (Bug #673474)
	sed -e "s:\$\$source/configure:\0 --disable-capstone:" \
		-i tools/Makefile || die

	# disable glusterfs
	sed -e "s:\$\$source/configure:\0 --disable-glusterfs:" \
		-i tools/Makefile || die

	# disable jpeg automagic
	sed -e "s:\$\$source/configure:\0 --disable-vnc-jpeg:" \
		-i tools/Makefile || die

	# disable png automagic
	sed -e "s:\$\$source/configure:\0 --disable-png:" \
		-i tools/Makefile || die

	# disable docker (Bug #732970)
	sed -e "s:\$\$source/configure:\0 --disable-containers:" \
		-i tools/Makefile || die

	# disable gettext (Bug #937219)
	sed -e "s:\$\$source/configure:\0 --disable-gettext:" \
		-i tools/Makefile || die

	# disable abi-dumper (Bug #791172)
	sed -e 's/$(ABI_DUMPER) /echo /g' \
		-i tools/libs/libs.mk || die

	# disable header check (Bug #921932)
	sed -e '/__XEN_INTERFACE_VERSION__/,+2d' \
		-i tools/qemu-xen/include/hw/xen/xen_native.h || die

	# Remove -Werror
	find . -type f \( -name Makefile -o -name "*.mk" \) \
		-exec sed -i \
		-e 's/-Werror //g' \
		-e '/^CFLAGS *+= -Werror$/d' \
		-e 's/, "-Werror"//' \
		{} + || die

	if use ovmf ; then
		# textrels cause failures w/ hardened binutils
		pushd tools/firmware/ovmf-dir-remote > /dev/null || die
		eapply "${FILESDIR}"/edk2-202202-binutils-2.41-textrels.patch
		popd > /dev/null || die

		# Use gnu17 because incompatible w/ C23
		sed -i -e "s:-DZZLEXBUFSIZE=65536:-DZZLEXBUFSIZE=65536 -std=gnu17:" \
			tools/firmware/ovmf-dir-remote/BaseTools/Source/C/VfrCompile/Pccts/*/makefile || die
	fi

	if ! use system-seabios ; then
		sed -i "/^export HOSTCC/i override CC:=gcc" tools/firmware/seabios-dir/Makefile || die
	fi

	default
}

src_configure() {
	local myconf=(
		--libdir="${EPREFIX}/usr/$(get_libdir)"
		--libexecdir="${EPREFIX}/usr/libexec"
		--localstatedir="${EPREFIX}/var"
		--disable-golang
		--disable-pvshim
		--disable-werror
		--disable-xen
		--enable-tools
		--enable-docs
		$(use_enable api xenapi)
		$(use_enable ipxe)
		$(usex system-ipxe '--with-system-ipxe=/usr/share/ipxe' '')
		$(use_enable ocaml ocamltools)
		$(use_enable ovmf)
		$(use_enable rombios)
		$(use_enable systemd)
		--with-xenstored=$(usex ocaml 'oxenstored' 'xenstored')
	)

	use system-seabios && myconf+=( --with-system-seabios=/usr/share/seabios/bios.bin )
	use system-qemu && myconf+=( --with-system-qemu=/usr/bin/qemu-system-x86_64 )
	use amd64 && myconf+=( $(use_enable qemu-traditional) )
	tc-ld-disable-gold # Bug 669570
	econf ${myconf[@]}
}

src_compile() {
	local myopt
	use debug && myopt="${myopt} debug=y"
	use python && myopt="${myopt} XENSTAT_PYTHON_BINDINGS=y"

	if test-flag-CC -fno-strict-overflow; then
		append-flags -fno-strict-overflow
	fi

	# bug #845099
	if use ipxe; then
		local -x NO_WERROR=1
	fi

	emake \
		HOSTCC="$(tc-getBUILD_CC)" \
		HOSTCXX="$(tc-getBUILD_CXX)" \
		CC="$(tc-getCC)" \
		CXX="$(tc-getCXX)" \
		LD="$(tc-getLD)" \
		AR="$(tc-getAR)" \
		OBJDUMP="$(tc-getOBJDUMP)" \
		RANLIB="$(tc-getRANLIB)" \
		build-tools ${myopt}

	if use doc; then
		emake -C docs build
	else
		emake -C docs man-pages
	fi
}

src_install() {
	# Override auto-detection in the build system, bug #382573
	export INITD_DIR=/tmp/init.d
	export CONFIG_LEAF_DIR=../tmp/default

	# Let the build system compile installed Python modules.
	local PYTHONDONTWRITEBYTECODE
	export PYTHONDONTWRITEBYTECODE

	emake DESTDIR="${ED}" DOCDIR="/usr/share/doc/${PF}" \
		XEN_PYTHON_NATIVE_INSTALL=y install-tools

	# Fix the remaining Python shebangs.
	python_fix_shebang "${D}"

	# Remove RedHat-specific stuff
	rm -rf "${D}"/tmp || die

	if use doc; then
		emake DESTDIR="${D}" DOCDIR="/usr/share/doc/${PF}" install-docs
		dodoc -r docs/{pdf,txt}
	else
		emake -C docs DESTDIR="${D}" DOCDIR="/usr/share/doc/${PF}" install-man-pages # Bug 668032
	fi
	dodoc ${DOCS[@]}

	newconfd "${FILESDIR}"/xendomains.confd xendomains
	newconfd "${FILESDIR}"/xenstored.confd xenstored
	newconfd "${FILESDIR}"/xenconsoled.confd xenconsoled
	newinitd "${FILESDIR}"/xendomains.initd-r2 xendomains
	newinitd "${FILESDIR}"/xenstored.initd-r1 xenstored
	newinitd "${FILESDIR}"/xenconsoled.initd xenconsoled
	newinitd "${FILESDIR}"/xencommons.initd xencommons
	newconfd "${FILESDIR}"/xencommons.confd xencommons
	newinitd "${FILESDIR}"/xenqemudev.initd xenqemudev
	newconfd "${FILESDIR}"/xenqemudev.confd xenqemudev
	newinitd "${FILESDIR}"/xen-watchdog.initd xen-watchdog

	if use screen; then
		cat "${FILESDIR}"/xendomains-screen.confd >> "${D}"/etc/conf.d/xendomains || die
		cp "${FILESDIR}"/xen-consoles.logrotate "${D}"/etc/xen/ || die
		keepdir /var/log/xen-consoles
	fi

	# For -static-libs wrt Bug 384355
	if ! use static-libs; then
		rm -f "${D}"/usr/$(get_libdir)/*.a "${D}"/usr/$(get_libdir)/ocaml/*/*.a
	fi

	# for xendomains
	keepdir /etc/xen/auto

	# Remove files failing QA AFTER emake installs them, avoiding seeking absent files
	find "${D}" \( -name openbios-sparc32 -o -name openbios-sparc64 \
		-o -name openbios-ppc -o -name palcode-clipper \) -delete || die

	keepdir /var/lib/xen/dump
	keepdir /var/lib/xen/xenpaging
	keepdir /var/lib/xenstored
	keepdir /var/log/xen

	if use python; then
		python_domodule "${S}/tools/libs/stat/bindings/swig/python/xenstat.py"
		python_domodule "${S}/tools/libs/stat/bindings/swig/python/_xenstat.so"
	fi

	python_optimize

	readme.gentoo_create_doc
}

pkg_postinst() {
	readme.gentoo_print_elog
}
