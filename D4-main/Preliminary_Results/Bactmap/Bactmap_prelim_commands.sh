#!/usr/bin/env bash

#These are the initial preliminary commands for the Bactmap nextflow workflow 
conda create -n nextflow -c bioconda nextflow 

conda activate nextflow 
#Clone the bactmap repo 
git clone https://github.com/nf-core/bactmap.git

#Make sure docker is open 
cd bactmap 

nextflow run nf-core/bactmap --input samplesheet.csv --reference reference.fa -profile docker --trim --remove_recombination --iqtree --max_memory 15.GB