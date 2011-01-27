==========================================================
 ``Chef Recipies`` -- For working with Vagrant.
==========================================================

A set of Chef recipies that I am using to provision virtual machines with
Vagrant for local development. They cut corner, do bad things and for this
reason shouldn't be used for deployment - however, they could be adapted
fairly easily to work well with both.

Please excuse my poor attempt at Ruby. This is my first attempt, suggestions
and patches are welcome.


Try It
==========================================================

    gem install vagrant

cd to somewhere you want to mame a vagrant project

    vagrant init

Replace the VagrantFile contents with vagrant_files/python_postgres in this repo

    vagrant up

Hopefully that works. Otherwise, go to http://vagrantup.com/ for help.
