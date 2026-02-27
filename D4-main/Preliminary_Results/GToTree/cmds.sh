conda init
source \.bash_profile

conda create -n gtt_env python=3.9
conda activate gtt_env

conda install -c astrobiomike -c conda-forge -c bioconda gtotree
conda install -c bioconda -c conda-forge -c defaults mafft snp-sites figtree

touch fasta_files.txt

time gtotree -f input_files.txt -H Epsilonproteobacteria -o Group4_prelim &> gtotree_run.log
figtree Group4_prelim/Group4_prelim.tre
