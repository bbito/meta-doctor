# Makefile for Activation Bypass modifications
#
# Copyright (C) 2009 by Rod Whitby <rod@whitby.id.au>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#

DEVICE  = pre
MODEL = p100eww
CARRIER = sprint
VERSION = 1.1.0

ifeq (${DEVICE},pre)
CODENAME = castle
endif

DOCTOR  = webosdoctor${MODEL}${CARRIER}.jar

APPLICATIONS = com.palm.app.firstuse
PATCHES = com.palm.app.firstuse.patch

PATHNAMES = ./usr/palm/applications/com.palm.app.firstuse ./usr/lib/ipkg/info

all: pack-sprint pack-bellmo

.PHONY: pack-%
pack-%:
	${MAKE} CARRIER=$* pack

.PHONY: pack
pack: build/${DEVICE}_${MODEL}_${CARRIER}/.packed

build/${DEVICE}_${MODEL}_${CARRIER}/.packed: build/${DEVICE}_${MODEL}_${CARRIER}/.patched
	rm -f $@
	tar -C build/${DEVICE}_${MODEL}_${CARRIER} \
		-f build/${DEVICE}_${MODEL}_${CARRIER}/nova-cust-image-castle.rootfs.tar \
		-r ${PATHNAMES} ./md5sums
	gzip -f build/${DEVICE}_${MODEL}_${CARRIER}/nova-cust-image-castle.rootfs.tar
	tar -C build/${DEVICE}_${MODEL}_${CARRIER} \
		-f build/${DEVICE}_${MODEL}_${CARRIER}/resources/webOS.tar \
		-r ./nova-cust-image-castle.rootfs.tar.gz
	( cd build/${DEVICE}_${MODEL}_${CARRIER} ; \
		zip -d ${DOCTOR} META-INF/MANIFEST.MF META-INF/JARKEY.* resources/webOS.tar )
	sed -i .orig -e '/^Name: /d' -e '/^SHA1-Digest: /d' -e '/^ /d' -e '/^\n$$/d' \
		build/${DEVICE}_${MODEL}_${CARRIER}/META-INF/MANIFEST.MF
	( cd build/${DEVICE}_${MODEL}_${CARRIER} ; \
		zip ${DOCTOR} META-INF/MANIFEST.MF resources/webOS.tar )
	touch $@

.PHONY: patch-%
patch-%:
	${MAKE} CARRIER=$* patch

.PHONY: patch
patch: build/${DEVICE}_${MODEL}_${CARRIER}/.patched

build/${DEVICE}_${MODEL}_${CARRIER}/.patched: build/${DEVICE}_${MODEL}_${CARRIER}/.unpacked
	rm -f $@
	( cd patches/${DEVICE}_${MODEL}_${CARRIER}_${VERSION} ; cat ${PATCHES} ) | \
	( cd build/${DEVICE}_${MODEL}_${CARRIER} ; patch -p0 )
	( cd build/${DEVICE}_${MODEL}_${CARRIER} ; \
	  find ./usr/palm/applications/com.palm.app.firstuse -type f | xargs md5sum ) \
	    > build/${DEVICE}_${MODEL}_${CARRIER}/usr/lib/ipkg/info/com.palm.app.firstuse.md5sums.new
	./scripts/replace-md5sums.py \
	  build/${DEVICE}_${MODEL}_${CARRIER}/usr/lib/ipkg/info/com.palm.app.firstuse.md5sums{.old,.new} \
	    > build/${DEVICE}_${MODEL}_${CARRIER}/usr/lib/ipkg/info/com.palm.app.firstuse.md5sums
	rm -f build/${DEVICE}_${MODEL}_${CARRIER}/usr/lib/ipkg/info/com.palm.app.firstuse.md5sums{.old,.new}
	( cd build/${DEVICE}_${MODEL}_${CARRIER} ; \
	  find ${PATHNAMES} -type f | xargs md5sum ) \
	    > build/${DEVICE}_${MODEL}_${CARRIER}/md5sums.new
	./scripts/replace-md5sums.py build/${DEVICE}_${MODEL}_${CARRIER}/md5sums{.old,.new} > \
				     build/${DEVICE}_${MODEL}_${CARRIER}/md5sums
	rm -f build/${DEVICE}_${MODEL}_${CARRIER}/md5sums{.old,.new}
	touch $@

.PHONY: unpack-%
unpack-%:
	${MAKE} CARRIER=$* unpack

.PHONY: unpack
unpack: build/${DEVICE}_${MODEL}_${CARRIER}/.unpacked

build/${DEVICE}_${MODEL}_${CARRIER}/.unpacked: downloads/${DOCTOR}
	rm -rf build/${DEVICE}_${MODEL}_${CARRIER}
	mkdir -p build/${DEVICE}_${MODEL}_${CARRIER}
	cp $< build/${DEVICE}_${MODEL}_${CARRIER}/${DOCTOR}
	( cd build/${DEVICE}_${MODEL}_${CARRIER} ; \
		unzip ${DOCTOR} META-INF/MANIFEST.MF resources/webOS.tar )
	tar -C build/${DEVICE}_${MODEL}_${CARRIER} \
		-f build/${DEVICE}_${MODEL}_${CARRIER}/resources/webOS.tar \
		-x ./nova-cust-image-castle.rootfs.tar.gz
	gunzip -f build/${DEVICE}_${MODEL}_${CARRIER}/nova-cust-image-castle.rootfs.tar.gz
	tar -C build/${DEVICE}_${MODEL}_${CARRIER} \
		-f build/${DEVICE}_${MODEL}_${CARRIER}/nova-cust-image-castle.rootfs.tar \
		-x ${PATHNAMES} ./md5sums
	mv build/${DEVICE}_${MODEL}_${CARRIER}/usr/lib/ipkg/info/com.palm.app.firstuse.md5sums{,.old}
	mv build/${DEVICE}_${MODEL}_${CARRIER}/md5sums{,.old}
	touch $@

.PHONY: download-%
download-%:
	${MAKE} CARRIER=$* download

.PHONY: download
download: downloads/${DOCTOR}

downloads/${DOCTOR}:
	mkdir -p downloads
	curl -R -L -o $@ http://palm.cdnetworks.net/rom/${DEVICE}_${MODEL}/${DOCTOR}

clobber:
	rm -rf build
