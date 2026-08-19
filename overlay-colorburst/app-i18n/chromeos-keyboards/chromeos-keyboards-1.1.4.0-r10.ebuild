# Copyright 2013 The ChromiumOS Authors
# Distributed under the terms of the Apache License v2.

EAPI="7"

DESCRIPTION="The Google Input Tools (keyboard part) based on IME Extension API"
HOMEPAGE="https://github.com/google/google-input-tools"
# TODO: Change the $PF to $P.
SRC_URI="https://commondatastorage.googleapis.com/chromeos-localmirror/distfiles/${P}-r6.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="*"

S="${WORKDIR}/${PN}"

# colorburst fork of app-i18n/chromeos-keyboards.
#
# These layout files -- not the C++ rulebased engine in Chrome -- are what
# actually transliterate physical-keyboard input for the vkd_* input methods.
# Proven on a VM: adding a marker rule to layouts/vi_telex.js changed what
# typing produced, and emptying that file stopped Vietnamese input working at
# all. See VIETNAMESE-IME.md 9.
#
# vietnamese-phase0.py adds the Telex and VNI rules that fix retyping a tone,
# escaping the w family by double-typing, and the uo double-horn. It is
# idempotent (it looks for its own marker) and asserts on every anchor, so an
# upstream tarball that no longer matches fails the build instead of silently
# shipping unpatched files.
PATCHES=(
	"${FILESDIR}"/${P}-insert-pub-key-private-api.patch
)

src_prepare() {
	default
	python3 "${FILESDIR}"/vietnamese-phase0.py "${S}/layouts" ||
		die "failed to patch the Vietnamese layout tables"
}

src_install() {
	insinto /usr/share/chromeos-assets/input_methods/keyboard_layouts
	doins -r ./*
}
