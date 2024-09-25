#!/bin/bash

GRADLE_VERSION="gradle-8.6-milestone-1"
GRADLE_BIN="$GRADLE_VERSION-bin.zip"
GRADLE_REPO_URL="https://services.gradle.org/distributions"
DOWNLOAD_URL=$GRADLE_REPO_URL/$GRADLE_BIN


# Check if the script is executed with root privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# Install Gradle
echo "Downloading from $DOWNLOAD_URL"
curl -OLs $DOWNLOAD_URL
#wget --show-progress $DOWNLOAD_URL
unzip $GRADLE_BIN
mkdir -p /opt/gradle
mv $GRADLE_VERSION /opt/gradle/
rm $GRADLE_BIN

echo "Gradle installed successfully."
echo "**************************************************************************"
echo "update PATH in /etc/environment file with /opt/gradle/$GRADLE_VERSION/bin"
echo "**************************************************************************"