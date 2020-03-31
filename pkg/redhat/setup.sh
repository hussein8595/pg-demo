#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "This script must be run as root"
  exit 1
fi

OS_VERSION=$(cat /etc/os-release | grep "^VERSION_ID=" | awk -F "=" '{ print $2 }' | sed 's/"//g')

# EPEL & other repos
yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-${OS_VERSION}.noarch.rpm
yum config-manager --enable PowerTools AppStream BaseOS *epel

# Node repo
echo "Setting up the NodeJS repo..."
curl -sL https://rpm.nodesource.com/setup_12.x | bash -

# Yarn repo
echo "Setting up the Yarn repo..."
curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | sudo tee /etc/yum.repos.d/yarn.repo

# Install pre-reqs
echo "Installing build pre-requisites..."
yum groupinstall -y "Development Tools"

if [ ${OS_VERSION} == 7 ]; then
    yum install -y expect fakeroot httpd-devel qt5-qtbase-devel postgresql-devel python3-devel nodejs yarn rpm-build
    pip3 install sphinx
else
    yum install -y expect fakeroot qt5-qtbase-devel libpq-devel python3-devel python3-sphinx nodejs yarn rpm-build
fi

# Setup RPM macros for signing
read -p "Do you want to append RPM macros for signing packages to ~/.rpmmacros (y/n)? " RESPONSE
case ${RESPONSE} in
    y|Y )
        cat << EOF >> ~/.rpmmacros
# Macros for signing RPMs.
# Added by the pgAdmin 4 build environment setup script at the users request.

%_signature gpg
%_gpg_path ~/.gnupg
%_gpg_name Package Manager
%_gpgbin /usr/bin/gpg2
%__gpg_sign_cmd %{__gpg} gpg --force-v3-sigs --batch --verbose --no-armor --passphrase-fd 3 --no-secmem-warning -u "%{_gpg_name}" -sbo %{__signature_filename} --digest-algo sha256 %{__plaintext_filename}'
EOF
        ;;
    * )
        exit 1;;
esac





