# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Sound Open Firmware (SOF) binary files"
HOMEPAGE="https://www.sofproject.org https://github.com/thesofproject/sof https://github.com/thesofproject/sof-bin"
SRC_URI="https://github.com/thesofproject/sof-bin/releases/download/v${PV}/sof-bin-${PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}"/sof-bin-${PV}

LICENSE="BSD"
SLOT="0"
KEYWORDS="amd64"
IUSE=""

src_install() {
	dodir /lib/firmware/intel
	dodir /usr/bin

	FW_DEST="${D}/lib/firmware/intel" TOOLS_DEST="${T}/tools-not-installed" \
		"${S}/install.sh" || die
}
