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

    # dx run swiss-army-knife \
    #     -iin="$bgen_dx_path" \
    #     -iin="$index_dx_path" \
    #     -iin="$snp_file_dx" \   # Full DNAnexus path here!
    #     -icmd="$job_cmd" \
    #     --tag="pgs_extract_chr${chr}${part}" \
    #     --instance-type "mem1_ssd1_v2_x72" \
    #     --destination="$output_folder" \
    #     --priority="high" \
    #     --brief --yes
# #!/usr/bin/env bash

# # --------------------
# # Inputs / configuration
# # --------------------
# input_folder="/Bulk/Imputation/UKB imputation from genotype/"
# output_folder="another_saniya_demo/extracted_genotypes_bgen"
# pgs_id="PGS002724"
# genome_build="GRCh37"
# snp_folder="another_saniya_demo/pgs_snps"
# log_file="variant_counts_${pgs_id}_${genome_build}.log"

# > "$log_file" # Clear old log file
# dx mkdir -p "$output_folder" # Create output folder

# # --------------------
# # STEP 1: Collect SNP files (full DNAnexus paths)
# # --------------------
# snp_files=()
# while IFS= read -r line; do
#     snp_files+=("$line")
# done < <(dx ls "$snp_folder")

# if [ ${#snp_files[@]} -eq 0 ]; then
#     echo "⚠️ No SNP files found in $snp_folder. Exiting."
#     exit 1
# fi

# echo "Found ${#snp_files[@]} SNP files."

# # --------------------
# # STEP 2: Loop over SNP files and submit jobs
# # --------------------
# for snp_file_dx in "${snp_files[@]}"; do
#     # ✅ Use basename instead of dx describe
#     snp_file=$(basename "$snp_file_dx")

#     # Extract chromosome number
#     if [[ "$snp_file" =~ _chr([0-9]+)_ ]]; then
#         chr="${BASH_REMATCH[1]}"
#     else
#         echo "⚠️ Could not extract chromosome from $snp_file. Skipping."
#         continue
#     fi

#     # Extract part info if present (_pX_of_Y)
#     part=""
#     if [[ "$snp_file" =~ _p([0-9]+)_of_([0-9]+) ]]; then
#         part="_p${BASH_REMATCH[1]}_of_${BASH_REMATCH[2]}"
#     fi

#     echo "Preparing job for SNP file: $snp_file | chr=${chr} | part=${part}"

#     # Input BGEN files (DNAnexus paths)
#     bgen_dx_path="${input_folder}/ukb22828_c${chr}_b0_v3.bgen"
#     index_dx_path="${input_folder}/ukb22828_c${chr}_b0_v3.bgen.bgi"

#     # Output files
#     output_bgen="${pgs_id}_${genome_build}_ukb22828_subset_chr${chr}${part}.bgen"
#     output_found_snps="${pgs_id}_${genome_build}_ukb22828_extractedSNPs_chr${chr}${part}.txt"

#     # Job command (use basenames inside container)
#     job_cmd="echo 'Processing chromosome ${chr}${part}';
#              bgenix -g $(basename "$bgen_dx_path") -incl-range $(basename "$snp_file_dx") > ${output_bgen};
#              bgenix -g ${output_bgen} -index;
#              # bgenix -g ${output_bgen} -list > ${output_found_snps};"

#     # Submit DNAnexus job
#     echo "😀 Submitting DNAnexus job for chromosome ${chr}${part}"
#     dx run swiss-army-knife \
#         -iin="$bgen_dx_path" \
#         -iin="$index_dx_path" \
#         -iin="$snp_file_dx" \
#         -icmd="$job_cmd" \
#         --tag="pgs_extract_chr${chr}${part}" \
#         --instance-type "mem1_ssd1_v2_x72" \
#         --destination="$output_folder" \
#         --priority="high" \
#         --brief --yes

#     echo "-------------------------------------"
# done



# #!/usr/bin/env bash

# # Inputs
# input_folder="/Bulk/Imputation/UKB imputation from genotype/"
# output_folder="another_saniya_demo/extracted_genotypes_bgen"
# pgs_id="PGS002724"
# genome_build="GRCh37"

# # Folder on DNAnexus where SNP files are stored
# snp_folder="another_saniya_demo/pgs_snps"

# # Clear log file
# log_file="variant_counts_${pgs_id}_${genome_build}.log"
# > "$log_file"

# dx mkdir -p "${output_folder}"

