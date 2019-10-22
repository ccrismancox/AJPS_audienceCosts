# Replication instructions for "Audience Costs and the Dynamics of War and Peace" 
# Casey Crisman-Cox and Michael Gibilisco
# 22 October 2019


## Update information
Note that this is the third update to the  archive.  In this update, we move to Ubuntu 18.04.3 LTS (Bionic Beaver) and away from the outdated Xubuntu 14.04.  Additionally, we no longer use the live version and instead encourage users to use a fresh install or a virtual machine.  The instructions we provide will work for either. We tested these using a virtual machine with the following allocations

- 50GB hard drive
- 32 GB memory
- 2 cpu cores


					 
# Setup instructions

1. Download the CD image (.iso file) associated with Ubuntu 18.04.3 LTS
    - The iso file can be downloaded from: [`this link`](http://no.releases.ubuntu.com/18.04/ubuntu-18.04.3-desktop-amd64.iso)
2. Use a virtual machine program (e.g., Parallels for Mac, Oracle VirtualBox, VMWare) to setup a machine based on the Ubuntu 18.04.3 iso file.  A tutorial for using VirtualBox can be found [`here`](https://itsfoss.com/install-linux-in-virtualbox/).
5. When given the option to either install Ubuntu or Try Ubuntu.  Select "Install." This will take you to the desktop and click through with the default options until everything is setup. You'll be asked to choose a username and password. You'll need these throughout.
6. Download the replication package (the Firefox web browser is pre-installed and should be available on the side bar).
7. Extract the replication package to the home folder (`/home/<USER>`), where `<USER>` is the user name you selected in step 3.
8. At this point you can run fullReplication.sh which will install all the necessary software and then run all the replication files
    - To do this navigate to the replication folder  (`/home/<USER>/Replication`) using the file manager (also found in the whisker menu), right click on some white space, select "Open Terminal Here", and run the command
```bash
bash fullReplication.sh
```
7. Alternatively, if you prefer to run the estimation and analysis files individually, you can just install all necessary software at this point by navigating to `/home/<USER>/Replication/Ubuntu Optimization/UbuntuSetup`, opening the terminal (again by right clicking and selecting "Open Terminal Here" and running the command
```bash
bash UbuntuSetup.sh
```
This step may take up to 30 minutes depending on computer and internet speed.
    - You will be required to press "Enter" at some point (roughly 20 minutes) into the process.
    - As the software updates, other background options may occur (screen resolution may adjust, printers may be discovered, other drives may be mounted, etc.)
    - Errors may appear during this process, but so long as the code does not stop, they can be safely ignored
    - When `UbuntuSetup.sh` finishes, the line  "`Ubuntu Setup Complete`" will print to the screen 

# Instructions for compiling the dataset
To recreate our dataset from scratch we use the file `/home/<USER>/Replication/Data/dyadicDataCreate.R` either from within an R environment (installed when running `UbuntuSetup.sh`, above) or by opening a terminal in this location and running
```bash
Rscript dyadicDataCreate.R
```



To convert the data from an rdata file to a pickle file (python readable), run `convertData_R2py.py` by navigating to  `/home/<USER>/Replication/Ubuntu Optimization/UbuntuOptimization/`, opening a terminal in that location, and running the commands
```bash
sudo pip install numpy==1.8.1
python convertData_R2py.py
```
This installs an older version of numpy so that the data conversions still work.

# Instructions for replicating the coefficients
To run the estimation  navigate to `/home/<USER>/Replication/Ubuntu Optimization/UbuntuOptimization`.
Open a terminal and run
```bash
bash runEstimation.sh
```
This script will convert the data (by running `convertData_R2py.py`) and run the estimation (by running `mainModelEstimation.py`).
To just run the estimation, open a terminal and run these two lines
```bash
sudo pip install numpy --upgrade
python mainModelEstimationCode.py
```
Note that numpy needs to be re-upgraded as it was downgraded during the data conversion stage.
In addition to estimating the coefficients, `mainModelEstimation.py` also exports the coefficients to `/home/<USER>/Replication/Paper Results/ReplicationOutput.rdata`.

# Instructions for replicating the tables and figures
To replicate the tables and figures, navigate to `/home/<USER>/Replication/Paper Results/`. These are all R files and can be run within any standard R environment or through the terminal.

- `analyticalSE_code.r` reads in the model coefficients and exports the coefficients and standard errors to `mainModelResults.rdata`.  Source this file in R or run
```bash
Rscript analyticalSE_code.r
```
in the terminal
- `Section4/Table1.r` replicates Table 1.  This file can be sourced in R or by opening a terminal in the `Section4` folder and running
```bash
Rscript Table1.r
```
- `Section5/Section5.0/replication5.0.R` produces and Figure 1.  This file can be sourced in R or by opening a terminal in the `Section5.0` folder and running
```bash
Rscript replication5.0.R
```
- `Section5/Section5.1/Table2.R` replicates Table 2.  This file can be sourced in R or by opening a terminal in the `Section5.1` folder and running
```bash
Rscript Table2.R
```
- `Section5/Section5.2/replication5.2.R` generates the information used to create Figure 2. As discussed above, we draw the regression tree in LaTeX using the TikZ to produce a more customized figure, `Figure2.pdf` looks different from this image, but the information is identical.  It also produces the information for Table 3 and prints it to the screen.  This file can be sourced in R or by opening a terminal in the `Section5.2` folder and running.
```bash
Rscript replication5.2.R
```
- `Section5/Section5.3/replication5.3.R` replicates Figures 3 and 4.  This file can be sourced in R or by opening a terminal in the `Section5.3` folder and running
```bash
Rscript replication5.3.R
```
- `conductAnalysis.sh` runs all the above files on this list and prints the output to screen. Run this file by opening a opening a terminal in this folder and running
```bash
bash conductAnalysis.sh
```
