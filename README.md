# pe_vagrant

First you need to install  [vagrant](https://www.vagrantup.com/downloads.html)

```bash
git clone git@github.com:rkuzovlev/pe_vagrant.git
cd pe_vagrant
git submodule init
git submodule update
vagrant up  # may ask root password for mount nfs from host to virtual machine
```
Open http://192.168.33.10/ in browser
