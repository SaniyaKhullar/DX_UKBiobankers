#!/usr/bin/env bash
# :) convert the extracted BGEN files (for chromosomes 1–22) to PLINK BED format using plink2 with the correct ref-first flag:
# this is Step 4 (by Saniya Khullar) after we have created the filtered bgen files (based on the PGS Catalog SNPs)

# --------------------
# Inputs / configuration
# --------------------
sample_dir="/Bulk/Imputation/UKB imputation from genotype"
main_folder="another_saniya_demo"
pgs_id="PGS002724"
genome_build="GRCh37"
max_len=75 # just in case there is an error:  "1 allele code too long for --set-all-var-ids.
# The longest observed allele code in this dataset has length xx".

bgen_dir="${main_folder}/extracted_genotypes_bgen"
output_folder="${main_folder}/extracted_genotypes_bed"

# Make sure output folder exists
dx mkdir -p "$output_folder"

# --------------------
# STEP 1: Get list of BGEN files with their DNAnexus paths
# --------------------
# dx ls --full outputs usable paths inside workspace
bgen_files=()
while IFS= read -r line; do
    bgen_files+=("$line")
done < <(dx ls "$bgen_dir" --full \
    | grep -E '\.bgen$' \
    | grep -v '\.bgen\.bgi' \
    | grep "$genome_build" \
    | grep "$pgs_id")

if [ ${#bgen_files[@]} -eq 0 ]; then
    echo "⚠️ No BGEN files found in $bgen_dir. Exiting."
    exit 1
fi

echo "Found ${#bgen_files[@]} BGEN files to convert."


# --------------------
# STEP 2: Loop over BGEN files and submit PLINK conversion jobs
# --------------------
total_files=${#bgen_files[@]}
counter=0
for bgen_file_dx in "${bgen_files[@]}"; do
    ((counter++))
    echo "😀🔹😀🔹 Please note: We are processing BGEN file ${counter}/${total_files}..."
    bgen_file=$(basename "$bgen_file_dx")

    # Extract chromosome and optional part info
    if [[ "$bgen_file" =~ _chr([0-9]+)(_p[0-9]+_of_[0-9]+)? ]]; then
        chr="${BASH_REMATCH[1]}"
        part="${BASH_REMATCH[2]}"
    else
        echo "⚠️ Could not extract chromosome from $bgen_file. Skipping."
        continue
    fi

    # Filename prefix for outputs
    filename_prefix="${pgs_id}_${genome_build}_ukb22828_subset_chr${chr}${part}"

    # Expected output files
    bed_file="${output_folder}/${filename_prefix}.bed"
    bim_file="${output_folder}/${filename_prefix}.bim"
    fam_file="${output_folder}/${filename_prefix}.fam"

    # --------------------
    # Check if all output files already exist
    # --------------------
    existing_count=$(dx ls "${output_folder}/" | grep -E "^${filename_prefix}\.(bed|bim|fam)$" | wc -l)

    if [ "$existing_count" -eq 3 ]; then
        echo "✅😇 All output files for chr${chr}${part} already exist in ${output_folder}. Skipping."
        echo "-------------------------------------------"
        continue
    else
        echo "🟡 Missing outputs for chr${chr}${part} (${existing_count}/3 found). Proceeding with conversion."
    fi

    # Corresponding UKB sample file path
    sample_file="ukb22828_c${chr}_b0_v3.sample"
    sample_file_dx="${sample_dir}/${sample_file}"

    # DNAnexus job command inside container
    # plink_cmd="plink2 --bgen ${bgen_file} ref-first --sample ${sample_file} --set-all-var-ids @:#:\\\$r:\\\$a --make-bed --out ${filename_prefix}"
    plink_cmd="plink2 --bgen ${bgen_file} ref-first --sample ${sample_file} --set-all-var-ids @:#:\\\$r:\\\$a --new-id-max-allele-len ${max_len} --make-bed --out ${filename_prefix}"

    echo "😀 Submitting DNAnexus job for chr${chr}${part}"
    echo "BGEN file: ${bgen_file_dx}"
    echo "Sample file: ${sample_file_dx}"
    echo "${plink_cmd}"

    dx run swiss-army-knife \
        -iin="${bgen_dir}/${bgen_file_dx}" \
        -iin="$sample_file_dx" \
        -icmd="$plink_cmd" \
        --tag="bgen-to-bed-chr${chr}${part}" \
        --destination="$output_folder" \
        --instance-type "mem1_ssd1_v2_x16" \
        --priority="high" \
        --brief --yes

    echo "-------------------------------------------"
done