==========================================================
 ``Chef Recipies`` -- For working with Vagrant.
==========================================================

A set of Chef recipies that I am using to provision virtual machines with
Vagrant for **local development**. They cut corners, do bad things and for this
reason should **not** be used for production/deployment or any publicly 
visible servers - however, they could be adapted fairly easily to work well 
with both.

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


What's on the box?
==========================================================

Currently this is tailored very much towards the tools that I liked to use.
However I'd really like to add more functionality and make it generic so pull
requests are very welcome.

A few system libraries that I frequently use; ack, vim, git, svn, libxml-dev

Some enforcement of my own personal development rules (pip wont work outside 
of a virtualenv). However, you will have a virtualenv setup with the name that
you set the PROJECT_NAME to in the Vagrantfile.

