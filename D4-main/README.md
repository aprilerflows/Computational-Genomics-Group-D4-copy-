# D4 - Comparative Genomics Project 
# Pipelines :

#  Outbreak‑Pipeline — Bactmap + Parsnp (Nextflow DSL 2) (Final) 

A lightweight **nf‑core style** workflow that combines:

| Branch | Toolchain | Goal |
|:-------|:----------|:-----|
| **Read‑based**    | **nf‑core/bactmap** (sub‑workflow) | QC → mapping → SNP calling → recombination removal → phylogeny |
| **Assembly‑based**| **Parsnp → Harvesttools → Gubbins** (local modules) | Core‑genome alignment → alignment conversion → recombination‑masked phylogeny |

Runs with **Docker**, **Singularity**, or **Conda** and supports checkpointing (`-resume`).

---

##  Features
* Dual data support — raw FASTQs *and* pre‑assembled genomes.  
* Reproducible — every process pulls an official BioContainer image.  
* Minimal code — three local modules (~20 lines each) plus nf‑core/bactmap.  
* Resume & scale — inherent Nextflow caching and parallelism.

## System Requirements

> **System Requirements:** The pipeline has been tested on Ubuntu 20.04 and CentOS 7 (x86‑64), but any modern Linux distribution with Docker (or Singularity) and Nextflow ≥ 23.10 should work.  Allocate **≥ 4 CPU cores** (8 + recommended for large isolate sets), **8 GB RAM minimum** (16–32 GB advisable for dozens of genomes or long reads), and **20–50 GB free disk space** to accommodate raw FASTQs, intermediate files, and container layers.  Docker must be able to pull images from Quay/BioContainers, and users should have permission to run the daemon (or use rootless Podman).  On HPC clusters, set comparable per‑job resources and ensure the filesystem supports Nextflow’s work directory (many small files).  Java ≥ 11 is bundled via the Nextflow container, so no additional JDK install is needed on the host.


---

## Folder Layout

outbreak-pipeline/ \
├── nextflow.config # parameters & profiles \
├── main.nf # workflow definition \
├── envs \
&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;├── outbreak_env.yml  
                                    

---

## Prerequisites

| Tool               | Version    | Notes                                    |
|--------------------|------------|------------------------------------------|
| Nextflow           | ≥ 23.10    | `curl -s https://get.nextflow.io \| bash` |
| Docker or Singularity | recent     | for `-profile docker` or `-profile singularity` |
| Conda (optional)   | ≥ 4.8      | for `-profile conda` (you don’t need both) |

> **Why Conda is optional:**  
> You can run all processes in containers (`-profile docker` or `-profile singularity`), OR you can spin up a single Conda env (`envs/outbreak_env.yml`) and run with `-profile conda`. You only need Conda if you choose that mode; otherwise containers suffice.

---

## Input Files
 Branch        | Required                                           |
|---------------|----------------------------------------------------|
| **Bactmap**   | `samplesheet.csv` *(columns: sample,fastq_1,fastq_2)*<br>`reference.fa` |
| **Parsnp**    | `reference.fa`<br>`assemblies/*.fa` directory      |
---

##  Quick Start (Docker)

```bash
# clone
git clone https://github.gatech.edu/compgenomics2025/D4.git
cd Final_results/outbreak-pipeline
conda create -f outbreak_envs.yml
conda activate outbreak env

# run both branches
nextflow run . \
  --all \
  --bactmap_csv data/samplesheet.csv \
  --bactmap_ref data/reference.fa \
  --parsnp_ref  data/reference.fa \
  --parsnp_dir  data/assemblies \
  -profile conda \
  -resume

```
Add -resume to skip completed tasks when re‑running.

###  Key Parameters

#### Parameter	Default	Usage \
* bactmap_csv	–	CSV path for nf‑core/bactmap\
* bactmap_ref	–	Reference FASTA for Bactmap\
* bactmap_profile	docker	Profile forwarded to sub‑workflow\
* bactmap_maxmem	15.GB	Max memory for Bactmap processes\
* parsnp_ref	–	Reference FASTA for Parsnp\
* parsnp_dir	–	Folder with assemblies (*.fasta)\
* parsnp_threads	2	-p threads for Parsnp\
* gubbins_threads	4	CPUs for Gubbins\
* outdir	results	Output root directory 

### Outputs

results/ \
├── bactmap/                 # present if read-based branch executed\
│   └── (QC reports, SNPs, trees…) \
└── parsnp/ \
    &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;├── parsnp.aln \
    &emsp;&emsp;&emsp;&emsp;&emsp;&emsp; ├── parsnp.tree\
    &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;├── parsnp.recombination_predictions.gff\
    &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;└── gubbins/\
        &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;├── parsnp.final_tree.tre\
        &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;└── recombination_statistics.txt\
