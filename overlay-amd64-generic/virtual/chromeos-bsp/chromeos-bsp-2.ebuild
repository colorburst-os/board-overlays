# Copyright 2026 The ChromiumOS Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

DESCRIPTION="ChromiumOS BSP virtual package for amd64-generic"
HOMEPAGE="https://github.com/colorburst-os"

LICENSE="metapackage"
SLOT="0"
KEYWORDS="*"

# Overrides the generic virtual/chromeos-bsp-1 in chromiumos-overlay, which is
# a direct dependency of virtual/target-chromium-os -- so our BSP package gets
# pulled into the image automatically.
RDEPEND="chromeos-base/chromeos-bsp-amd64-generic"
