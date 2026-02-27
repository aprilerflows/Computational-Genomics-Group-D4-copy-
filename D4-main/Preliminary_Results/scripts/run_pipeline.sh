#!/usr/bin/env bash
set -e
set -o pipefail

################################################################################
# Usage:
#   bash run_pipeline.sh [--bactmap] [--parsnp] [--all]
#       --bactmap_csv PATH      : CSV file for nf-core/bactmap
#       --bactmap_ref PATH      : Reference FASTA for nf-core/bactmap
#       --bactmap_profile TYPE  : docker, singularity, or conda (default docker)
#       --max_memory VALUE      : e.g. "15.GB" for Bactmap
#
#       --parsnp_ref PATH       : Reference FASTA for Parsnp
#       --parsnp_dir PATH       : Directory of assemblies
#
# Flags:
#   --bactmap, --parsnp, --all
#   --help or -h for usage
################################################################################

# Defaults
RUN_BACTMAP="false"
RUN_PARSNP="false"

BACTMAP_CSV=""
BACTMAP_REF=""
BACTMAP_PROFILE="docker"
BACTMAP_MAXMEM="15.GB"

PARSNP_REF=""
PARSNP_DIR=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --bactmap)
      RUN_BACTMAP="true"; shift;;
    --parsnp)
      RUN_PARSNP="true"; shift;;
    --all)
      RUN_BACTMAP="true"
      RUN_PARSNP="true"
      shift;;
    --bactmap_csv)
      BACTMAP_CSV="$2"; shift 2;;
    --bactmap_ref)
      BACTMAP_REF="$2"; shift 2;;
    --bactmap_profile)
      BACTMAP_PROFILE="$2"; shift 2;;
    --max_memory)
      BACTMAP_MAXMEM="$2"; shift 2;;
    --parsnp_ref)
      PARSNP_REF="$2"; shift 2;;
    --parsnp_dir)
      PARSNP_DIR="$2"; shift 2;;
    --help|-h)
      grep "^# " "$0" | cut -c4-
      exit 0;;
    *)
      echo "[ERROR] Unknown option: $1"
      exit 1;;
  esac
done

echo "[INFO] Bactmap = $RUN_BACTMAP, Parsnp = $RUN_PARSNP"

################################################################################
# 1) BACTMAP: READ-BASED
################################################################################
if [[ "$RUN_BACTMAP" == "true" ]]; then
  if [[ -z "$BACTMAP_CSV" || -z "$BACTMAP_REF" ]]; then
    echo "[ERROR] Must provide --bactmap_csv and --bactmap_ref for Bactmap"
    exit 1
  fi
  conda activate nextflow_env
  mkdir -p logs results/bactmap
  nextflow run nf-core/bactmap \
    --input "$BACTMAP_CSV" \
    --reference "$BACTMAP_REF" \
    -profile "$BACTMAP_PROFILE" \
    --trim \
    --remove_recombination \
    --iqtree \
    --max_memory "$BACTMAP_MAXMEM" \
    --outdir results/bactmap \
    | tee logs/bactmap.log
fi

################################################################################
# 2) PARSNP + GUBBINS  (Assembly‑based workflow with recombination filtering)
################################################################################
if [[ "$RUN_PARSNP" == "true" ]]; then
  echo "[INFO] Starting Parsnp + Gubbins workflow…"

  if [[ -z "$PARSNP_REF" || -z "$PARSNP_DIR" ]]; then
    echo "[ERROR] --parsnp_ref and --parsnp_dir must be provided for Parsnp."
    exit 1
  fi

  conda activate parsnp_env
  mkdir -p logs results/parsnp

  # 2.1 Multi‑genome alignment with Parsnp
  parsnp \
    -d "$PARSNP_DIR" \
    -r "$PARSNP_REF" \
    -o results/parsnp \
    -p 2 \
    > logs/parsnp.log 2>&1

  # 2.2 Convert XMFA → FASTA alignment (needed by Gubbins)
  harvesttools \
    -x results/parsnp/parsnp.xmfa \
    -M results/parsnp/parsnp.aln \
    >> logs/parsnp.log 2>&1

  # 2.3 Recombination filtering with Gubbins
  echo "[INFO] Running Gubbins on Parsnp alignment…"
  run_gubbins.py \
    -p parsnp \
    results/parsnp/parsnp.aln \
    > logs/gubbins_on_parsnp.log 2>&1

  echo "[INFO] Parsnp + Gubbins workflow completed. Outputs in results/parsnp/."
fi
echo "[INFO] Pipeline finished successfully."
