# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools flag-o-matic multilib-minimal

MY_PV="${PV/_/-}"
MY_P="${PN}-${MY_PV}"

DESCRIPTION="Protocol Buffers implementation in C"
HOMEPAGE="https://github.com/protobuf-c/protobuf-c"
SRC_URI="https://github.com/${PN}/${PN}/releases/download/v${MY_PV}/${MY_P}.tar.gz"
S="${WORKDIR}/${MY_P}"

LICENSE="BSD-2"
# Subslot == SONAME version
SLOT="0/1.0.0"
KEYWORDS="~alpha amd64 arm arm64 ~hppa ~loong ~mips ppc ppc64 ~riscv ~s390 sparc x86"
IUSE="static-libs test"
RESTRICT="!test? ( test )"

BDEPEND="
	>=dev-libs/protobuf-3:0
	virtual/pkgconfig
"
DEPEND=">=dev-libs/protobuf-3:0=[${MULTILIB_USEDEP}]"
RDEPEND="${DEPEND}"

PATCHES=(
	"${FILESDIR}"/${PN}-1.4.0-include-path.patch
	"${FILESDIR}"/${P}-protobuf-22.patch
)

src_prepare() {
	default

	if ! use test; then
		eapply "${FILESDIR}"/${PN}-1.3.0-no-build-tests.patch
	fi

	eautoreconf
}

src_configure() {
	# Workaround for bug #946366
	append-flags $(test-flags-CC -fzero-init-padding-bits=unions)

	multilib-minimal_src_configure
}

multilib_src_configure() {
	local myeconfargs=(
		$(use_enable static-libs static)
	)

	ECONF_SOURCE="${S}" econf "${myeconfargs[@]}"
}

multilib_src_install_all() {
	find "${ED}" -name '*.la' -type f -delete || die
	einstalldocs
}
