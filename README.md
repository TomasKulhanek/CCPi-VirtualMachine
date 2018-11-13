# CCPi Virtual Machine
This repository contains scripts to create virtual machine with installed CCPi software for tomographic imaging from scratch. VM includes separate environment with Python 3.7.1 and all CCPi repositories installed using `conda` tool at `/opt/ccpi` path.
Currently preprocessing, reconstruction, quantification, segmentation and regularisation are present.

## Brief installation instruction 
Requirement: 
- HW: 1 CPU, 2 GB RAM, 5-50GB disk space.
- OS: Any OS supported by VirtualBox and Vagrant tool (tested on Windows 7,Windows 10, Ubuntu 16.04)
- SW: Install [VirtualBox](https://www.virtualbox.org/wiki/Downloads) and [Vagrant](https://www.vagrantup.com/downloads.html) tested version 2.1.1. Some OS has their own distribution of vagrant and virtualbox: `yum install vagrant virtualbox` OR `apt install vagrant virtualbox`.

Then type in your command line:

```bash
git clone https://github.com/vais-ral/CCPi-VirtualMachine.git
cd CCPi-VirtualMachine
vagrant up
```
- `git clone` - clones this repository into your preferred location 
- `cd tomographic-imaging-vm` - changes dir to the repository directory
- `vagrant up` - for the first time it downloads and boots minimal Scientific Linux 7 with GUI environment (XFCE) (600 MB) from app.vagrantup.com and installs CCPi from conda. First boot provisions the system and takes 17 and more minutes. It configures the ssh on guest and host to accept password-less login. It creates default shared folder `tomographic-imaging-vm` which is shared in quest as `\vagrant`. 

## After installation
Open VirtualBox desktop and work with VM. The CCPi installation of Python 3.7.1 and all CCPi dependent modules are present at `/opt/ccpi/` directory, PATH environment is set for BASH. In order to exchange files between guest and host, the `/vagrant` is mapped to guest path of the `CCPi-VirtualMachine` directory. 
Follow https://cil.readthedocs.io and binary installation option for PATH `/opt/ccpi`.

- `vagrant ssh` - connects to the VM - only console access via ssh.
- `vagrant halt` - shutdowns the VM.
- `vagrant up` - launched for the second and other time it will boot into existing VM in several seconds.

![Vagrant up screenshot](/vagrantupscreen.gif)
