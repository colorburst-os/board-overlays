# Copyright 2022 The ChromiumOS Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

DESCRIPTION="Virtual for OpenGLES implementations"

LICENSE="metapackage"
SLOT="0"
KEYWORDS="*"
IUSE=""

# colorburst: mesa-reven carries every driver this generic image can meet
# (iris for modern Intel laptops, amdgpu, plus virgl for our VMs); the
# board-profile VIDEO_CARDS decides which ones actually get built.
RDEPEND="media-libs/mesa-reven[egl,gles2]"
DEPEND=""
