# Copyright 2026 The ChromiumOS Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

inherit appid osreleased

DESCRIPTION="colorburst BSP: reven hardware enablement plus colorburst identity"
HOMEPAGE="https://github.com/colorburst-os"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
IUSE="colorburst_devtools"

# The colorburst application id. Devices report this to the update server.
# Baked into shipped images and effectively permanent: changing it makes
# existing devices look like a different product to the update server.
# (Same id as the amd64-generic-era builds, so early devices stay one fleet.)
COLORBURST_APPID="{3EFFC3C6-5828-4F3A-967D-BAEA412E2DC8}"

# TODO(b/321687359) inherited from chromeos-bsp-reven: image build breaks
# without these in DEPEND. Drop when reven drops them.
DEPEND="
	sys-apps/busybox
	sys-apps/pv
"

# The reven set, minus chromeos-base/flex_hwis: that service inventories the
# hardware and reports it to Google, which colorburst has no business doing.
# sof-firmware and the AX210 ucode are pulled here because on real reven the
# private BSP does it.
#
# chromeos-login: /etc/chrome_dev.conf is installed by it
# (platform2/login_manager/BUILD.gn). Depend on it so that we are merged
# afterwards and the file exists when pkg_postinst runs.
RDEPEND="
	!<chromeos-base/gestures-conf-0.0.2
	app-i18n/unikey-engine-source
	chromeos-base/chromeos-login
	chromeos-base/reven-hwdb
	chromeos-base/reven-quirks
	dev-libs/libinput
	media-sound/sound_card_init
	sys-firmware/fwupd-uefi-dbx
	sys-firmware/sof-firmware
	sys-kernel/colorburst-wifi-firmware
"

S="${WORKDIR}"

# Appending to a file owned by another package is not tidy, but there is no
# chrome_dev.conf.d: chrome_setup.cc hardcodes the single path, so a second
# package installing the same file would collide instead. The append is
# guarded by a marker so re-merging is idempotent.
#
# NOTE: chrome_dev.conf is DEV-IMAGE-ONLY plumbing. session_manager applies
# it only when is_developer_end_user() (chrome_setup.cc:556), i.e. when
# cros_debug is on the kernel cmdline -- never on an official/release image.
# Since R2026.32.2 the Gaia-less local-account defaults below are ALSO baked
# into our Chrome fork (chrome/app/chrome_main_delegate.cc,
# ApplyColorburstLocalAccountDefaults; add-if-absent, so these lines still
# override on dev images). Keep the two lists in sync. The devtools block
# stays dev-only on purpose.
#
# Caveat: re-emerging chromeos-login on its own reinstalls a pristine
# chrome_dev.conf and drops these lines. Re-merge this package (or rebuild)
# afterwards.
CROS_LOCAL_ACCOUNT_MARKER="# --- colorburst: Gaia-less local accounts ---"