# # --- STEP 1: Build list of SNP files locally (before submission) ---
# snp_files=()
# while IFS= read -r f; do
#     snp_files+=("$f")
# done < <(dx ls "$snp_folder" --brief)

# if [ ${#snp_files[@]} -eq 0 ]; then
#     echo "⚠️ No SNP files found in ${snp_folder}. Exiting."
#     exit 1
# fi

# echo "Found ${#snp_files[@]} SNP files."

# # --- STEP 2: Loop over all SNP files and submit DNAnexus jobs ---
# for snp_file_dx in "${snp_files[@]}"; do
#     # Get basename for regex and inside container
#     snp_file=$(basename "$snp_file_dx")

#     # Extract chromosome number
#     if [[ "$snp_file" =~ _chr([0-9]+)_ ]]; then
#         chr="${BASH_REMATCH[1]}"
#     else
#         echo "⚠️ Could not extract chromosome from $snp_file. Skipping."
#         continue
#     fi

#     # Extract part info if present
#     part=""
#     if [[ "$snp_file" =~ _p([0-9]+)_of_([0-9]+) ]]; then
#         part="_p${BASH_REMATCH[1]}_of_${BASH_REMATCH[2]}"
#     fi

#     echo "Preparing job for SNP file: $snp_file | chr=${chr} | part=${part}"

#     # Input BGEN files (DNAnexus paths)
#     bgen_dx_path="${input_folder}/ukb22828_c${chr}_b0_v3.bgen"
#     index_dx_path="${input_folder}/ukb22828_c${chr}_b0_v3.bgen.bgi"

#     # Output files
#     output_bgen="${pgs_id}_${genome_build}_ukb22828_subset_chr${chr}${part}.bgen"
#     output_found_snps="${pgs_id}_${genome_build}_ukb22828_extractedSNPs_chr${chr}${part}.txt"

#     # Job command: use basenames (files staged in container)
#     job_cmd="echo 'Processing chromosome ${chr}${part}';
#              bgenix -g $(basename "$bgen_dx_path") -incl-range $(basename "$snp_file_dx") > ${output_bgen};
#              bgenix -g ${output_bgen} -index;
#              # bgenix -g ${output_bgen} -list > ${output_found_snps};"

#     # Submit job
#     dx run swiss-army-knife \
#         -iin="$bgen_dx_path" \
#         -iin="$index_dx_path" \
#         -iin="$snp_file_dx" \
#         -icmd="$job_cmd" \
#         --tag="pgs_extract_chr${chr}${part}" \
#         --instance-type "mem1_ssd1_v2_x72" \
#         --destination="$output_folder" \
#         --priority="high" \
#         --brief --yes

#     echo "-------------------------------------"
# done

# #!/usr/bin/env bash

# # Inputs
# input_folder="/Bulk/Imputation/UKB imputation from genotype/"
# output_folder="another_saniya_demo/extracted_genotypes_bgen"
# pgs_id="PGS002724"
# genome_build="GRCh37"
# snp_folder="another_saniya_demo/pgs_snps"
# log_file="variant_counts_${pgs_id}_${genome_build}.log"

# > "$log_file" # Clear old log file
# dx mkdir -p "${output_folder}" # Create output folder

# # Get all SNP files in the project folder (DNAnexus paths)
# # Collect SNP files into an array
# snp_files=()
# while IFS= read -r line; do
#     snp_files+=("$line")
# done < <(dx ls "$snp_folder" --brief)
# # mapfile -t snp_files < <(dx ls "$snp_folder" --brief)

# if [ ${#snp_files[@]} -eq 0 ]; then
#     echo "⚠️ No SNP files found in ${snp_folder}. Exiting."
#     exit 1
# fi

# echo "Found ${#snp_files[@]} SNP files."

# # Loop over all SNP files
# for snp_file_dx in "${snp_files[@]}"; do
#     snp_file=$(basename "$snp_file_dx")

#     # Extract chromosome number
#     if [[ "$snp_file" =~ _chr([0-9]+)_ ]]; then
#         chr="${BASH_REMATCH[1]}"
#     else
#         echo "⚠️ Could not extract chromosome from $snp_file. Skipping."
#         continue
#     fi

#     # Extract part info if present
#     part=""
#     if [[ "$snp_file" =~ _p([0-9]+)_of_([0-9]+) ]]; then
#         part="_p${BASH_REMATCH[1]}_of_${BASH_REMATCH[2]}"
#     fi

