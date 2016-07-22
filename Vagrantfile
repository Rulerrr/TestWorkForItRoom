# -*- mode: ruby -*-
# vi: set ft=ruby :

box      = "ubuntu-server-14.04"
box_url  = "https://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-i386-vagrant-disk1.box"
hostname = "yiitest2.loc"
www_dst  = "/var/www"
www_src  = "./"
ip       = "192.168.56.102"
ram      = "1024"

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.box = box

  config.vm.box_url = box_url

  config.vm.host_name = hostname

  config.vm.network "private_network", ip: ip
  config.vm.network "forwarded_port", guest: 80, host: 8080

  config.vm.synced_folder www_src, www_dst, owner: "www-data", group: "www-data"

  config.vm.provider "virtualbox" do |vb|
    vb.customize [
      "modifyvm", :id,
      "--name", hostname,
      "--memory", ram
    ]
  end

  config.vm.provision "shell", path: "./provision.sh"

end
