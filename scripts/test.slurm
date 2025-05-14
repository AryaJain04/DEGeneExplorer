#!/bin/bash
#SBATCH --job-name=multi_nextflow
#SBATCH --output=logs/multi_nextflow_%j.out
#SBATCH --error=logs/multi_nextflow_%j.err
#SBATCH --time=04:00:00
#SBATCH --partition=work
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=64G
#SBATCH --export=ALL

# Enable Proxy (if needed)
export http_proxy=http://proxy:80
export https_proxy=http://proxy:80
export HTTP_PROXY=http://proxy:80
export HTTPS_PROXY=http://proxy:80

# List of studies
STUDIES=("SRP081605" "SRP092402" "SRP098758" "SRP116272" "SRP136102" "SRP152983" "SRP155483" "SRP212755" "SRP071965")

# Loop through studies
for study in "${STUDIES[@]}"; do
    echo "Processing study: $study"
    
    # Run Nextflow differential abundance
    nextflow run nf-core/differentialabundance \
        -r 1.5.0 \
        --input Metadata/standardized_${study}.csv \
        --contrasts Contrast/${study}_contrast.csv \
        --matrix counts/${study}_raw_count.csv \
        --max_memory '32 GB' \
        --outdir result/${study} \
        -profile singularity \
        -resume

    echo "Completed Nextflow for $study"

    # === Run annotation R script ===
    DE_RESULT="result/${study}/tables/differential/condition_Control_Case.deseq2.results.tsv"
    ANNOT_FILE="annotation.tsv"
    OUTPUT_FILE="result/${study}/tables/differential/deseq2.annotated.tsv"

    if [ -f "$DE_RESULT" ]; then
        echo "Annotating results for $study"
        Rscript annotate_results.R "$DE_RESULT" "$ANNOT_FILE" "$OUTPUT_FILE"
    else
        echo "⚠️ DE result file not found for $study: $DE_RESULT"
    fi
done

echo "✅ All studies processed and annotated!"