The transient work/ directory can be purged with nextflow clean -f.\

### Troubleshooting

Issue	Fix\
Cannot run program "docker"	Start Docker daemon or add user to docker group.\
“No assemblies found”	Verify --parsnp_dir path and .fasta extension.\
Out‑of‑memory errors	Raise --bactmap_maxmem or adjust process.memory in config.\


# Bactmap + Parsnp bash Pipeline (Prelim) 

This document provides a comprehensive overview of a two-stage bacterial genomics pipeline that utilizes:

1. **nf-core/bactmap** (read-based analysis)  
2. **Parsnp** (assembly-based analysis)

We chose **bactmap** and **Parsnp** over other possible tools (e.g., GToTree, Snippy) for a more streamlined, automated, and rapid outbreak-focused workflow.

---

## **1. What This Pipeline Does**

1. **nf-core/bactmap (Read-Based)**  
   - Automates QC (optional trimming), read mapping, SNP calling, recombination removal, and phylogenetic analysis.  
   - Uses Nextflow to manage dependencies and parallelization.

2. **Parsnp (Assembly-Based)**  
   - Aligns assembled genome FASTAs (one per sample), detects core SNPs, and builds a phylogenetic tree.  
   - Well-suited for outbreak-scale comparisons when you already have assembled genomes.

---

## **2. Recommended Folder Structure**

- **`data/raw_reads`**: Contains your raw paired-end FASTQ files (e.g., `sample1_R1.fastq.gz`, `sample1_R2.fastq.gz`).  
- **`data/assemblies`**: Contains assembled genome FASTAs (e.g., `sample1_assembly.fasta`).  
- **`envs/`**: Holds the YAML files for conda environments.  
- **`results/`**: Where final outputs for each step are stored.  
- **`logs/`**: Pipeline logs, helpful for troubleshooting.  
- **`scripts/`**: Contains your main pipeline shell script.

---

## **3. System Requirements**

- **Operating System**: Linux-based (tested on Ubuntu 20.04 / CentOS 7).  
- **CPU Cores**: At least 4 (8+ recommended for larger datasets).  
- **RAM**: 8 GB minimum, 16–32 GB recommended for large outbreak studies.  
- **Disk Space**: ~20–50 GB free, depending on sample count and read/assembly sizes.  
- **Conda**: v4.8+ recommended (or Mamba).  
- **Docker or Singularity** (optional, but recommended if you use containerization with Nextflow).

---

## **4. Conda Environments**

### 4.1 **env_nextflow.yml** (for Bactmap)

```yaml
name: nextflow_env
channels:
  - bioconda
  - conda-forge
dependencies:
  - nextflow
  - openjdk
  - python=3.9
  # add other dependencies or pinned versions if needed
```
### 4.2 **env_parsnp.yml** (for Parsnp)

```yaml
name: parsnp_env
channels:
  - bioconda
  - conda-forge
dependencies:
  # Core alignment + tree visualisation
  - parsnp                    # multi‑genome alignment
  - harvesttools              # converts .xmfa ↔︎ .aln, extracts SNPs, etc.
  - figtree                   # optional GUI for trees

  # Recombination filtering on the Parsnp alignment
  - gubbins                   # run_gubbins.py
  - python=3.9                # gubbins dependency
```

To create either environment 

```bash
conda env create -f envs/env_name.yml
```

## 5. How to Run
### 5.1 Sample Command Overview
Bactmap Only (read-based):

```bash
bash scripts/run_pipeline.sh \
  --bactmap \
  --bactmap_csv samplesheet.csv \
  --bactmap_ref reference.fa
 ``` 
Parsnp Only (assembly-based):

```bash
bash scripts/run_pipeline.sh \
  --parsnp \
  --parsnp_ref path/to/parsnp_ref.fasta \
  --parsnp_dir path/to/assemblies
```
Both:

```bash
bash scripts/run_pipeline.sh \
  --all \
  --bactmap_csv samplesheet.csv \
  --bactmap_ref reference.fa \
  --parsnp_ref reference.fasta \
  --parsnp_dir data/assemblies
```

### 5.2 Required Inputs
Bactmap
A CSV samplesheet (e.g., samplesheet.csv) with columns:

```lua
sample,fastq_1,fastq_2
sample1,/abs/path/sample1_R1.fastq.gz,/abs/path/sample1_R2.fastq.gz
sample2,/abs/path/sample2_R1.fastq.gz,/abs/path/sample2_R2.fastq.gz
A reference genome FASTA (e.g., reference.fa).
```
Parsnp

