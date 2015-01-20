if [ ${ZERO_LINK} == YES ]; then
	echo error:0:Cannot distribute a ZeroLink build
	exit 1
fi

dmgSize=${DiskImageSizeInMB}
dmgBasePath="${TARGET_BUILD_DIR}/${DiskImageVolumeName}"

if [ x${ACTION} = xclean ]; then
	echo "Removing disk image ${dmgPath}.dmg"
	rm -f "${dmgBasePath}.dmg"
	exit 0
fi

echo "Creating ${dmgSize} MB disk image named '${DiskImageVolumeName}'..."
rm -f "${dmgBasePath}.dmg"
hdiutil create "${dmgBasePath}.dmg" -volname "${DiskImageVolumeName}" -megabytes ${dmgSize} -layout NONE -fs HFS+ -quiet

if [ $? != 0 ]; then
	echo error:0: Failed to create disk image at ${dmgBasePath}.dmg
	exit 1
fi
echo "...done"
echo

echo "Mounting newly created disk image..."
hdidOutput=`hdiutil mount "${dmgBasePath}.dmg" | grep '/dev/disk[0-9]*' | awk '{print $1}'`
mountedDmgPath="/Volumes/${DiskImageVolumeName}"
if [ $? != 0  -o  ! -x "${mountedDmgPath}" ]; then
	echo error:0: Failed to mount newly created disk image at ${dmgBasePath}.dmg
	exit 1
fi
sleep 2
echo "...done"
echo

echo "Copying contents to ${dmgPath}..."
ditto -V -rsrc "${BUILT_PRODUCTS_DIR}/${DiskImageProduct}" "${mountedDmgPath}/${DiskImageProduct}"
echo "...done"
echo
echo "${mountedDmgPath}"

echo "Configuring folder properties..."
osascript -e "tell application \"Finder\"" \
          -e "    set mountedDiskImage to disk \"${DiskImageVolumeName}\"" \
          -e "    open mountedDiskImage" \
          -e "    tell container window of mountedDiskImage" \
          -e "        set toolbar visible to false" \
          -e "        set current view to icon view" \
          -e "        set position of file \"${DiskImageProduct}\" to {(${DiskImageWindowMaxX} - ${DiskImageWindowMinX}) / 2, 40}" \
          -e "        set bounds to {${DiskImageWindowMinX}, ${DiskImageWindowMinY}, ${DiskImageWindowMaxX}, ${DiskImageWindowMaxY}}" \
          -e "    end tell" \
          -e "    set icon size of icon view options of container window of mountedDiskImage to 128" \
          -e "end tell" \
          > /dev/null
echo "...done"
echo

echo "Unmounting disk image..."
hdiutil eject -quiet ${hdidOutput}
echo "...done"
echo

echo "Compressing disk image..."
mv "${dmgBasePath}.dmg" "${dmgBasePath}-orig.dmg"
if [ ${DiskImageEncryption} != 0 ]; then
	hdiutil convert "${dmgBasePath}-orig.dmg" -encryption -format UDZO -o "${dmgBasePath}"
else
	hdiutil convert "${dmgBasePath}-orig.dmg" -format UDZO -o "${dmgBasePath}"
fi

if [ $? != 0 ]; then
	echo error:0: Failed to compress newly created disk image at ${dmgBasePath}.dmg
	exit 1
fi
rm "${dmgBasePath}-orig.dmg"
echo "...done"
echo

osascript -e "tell application \"Finder\"" -e "select posix file \"${TARGET_BUILD_DIR}/${DiskImageVolumeName}.dmg\"" -e "end tell" > /dev/null

exit 0
