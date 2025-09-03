#!/bin/bash

echo "🤓 Please note that we will be running these commands to create folders in DNA Nexus!" 

main_folder_name="saniya_tutorials"
sub_folder_name1="pgs_snps"
sub_folder_name2="pgs_scores"
sub_folder_name3="pgsc_calc_output_by_pgs_id"

# Please create the main directory on DNA Nexus if it is not already there
dx mkdir /${main_folder_name} 
echo "📁 Main directory '${main_folder_name}' 😄"

# Please create a subfolder on DNA Nexus if it is not already there: pgs_snps
dx mkdir /${main_folder_name}/${sub_folder_name1}  # Creates folder if it is not there
echo "📂 Subfolder '${sub_folder_name1}' is here: '${main_folder_name}/${sub_folder_name1}'! 😃"

# Please create a subfolder on DNA Nexus if it is not already there: pgs_scores
dx mkdir /${main_folder_name}/${sub_folder_name2}  # Creates folder if it is not there
echo "📂 Subfolder '${sub_folder_name2}' is here: '${main_folder_name}/${sub_folder_name2}'! 😃"

# Please create a subfolder on DNA Nexus if it is not already there: pgsc_calc_output_by_pgs_id
dx mkdir /${main_folder_name}/${sub_folder_name3}  # Creates folder if it is not there
echo "📂 Subfolder '${sub_folder_name3}' is here: '${main_folder_name}/${sub_folder_name3}'! 😃"

# Final confirmation
echo "✅ Please note that we ensure that all directories (folders) are set up and ready 😎"