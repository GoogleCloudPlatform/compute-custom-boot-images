# Creating Custom Boot Images for Compute Engine
This is the set of scripts for Creating custom base Images for Compute Engine with Jenkins or Cloud Build and Packer.  The tutorial explains how to create a Jenkins job and Packer scripts to build a custom boot image from an ISO and Kickstart file.

# Included Files
1. /http/centos-7.ks - kickstart file for CentOS7.
2. /scripts/gce.sh - provisioning script used to provision initial gce image.
3. /scripts/linux-guest-environment.sh used to finalize the image with the linux guest environment for Google Cloud.
5. centos-7-from-iso.json - uses Packer, an ISO file and the supplied Kickstart script to build the raw compute image.
