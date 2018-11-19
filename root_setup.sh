#!/bin/bash
apt-get update

apt-get install -y xorg # X display server https://en.wikipedia.org/wiki/X.Org_Server

# installing and configuring nvidia DRIVERS
apt-get install build-essential -y
curl -O http://us.download.nvidia.com/XFree86/Linux-x86_64/367.57/NVIDIA-Linux-x86_64-367.57.run
chmod +x ./NVIDIA-Linux-x86_64-*.run
./NVIDIA-Linux-x86_64-*.run -q -a -n -X -s

# xorg conf generated via nvidia-xconfig --allow-empty-initial-configuration
# overwriting xorg.conf adding the BusID where the video card is installed
NVIDIA_DRIVER_BUSID=`nvidia-xconfig --query-gpu-info | grep -i -m 1 busid | awk '{print $4}'`
sudo nvidia-xconfig -a --allow-empty-initial-configuration --virtual=1920x1200 --only-one-x-screen --busid=${NVIDIA_DRIVER_BUSID}

# Docker
apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
apt-add-repository 'deb https://apt.dockerproject.org/repo ubuntu-xenial main'
apt-get update -y
apt-get install -y docker-engine
# 'systemctl status docker' to check the service status
# allow docker to be used without sudo - THIS REQUIRES TO LOGOUT AND LOGIN AGAIN!!!
usermod -aG docker ubuntu # assuming "ubuntu" is the user name

# Nvidia docker https://github.com/NVIDIA/nvidia-docker/wiki
export NVIDIADOCKER_VERSION=1.0.1
wget -P /tmp https://github.com/NVIDIA/nvidia-docker/releases/download/v${NVIDIADOCKER_VERSION}/nvidia-docker_${NVIDIADOCKER_VERSION}-1_amd64.deb
dpkg -i /tmp/nvidia-docker*.deb && rm /tmp/nvidia-docker*.deb
# Test nvidia-smi
# nvidia-docker run --rm nvidia/cuda nvidia-smi

# Docker compose
curl -L https://github.com/docker/compose/releases/download/1.8.1/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
rm -f /usr/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# Nvidia docker compose https://github.com/eywalker/nvidia-docker-compose
apt-get install python-pip -y
pip install --upgrade pip
pip install nvidia-docker-compose

# install virtualgl
export VGL_VERSION=2.5.2
wget http://downloads.sourceforge.net/project/virtualgl/${VGL_VERSION}/virtualgl_${VGL_VERSION}_amd64.deb
dpkg -i virtualgl*.deb && rm virtualgl*.deb

# Set VirtualLG defaults, xauth bits, this adds a DRI line to xorg.conf.
#/opt/VirtualGL/bin/vglserver_config -config -s -f +t
/opt/VirtualGL/bin/vglserver_config -config +s +f -t  # access open to all users, restricting users doesn't really work :\

# install lightdm
apt-get install -qqy lightdm

# fix lightdm bug
# https://wiki.archlinux.org/index.php/VirtualGL#Problem:_Error_messages_about_.2Fetc.2Fopt.2FVirtualGL.2Fvgl_xauth_key_not_existing
rm /etc/lightdm/lightdm.conf
# overriding deprecated default configuration [SeatDefaults] https://wiki.ubuntu.com/LightDM
cat << EOF - > /etc/lightdm/lightdm.conf
[Seat:seat0]
display-setup-script=/usr/bin/vglgenkey
display-setup-script=xhost +LOCAL:
EOF

apt-get install -y mesa-utils

# install turbovnc
# can be updated to 1.5.1
export LIBJPEG_VERSION=1.4.2
wget http://downloads.sourceforge.net/project/libjpeg-turbo/${LIBJPEG_VERSION}/libjpeg-turbo-official_${LIBJPEG_VERSION}_amd64.deb
dpkg -i libjpeg-turbo-official*.deb && rm libjpeg-turbo-official*.deb
# can be updated to 2.1
export TURBOVNC_VERSION=2.0.1
wget http://downloads.sourceforge.net/project/turbovnc/${TURBOVNC_VERSION}/turbovnc_${TURBOVNC_VERSION}_amd64.deb
dpkg -i turbovnc*.deb && rm turbovnc*.deb

# install window manager
# installing mate as it's supported out of the box by turbovnc, see ~/.vnc/xstartup.turbovnc for more info
apt-get install mate -y --no-install-recommends

# start lightdm display manager, so far there was NO display manager!
service lightdm start

#test vgl with /opt/VirtualGL/bin/glxinfo -display :0 -c | tail
