# Copyright 2026 The ChromiumOS Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

DESCRIPTION="colorburst board-specific packages"

LICENSE="metapackage"
SLOT="0"
KEYWORDS="*"

# Overrides reven's chromeos-bsp-2: chromeos-bsp-colorburst carries the whole
# reven hardware-enablement set (minus flex_hwis) plus the colorburst identity.
RDEPEND="chromeos-base/chromeos-bsp-colorburst"
DEPEND=""
