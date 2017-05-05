#!/bin/bash -ex

if [ "$EUID" -ne 0 ]
      then echo "Please run as root"
      exit
fi

echo "[Info] Install InfraSIM "
sudo pip install infrasim-compute==3.0.1


echo "[Info] clean up previous InfraSIM"
sudo infrasim node destroy

echo "[Info] Init InfraSIM"
sudo infrasim init

echo "[Info] Update InfraSIM config"
sed -i "s/network_mode: nat/network_mode: bridge/g" ~/.infrasim/.node_map/default.yml
sed -i "s/network_name: ens192/network_name: br0/g" ~/.infrasim/.node_map/default.yml
sudo bash -c "echo '' >> ~/.infrasim/.node_map/default.yml"
sudo bash -c "echo 'bmc:' >> ~/.infrasim/.node_map/default.yml"
sudo bash -c "echo '    interface: br0' >> ~/.infrasim/.node_map/default.yml"



echo "[Info] Starts InfraSIM"
sudo infrasim node start



