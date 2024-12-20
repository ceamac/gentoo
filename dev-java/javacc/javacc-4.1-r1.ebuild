# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

JAVA_PKG_IUSE="doc examples source test"
MAVEN_ID="net.java.dev.javacc:javacc:${PV}"

inherit java-pkg-2

DESCRIPTION="Java Compiler Compiler - The Java Parser Generator"
HOMEPAGE="https://javacc.github.io/javacc/"
SRC_URI="https://github.com/javacc/javacc/archive/release_${PV//./}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/javacc-release_${PV//./}"

LICENSE="BSD-2"
SLOT="0"
KEYWORDS="amd64 arm64 ppc64"

BDEPEND=">=dev-java/ant-1.10.14:0"

DEPEND="
	dev-java/junit:0
	>=virtual/jdk-1.8:*
	test? (	>=dev-java/ant-1.10.14:0[junit] )
"
RDEPEND=">=virtual/jre-1.8:*"

PATCHES=(
	"${FILESDIR}/${PN}-4.1-javadoc.patch"
	"${FILESDIR}/javacc-4.1-source8.patch"
)

src_prepare() {
	default #780585
	java-pkg-2_src_prepare
	java-pkg_clean ! -path "./bootstrap/*"
	java-pkg_jar-from --build-only --into lib/junit3.8.1 junit
}

src_compile() {
	eant
	use doc && eant javadoc
}

src_test() {
	eant test
}

src_install() {
	java-pkg_dojar bin/lib/"${PN}".jar

	if use doc; then
		java-pkg_dohtml -r www/*
		java-pkg_dojavadoc doc/api
	fi

	use examples && java-pkg_doexamples examples
	use source && java-pkg_dosrc src/*

	echo "JAVACC_HOME=${EPREFIX}/usr/share/javacc/" > "${T}"/22javacc-${SLOT} || die
	doenvd "${T}"/22javacc-${SLOT}

	echo "export VERSION=${PV}" > "${T}"/pre || die

	local launcher
	for launcher in javacc jjdoc jjtree; do
		java-pkg_dolauncher ${launcher} -pre "${T}"/pre --main ${launcher}
	done

	einstalldocs
}
