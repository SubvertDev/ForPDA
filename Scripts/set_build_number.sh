#!/bin/bash

# Get the Git commit count
#commitCount=$(git rev-list --count HEAD)

# Check if commitCount is a valid number
#if [[ ! $commitCount =~ ^[0-9]+$ ]]; then
#  echo "Failed to get Git commit count."
#  exit 1
#fi

git=`sh /etc/profile; which git`
branchName=`"$git" rev-parse --abbrev-ref HEAD`
buildNumber=$(expr $(git rev-list $branchName --count) - $(git rev-list HEAD..$branchName --count))

if [ $CONFIGURATION = "Debug" ] || [ $branchName != "main" ] && [ $branchName != "develop" ];then
    build=$buildNumber-$branchName
else
    build=$buildNumber
fi

# Set the build number in Info.plist for the main app target
mainPlistPath="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
echo "Setting build number to $commitCount in $mainPlistPath"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $commitCount" "$mainPlistPath"

# Set the build number in Info.plist for each app extension
appExtensions=("OpenInAppExtension" "ShareExtension")  # Add the names of your app extensions here
for extension in "${appExtensions[@]}"; do
  extensionPlistPath="${TARGET_BUILD_DIR}/${PRODUCT_NAME}.app/PlugIns/$extension.appex/Info.plist"
  echo "Setting build number to $commitCount in $extensionPlistPath"
  /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $commitCount" "$extensionPlistPath"
done