#     echo "Preparing job for SNP file: $snp_file | chr=${chr} | part=${part}"

#     # Input BGEN files (DNAnexus paths)
#     bgen_dx_path="${input_folder}/ukb22828_c${chr}_b0_v3.bgen"
#     index_dx_path="${input_folder}/ukb22828_c${chr}_b0_v3.bgen.bgi"

#     # Output files
#     output_bgen="${pgs_id}_${genome_build}_ukb22828_subset_chr${chr}${part}.bgen"
#     output_found_snps="${pgs_id}_${genome_build}_ukb22828_extractedSNPs_chr${chr}${part}.txt"

#     # DNAnexus job command: use basename inside container
#     job_cmd="echo 'Processing chromosome ${chr}${part}';
#         bgenix -g $(basename "$bgen_dx_path") -incl-range $(basename "$snp_file_dx") > ${output_bgen};
#         bgenix -g ${output_bgen} -index;
#         # bgenix -g ${output_bgen} -list > ${output_found_snps};"

#     echo "😀 Submitting DNAnexus job for chromosome ${chr}${part}"
#     dx run swiss-army-knife \
#         -iin="$bgen_dx_path" \
#         -iin="$index_dx_path" \
#         -iin="$snp_file_dx" \
#         -icmd="$job_cmd" \
#         --tag="pgs_extract_chr${chr}${part}" \
#         --instance-type "mem1_ssd1_v2_x72" \
#         --destination="$output_folder" \
#         --priority="high" \
#         --brief --yes

#     echo "-------------------------------------"
# done

# #!/usr/bin/env bash

# # --------------------
# # Inputs / configuration
# # --------------------
# input_folder="/Bulk/Imputation/UKB imputation from genotype/"
# output_folder="another_saniya_demo/extracted_genotypes_bgen"
# pgs_id="PGS002724"
# genome_build="GRCh37"
# snp_folder="another_saniya_demo/pgs_snps"
# log_file="variant_counts_${pgs_id}_${genome_build}.log"

# > "$log_file"
# dx mkdir -p "$output_folder"

# # --------------------
# # STEP 1: Get all SNP files (full DNAnexus paths)
# # --------------------
# snp_files=( $(dx ls another_saniya_demo/pgs_snps --brief) )
# # snp_files=()
# # while IFS= read -r line; do
# #     snp_files+=("$line")
# # done < <(dx ls "$snp_folder" --brief)

# if [ ${#snp_files[@]} -eq 0 ]; then
#     echo "⚠️ No SNP files found in $snp_folder. Exiting."
#     exit 1
# fi

# echo "Found ${#snp_files[@]} SNP files."

# # --------------------
# # STEP 2: Loop over all SNP files and submit jobs
# # --------------------
# for snp_file_dx in "${snp_files[@]}"; do
#     # Get the real filename
#     snp_file=$(basename "$snp_file_dx")

#     # Extract chromosome number
#     if [[ "$snp_file" =~ _chr([0-9]+)_ ]]; then
#         chr="${BASH_REMATCH[1]}"
#     else
#         echo "⚠️ Could not extract chromosome from $snp_file. Skipping."
#         continue
#     fi

#     # Extract part info if present (_pX_of_Y)
#     part=""
#     if [[ "$snp_file" =~ _p([0-9]+)_of_([0-9]+) ]]; then
#         part="_p${BASH_REMATCH[1]}_of_${BASH_REMATCH[2]}"
#     fi

#     echo "Preparing job for SNP file: $snp_file | chr=${chr} | part=${part}"

#     # Input BGEN files (DNAnexus paths)
#     bgen_dx_path="${input_folder}/ukb22828_c${chr}_b0_v3.bgen"
#     index_dx_path="${input_folder}/ukb22828_c${chr}_b0_v3.bgen.bgi"

#     # Output file names
#     output_bgen="${pgs_id}_${genome_build}_ukb22828_subset_chr${chr}${part}.bgen"
#     output_found_snps="${pgs_id}_${genome_build}_ukb22828_extractedSNPs_chr${chr}${part}.txt"

#     # Job command inside container (basenames)
#     job_cmd="echo 'Processing chromosome ${chr}${part}';
#              bgenix -g $(basename "$bgen_dx_path") -incl-range $(basename "$snp_file_dx") > ${output_bgen};
#              bgenix -g ${output_bgen} -index;
#              # bgenix -g ${output_bgen} -list > ${output_found_snps};"

