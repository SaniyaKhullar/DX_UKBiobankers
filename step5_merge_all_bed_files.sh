#!/usr/bin/env bash
# Step 5 by Saniya Khullar: Merge all converted PLINK BED files (PGS-based SNPs) into a single binary PLINK dataset

# ===== Constants =====
pgs_id="PGS000053"
genome_build="GRCh37"
input_folder="/saniya_tutorials/extracted_genotypes_bed"
output_folder="/saniya_tutorials/merged_genotypes"

# ===== Ensure output folder exists =====
mkdir -p "${output_folder}"

# Construct PLINK merge command
echo "🛠️ Building PLINK merge command..."

merge_file_paths_name="bed_files_to_merge_${pgs_id}_${genome_build}_step5.txt"
outname="all_chromosomes_SNPs_merged_${pgs_id}_${genome_build}"

plink_merge_cmd="ls /mnt/project/${input_folder}/*.bim | sed -e 's/.bim//g'> ${merge_file_paths_name}; \
        plink --merge-list ${merge_file_paths_name} --make-bed --out ${outname}"

echo "Command to run:"
# echo "$plink_merge_cmd"

# Submit merge job on DNAnexus
dx run swiss-army-knife \
  -icmd="${plink_merge_cmd}" \
  --tag="new-plink-merge-omicsSNPs" \
  --destination="${output_folder}" \
  --instance-type "mem1_ssd1_v2_x16" \
  --priority="high" \
  --brief --yes

echo "🚀 Submitted PLINK merge job for all chromosomes!"