A reference FASTA (e.g., parsnp_ref.fasta).
A directory containing your assembled FASTAs.

# Tools used : 
## Parsnp
- **CPU Architecture**: x86_64 (2-core)
- **Machine**: HP Spectre
- **Operating System**: Ubuntu 22.04 LTS
- **Parsnp Version**: v1.5.6
- **OS Compatibility**: Linux, macOS - Windows users are advised to use WSL or a virtual machine for compatibility.
- **Input: Assemblies (.fasta or .fna files)**
- **Output:**
- ### 📄 `parsnp.xmfa`
- **Description**: XMFA (Multiple Alignment Format) file representing the core genome alignment of all input genomes.
- **Usage**: Can be viewed with alignment viewers or converted to other formats. Required for downstream visualization and analysis (e.g., iTOL or Gingr).
- ### 🌳 `parsnp.tree`
- **Description**: Newick-format phylogenetic tree based on the core genome alignment.
- **Usage**: Input for tree visualization tools (e.g., FigTree, iTOL). Shows the evolutionary relationships among input genomes.
- ### 📦 `parsnp.ggr`
- **Description**: Binary compressed core genome representation.
- **Usage**: For internal use by Gingr for real-time, interactive exploration of genome alignments and variants.
- ### `parsnpAligner.log`
- **Description**: Log file capturing runtime details, process status, and any warnings or errors during execution.
- **Usage**: Helps with debugging, reviewing runtime parameters, or verifying reproducibility.
- ### ⚙️ `parsnpAligner.ini`
- **Description**: Configuration file generated by Parsnp to document the parameters and settings used in the run.
- **Usage**: Essential for reproducibility and understanding specific aligner behavior.
## Bactmap
## Overview

