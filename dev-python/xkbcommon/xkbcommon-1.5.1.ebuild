# Copyright 2023-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_EXT=1
DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{10..13} pypy3 pypy3_11 )

inherit distutils-r1 pypi

DESCRIPTION="Python bindings for libxkbcommon using cffi"
HOMEPAGE="
	https://github.com/sde1000/python-xkbcommon/
	https://pypi.org/project/xkbcommon/
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 ~riscv ~x86"

# x11-libs/libxkbcommon dep per README
RDEPEND="
	>=x11-libs/libxkbcommon-${PV}
	$(python_gen_cond_dep '
		dev-python/cffi[${PYTHON_USEDEP}]
	' 'python*')
"
DEPEND="${RDEPEND}"

distutils_enable_tests pytest

python_test() {
	rm -rf xkbcommon || die

	local -x PYTEST_DISABLE_PLUGIN_AUTOLOAD=1
	epytest
}
