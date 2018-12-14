# installs ccpi from scratch
export INSTALLDIR=/opt/ccpi
echo Bootstrapping Conda
bash /vagrant/scripts/bootstrapconda.sh
echo Bootstrapping Jupyter NB
bash /vagrant/scripts/bootstrapjupyter.sh
echo Boostrapping CCPI
bash /vagrant/scripts/bootstrapccpi.sh
echo Bootstrapping CCPPETMR
bash /vagrant/scripts/bootstrappetmr.sh

sudo chown -R vagrant:vagrant /home/vagrant/.Conda
sudo chown -R vagrant:vagrant $INSTALLDIR

yum install -y mc
echo "CCPi installed. Connect to VM using 'vagrant ssh', use VirtualBox VM desktop. Jupyter available at http://localhost:8080/jupyter"

