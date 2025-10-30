#!/bin/bash
main_folder="/hg38_saniya_demo/"
# Ancestry information
ancestry_folder="/${main_folder}/ancestry_reference_data/"
ancestry_data_name="pgsc_HGDP+1kGP_v1.tar.zst"                             # Which ancestry data to fetch


# Script to download ancestry reference data and upload to DNAnexus only if missing
# --- URL SELECTION ---
# Map ancestry_data_name → correct URL
case "$ancestry_data_name" in
  "pgsc_HGDP+1kGP_v1.tar.zst")
    URL="https://ftp.ebi.ac.uk/pub/databases/spot/pgs/resources/pgsc_HGDP+1kGP_v1.tar.zst"
    ;;
  "pgsc_1000G_v1.tar.zst")
    URL="https://ftp.ebi.ac.uk/pub/databases/spot/pgs/resources/pgsc_1000G_v1.tar.zst"
    ;;
  *)
    echo "❌ Unknown ancestry_data_name: $ancestry_data_name"
    exit 1
    ;;
esac

dx mkdir -p "${ancestry_folder}"

# --- CHECK IF FILE ALREADY EXISTS ---
echo "🔍 Checking if ${ancestry_data_name} already exists in ${ancestry_folder} ..."
if dx ls "${ancestry_folder}" | grep -q "^${ancestry_data_name}$"; then
  echo "✅ ${ancestry_data_name} already exists in DNAnexus folder. Skipping download/upload."
else
  echo "⬇️  Downloading ${ancestry_data_name} ..."
  curl -L -o "${ancestry_data_name}" "${URL}"

  if [[ -f "${ancestry_data_name}" ]]; then
    echo "📤 Uploading ${ancestry_data_name} to DNAnexus..."
    dx upload "${ancestry_data_name}" --path "${ancestry_folder}" --brief
    rm "${ancestry_data_name}"
  else
    echo "❌ Failed to download ${ancestry_data_name} — skipping upload."
    exit 1
  fi
fi

rm ${ancestry_data_name}

echo "🎉 Yay! ${ancestry_data_name} is available in ${ancestry_folder}"
