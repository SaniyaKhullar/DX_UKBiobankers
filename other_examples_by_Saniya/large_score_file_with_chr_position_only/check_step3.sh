#!/bin/bash

# ------------------------------------------------------------
#                   Inputs / configuration
# ------------------------------------------------------------

sample_dir="/Bulk/Imputation/UKB imputation from genotype"
main_folder="another_saniya_demo"
pgs_id="PGS002724"
genome_build="GRCh37"

bgen_dir="${main_folder}/extracted_genotypes_bgen"
snp_folder="${main_folder}/pgs_snps"

# ------------------------------------------------------------
# STEP 1: Get list of BGEN files with their DNAnexus paths
# ------------------------------------------------------------
# dx ls --full outputs usable paths inside workspace
# ------------------------------------------------------------

bgen_files=()
while IFS= read -r line; do
    bgen_files+=("$line")
done < <(dx ls "$bgen_dir" --full \
    | grep -E '\.bgen$' \
    | grep -v '\.bgen\.bgi' \
    | grep "$genome_build" \
    | grep "$pgs_id")

if [ ${#bgen_files[@]} -eq 0 ]; then
    echo "⚠️ No BGEN files found in $bgen_dir containing $pgs_id. Exiting."
    exit 1
fi

echo "✅ Found ${#bgen_files[@]} BGEN files that were extracted for ${pgs_id} with human build $genome_build."

# ------------------------------------------------------------
#       STEP 2: Collect SNP files (full DNAnexus paths)
# ------------------------------------------------------------

snp_files=()
while IFS= read -r line; do
    if [[ "$line" == *"$genome_build"* ]]; then
        snp_files+=("$line")
    fi
done < <(dx ls "$snp_folder" --full | grep "$pgs_id")

if [ ${#snp_files[@]} -eq 0 ]; then
    echo "⚠️😟 No ${genome_build} Variant-based Chromosome Score files found in $snp_folder containing $pgs_id. Exiting."
    exit 1
fi


echo "Please note: There are ${#snp_files[@]} ${genome_build} Variant-based Chromosome Score files for ${pgs_id} in ${snp_folder}."
echo "We will now check if we have extracted BGEN files for all of these ${#snp_files[@]} files."


# ----------------------------------------------------------------------------------------------------
#   STEP 3: Compare counts (defensive programming - ensure that we have found the correct counts")
# ----------------------------------------------------------------------------------------------------

if [ ${#bgen_files[@]} -eq ${#snp_files[@]} ]; then
    echo "✅ 😃 Yay! The number of BGEN files matches the number of ${genome_build} Variant-based Chromosome-based score files (${#bgen_files[@]}) for ${pgs_id}."
    echo "😁 We may proceed to Step 4️⃣  (Going from BGEN ➡️  Bed Files)..."
elif [ ${#bgen_files[@]} -gt ${#snp_files[@]} ]; then
    diff=$(( ${#bgen_files[@]} - ${#snp_files[@]} ))
    echo "⚠️ 😮 There are $diff more BGEN files than ${genome_build} Variant-based Chromosome-based score files for ${pgs_id}. Please check your input folders."
else
    diff=$(( ${#snp_files[@]} - ${#bgen_files[@]} ))
    echo "❌ 😟 Uh-oh! Missing $diff BGEN files corresponding to some ${genome_build} Variant-based Chromosome-based score parts for ${pgs_id}. Please verify input data before continuing and re-run Step 3️⃣."
    exit 1
fi