#!/bin/bash

USERNAME=$1
PASSWORD=$2
HOSTNAME=$3
NODECOUNT=$4
ROUTEREXTIP=$5
RHNUSERNAME=$6
RHNPASSWORD=$7
RHNPOOLID=$8
SSHPRIVATEDATA=$9
SSHPUBLICDATA=${10}
SSHPUBLICDATA2=${11}
SSHPUBLICDATA3=${12}

ps -ef | grep master.sh > cmdline.out

mkdir -p /home/$USERNAME/.ssh
echo $SSHPUBLICDATA $SSHPUBLICDATA2 $SSHPUBLICDATA3 >  /home/$USERNAME/.ssh/id_rsa.pub
echo $SSHPRIVATEDATA | base64 --d > /home/$USERNAME/.ssh/id_rsa
chown $USERNAME /home/$USERNAME/.ssh/id_rsa.pub
chmod 600 /home/$USERNAME/.ssh/id_rsa.pub
chown $USERNAME /home/$USERNAME/.ssh/id_rsa
chmod 600 /home/$USERNAME/.ssh/id_rsa

mkdir -p /root/.ssh
echo $SSHPRIVATEDATA | base64 --d > /root/.ssh/id_rsa
echo $SSHPUBLICDATA $SSHPUBLICDATA2 $SSHPUBLICDATA3   >  /root/.ssh/id_rsa.pub
chown root /root/.ssh/id_rsa.pub
chmod 600 /root/.ssh/id_rsa.pub
chown root /root/.ssh/id_rsa
chmod 600 /root/.ssh/id_rsa

mkdir -p /var/lib/origin/openshift.local.volumes
ZEROVG=$( parted -m /dev/sda print all 2>/dev/null | grep unknown | grep /dev/sd | cut -d':' -f1 | head -n1)
parted -s -a optimal ${ZEROVG} mklabel gpt -- mkpart primary xfs 1 -1
sleep 5
mkfs.xfs -f ${ZEROVG}1
echo "${ZEROVG}1  /var/lib/origin/openshift.local.volumes xfs  defaults,gquota  0  0" >> /etc/fstab
mount ${ZEROVG}1

DOCKERVG=$( parted -m /dev/sda print all 2>/dev/null | grep unknown | grep /dev/sd | cut -d':' -f1 | head -n1 )

echo "DEVS=${DOCKERVG}" >> /etc/sysconfig/docker-storage-setup
cat <<EOF > /etc/sysconfig/docker-storage-setup
DEVS=$DOCKERVG
VG=docker-vg
DATA_SIZE=95%VG
EXTRA_DOCKER_STORAGE_OPTIONS="--storage-opt dm.basesize=3G"
EOF

cat <<EOF > /home/${USERNAME}/.ansible.cfg
[defaults]
host_key_checking = False
EOF
chown ${USERNAME} /home/${USERNAME}/.ansible.cfg

cat <<EOF > /root/.ansible.cfg
[defaults]
host_key_checking = False
EOF

touch /root/.updateok
