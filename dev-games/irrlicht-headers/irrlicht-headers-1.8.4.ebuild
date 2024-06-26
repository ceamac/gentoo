# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit edos2unix

MY_PN="irrlicht"
MY_P="${MY_PN}-${PV}"
DESCRIPTION="Irrlicht 3D engine headers"
HOMEPAGE="https://irrlicht.sourceforge.io/"
SRC_URI="https://downloads.sourceforge.net/irrlicht/${MY_P}.zip
	https://dev.gentoo.org/~mgorny/dist/${MY_P}-patchset.tar.bz2"

LICENSE="ZLIB"
SLOT="0"
KEYWORDS="amd64 ~riscv x86"

RDEPEND="!<dev-games/irrlicht-1.8.4-r1"
BDEPEND="app-arch/unzip"

S=${WORKDIR}/${MY_P}/source/${MY_PN^}

PATCHES=(
	"${WORKDIR}"/${MY_P}-patchset/${MY_P}-config.patch
)

src_prepare() {
	cd "${WORKDIR}"/${MY_P} || die
	edos2unix include/IrrCompileConfig.h
	default
}

src_configure() { :; }

src_compile() { :; }

src_install() {
	cd "${WORKDIR}"/${MY_P} || die

	insinto /usr/include/${MY_PN}
	doins include/*
}
