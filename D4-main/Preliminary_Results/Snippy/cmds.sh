###Preliminiary bash commands pipeline
conda create -n D4 -c bioconda fastp gubbins snippy
for R1 in ~/Desktop/BIOL_7210/Team_D_Data/2025_Team_D/*_R1_001.fastq.gz; do     FILENAME=$(basename "$R1");     BASE=$(echo "$FILENAME" | gsed 's/_R1_001.fastq.gz//');      R2=~/Desktop/BIOL_7210/Team_D_Data/2025_Team_D/${BASE}_R2_001.fastq.gz;      OUT_R1="${BASE}_R1_paired.fastq.gz";     OUT_R2="${BASE}_R2_paired.fastq.gz";     JSON_REPORT="${BASE}_fastp.json";     HTML_REPORT="${BASE}_fastp.html";      fastp         -i "$R1"         -I "$R2"         -o "$OUT_R1"         -O "$OUT_R2"         --thread 4         --html "$HTML_REPORT"         --json "$JSON_REPORT"; done

for read in ~/D4/cleaned_reads/*_R1_paired.fastq.gz; do   SAMPLE=$(basename "$read" _R1_paired.fastq.gz);    R2=~/D4/cleaned_reads/${SAMPLE}_R2_paired.fastq.gz;    OUTDIR=~/D4/snippy_output/mysnps-${SAMPLE};    snippy     --cpus 10     --outdir "$OUTDIR"     --ref ~/D4/snippy_ref/GCF_000009085.1_ASM908v1_genomic.fna     --R1 "$read"     --R2 "$R2"; done

snippy-core --prefix ~/D4/snippy_output/core --ref ~/D4/snippy_ref/GCF_000009085.1_ASM908v1_genomic.fna ~/D4/snippy_output/mysnps-*

snippy-clean_full_aln core.full.aln > clean.full.aln

run_gubbins.py -p gubbins clean.full.aln

snp-sites -c gubbins.filtered_polymorphic_sites.fasta > clean.core.aln

iqtree  -nt AUTO  -st DNA -s ~/D4/snippy_output/clean.core.aln -bb 1000  -alrt 1000
