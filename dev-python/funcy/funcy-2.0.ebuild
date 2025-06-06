# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{11..14} )

inherit distutils-r1 pypi

DESCRIPTION="A collection of fancy functional tools focused on practicality"
HOMEPAGE="
	https://github.com/Suor/funcy/
	https://pypi.org/project/funcy/
"

LICENSE="BSD"
SLOT="0"
KEYWORDS="amd64 arm64 x86"

BDEPEND="
	test? (
		>=dev-python/whatever-0.7[${PYTHON_USEDEP}]
	)
"

distutils_enable_tests pytest
