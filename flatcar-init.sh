#!/bin/bash -e
# installs flatcar with ignition file

# flatcar-install only works in linux
[ $(uname -s) == "Linux" ] || (echo "flatcar-install only works in Linux" && exit 11)
# write custom rpi4 firmware to boot partition (dynamically determined)
DISK=/dev/sdc
# names of pubkey and img_name defaults
# customize PUBKEY to your requirements
PUBKEY=id_rsa.pub
IMG_NAME=flatcar_production_image.bin.bz2

# must specify 'server' or 'agent' at prompt
case $1 in
  agent)
    IGN=config.k3s-agent.ign
    ;;
  server)
    IGN=config.k3s-server.ign
    ;;
  *)
    echo "Run either '${BASH_SOURCE[0]} server' or '${BASH_SOURCE[0]} agent'"
    exit 1
    ;;
esac

# replace config.system.bu pubkey with local $PUBKEY
if [ -f ${PUBKEY} ]; then
    KEY=$(cat ${PUBKEY})
    sed -i -e "s'- ssh-rsa .*'- ${KEY}'" config.system.bu
else
    echo "${PUBKEY} must exist, or redefine PUBKEY in script"
    exit 1
fi

# get some flatcar-install
if [ -f /usr/local/bin/flatcar-install ]; then 
    true
else
    curl -sLO https://raw.githubusercontent.com/flatcar/init/flatcar-master/bin/flatcar-install && sudo install flatcar-install /usr/local/bin && rm -f flatcar-install
fi

# process butanes
for i in system sysext k3s k3s-server k3s-agent; do
    butane -d . -spo config.$i.ign config.$i.bu
done

# download the image separately for future installs
if [ ! -f ${IMG_NAME} ]; then 
    flatcar-install -D -f ${IMG_NAME} -C stable -B arm64-usr -o ''
    echo "Flatcar image will remain in this path for future installs"
fi
# once disk is inserted, it may automount; unmount it
sudo umount ${DISK}{1..9} 2>/dev/null || true
# actually install
time sudo flatcar-install -d ${DISK} -i ${IGN} -f ${IMG_NAME} -C stable -B arm64-usr -o ''
# prepare custom UEFI write
efipartition=$(lsblk ${DISK} -oLABEL,PATH | awk '$1 == "EFI-SYSTEM" {print $2}')
mkdir -p /tmp/efipartition
sudo mount ${efipartition} /tmp/efipartition
pushd /tmp/efipartition
# download and install UEFI
version=$(curl --silent "https://api.github.com/repos/pftf/RPi4/releases/latest" | jq -r .tag_name)
# unzip still can't take a redirect pipe because it's from 2009
sudo curl -LO https://github.com/pftf/RPi4/releases/download/${version}/RPi4_UEFI_Firmware_${version}.zip
sudo unzip RPi4_UEFI_Firmware_${version}.zip
sudo rm RPi4_UEFI_Firmware_${version}.zip

popd
sudo umount /tmp/efipartition
sudo eject ${DISK} && echo "${DISK} is ejected and ready to remove"