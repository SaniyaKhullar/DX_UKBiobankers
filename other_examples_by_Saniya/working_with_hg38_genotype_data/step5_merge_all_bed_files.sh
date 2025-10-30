#!/usr/bin/env bash
# Step 5 by Saniya Khullar: Merge all converted PLINK BED files (PGS-based SNPs) into a single binary PLINK dataset

# ===== Constants =====
pgs_id="PGS005072"
genome_build="GRCh38"
main_folder="hg38_saniya_demo"
input_folder="${main_folder}/extracted_genotypes_bed"
output_folder="${main_folder}/merged_genotypes"
snp_folder="${main_folder}/pgs_snps"

# --------------------
# STEP 1: Get list of BED files with their DNAnexus paths
# --------------------
bed_files=()

# Read only lines ending with ".bed"
while IFS= read -r line; do
    if [[ "$line" == *.bed ]]; then
        bed_files+=("$line")
    fi
done < <(dx ls "$input_folder" --full)

if [ ${#bed_files[@]} -eq 0 ]; then
    echo "⚠️ No BED files found in $input_folder. Exiting."
    exit 1
fi

echo "✅ Found ${#bed_files[@]} BED files in $input_folder."

# ===== Ensure output folder exists =====
mkdir -p "${output_folder}"

# Construct PLINK merge command
echo "🛠️ Building PLINK merge command..."

merge_file_paths_name="bed_files_to_merge_${pgs_id}_${genome_build}_step5.txt"
outname="all_chromosomes_SNPs_merged_${pgs_id}_${genome_build}"

plink_merge_cmd="ls /mnt/project/${input_folder}/*.bim | sed -e 's/.bim//g'> ${merge_file_paths_name}; \
        plink --merge-list ${merge_file_paths_name} --make-bed --set-missing-var-ids @:# --out ${outname}"
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