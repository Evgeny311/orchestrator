# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
    # Common configuration
    config.vm.box = "ubuntu/jammy64"
    config.vm.box_check_update = true

    # Master Node
    config.vm.define "master" do |master|
        master.vm.hostname = "k3s-master"
        master.vm.network "private_network", ip: "192.168.56.100"

        master.vm.provider "virtualbox" do |vb|
            vb.name = "k3s-master"
            vb.memory = "2048"
            vb.cpus = 1
        end

        # Install K3s Master
        master.vm.provision "shell", path: "scripts/install-k3s-master.sh"

        # Copy kubeconfig to shared folder
        master.vm.provision "shell", inline: <<-SHELL
            mkdir -p /vagrant/kubeconfig
            sudo cp /etc/rancher/k3s/k3s.yaml /vagrant/kubeconfig/k3s.yaml
            sudo chown vagrant:vagrant /vagrant/kubeconfig/k3s.yaml

            # Replace localhost with master IP
            sudo sed -i 's/127.0.0.1/192.168.56.100/g' /vagrant/kubeconfig/k3s.yaml

            # Save node token for agent

            sudo cat /var/lib/rancher/k3s/server/node-token > /vagrant/kubeconfig/node-token
            sudo chown vagrant:vagrant /vagrant/kubeconfig/node-token

            echo "Master node ready"
            echo "Node token saved to /vagrant/kubeconfig/node-token"
        SHELL
    end

    # Agent Node

    config.vm.define "agent" do |agent|
        agent.vm.hostname = "k3s-agent"
        agent.vm.network "private_network", ip: "192.168.56.101"

        agent.vm.provider "virtualbox" do |vb|
            vb.name = "k3s-agent"
            vb.memory = "2048"
            vb.cpus = 1
        end

        # Install k3s Agent
        agent.vm.provision "shell", path: "scripts/install-k3s-agent.sh"

        agent.vm.provision "shell", inline: <<-SHELL
            echo "Agent node ready"
        SHELL
    end

    config.vm.post_up_message = <<-MESSAGE
    ╔════════════════════════════════════════════════════════════╗
    ║  K3s Cluster is ready!                                     ║
    ╠════════════════════════════════════════════════════════════╣
    ║                                                            ║
    ║  Master: 192.168.56.100                                    ║
    ║  Agent:  192.168.56.101                                    ║
    ║                                                            ║
    ║  Setup kubectl on your host:                               ║
    ║  $ export KUBECONFIG=$(pwd)/kubeconfig/k3s.yaml            ║
    ║  $ kubectl get nodes                                       ║
    ║                                                            ║
    ║  Deploy applications:                                      ║
    ║  $ ./orchestrator.sh create                                ║
    ║                                                            ║
    ╚════════════════════════════════════════════════════════════╝
  MESSAGE
end
