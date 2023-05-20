git=`sh /etc/profile; which git`
branchName=`"$git" rev-parse --abbrev-ref HEAD`
buildNumber=$(expr $(git rev-list $branchName --count) - $(git rev-list HEAD..$branchName --count))
if [ $CONFIGURATION = "Debug" ] || [ $branchName != "main" ] || [ $branchName != "develop" ];then
build=$buildNumber-$branchName
else
build=$buildNumber
fi
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $build" "${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
echo "Updated ${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
echo "Updated build number to $build using branch '$branchName'"

# 把版本号显示在 Setting Bundle
version=`/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"`
versionBuild="$version\($build\)"
/usr/libexec/PlistBuddy -c "Set PreferenceSpecifiers:0:DefaultValue $versionBuild" "${TARGET_BUILD_DIR}/${FULL_PRODUCT_NAME}/Settings.bundle/Root.plist"
echo "Updated Settings.bundle"