#     # Submit the job
#     dx run swiss-army-knife \
#         -iin="$bgen_dx_path" \
#         -iin="$index_dx_path" \
#         -iin="$snp_file_dx" \
#         -icmd="$job_cmd" \
#         --tag="pgs_extract_chr${chr}${part}" \
#         --instance-type "mem1_ssd1_v2_x72" \
#         --destination="$output_folder" \
#         --priority="high" \
#         --brief --yes

#     echo "-------------------------------------"
# done

# #!/usr/bin/env bash

# # Inputs
# input_folder="/Bulk/Imputation/UKB imputation from genotype/"
# output_folder="another_saniya_demo/extracted_genotypes_bgen"
# pgs_id="PGS002724"
# genome_build="GRCh37"

# # Folder on DNAnexus where SNP files are stored
# snp_folder="another_saniya_demo/pgs_snps"

# # Clear log file
# log_file="variant_counts_${pgs_id}_${genome_build}.log"
# > "$log_file"

# dx mkdir -p "${output_folder}"

# # --- STEP 1: Build list of SNP files locally (before submission) ---
# snp_files=()
# while IFS= read -r f; do
#     snp_files+=("$f")
# done < <(dx ls "$snp_folder" --brief)

# if [ ${#snp_files[@]} -eq 0 ]; then
#     echo "⚠️ No SNP files found in ${snp_folder}. Exiting."
#     exit 1
# fi

# echo "Found ${#snp_files[@]} SNP files."

# # --- STEP 2: Loop over all SNP files and submit DNAnexus jobs ---
# for snp_file_dx in "${snp_files[@]}"; do
#     # Get basename for regex and inside container
#     snp_file=$(basename "$snp_file_dx")

#     # Extract chromosome number
#     if [[ "$snp_file" =~ _chr([0-9]+)_ ]]; then
#         chr="${BASH_REMATCH[1]}"
#     else
#         echo "⚠️ Could not extract chromosome from $snp_file. Skipping."
#         continue
#     fi

#     # Extract part info if present
#     part=""
#     if [[ "$snp_file" =~ _p([0-9]+)_of_([0-9]+) ]]; then
#         part="_p${BASH_REMATCH[1]}_of_${BASH_REMATCH[2]}"
#     fi

#     echo "Preparing job for SNP file: $snp_file | chr=${chr} | part=${part}"

#     # Input BGEN files (DNAnexus paths)
#     bgen_dx_path="${input_folder}/ukb22828_c${chr}_b0_v3.bgen"
#     index_dx_path="${input_folder}/ukb22828_c${chr}_b0_v3.bgen.bgi"

#     # Output files
#     output_bgen="${pgs_id}_${genome_build}_ukb22828_subset_chr${chr}${part}.bgen"
#     output_found_snps="${pgs_id}_${genome_build}_ukb22828_extractedSNPs_chr${chr}${part}.txt"

#     # Job command: use basenames (files staged in container)
#     job_cmd="echo 'Processing chromosome ${chr}${part}';
#              bgenix -g $(basename "$bgen_dx_path") -incl-range $(basename "$snp_file_dx") > ${output_bgen};
#              bgenix -g ${output_bgen} -index;
#              # bgenix -g ${output_bgen} -list > ${output_found_snps};"

#     # Submit job
#     dx run swiss-army-knife \
#         -iin="$bgen_dx_path" \
#         -iin="$index_dx_path" \
#         -iin="$snp_file_dx" \
#         -icmd="$job_cmd" \
#         --tag="pgs_extract_chr${chr}${part}" \
#         --instance-type "mem1_ssd1_v2_x72" \
#         --destination="$output_folder" \
#         --priority="high" \
#         --brief --yes

#     echo "-------------------------------------"
# done

# #!/usr/bin/env bash

# # Inputs
# input_folder="/Bulk/Imputation/UKB imputation from genotype/"
# output_folder="another_saniya_demo/extracted_genotypes_bgen"
# pgs_id="PGS002724"
# genome_build="GRCh37"
# snp_folder="another_saniya_demo/pgs_snps"
# log_file="variant_counts_${pgs_id}_${genome_build}.log"

# > "$log_file" # Clear old log file
# dx mkdir -p "${output_folder}" # Create output folder

# # Collect SNP files (real filenames) from DNAnexus folder
# snp_files=()
# while IFS= read -r line; do
#     snp_files+=("$line")
# done < <(dx ls "$snp_folder")

