#!/bin/bash
Rscript analyticalSE_code.r
cd Section4
Rscript Table1.r
cd ../Section5/Section5.0
Rscript replication5.0.R
cd ../Section5.1
Rscript Table2.R
cd ../Section5.2
Rscript replication5.2.R
cd ../Section5.3
Rscript replication5.3.R
