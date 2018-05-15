#!/bin/bash
cd Ubuntu\ Optimization/UbuntuSetup
bash UbuntuSetup.sh
cd ../../Data
Rscript dyadicDataCreate.R
cd ../Ubuntu\ Optimization/UbuntuOptimization
bash runEstimation.sh
cd ../../Paper\ Results
bash conductAnalysis.sh