# if [ ${#snp_files[@]} -eq 0 ]; then
#     echo "⚠️ No SNP files found in ${snp_folder}. Exiting."
#     exit 1
# fi

# echo "Found ${#snp_files[@]} SNP files."

# # Loop over all SNP files
# for snp_file_dx in "${snp_files[@]}"; do
#     # Extract the actual filename (not file ID)
#     snp_file=$(dx describe "$snp_file_dx" --name)

#     # Extract chromosome number
#     if [[ "$snp_file" =~ _chr([0-9]+)_ ]]; then
#         chr="${BASH_REMATCH[1]}"
#     else
#         echo "⚠️ Could not extract chromosome from $snp_file. Skipping."
#         continue
#     fi

#     # Extract part info if present (_pX_of_Y)
#     part=""
#     if [[ "$snp_file" =~ _p([0-9]+)_of_([0-9]+) ]]; then
#         part="_p${BASH_REMATCH[1]}_of_${BASH_REMATCH[2]}"
#     fi

#     echo "Preparing job for SNP file: $snp_file | chr=${chr} | part=${part}"

#     # Input BGEN files (DNAnexus paths)
#     bgen_dx_path="${input_folder}/ukb22828_c${chr}_b0_v3.bgen"
#     index_dx_path="${input_folder}/ukb22828_c${chr}_b0_v3.bgen.bgi"

#     # Output files
#     output_bgen="${pgs_id}_${genome_build}_ukb22828_subset_chr${chr}${part}.bgen"
#     output_found_snps="${pgs_id}_${genome_build}_ukb22828_extractedSNPs_chr${chr}${part}.txt"

#     # DNAnexus job command: use basename inside container
#     job_cmd="echo 'Processing chromosome ${chr}${part}';
#         bgenix -g $(basename "$bgen_dx_path") -incl-range $(basename "$snp_file_dx") > ${output_bgen};
#         bgenix -g ${output_bgen} -index;
#         # bgenix -g ${output_bgen} -list > ${output_found_snps};"

#     echo "😀 Submitting DNAnexus job for chromosome ${chr}${part}"
#     dx run swiss-army-knife \
#         -iin="$bgen_dx_path" \
#         -iin="$index_dx_path" \
#         -iin="$snp_file_dx" \
#         -icmd="$job_cmd" \
#         --tag="pgs_extract_chr${chr}${part}" \
#         --instance-type "mem1_ssd1_v2_x72" \
#         --destination="$output_folder" \
#         --priority="high" \
#         --brief --yes

#     echo "-------------------------------------"
# done


# #!/usr/bin/env bash

# # Inputs
# input_folder="/Bulk/Imputation/UKB imputation from genotype/"
# output_folder="another_saniya_demo/extracted_genotypes_bgen"
# pgs_id="PGS002724"
# genome_build="GRCh37"
# snp_folder="another_saniya_demo/pgs_snps"
# log_file="variant_counts_${pgs_id}_${genome_build}.log"

# > "$log_file" # Clear old log file
# dx mkdir -p "${output_folder}" # Create output folder

# # Get all SNP files in the project folder (DNAnexus paths)
# # Collect SNP files into an array
# snp_files=()
# while IFS= read -r line; do
#     snp_files+=("$line")
# done < <(dx ls "$snp_folder" --brief)
# # mapfile -t snp_files < <(dx ls "$snp_folder" --brief)

# if [ ${#snp_files[@]} -eq 0 ]; then
#     echo "⚠️ No SNP files found in ${snp_folder}. Exiting."
#     exit 1
# fi

# echo "Found ${#snp_files[@]} SNP files."

# # Loop over all SNP files
# for snp_file_dx in "${snp_files[@]}"; do
#     snp_file=$(basename "$snp_file_dx")

#     # Extract chromosome number
#     if [[ "$snp_file" =~ _chr([0-9]+)_ ]]; then
#         chr="${BASH_REMATCH[1]}"
#     else
#         echo "⚠️ Could not extract chromosome from $snp_file. Skipping."
#         continue
#     fi

#     # Extract part info if present
#     part=""
#     if [[ "$snp_file" =~ _p([0-9]+)_of_([0-9]+) ]]; then
#         part="_p${BASH_REMATCH[1]}_of_${BASH_REMATCH[2]}"
#     fi

#     echo "Preparing job for SNP file: $snp_file | chr=${chr} | part=${part}"

