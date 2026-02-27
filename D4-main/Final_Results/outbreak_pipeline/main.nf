#!/usr/bin/env nextflow
nextflow.enable.dsl=2

workflow {
    if( params.all || params.bactmap )  Bactmap()
    if( params.all || params.parsnp  )  Parsnp()
}

process Bactmap {
    tag "bactmap"

    publishDir "results/bactmap", mode: 'copy'
    publishDir "logs",           mode: 'copy', pattern: "bactmap.log"

    script:
    """
    mkdir -p logs results/bactmap

    nextflow run nf-core/bactmap \
      --input      ${projectDir}/${params.bactmap_csv} \
      --reference  ${projectDir}/${params.bactmap_ref} \
      -profile     conda \
      --trim --remove_recombination --iqtree \
      --max_memory ${params.bactmap_maxmem} \
      --outdir     results/bactmap \
      &> logs/bactmap.log
    """
}

process Parsnp {
    tag "parsnp"

    publishDir "results/parsnp", mode: 'copy'
    publishDir "logs",           mode: 'copy', pattern: "parsnp.log,gubbins_on_parsnp.log"

    script:
    """
    mkdir -p logs results/parsnp

    parsnp \
      -d ${projectDir}/${params.parsnp_dir} \
      -r ${projectDir}/${params.parsnp_ref} \
      -o parsnp_out \
      -p ${task.cpus} \
      &> logs/parsnp.log

    harvesttools \
      -x parsnp_out/parsnp.xmfa \
      -M parsnp_out/parsnp.aln \
      &>> logs/parsnp.log

   set +e
    run_gubbins.py \
      -p parsnp parsnp_out/parsnp.aln \
      &> logs/gubbins_on_parsnp.log
set -e
    cp -r parsnp_out/* results/parsnp/
    """
}
