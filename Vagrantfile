# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "precise64"

  # The url from where the 'config.vm.box' box will be fetched if it
  # doesn't already exist on the user's system.
  config.vm.box_url = "http://files.vagrantup.com/precise64.box"

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 8000 on the guest machine.
  config.vm.network :forwarded_port, guest: 8000, host: 8000

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  config.vm.network :private_network, ip: "192.168.33.11"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  config.vm.network :public_network

  # If you know the device you want to use, you can use the following line
  # which will avoid the prompt
  # config.vm.network :public_network, :bridge => 'br0'

  # If true, then any SSH connections made will enable agent forwarding.
  # Default value: false
  # config.ssh.forward_agent = true

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #

  config.vm.provider :virtualbox do |vb|
  #   # Don't boot with headless mode
  #   vb.gui = true
  #
  #   # Use VBoxManage to customize the VM. For example to change memory:
     vb.customize ["modifyvm", :id, "--memory", "2048"]
  end
  #
  # View the documentation for the provider you're using for more
  # information on available options.

  config.vm.synced_folder "../drupal/", "/var/www/source"

  # Make salt files and formula available to the minion.
  config.vm.synced_folder "salt/", "/srv/salt"

  config.vm.provision :salt do |salt|
    salt.minion_config = "salt/minion"
    salt.run_highstate = true
  end

end