#     # Input BGEN files (DNAnexus paths)
#     bgen_dx_path="${input_folder}/ukb22828_c${chr}_b0_v3.bgen"
#     index_dx_path="${input_folder}/ukb22828_c${chr}_b0_v3.bgen.bgi"

#     # Output files
#     output_bgen="${pgs_id}_${genome_build}_ukb22828_subset_chr${chr}${part}.bgen"
#     output_found_snps="${pgs_id}_${genome_build}_ukb22828_extractedSNPs_chr${chr}${part}.txt"

#     # DNAnexus job command: use basename inside container
#     job_cmd="echo 'Processing chromosome ${chr}${part}';
#         bgenix -g $(basename "$bgen_dx_path") -incl-range $(basename "$snp_file_dx") > ${output_bgen};
#         bgenix -g ${output_bgen} -index;
#         # bgenix -g ${output_bgen} -list > ${output_found_snps};"

#     echo "😀 Submitting DNAnexus job for chromosome ${chr}${part}"
#     dx run swiss-army-knife \
#         -iin="$bgen_dx_path" \
#         -iin="$index_dx_path" \
#         -iin="$snp_file_dx" \
#         -icmd="$job_cmd" \
#         --tag="pgs_extract_chr${chr}${part}" \
#         --instance-type "mem1_ssd1_v2_x72" \
#         --destination="$output_folder" \
#         --priority="high" \
#         --brief --yes

#     echo "-------------------------------------"
# done

# #!/usr/bin/env bash

# # Inputs
# input_folder="/Bulk/Imputation/UKB imputation from genotype/"
# output_folder="/another_saniya_demo/extracted_genotypes_bgen"
# pgs_id="PGS002724"
# genome_build="GRCh37"
# snp_folder="/another_saniya_demo/pgs_snps"
# log_file="variant_counts_${pgs_id}_${genome_build}.log"

# > "$log_file" # Clear old log file
# dx mkdir -p "${output_folder}" # Create output folder

# # Enable nullglob so unmatched globs expand to nothing
# shopt -s nullglob
# # Get DNAnexus object paths into an array
# mapfile -t snp_files < <(dx ls "$snp_folder" --brief)

# echo "Found ${#snp_files[@]} SNP files:"
# for f in "${snp_files[@]}"; do
#     echo "  $f"
# done
# # snp_files=dx ls snp_folder #("${snp_folder}"/*.txt)

# if [ ${#snp_files[@]} -eq 0 ]; then
#     echo "⚠️ No SNP files found in ${snp_folder}. Exiting."
#     exit 1
# fi

# # Loop over all SNP files
# for snp_file_path in "${snp_files[@]}"; do
#     snp_file=$(basename "$snp_file_path")

#     # Extract chromosome number from _chr#_
#     if [[ "$snp_file" =~ _chr([0-9]+)_ ]]; then
#         chr="${BASH_REMATCH[1]}"
#     else
#         echo "⚠️ Could not extract chromosome from $snp_file. Skipping."
#         continue
#     fi

#     # Extract part info if present (_pX_of_Y)
#     part=""
#     if [[ "$snp_file" =~ _p([0-9]+)_of_([0-9]+) ]]; then
#         part="_p${BASH_REMATCH[1]}_of_${BASH_REMATCH[2]}"
#     fi

#     echo "Found SNP file: $snp_file | chr=${chr} | part=${part}"

#     # Input BGEN files (full DNAnexus paths)
#     bgen_dx_path="${input_folder}/ukb22828_c${chr}_b0_v3.bgen"
#     index_dx_path="${input_folder}/ukb22828_c${chr}_b0_v3.bgen.bgi"

#     # Output files
#     output_bgen="${pgs_id}_${genome_build}_ukb22828_subset_chr${chr}${part}.bgen"
#     output_found_snps="${pgs_id}_${genome_build}_ukb22828_extractedSNPs_chr${chr}${part}.txt"

#     # DNAnexus job command using full DNAnexus paths
#     job_cmd="echo 'Processing chromosome ${chr}${part}';
#         bgenix -g ${bgen_dx_path} -incl-range ${snp_file_path} > ${output_bgen};
#         bgenix -g ${output_bgen} -index;
#         # bgenix -g ${output_bgen} -list > ${output_found_snps};"

