#!/bin/bash
echo "started the script"

# Variables
baseUrl="$1"
keyvaultName="$2"
requirementFile="requirements.txt"
requirementFileUrl=${baseUrl}"Deployment/scripts/index_scripts/requirements.txt"

echo "Download Started"

# Download the create_index python files
curl --output "create_search_index.py" ${baseUrl}"Deployment/scripts/index_scripts/create_search_index.py"


# Download the requirement file
curl --output "$requirementFile" "$requirementFileUrl"

echo "Download completed"

#Replace key vault name 
sed -i "s/kv_to-be-replaced/${keyvaultName}/g" "create_search_index.py"

pip install -r requirements.txt

python create_search_index.py
