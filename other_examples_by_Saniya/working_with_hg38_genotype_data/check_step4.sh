#!/bin/bash

# ===== Constants =====
pgs_id="PGS005072"
genome_build="GRCh38"
main_folder="hg38_saniya_demo"
input_folder="${main_folder}/extracted_genotypes_bed"
snp_folder="${main_folder}/pgs_snps"

# --------------------
# STEP 1: Get list of BED files with their DNAnexus paths
# --------------------
# Read only lines ending with ".bed"
bed_files=()
while IFS= read -r line; do
    bed_files+=("$line")
done < <(dx ls "$input_folder" --full \
    | grep -E '\.bed$' \
    | grep "$genome_build" \
    | grep "$pgs_id")



if [ ${#bed_files[@]} -eq 0 ]; then
    echo "⚠️ 😧 No BED files found in $input_folder. Exiting."
    exit 1
fi

echo "✅ Found ${#bed_files[@]} BED files in $input_folder."

# --------------------
# STEP 2: Get SNP files
# --------------------
snp_files=()
while IFS= read -r line; do
    if [[ "$line" == *"$genome_build"* ]]; then
        snp_files+=("$line")
    fi
done < <(dx ls "$snp_folder" --full | grep "$pgs_id")

if [ ${#snp_files[@]} -eq 0 ]; then
    echo "⚠️😟 No ${genome_build} Variant-based Chromosome Score files found in $snp_folder containing $pgs_id for $genome_build. Exiting."
    exit 1
fi

echo "✅ Found ${#snp_files[@]} ${genome_build} Variant-based Chromosome-based score files in $snp_folder."
echo "We will now check if we have extracted BED files (after converting BGEN to BED format) for all of these ${#snp_files[@]} files."

# --------------------
# STEP 3: Compare counts
# --------------------
if [ ${#bed_files[@]} -eq ${#snp_files[@]} ]; then
    echo "✅ 😃 The number of BED files matches the number of ${genome_build} Variant-based Chromosome-based score files (${#bed_files[@]})."
    echo "😁 We may proceed to Step 5️⃣  (Merging BED Files into 1 Set of Files 📁)..."
elif [ ${#bed_files[@]} -gt ${#snp_files[@]} ]; then
    diff=$(( ${#bed_files[@]} - ${#snp_files[@]} ))
    echo "⚠️ 😮 There are $diff more BED files than ${genome_build} Variant-based Chromosome-based score files. Please check your input folders and re-run Step 4️⃣  (Going from BGEN ➡️  Bed Files)."
else
    diff=$(( ${#snp_files[@]} - ${#bed_files[@]} ))
    echo "❌ 😟 Uh-oh! We are missing $diff BED files corresponding to some ${genome_build} Variant-based Chromosome-based score parts. Please verify input data before continuing."
    exit 1
fi