#     echo "😀 Submitting DNAnexus job for chromosome ${chr}${part}"
#     dx run swiss-army-knife \
#         -iin="$bgen_dx_path" \
#         -iin="$index_dx_path" \
#         -iin="$snp_file_path" \
#         -icmd="${job_cmd}" \
#         --tag="pgs_extract_chr${chr}${part}" \
#         --instance-type "mem1_ssd1_v2_x72" \
#         --destination="${output_folder}" \
#         --priority="high" \
#         --brief --yes

#     echo "-------------------------------------"
# done

# #!/usr/bin/env bash

# # Inputs
# input_folder="/Bulk/Imputation/UKB imputation from genotype/"
# output_folder="/another_saniya_demo/extracted_genotypes_bgen"
# pgs_id="PGS002724"
# genome_build="GRCh37"
# snp_folder="/another_saniya_demo/pgs_snps"
# log_file="variant_counts_${pgs_id}_${genome_build}.log"

# > "$log_file" # Clear old log file
# dx mkdir -p "${output_folder}" # Create output folder

# # Ensure globbing works correctly
# shopt -s nullglob
# snp_files=("${snp_folder}"/*.txt)

# if [ ${#snp_files[@]} -eq 0 ]; then
#     echo "⚠️ No SNP files found in ${snp_folder}. Exiting."
#     exit 1
# fi

# # Loop over all SNP files
# for snp_file_path in "${snp_files[@]}"; do
#     snp_file=$(basename "$snp_file_path")

#     # Extract chromosome number from _chr#_
#     if [[ "$snp_file" =~ _chr([0-9]+)_ ]]; then
#         chr="${BASH_REMATCH[1]}"
#     else
#         echo "⚠️ Could not extract chromosome from $snp_file. Skipping."
#         continue
#     fi

#     # Extract part info if present (_pX_of_Y)
#     part=""
#     if [[ "$snp_file" =~ _p([0-9]+)_of_([0-9]+) ]]; then
#         part="_p${BASH_REMATCH[1]}_of_${BASH_REMATCH[2]}"
#     fi

#     echo "Found SNP file: $snp_file | chr=${chr} | part=${part}"

#     # Input files
#     bgen_filename="ukb22828_c${chr}_b0_v3.bgen"
#     index_filename="ukb22828_c${chr}_b0_v3.bgen.bgi"

#     # Output files
#     output_bgen="${pgs_id}_${genome_build}_ukb22828_subset_chr${chr}${part}.bgen"
#     output_found_snps="${pgs_id}_${genome_build}_ukb22828_extractedSNPs_chr${chr}${part}.txt"

#     # Check if SNP file exists in DNAnexus
#     if ! dx ls "$snp_file_path" &>/dev/null; then
#         echo "⚠️ SNP file ${snp_file_path} for chromosome ${chr} not found. Skipping."
#         continue
#     fi

#     # DNAnexus job command
#     job_cmd="echo 'Processing chromosome ${chr}${part}';
#         bgenix -g ${bgen_filename} -incl-range ${snp_file} > ${output_bgen};
#         bgenix -g ${output_bgen} -index;"
#         # bgenix -g ${output_bgen} -list > ${output_found_snps};"

#     echo "😀 Submitting DNAnexus job for chromosome ${chr}${part}"
#     dx run swiss-army-knife \
#         -iin="${input_folder}/${bgen_filename}" \
#         -iin="${input_folder}/${index_filename}" \
#         -iin="$snp_file_path" \
#         -icmd="${job_cmd}" \
#         --tag="pgs_extract_chr${chr}${part}" \
#         --instance-type "mem1_ssd1_v2_x72" \
#         --destination="${output_folder}" \
#         --priority="high" \
#         --brief --yes

#     echo "-------------------------------------"
# done
# #!/usr/bin/env bash

# # Inputs
# input_folder="/Bulk/Imputation/UKB imputation from genotype/"
# output_folder="/another_saniya_demo/extracted_genotypes_bgen"
# pgs_id="PGS002724"
# genome_build="GRCh37"
# snp_folder="/another_saniya_demo/pgs_snps"
# log_file="variant_counts_${pgs_id}_${genome_build}.log"

# > "$log_file" # Clear old log file
# dx mkdir -p "${output_folder}" # Create output folder

# # Loop over SNP files in the folder
# for snp_file_path in "${snp_folder}"/*.txt; do
#     snp_file=$(basename "$snp_file_path")

#     # Extract chromosome number from _chr#_
#     if [[ "$snp_file" =~ _chr([0-9]+)_ ]]; then
#         chr="${BASH_REMATCH[1]}"
#     else
#         echo "⚠️ Could not extract chromosome from $snp_file. 😟 Skipping for ranges.."
#         continue
#     fi