This workflow utilizes the [nf-core/bactmap](https://github.com/nf-core/bactmap) pipeline to perform mapping-based phylogenetic analysis of bacterial whole-genome sequencing (WGS) data. The pipeline maps short reads to a reference genome, calls and filters variants, constructs pseudogenomes, and optionally generates phylogenetic trees.

## System Configuration

- **Hardware**: Windows Desktop  
- **Memory**: 32 GB RAM  
- **Operating System**: Windows 10 WSL2 Ubuntu
- **Workflow Manager**: Nextflow  
- **Environment Management**: Conda  
- **Containerization**: Docker  

## Installation and Setup

1. **Install Conda**  
   Ensure that Conda is installed on your system.

2. **Create and Activate Conda Environment**:
   ```bash
   conda create -n bactmap_env nextflow -c bioconda -c conda-forge
   conda activate bactmap_env
3. Install Docker using the official website and guidelines https://docs.docker.com/get-started/
4. Input Preparation: Prepare a csv sheet with the samples and filepaths, as well as any extra metadata you want to include
   ```bash
   sample,fastq_1,fastq_2
   Sample1,fastqs/Sample1_1.fastq.gz,fastqs/Sample1_2.fastq.gz
   Sample2,fastqs/Sample2_1.fastq.gz,fastqs/Sample2_2.fastq.gz

5. Running the pipeline:
Once everything is prepared you can run the pipeline with the following command:
```bash
nextflow run nf-core/bactmap --input samplesheet.csv --reference reference.fa -profile docker --trim --remove_recombination --iqtree --max_memory 15.GB

--trim trims the reads
--remove_recombination uses Gubbins to account for recombination 
--iqtree uses IQ-Tree for the phylogenetic tree creation 
--max_memory is to set whatever max ram allocation works for your system
```
Upon successful execution, the pipeline will generate a results/ directory containing the following:
```bash
fastp/: Reports from read trimming
rasusa/: Subsampled FASTQ files
samtools/: Sorted BAM files and associated statistics
variants/: Filtered VCF files containing variants
pseudogenomes/: Pseudogenome FASTA files and alignments
gubbins/: Recombination analysis outputs (if enabled)
snpsites/: Alignments with only informative positions
rapidnj/, fasttree/, iqtree/, raxmlng/: Phylogenetic trees generated by respective tools (if enabled)
multiqc/: Aggregated quality control reports
pipeline_info/: Execution reports and logs
For a complete breakdown, refer to the nf-core/bactmap output documentation.
```
# Snippy

## Overview

This project uses [Snippy](https://github.com/tseemann/snippy) to identify core SNPs across multiple bacterial isolates using short-read WGS data. Reads were quality-trimmed using `fastp`, aligned to a reference genome with `Snippy`, and SNP alignments were post-processed with `snippy-core`, `Gubbins`, and `IQ-TREE` to produce a recombination-filtered phylogeny.

## System Configuration

- **Hardware**: MacBook Pro M2 Max  
- **Memory**: 32 GB RAM  
- **Operating System**: macOS  
- **Environment Management**: Conda  
- **Main Tools**: fastp, Snippy, Gubbins, IQ-TREE  

## Installation and Setup

1. **Create and Activate Conda Environment**:
   ```bash
   conda create -n D4 -c bioconda fastp gubbins snippy
   conda activate D4
2. Prepare the input reads in a folder of your choice
3. Read cleaning with fastp:
   ```bash
   for R1 in ~/Desktop/BIOL_7210/Team_D_Data/2025_Team_D/*_R1_001.fastq.gz; do
    FILENAME=$(basename "$R1")
    BASE=$(echo "$FILENAME" | gsed 's/_R1_001.fastq.gz//')
    R2=~/Desktop/BIOL_7210/Team_D_Data/2025_Team_D/${BASE}_R2_001.fastq.gz
    OUT_R1="${BASE}_R1_paired.fastq.gz"
    OUT_R2="${BASE}_R2_paired.fastq.gz"
    JSON_REPORT="${BASE}_fastp.json"
    HTML_REPORT="${BASE}_fastp.html"

    fastp \
        -i "$R1" \
        -I "$R2" \
        -o "$OUT_R1" \
        -O "$OUT_R2" \
        --thread 4 \
        --html "$HTML_REPORT" \
        --json "$JSON_REPORT"
   done
   
5. SNP Calling with Snippy:
   ```bash
   for read in /D4/cleaned_reads/*_R1_paired.fastq.gz; do
    SAMPLE=$(basename "$read" _R1_paired.fastq.gz)
    R2=/D4/cleaned_reads/${SAMPLE}_R2_paired.fastq.gz
    OUTDIR=~/D4/snippy_output/mysnps-${SAMPLE}

    snippy \
        --cpus 10 \
        --outdir "$OUTDIR" \
        --ref ~/D4/snippy_ref/GCF_000009085.1_ASM908v1_genomic.fna \
        --R1 "$read" \
        --R2 "$R2"
   done

7. Create Core Gene Alignment:
   ```bash
   snippy-core \
     --prefix ~/D4/snippy_output/core \
     --ref ~/D4/snippy_ref/GCF_000009085.1_ASM908v1_genomic.fna \
     ~/D4/snippy_output/mysnps-*
9. Clean the Full alignment:
    ```bash
   snippy-clean_full_aln core.full.aln > clean.full.aln
11. Run Gubbins:
    ```bash
      run_gubbins.py -p gubbins clean.full.aln
13. Extract Core SNP-Sites:
    ```bash
      snp-sites -c gubbins.filtered_polymorphic_sites.fasta > clean.core.aln
15. Build Tree with IQ-Tree:
    ```bash
    iqtree \
     -nt AUTO \
     -st DNA \
     -s ~/D4/snippy_output/clean.core.aln \
     -bb 1000 \
     -alrt 1000
17. Outputs:
    ```bash
      *_paired.fastq.gz: Cleaned reads from fastp
      snippy_output/mysnps-*: Per-sample variant calling output
      core.full.aln: Core genome alignment across samples
      clean.full.aln: Cleaned alignment after removing ambiguous sites
      gubbins.filtered_polymorphic_sites.fasta: Recombination-filtered alignment
      clean.core.aln: Final SNP alignment for phylogenetic inference
      .treefile, .iqtree, .log: IQ-TREE outputs including the phylogenetic tree


# GToTree

## Overview

GToTree is a scalable and user-friendly tool for building phylogenomic trees from genome assemblies. It uses single-copy marker genes (SCGs) to generate concatenated alignments and construct trees using FastTree or IQ-TREE.

## System Configuration

- **Operating System**: macOS
- **CPU**: 2 cores, Intel 
- **RAM**: 8 GB
- **Conda Version**: 25.3.1
- **GToTree Version**: 1.8.4

---

## Installation and Setup

1. Create Conda Environment and Install Dependencies
2. Run GToTree + figtree

```bash
conda create -n gtt_env python=3.9
conda activate gtt_env

conda install -c astrobiomike -c conda-forge -c bioconda gtotree
conda install -c bioconda -c conda-forge -c defaults mafft snp-sites figtree

time gtotree -f input_files.txt -H Epsilonproteobacteria -o Group4_prelim &> gtotree_run.log
figtree Group4_prelim/Group4_prelim.tre
