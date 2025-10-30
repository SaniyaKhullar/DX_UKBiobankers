#!/usr/bin/env bash

# --------------------
# Inputs / configuration
# --------------------
input_folder="/Bulk/Imputation/UKB imputation from genotype/"
main_folder="another_saniya_demo"
output_folder="${main_folder}/extracted_genotypes_bgen"
pgs_id="PGS002724"
genome_build="GRCh37"
snp_folder="${main_folder}/pgs_snps"
log_file="variant_counts_${pgs_id}_${genome_build}.log"

> "$log_file" # Clear old log file
dx mkdir -p "$output_folder" # Create output folder

# --------------------
# STEP 1: Collect SNP files (full DNAnexus paths)
# --------------------
snp_files=()
while IFS= read -r line; do
    snp_files+=("$line")
done < <(dx ls "$snp_folder")

if [ ${#snp_files[@]} -eq 0 ]; then
    echo "⚠️ No SNP files found in $snp_folder. Exiting."
    exit 1
fi

echo "Found ${#snp_files[@]} SNP files."

# --------------------
# STEP 2: Loop over SNP files and submit jobs
# --------------------
total_files=${#snp_files[@]}
counter=0
for snp_file_dx in "${snp_files[@]}"; do
    ((counter++))
    echo "😀🔹😀🔹 Please note: We are processing BGEN Subsetting for Variant Score File ${counter}/${total_files}..."
    # Use basename inside container for regex and bgenix
    snp_file=$(basename "$snp_file_dx")

    # Extract chromosome number
    if [[ "$snp_file" =~ _chr([0-9]+)_ ]]; then
        chr="${BASH_REMATCH[1]}"
    else
        echo "⚠️ Could not extract chromosome from $snp_file. Skipping."
        continue
    fi

    # Extract part info if present (_pX_of_Y)
    part=""
    if [[ "$snp_file" =~ _p([0-9]+)_of_([0-9]+) ]]; then
        part="_p${BASH_REMATCH[1]}_of_${BASH_REMATCH[2]}"
    fi

    echo "Preparing job for SNP file: $snp_file | chr=${chr} | part=${part}"

    # Input BGEN files (DNAnexus paths)
    bgen_dx_path="${input_folder}/ukb22828_c${chr}_b0_v3.bgen"
    index_dx_path="${input_folder}/ukb22828_c${chr}_b0_v3.bgen.bgi"

    # Output files
    output_bgen="${pgs_id}_${genome_build}_ukb22828_subset_chr${chr}${part}.bgen"
    output_found_snps="${pgs_id}_${genome_build}_ukb22828_extractedSNPs_chr${chr}${part}.txt"

    # --------------------
    # Check if output files exist using dx describe
    # --------------------
    bgen_exists=$(dx describe "${output_folder}/${output_bgen}" &> /dev/null && echo 1 || echo 0)

    if [[ $bgen_exists -eq 1 ]]; then
        echo ":white_check_mark::innocent: Output files for chr${chr}${part} already exist in ${output_folder}. Skipping."
        echo "-------------------------------------------"
        continue
    else
        echo ":large_yellow_circle: Missing outputs for chr${chr}${part}. Proceeding with extraction."
        echo "Preparing job for SNP file: $snp_file | chr=${chr} | part=${part}"

    fi

    # DNAnexus job command: use basename inside container
    job_cmd="echo 'Processing chromosome ${chr}${part}'; \
bgenix -g $(basename "$bgen_dx_path") -incl-range $(basename "$snp_file_dx") > ${output_bgen}; \
bgenix -g ${output_bgen} -index;"

    # Submit DNAnexus job
    echo "😀 Submitting DNAnexus job for chromosome ${chr}${part}"
    dx run swiss-army-knife \
    -iin="$bgen_dx_path" \
    -iin="$index_dx_path" \
    -iin="${snp_folder}/${snp_file_dx}" \
    -icmd="$job_cmd" \
    --tag="pgs_extract_chr${chr}${part}" \
    --instance-type "mem1_ssd1_v2_x72" \
    --destination="$output_folder" \
    --priority="high" \
    --brief --yes

    echo "-------------------------------------"
done