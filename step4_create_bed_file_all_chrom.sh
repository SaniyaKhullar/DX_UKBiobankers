#!/usr/bin/env bash
# :) convert the extracted BGEN files (for chromosomes 1–22) to PLINK BED format using plink2 with the correct ref-first flag:
# this is Step 4 (by Saniya Khullar) after we have created the filtered bgen files (based on the PGS Catalog SNPs)

# Inputs
bgen_dir="/saniya_tutorials/extracted_genotypes_bgen"
sample_dir="/Bulk/Imputation/UKB imputation from genotype"
output_folder="/saniya_tutorials/extracted_genotypes_bed"
pgs_id="PGS000053"
genome_build="GRCh37"
dx mkdir -p "${output_folder}" # Create output folder

for chr in {1..22}; do
    filename_prefix="${pgs_id}_${genome_build}_ukb22828_subset_chr${chr}_rsids"
    bgen_filename="${filename_prefix}.bgen"
    sample_filename="ukb22828_c${chr}_b0_v3.sample"

    echo ":) Converting BGEN to BED for chromosome ${chr}"
    echo "BGEN file: ${bgen_filename}"
    echo "Sample file: ${sample_filename}"

    bgen_file_dx="${bgen_dir}/${bgen_filename}" # Check if bgen file exists
    if ! dx ls "$bgen_file_dx" &>/dev/null; then
        echo "⚠️ Please note that the filtered BGEN file for chromosome ${chr} is not found. 😟 Skipping for bed file."
        continue
    fi

    # DNAnexus job Command to run inside swiss-army-knife
    # UKB convention: reference is always listed first so we use ref-first.
    # For instance for: 20:55018260_T_C  rs7274581  20  55018260  2  T  C
    # Here, first_allele = T (the reference allele from GRCh37), alternative_alleles = C.
    # That matches the UKBB convention: reference is always listed first.
    extract_cmd="plink2 --bgen ${bgen_filename} ref-first --sample ${sample_filename} --make-bed --out ${filename_prefix}"

    echo "😀 Submitting DNA Nexus job for chromosome ${chr}"
    echo "${extract_cmd}"

    # Submit DNAnexus job
    dx run swiss-army-knife \
        -iin="${bgen_dir}/${bgen_filename}" \
        -iin="${sample_dir}/${sample_filename}" \
        -icmd="${extract_cmd}" \
        --tag="bgen-to-bed-chr${chr}" \
        --destination="${output_folder}" \
        --instance-type "mem1_ssd1_v2_x16" \
        --priority="high" \
        --brief --yes

    echo "Submitted PLINK conversion job for chr${chr}"
    echo "-------------------------------------------"

done