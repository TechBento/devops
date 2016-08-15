#!/bin/bash
# As-Is, no warranty. Use at your own risk.  Works only on Amazon Linux.
# ----------------------------------
# $Id:$ 
# ----------------------------------
#CHANGE THIS
javaversionminor="101" #CHANGE ME IF NEEDED
# LOOK ABOVE!
sudo mkdir -P /usr/shared/techbento
sudo chmod 777 /usr/shared/techbento
echo "================================================================="
echo "Testing Java version.  Expect 1.8 Java SE.  If you see OpenJDK, it should be replaced by the fist task."
java -version
echo "Replace OpenJDK with Sun Microsystems Java. If you are installing on an Amazon LINUX machine, then you must run this step one time."
echo "Do you wish to proceed with this action? 1 for YES, 2 for NO."
read -n1 -p "[1,2]. . . . . :" actionJavaVar
if [ "$actionJavaVar" == "1" ]
then
sudo rpm --erase --nodeps java-1.7.0-openjdk java-1.7.0-openjdk-devel
#Example link http://download.oracle.com/otn-pub/java/jdk/8u101-b13/jdk-8u101-windows-x64.exe
wget -N  --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u$javaversionminor-b13/jdk-8u$javaversionminor-linux-x64.rpm" -P /usr/shared/techbento/
sudo yum install /usr/shared/techbento/jdk-8u$javaversionminor-linux-x64.rpm
echo "Ready for a multiple line java swap. You are going to be pressing ENTER a bunch of times.  Ready?!"
read -p "Press [Enter] to continue..."
for i in /usr/java/jdk1.8.0_$javaversionminor/bin/* ; do \
f=$(basename $i); echo $f; \
sudo alternatives --install /usr/bin/$f $f $i 20000 ; \
sudo update-alternatives --config $f ; \
done
echo "Yay! All done."
read -p "Press [Enter] to continue..."
sudo ln -sfn /usr/java/jdk1.8.0_$javaversionminor java_sdk
sudo ln -sfn /usr/java/jdk1.8.0_$javaversionminor/jre jre
else "Looks like you chose to skip this step. Press any key to continue..."
fi
echo "Done."