# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..13} )

inherit font python-any-r1

DESCRIPTION="A Helvetica/Times/Courier replacement TrueType font set, courtesy of Red Hat"
HOMEPAGE="https://github.com/liberationfonts/liberation-fonts"
SRC_URI="fontforge? ( https://github.com/liberationfonts/liberation-fonts/files/7261483/${P}.tar.gz )
	!fontforge? ( https://github.com/liberationfonts/liberation-fonts/files/7261482/${PN}-ttf-${PV}.tar.gz )
"

KEYWORDS="~alpha amd64 arm arm64 ~hppa ~loong ~m68k ppc ppc64 ~riscv ~sparc x86 ~amd64-linux ~x86-linux ~arm64-macos ~x64-solaris"
SLOT="0"
LICENSE="OFL-1.1"
IUSE="fontforge X"

FONT_SUFFIX="ttf"

FONT_CONF=( "${FILESDIR}/60-liberation.conf" )

BDEPEND="
	fontforge? (
		${PYTHON_DEPS}
		media-gfx/fontforge
		$(python_gen_any_dep 'dev-python/fonttools[${PYTHON_USEDEP}]')
	)"

python_check_deps() {
	python_has_version "dev-python/fonttools[${PYTHON_USEDEP}]"
}

src_prepare() {
	default
	if use fontforge ; then
		sed -i "s/= python3/= ${EPYTHON}/" Makefile || die
	fi
}

pkg_setup() {
	if use fontforge; then
		FONT_S="${S}/${PN}-ttf-${PV}"
		python-any-r1_pkg_setup
	else
		FONT_S="${WORKDIR}/${PN}-ttf-${PV}"
		S="${FONT_S}"
	fi
	font_pkg_setup
}
