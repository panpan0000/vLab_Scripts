#!/bin/bash -x

if [ "$EUID" -ne 0 ]
      then echo "Please run as root"
      exit
fi

echo "[Info] 1. Clear Database..."
echo "db.dropDatabase()" | mongo pxe

echo "[Info] 1. Install a released version of RackHD from official npm source."

cd ~
mkdir -p ~/node_modules

for service in $(echo "on-dhcp-proxy on-http on-tftp on-syslog on-taskgraph");
do
       if [ -d node_modules/$service ]; then
           echo "[warning] there's already folder named $service under $(pwd) already. delete it."
           rm -rf $service
       fi
       npm install $service@vlab;
   done


echo "[Info] 2. Install the micro-kernel ( it will download images for PXE boot)"

   mkdir -p node_modules/on-tftp/static/tftp
   cd node_modules/on-tftp/static/tftp
   for file in $(echo "\
       monorail.ipxe \
       monorail-undionly.kpxe \
       monorail-efi64-snponly.efi \
       monorail-efi32-snponly.efi");do
   wget "https://dl.bintray.com/rackhd/binary/ipxe/$file"
   done
   cd -
   mkdir -p node_modules/on-http/static/http/common
   cd node_modules/on-http/static/http/common
   for file in $(echo "\
       base.trusty.3.16.0-25-generic.squashfs.img \
       discovery.overlay.cpio.gz \
       initrd.img-3.16.0-25-generic \
       vmlinuz-3.16.0-25-generic");do
   wget "https://dl.bintray.com/rackhd/binary/builds/$file"
   done
   cd ~


echo "[Info] 3. Generate the required file /opt/monorail/config.json ( Note: a template config file will be downloaded with below commands )"

sudo mkdir -p /opt/monorail
sudo wget -O /opt/monorail/config.json    https://raw.githubusercontent.com/RackHD/RackHD/master/packer/ansible/roles/monorail/files/config.json 

echo "[Info] 4.1 Change the 15th line from (Click 'i' button to enter editing mode so you can edit the file like notepad)"

sudo sed -i '15s/"authEnabled": true,/"authEnabled": false,/' /opt/monorail/config.json

if [ "$(grep "\"autoCreateObm\": true,"  /opt/monorail/config.json )"  == ""  ]; then
    echo "[Info] 4.2 add autoCreateObm true into config file"
    sudo sed -i 's/\"dhcpSubnetMask\": \"255.255.240.0\",/\"dhcpSubnetMask\": \"255.255.240.0\",\n\    "autoCreateObm\": true,/' /opt/monorail/config.json
else
    echo "[Info] 4.2 autoCreateObm field only exist in /opt/monorail/config.json, skip this step"
fi

echo "[Info] 5. add pm2 config file"

cat << EOF > ~/rackhd.yml
apps:
  - script: index.js
    name: on-taskgraph
    cwd: node_modules/on-taskgraph
  - script: index.js
    name: on-http
    cwd: node_modules/on-http
  - script: index.js
    name: on-dhcp-proxy
    cwd: node_modules/on-dhcp-proxy
  - script: index.js
    name: on-syslog
    cwd: node_modules/on-syslog
  - script: index.js
    name: on-tftp
    cwd: node_modules/on-tftp
EOF


echo "[Info] 6. start RackHD"
cd ~
sudo pm2 start rackhd.yml



echo "[Info] 7. check RackHD API runs after 15 sec"
sleep 15
curl localhost:8080/api/current/nodes

