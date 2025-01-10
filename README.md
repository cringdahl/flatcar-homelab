# flatcar-homelab

k3s cluster on Flatcar Linux on a RPi4 homelab

## Summary

The lab is a teardown-friendly, on-prem cloud native, IaC experiment. No permanent/mission-critical middleware can live here, since we need all that to spin up the lab.

Once you have the physical lab setup, you can install the k3s-server on n1, and the k3s-agent on n2+. The agents require the token from n1. You'll also need the kubeconfig from n1 in order to interact with it via kubectl.

## Install Steps

n1 is our k3s-server, n2 is our k3s-agent

1. Have a Fedora workstation or VM
1. Clone this repo, cd to it
1. `sudo dnf install butane`
1. `cp ~/.ssh/id_rsa.pub id_rsa.pub`
    * or symlink or whatever works
1. Insert `n1` SD card
    * if your SD card isn't `/dev/sdc`, edit the script's `DISK` variable
1. `./flatcar-install server`
1. Put SD card into `n1` Pi4, boot it, verify ssh.
    * `ssh core@n1 cat /etc/motd`
1. `ssh core@n1 'sudo cat /var/lib/rancher/k3s/server/token' > token.txt`
    * this `token.txt` will be picked up by Ignition during install
1. `ssh core@n1 'sudo cat /etc/rancher/k3s/k3s.yaml' | sed -e 's/127\.0\.0\.1/n1/' >> ~/.kube/config`
1. Insert `n2` SD card
1. `./flatcar-install agent`
1. Put SD card into `n2` Pi4, boot it, verify ssh.
1. `kubectl get no` should yield both nodes

## Requirements

### Workstation 

Lots of specifics to getting this working, unfortunately.

#### Linux Workstation or Fedora VM

Actual installation is done via the flatcar-install script, which requires specifically Linux to run. Butane, the Ignition configuration transpiler, requires either an ignition container or a Fedora package. Since I'm on a Mac, I'm running a Fedora 40 VM to solve both problems.

#### USB-C Hub Splitter

We're installing on SD cards, so we need a way to read them. I have a [USB-C hub splitter](https://www.amazon.com/gp/product/B09NKTTG74/); this one is unavailable at time of writing, but similar items continue to exist.

### Lab Setup

The actual physical lab itself is [here](docs/LAB-DESC.md)

#### DHCP & DNS

In addition to the hardware setup, you should add DHCP reservations for your nodes. DNS hostnames are also required; I'm using `n1`, `n2`, and so on. This is reflected in the docs and setup.

### k3s-agent node setup

See install steps above for actual setup.

I'm sharing my flatcar-init directory between my Mac and Fedora, so running the token step "locally" will be picked up by Fedora's flatcar-init.sh run. Also, my ssh pub key is only on my Mac.

## Future Considerations

In addition to the below, nothing has actually been installed in this environment yet. I'm pausing this particular project in favor of other work, but revisiting will bring basic services, possibly in a separate repo.

### Configuration changes

In-place updates as is are a pain. If I want a configuration change, it's either a Butane change and reinstall, or an Ignition change in `/oem` and re-run ignition on next boot.

Making reinstalls trivial would involve adding secondary storage for data volumes and (maybe) containers, as well as persistent k3s-server tokens and kubeconfs.

### System updates

Relying on simple flatcar update cycles, or even locksmithd coordination, is just reboots, with no consideration for k3s at all. [Kured](https://kured.dev) is the recommended update manager. It's container based, so it hasn't been part of this setup.

## Reference Docs

Documentation aplenty. At least skim the following:
* [Flatcar Setup on Raspberry Pi](https://aao.fyi/bits/sbc/raspi-flatcar-setup/) 
  * this gets you to a basic install quickly
* [Running Flatcar Container Linux on Raspberry Pi 4](https://www.flatcar.org/docs/latest/installing/bare-metal/raspberry-pi/)
* [Flatcar Butane Specification v1.1.0](https://coreos.github.io/butane/config-flatcar-v1_1/)
* Pulled a lot of inspiration from [this Medium article](https://medium.com/@life-is-short-so-enjoy-it/raspberry-pi-4-install-flatcar-container-linux-with-new-sd-947e86700049)
