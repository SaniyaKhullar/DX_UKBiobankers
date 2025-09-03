#!/usr/bin/env bash
# Inputs
input_folder="/Bulk/Imputation/UKB imputation from genotype/"
output_folder="/saniya_tutorials/extracted_genotypes_bgen"
pgs_id="PGS000053"
chrom_file="/saniya_tutorials/pgs_snps/chromNames_${pgs_id}.txt"
genome_build="GRCh37"
log_file="variant_counts_${pgs_id}_${genome_build}.log"

> "$log_file" # Clear old log file
dx mkdir -p "${output_folder}" # Create output folder

for chr in {1..22}; do
    # Input files
    bgen_filename="ukb22828_c${chr}_b0_v3.bgen"
    index_filename="ukb22828_c${chr}_b0_v3.bgen.bgi"
    snp_filename="${pgs_id}_chr${chr}_${genome_build}_rsids.txt"
    output_bgen="${pgs_id}_${genome_build}_ukb22828_subset_chr${chr}_rsids.bgen"
    output_found_snps="${pgs_id}_${genome_build}_ukb22828_extractedSNPs_chr${chr}.txt"

    snp_file_dx="/saniya_tutorials/pgs_snps/${snp_filename}" # Check if SNP file exists
    if ! dx ls "$snp_file_dx" &>/dev/null; then
        echo "Please note: ⚠️ SNP file for chromosome ${chr} is not found. 😟 Skipping for rsids."
        continue
    fi

    # DNAnexus job command
    job_cmd="echo 'Processing chromosome ${chr}';
        bgenix -g ${bgen_filename} -incl-rsids ${snp_filename} > ${output_bgen};
        bgenix -g ${output_bgen} -index;
        bgenix -g ${output_bgen} -list > ${output_found_snps};"

    echo "😀 Submitting DNA Nexus job for chromosome ${chr}"
    dx run swiss-army-knife \
        -iin="${input_folder}/${bgen_filename}" \
        -iin="${input_folder}/${index_filename}" \
        -iin="$snp_file_dx" \
        -icmd="${job_cmd}" \
        --tag="pgs_extract_chr${chr}" \
        --instance-type "mem1_ssd1_v2_x72" \
        --destination="${output_folder}" \
        --priority="high" \
        --brief --yes
    echo "-------------------------------------"
done