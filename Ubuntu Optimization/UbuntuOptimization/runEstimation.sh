#!/bin/bash
sudo pip install numpy==1.8.1
python convertData_R2py.py
sudo pip install numpy --upgrade
python mainModelEstimationCode.py
