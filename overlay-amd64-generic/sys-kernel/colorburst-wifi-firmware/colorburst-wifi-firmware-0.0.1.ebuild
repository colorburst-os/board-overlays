# Copyright 2026 The ChromiumOS Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

DESCRIPTION="Wi-Fi firmware the pinned linux-firmware snapshot is missing"
HOMEPAGE="https://gitlab.com/kernel-firmware/linux-firmware"

# The tree's sys-kernel/linux-firmware is pinned to a snapshot whose newest
# AX210 firmware is API 88, but the 5.15 iwl7000 driver requests exactly its
# maximum supported API (89) and never falls back to older files already on
# disk -- the card ends up with "no suitable firmware found" while
# iwlwifi-ty-a0-gf-a0-{83,86,88}.ucode sit unused in /lib/firmware.
# Seen on an AX210 ("Typhoon Peak") in a ThinkPad T14 gen 2.
#
# File fetched from the linux-firmware mirror (intel/iwlwifi/), unmodified.
# If another Intel card family hits the same "requests only max API" wall,
# add its .ucode here the same way.

LICENSE="LICENCE.iwlwifi_firmware"
SLOT="0"
KEYWORDS="*"

S="${WORKDIR}"

src_install() {
	insinto /lib/firmware
	doins "${FILESDIR}"/iwlwifi-ty-a0-gf-a0-89.ucode
}
