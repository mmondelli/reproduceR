# reproduceR

The purpose of this package is to add functionalities of other existent packages in functions for the packaging, validation and publication of experiments defined by R scripts. The following describes the workflow for use of the package and the details of each step.

This package creates a virtual machine and requires Vagrant to be installed. If you do not have Vagrant installed, please refer to [this link](https://www.vagrantup.com/intro/getting-started/index.html) for instructions.

# Installing
reproduceR can be installed from github:

```
library(devtools)
devtools::install_github('mmondelli/reproduceR')
```

# Step 1: Packaging
After installing the package, you should load it into R. The working directory should be the directory where the experiment script is placed. You can check the working directory using ```setwd()``` and change it with ```getwd()```.

```
library(reproduceR)
```

You can now execute the pack() function:

```
reproduceR::pack()
```

This function will:

* Start packrat in your experiment directory to manage the dependencies of used packages
* Pack the experiment and used packages into a compressed file (which will be located at ./packrat/bundles/<experiment>.tar.gz)
* Create and start a virtual machine using Vagrant

Running this function may take a few minutes, and when done, the virtual machine will be ready to be accessed. You should then perform the following steps before Step 2:

**1. Access the VM:** Through the Linux terminal (or Power shell in Windows), you must access the directory of the experiment. You will see a Vagrantfile now located in this directory. This file contains the configuration of the VM created with the pack() function, but you do not have to worry about it, unless you prefer to change some specification. Within the directory you must run ```vagrant ssh``` to access the machine.

**2. Copy the packaged experiment to /home:** Vagrant creates a directory in the VM (/vagrant) that is shared with the directory in the local machine where Vagrant was started (/&lt;experiment directory&gt;). Thus, any changes made to /vagrant will be reflected in the local directory. Therefore, we advise you to copy the experiment that was packaged in the previous step to the /home of the VM. For example: 

```
cp /vagrant/<experiment dir>/packrat/bundles/<experiment>.tar.gz /home/vagrant
```

**3. Install dependencies:** The Vagrant specification that is provided along with the reproduceR contains the installation of some basic system packages. If the experiment depends on a specific application, we suggest installing in this step. _(The list of what is installed by default in the VM is provided at the end of this document)._

**4. Unpack the experiment:** Now, you can unpack the experiment as follows:

```
cd ~
R
library('packrat')
packrat::unbundle(bundle='<experiment>.tar.gz', where='.')
```

This will take a few minutes, depending on the number of packages that have to be installed.
Note: If any dependency has not been resolved (as suggested in 3), installing packages in this step with packrat may fail at some point. You should quit R, resolve the dependecy, access the experiment directory created in the VM, execute R and type ```packrat::restore()```. Packrat will continue to install the packages from where it stopped.

# Step 2: Validating

Now you have a new directory in /home/vagrant containing the experiment to be validated. You must execute the following:

```
cd <experiment>
R
library(reproduceR, lib.loc = '/usr/local/lib/R/site-library/')
reproduceR::validate()
```
This function is responsible for re-executing the experiment with the [rdt](https://github.com/End-to-end-provenance/rdt) package, collecting and storing the provenance in a relational database (~/prov.db). This database can be queried through sql statements using sqlite3.

Example:

```
sqlite3 ~/prov.db
select * from input_output;
```
# Step 3: Publishing

The publication of the experiment involves gathering the packaged experiment, the provenance (including the relational database) and a new Vagrantfile and compressing it to send to Zenodo, the general-purpose open-access repository for research data.

Before publishing the experiment, you must [create a token in Zenodo](https://zenodo.org/account/settings/applications/tokens/new/) and inform it as a parameter to the function.

Then you can execute the function:

```
reproduceR::publish(token=<your_token>, bundle=<packaged experiment>, prov_dir=<provenance dir>)
```

## Additional information

* The libs and applications already provided by the VM (in this package) are: default-jdk, libcurl4-openssl-dev, build-essential, libgit2-dev, libssl-dev, libxml2-dev, r-base-core, r-recommended, sqlite3

* Also, devtools and reproduceR R packages are already installed (to load them into R, you can inform the location: lib.loc='/usr/local/lib/R/site-library/')



