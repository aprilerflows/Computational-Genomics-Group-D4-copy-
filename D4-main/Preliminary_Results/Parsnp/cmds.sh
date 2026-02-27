#!/bin/bash

# conda activate compg_env

REF=~/group4/GCF_000009085.1_ASM908v1_genomic.fna
INPUT_DIR=~/group4/input-sequences
OUT_DIR=~/group4/output_dir
LOG_FILE=log.txt


# Remove previous output if it exists


if [ -d "$OUT_DIR" ]; then
  echo "[INFO] Removing previous output directory: $OUT_DIR"
  rm -rf "$OUT_DIR"
fi


# Run Parsnp with timing + log


echo "[INFO] Running Parsnp..."
/usr/bin/time -f "[Parsnp]\t%M KB\t%E elapsed\t%P CPU" \
  -o time.log \
  parsnp -r "$REF" -d "$INPUT_DIR" -o "$OUT_DIR" > "$LOG_FILE" 2>&1


# Launch FigTree with the tree

TREE_FILE="$OUT_DIR/parsnp.tree"

if [ -f "$TREE_FILE" ]; then
  echo "[INFO] Opening tree in FigTree..."
  figtree "$TREE_FILE"
else
  echo "[ERROR] Tree file not found: $TREE_FILE"
fi