#     # Extract part info if present (_pX_of_Y)
#     part=""
#     if [[ "$snp_file" =~ _p([0-9]+)_of_([0-9]+) ]]; then
#         part="_p${BASH_REMATCH[1]}_of_${BASH_REMATCH[2]}"
#     fi

#     # Input files
#     bgen_filename="ukb22828_c${chr}_b0_v3.bgen"
#     index_filename="ukb22828_c${chr}_b0_v3.bgen.bgi"

#     # Output files
#     output_bgen="${pgs_id}_${genome_build}_ukb22828_subset_chr${chr}${part}.bgen"
#     output_found_snps="${pgs_id}_${genome_build}_ukb22828_extractedSNPs_chr${chr}${part}.txt"

#     # Check if SNP file exists in DNAnexus
#     if ! dx ls "$snp_file_path" &>/dev/null; then
#         echo "⚠️ SNP file ${snp_file_path} for chromosome ${chr} not found. Skipping."
#         continue
#     fi

#     # DNAnexus job command
#     job_cmd="echo 'Processing chromosome ${chr}${part}';
#         bgenix -g ${bgen_filename} -incl-range ${snp_file} > ${output_bgen};
#         bgenix -g ${output_bgen} -index;"
#         # bgenix -g ${output_bgen} -list > ${output_found_snps};"

#     echo "😀 Submitting DNAnexus job for chromosome ${chr}${part}"
#     dx run swiss-army-knife \
#         -iin="${input_folder}/${bgen_filename}" \
#         -iin="${input_folder}/${index_filename}" \
#         -iin="$snp_file_path" \
#         -icmd="${job_cmd}" \
#         --tag="pgs_extract_chr${chr}${part}" \
#         --instance-type "mem1_ssd1_v2_x72" \
#         --destination="${output_folder}" \
#         --priority="high" \
#         --brief --yes

#     echo "-------------------------------------"
# done


# #!/usr/bin/env bash
# # Inputs
# input_folder="/Bulk/Imputation/UKB imputation from genotype/"
# output_folder="/another_saniya_demo/extracted_genotypes_bgen"
# pgs_id="PGS002724"
# chrom_file="/another_saniya_demo/pgs_snps/chromNames_${pgs_id}.txt"
# genome_build="GRCh37"
# log_file="variant_counts_${pgs_id}_${genome_build}.log"

# > "$log_file" # Clear old log file
# dx mkdir -p "${output_folder}" # Create output folder

# for chr in {1..22}; do
#     # Input files
#     bgen_filename="ukb22828_c${chr}_b0_v3.bgen"
#     index_filename="ukb22828_c${chr}_b0_v3.bgen.bgi"
#     snp_filename="${pgs_id}_retry_chr${chr}_${genome_build}_ranges.txt"

#     # snp_filename="${pgs_id}_chr${chr}_${genome_build}_ranges.txt"
#     output_bgen="${pgs_id}_${genome_build}_ukb22828_subset_chr${chr}_ranges.bgen"
#     output_found_snps="${pgs_id}_${genome_build}_ukb22828_extractedSNPs_chr${chr}.txt"

#     snp_file_dx="/another_saniya_demo/pgs_snps/${snp_filename}" # Check if SNP file exists
#     if ! dx ls "$snp_file_dx" &>/dev/null; then
#         echo "Please note: ⚠️ SNP file ${snp_file_dx} for chromosome ${chr} is not found. 😟 Skipping for ranges."
#         continue
#     fi

#     # DNAnexus job command
#     job_cmd="echo 'Processing chromosome ${chr}';
#         bgenix -g ${bgen_filename} -incl-range ${snp_filename} > ${output_bgen};
#         bgenix -g ${output_bgen} -index;"
#         # bgenix -g ${output_bgen} -list > ${output_found_snps};"

#     echo "😀 Submitting DNA Nexus job for chromosome ${chr}"
#     dx run swiss-army-knife \
#         -iin="${input_folder}/${bgen_filename}" \
#         -iin="${input_folder}/${index_filename}" \
#         -iin="$snp_file_dx" \
#         -icmd="${job_cmd}" \
#         --tag="pgs_extract_chr${chr}" \
#         --instance-type "mem1_ssd1_v2_x72" \
#         --destination="${output_folder}" \
#         --priority="high" \
#         --brief --yes
#     echo "-------------------------------------"
# done

