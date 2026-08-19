# Copyright 2026 The ChromiumOS Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

inherit appid osreleased

DESCRIPTION="colorburst BSP for amd64-generic: identity, locale, local accounts"
HOMEPAGE="https://github.com/colorburst-os"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
IUSE="colorburst_devtools"

# The colorburst application id. Devices report this to the update server; the
# board previously had none, so every device sent the generic {87efface-...}
# fallback and was indistinguishable from any other ChromiumOS install.
#
# This is baked into shipped images and is effectively permanent: changing it
# makes existing devices look like a different product to the update server.
COLORBURST_APPID="{3EFFC3C6-5828-4F3A-967D-BAEA412E2DC8}"

# /etc/chrome_dev.conf is installed by chromeos-login
# (platform2/login_manager/BUILD.gn). Depend on it so that we are merged
# afterwards and the file exists when pkg_postinst runs.
RDEPEND="
	chromeos-base/chromeos-login
	sys-kernel/colorburst-wifi-firmware
	sys-firmware/sof-firmware
"

S="${WORKDIR}"

# Appending to a file owned by another package is not tidy, but there is no
# chrome_dev.conf.d: chrome_setup.cc hardcodes the single path, so a second
# package installing the same file would collide instead. The append is
# guarded by a marker so re-merging is idempotent.
#
# Caveat: re-emerging chromeos-login on its own reinstalls a pristine
# chrome_dev.conf and drops these lines. Re-merge this package (or rebuild)
# afterwards.
CROS_LOCAL_ACCOUNT_MARKER="# --- colorburst: Gaia-less local accounts ---"

src_install() {
	# Identify as colorburst to the update server, and in /etc/os-release.
	# REFERENCE is the honest devicetype for a generic-board build.
	doappid "${COLORBURST_APPID}" "REFERENCE"

	do_osrelease_field NAME colorburst
	do_osrelease_field ID colorburst
	do_osrelease_field HOME_URL "https://github.com/colorburst-os"
}

pkg_postinst() {
	local conf="${ROOT%/}/etc/chrome_dev.conf"

	if [[ ! -f ${conf} ]]; then
		ewarn "${conf} missing; local-account flags not installed."
		return 0
	fi

	# Replace our block rather than skipping when it is already there. The
	# board sysroot persists between builds, so a "skip if present" guard
	# silently pins the first build's flags forever: edits to this ebuild
	# appear to do nothing, and the image ships stale settings.
	#
	# Our block always runs to end-of-file, so deleting from the marker to
	# EOF removes exactly it. If another package ever appends after us, this
	# needs revisiting.
	if grep -qF "${CROS_LOCAL_ACCOUNT_MARKER}" "${conf}"; then
		einfo "Refreshing existing colorburst block in ${conf}"
		sed -i "/^${CROS_LOCAL_ACCOUNT_MARKER}\$/,\$d" "${conf}" ||
			die "failed to strip previous colorburst block"
	fi

	einfo "Appending Gaia-less local-account flags to ${conf}"
	cat >>"${conf}" <<-EOF

		${CROS_LOCAL_ACCOUNT_MARKER}
		# Chrome refuses to create a user at all when the API keys are absent
		# ("missing Google API keys"). It never contacts Google on the local
		# path, so placeholders are enough.
		GOOGLE_API_KEY=dummy-not-a-real-key
		GOOGLE_DEFAULT_CLIENT_ID=dummy-not-a-real-id
		GOOGLE_DEFAULT_CLIENT_SECRET=dummy-not-a-real-secret

		# No Gaia, and do not force online re-auth for an account whose OAuth
		# token status is necessarily invalid (it never had one).
		--disable-gaia-services
		--skip-force-online-signin-for-testing
		--disable-hid-detection-on-oobe

		# MANDATORY. Without these, DevicePolicyService::Initialize() fails
		# after a Gaia-less login and calls InitiateDeviceWipe(kBadPolicyKey):
		# the device powerwashes itself a couple of boots later and takes the
		# whole stateful partition with it.
		--profile-requires-policy=false
		--allow-failed-policy-fetch-for-test
		--disable-policy-key-verification

		# Vietnamese by default. cros-regions.json already carries a "vn"
		# entry; --cros-region overrides the VPD region, which a generic
		# board does not have. Gives Vietnamese OOBE, Asia/Ho_Chi_Minh, and
		# the Vietnamese keyboard layouts.
		#
		# Telex typing works: our Chrome restores the in-process rule-based
		# engine, so vkd_vi_telex needs no decoder blob. See VIETNAMESE-IME.md.
		--cros-region=vn

	EOF

	# An automation API and an open DevTools port are genuine remote-control
	# surfaces and must never ship. Nothing needs them any more: the user
	# creates a local account through Chrome's own OOBE screens. They exist
	# purely to let us drive OOBE from the host while developing.
	if use colorburst_devtools; then
		cat >>"${conf}" <<-EOF

			# Dev images only (USE=colorburst_devtools).
			--enable-oobe-test-api
			--remote-debugging-port=9229
		EOF
	fi
}
