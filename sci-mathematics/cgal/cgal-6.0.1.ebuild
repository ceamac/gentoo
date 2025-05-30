# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# Modules provided by dev-cpp/eigen
CMAKE_REMOVE_MODULES_LIST=( FindEigen3 )
inherit cmake

MY_PV="${PV/_/-}"
MY_P="CGAL-${PV/_/-}"
DESCRIPTION="C++ library for geometric algorithms and data structures"
HOMEPAGE="https://www.cgal.org/"
SRC_URI="
	https://github.com/CGAL/cgal/releases/download/v${MY_PV}/${MY_P}.tar.xz
	doc? ( https://github.com/CGAL/cgal/releases/download/v${MY_PV}/${MY_P}-doc_html.tar.xz )"
S="${WORKDIR}/${MY_P}"

LICENSE="LGPL-3 GPL-3 Boost-1.0"
SLOT="0/14"
KEYWORDS="amd64 ~arm64 ~ppc64 ~x86 ~amd64-linux ~x86-linux"
IUSE="doc examples test"
RESTRICT="!test? ( test )"

RDEPEND="
	dev-cpp/eigen
	dev-libs/boost:=
	dev-libs/gmp:=[cxx]
	dev-libs/mpfr:=
	sys-libs/zlib
	x11-libs/libX11:=
	virtual/glu:=
	virtual/opengl:=
"
DEPEND="${RDEPEND}"
BDEPEND="
	app-arch/xz-utils
	virtual/pkgconfig
"

PATCHES=(
	"${FILESDIR}"/${PN}-4.11.1-fix-buildsystem.patch
)

src_configure() {
	local mycmakeargs=(
		-DCGAL_INSTALL_LIB_DIR="$(get_libdir)"
		-DCGAL_INSTALL_CMAKE_DIR="$(get_libdir)/cmake/CGAL"

		# https://github.com/CGAL/cgal/wiki/Testing#using-ctest
		-DCGAL_ENABLE_TESTING="$(usex test)"
		-DCGAL_TEST_SUITE="$(usex test)"
		-DBUILD_TESTING="$(usex test)"
		-DWITH_examples="$(usex test)"
	)

	cmake_src_configure
}

src_install() {
	use doc && local HTML_DOCS=( "${WORKDIR}"/doc_html/. )

	cmake_src_install

	if use examples; then
		dodoc -r examples demo
	fi
}