src_install() {
	# Touchpad tuning for machines the gestures library mishandles,
	# verbatim from chromeos-bsp-reven.
	insinto "/etc/gesture"
	doins "${FILESDIR}"/gesture/*

	# Tier-1 baseline speaker tuning: 120 Hz highpass + mild high shelf +
	# gentle 3-band drc, applied only to nodes with dsp_name "speaker_eq".
	# cras-env.sh already points CRAS at /etc/cras/dsp.ini for this board
	# (no /audio/main in our chromeos-config model). adhd installs other
	# files into /etc/cras (processor_override.txtpb, for_all_boards/*) but
	# no dsp.ini, so this path is ours.
	#
	# NOTE: the tuning is INERT until the Speaker UCM node carries
	# DspName "speaker_eq". The forked UCM lives in
	# files/ucm-config/sof-hda-dsp/ ready to go, but it is NOT installed
	# here: media-sound/adhd already installs the identical paths
	# /usr/share/alsa/ucm2/conf.d/sof-hda-dsp/{sof-hda-dsp.conf,HiFi.conf}
	# (adhd ucm-config/BUILD.bazel, pkg prefix /usr/share/alsa/ucm2/conf.d),
	# and a second package installing the same files is a Portage file
	# collision. Resolution options, in preference order:
	#   1. carry the DspName addition as a patch to media-sound/adhd's
	#      for_all_boards_ucm2/sof-hda-dsp/HiFi.conf, or
	#   2. give the board a chromeos-config /audio/main ucm-suffix and
	#      install files/ucm-config as sof-hda-dsp.<suffix>/ the way
	#      overlay-nissa does (no collision, but pulls in unibuild audio
	#      plumbing we do not have yet).
	insinto /etc/cras
	doins "${FILESDIR}"/cras-config/dsp.ini

	# The UCM fork that tags the internal speaker with DspName "speaker_eq"
	# (activating dsp.ini). Installed under the ucm-suffix name so it cannot
	# collide with adhd's own sof-hda-dsp files; chromeos-config's
	# /audio/main ucm-suffix makes CRAS pick it up for the internal card.
	insinto /usr/share/alsa/ucm2/conf.d/sof-hda-dsp.colorburst
	doins "${FILESDIR}"/ucm-config/sof-hda-dsp.colorburst/*

	# The OTA payload verification key. update_engine on an official build
	# trusts exactly this file, read from the currently running rootfs
	# (platform_constants_chromeos.cc); insert_au_publickey.sh is the
	# upstream way to add it but only Google's signer calls it, and baking
	# it at build time is equivalent because dm-verity hashes are computed
	# after the rootfs is assembled. Installed unconditionally: on dev
	# (unofficial) images signature checks are not mandatory, so unsigned
	# dev payloads still apply. The private half lives on the YubiKeys.
	insinto /usr/share/update_engine
	newins "${FILESDIR}"/update-payload-key.pub.pem update-payload-key.pub.pem

	# Identify as colorburst to the update server, and in /etc/os-release.
	# REFERENCE is the honest devicetype for a generic-hardware build.
	doappid "${COLORBURST_APPID}" "REFERENCE"

	do_osrelease_field NAME colorburst
	do_osrelease_field ID colorburst
	do_osrelease_field HOME_URL "https://github.com/colorburst-os"

	# Release version: <year>.<series>.<patch>, read VERBATIM from
	# files/RELEASE. Deliberately NOT derived from the build clock: the
	# version identifies the SOURCE, so rebuilding a given commit has to
	# reproduce the same version string. (Through 2026.32.9 the year/week
	# came from `date`, so the same tree built in a different week produced
	# a different version and a shipped release could not be reproduced at
	# all.) Every other consumer -- chromium/build-release.sh,
	# build-image.sh, build-ota-test-image.sh, rebuild-release.sh -- reads
	# this same file, so they cannot drift. Bump it with release/cut.sh.
	local ver
	ver="$(< "${FILESDIR}"/RELEASE)"
	do_osrelease_field VERSION "R${ver}"
	# BUILD_ID identifies the build INPUTS, not the day: the chromium-os
	# commit that drove the build, written by release/cut.sh. Falls back to
	# the version itself for a hand build with no BUILD-ID recorded.
	do_osrelease_field BUILD_ID "$(< "${FILESDIR}"/BUILD-ID 2>/dev/null || echo "${ver}")"

	# Mints /var/lib/colorburst/device-id once, on installed systems only.
	# update_engine sends it to our update server so releases can be staged
	# and devices counted; USB/live boots are skipped and stay anonymous.
	# See the job for the full rationale.
	insinto /etc/init
	doins "${FILESDIR}"/init/colorburst-device-id.conf

	# Dev images debug themselves: snapshot dmesg, DRM state, jobs, network
	# and the Chrome logs to stateful every 10s for the first 3 minutes of
	# each boot. This is how the amd64-generic hardware bring-up was done by
	# shuttling a USB stick; now it is built in. Dev images only.
	if use colorburst_devtools; then
		insinto /etc/init
		doins "${FILESDIR}"/init/cb-diag.conf
	fi
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

		# No Gaia surfaces anywhere in the UI.
		#
		# The policy test switches that used to sit here
		# (--skip-force-online-signin-for-testing,
		# --profile-requires-policy=false,
		# --allow-failed-policy-fetch-for-test,
		# --disable-policy-key-verification) are gone: local accounts are
		# first-class in our Chrome (password factor created atomically with
		# the user, no user cloud policy manager, stock consumer ownership),
		# so nothing needs papering over. The old powerwash was upstream's
		# MisconfiguredUserCleaner kSilentPowerwash trapdoor for factor-less
		# new first users, not DevicePolicyService.
		--disable-gaia-services
		--disable-hid-detection-on-oobe

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
