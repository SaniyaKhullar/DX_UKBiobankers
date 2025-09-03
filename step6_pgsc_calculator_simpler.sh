#!/usr/bin/env bash
# Step 6 (by Saniya Khullar): Run PGS Catalog Calculator on the specified score file.

# ===== User-defined constants =====
pgs_catalog_id="PGS000053"                 # Polygenic Score (PGS) ID from the PGS Catalog
genome_build="GRCh37"                      # Genome build (GRCh37 = hg19, GRCh38 = hg38)

# Input: PGS Catalog score file
score_folder="/saniya_tutorials/pgs_scores"
score_file="${pgs_catalog_id}.txt"         # Alternatively, use --pgs_id directly

# Input: Samplesheet (maps individuals → genotype data prefix)
samplesheet_path="/saniya_tutorials/pgs_calc_${pgs_catalog_id}_${genome_build}_samplesheet.csv"

# Input: Genotype data (PLINK 1 binary format, merged across chromosomes)
genotype_prefix="all_chromosomes_SNPs_merged_${pgs_catalog_id}_${genome_build}"
genotype_folder="/saniya_tutorials/merged_genotypes"

output_folder="/saniya_tutorials/new_pgsc_calc_output_by_pgs_id" # Output folder

# ===== Skip if an output folder for this PGS (Polygenic Score) already exists =====
dx mkdir -p "${output_folder}"
if dx ls "${output_folder}" | grep -q "^${pgs_catalog_id}"; then
    echo "✅ Output for ${pgs_catalog_id} already exists — skipping."
    exit 0
fi

echo "🚀 Running pgsc_calc for ${pgs_catalog_id} (build: ${genome_build})"

# ===== Build Nextflow command =====
# - Installs Nextflow;
# - Creates a params.yml file describing score/genotype details
# - Runs pgsc_calc workflow with Docker
CMD="
curl -fsSL get.nextflow.io | bash && \
mkdir -p ~/.local/bin && \
mv nextflow ~/.local/bin && \
export PATH=\"\$PATH:~/.local/bin\" && \

# Write params.yml for pgsc_calc
cat <<EOT > params.yml
scorefile: ${score_file}
genotype_path: ${genotype_prefix}
EOT

# Run pgsc_calc (Polygenic Score Catalog Calculator)
nextflow run pgscatalog/pgsc_calc -profile docker \
    --input $(basename ${samplesheet_path}) \
    --scorefile ${score_file} \
    --target_build ${genome_build} \
    --params-file params.yml \
    --outdir pgsc_calc_results_${pgs_catalog_id}
"

# ===== Submit job to DNAnexus Swiss Army Knife =====
dx run swiss-army-knife \
    -iin="${score_folder}/${score_file}" \
    -iin="${samplesheet_path}" \
    -iin="${genotype_folder}/${genotype_prefix}.bed" \
    -iin="${genotype_folder}/${genotype_prefix}.bim" \
    -iin="${genotype_folder}/${genotype_prefix}.fam" \
    -icmd="$CMD" \
    --tag="pgscalc_${pgs_catalog_id}" \
    --priority="high" \
    --instance-type mem3_ssd1_v2_x8 \
    --destination="${output_folder}" \
    --brief --yes

echo "🎉 Submitted PGS Calculator job for ${pgs_catalog_id}!"
