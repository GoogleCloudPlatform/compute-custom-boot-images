#!/bin/sh
# Copyright 2018 Google LLC

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#  https://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#######################################
## Linux Guest Environment
curl -O https://packages.cloud.google.com/yum/doc/yum-key.gpg
curl -O https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
rpm --import yum-key.gpg --quiet
rpm --import rpm-package-key.gpg --quiet
rm yum-key.gpg
rm rpm-package-key.gpg
yum updateinfo
OS_RELEASE_FILE="/etc/redhat-release"
if [ ! -f $OS_RELEASE_FILE ]; then
   OS_RELEASE_FILE="/etc/centos-release"
fi
DIST=$(cat $OS_RELEASE_FILE | grep -o '[0-9].*' | awk -F'.' '{print $1}')
sudo tee /etc/yum.repos.d/google-cloud.repo << EOM
[google-cloud-compute]
name=Google Cloud Compute
baseurl=https://packages.cloud.google.com/yum/repos/google-cloud-compute-el${DIST}-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOM
sudo yum updateinfo
yum install -y python-google-compute-engine \
google-compute-engine-oslogin \
google-compute-engine
sudo yum -y update
### END Linux Guest Environment #######
