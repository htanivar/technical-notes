#!/bin/bash

MAVEN_VERSION="4.0.0-alpha-9"
MAVEN_REPO_URL="https://apache.osuosl.org/maven/maven-4"
DOWNLOAD_URL=$MAVEN_REPO_URL/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz


# Check if the script is executed with root privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# Update the system
#apt update

# Install Maven
# Install Maven
echo "Downloading from $DOWNLOAD_URL"
curl -Os $DOWNLOAD_URL
tar -xzf apache-maven-$MAVEN_VERSION-bin.tar.gz
mkdir -p /opt/maven
mv apache-maven-$MAVEN_VERSION /opt/maven/
rm -rf apache-maven-$MAVEN_VERSION/
rm apache-maven-$MAVEN_VERSION-bin.tar.gz
#

echo "Maven installed successfully."
echo "**************************************************************************"
echo "update PATH in /etc/environment file with /opt/maven/apache-maven-$MAVEN_VERSION/bin"
echo "**************************************************************************"
