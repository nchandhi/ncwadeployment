resourceGroupName="nc_byoawa_test11"
location="eastus"
functionAppName="nctestfnapp7101"
storageAccountName="nctestfnapp7101storage"
zipBlobUrl="https://raw.githubusercontent.com/nchandhi/ncwadeployment/main/WealthAdvisor/AzureFunction/function_app.zip"
appServicePlanName="${functionAppName}-plan"

# Create a Resource Group
# az group create --name $resourceGroupName --location $location

# Create a Storage Account
az storage account create --name $storageAccountName --location $location --resource-group $resourceGroupName --sku Standard_LRS

# Create an App Service Plan (Consumption Plan)
az appservice plan create --name $appServicePlanName --resource-group $resourceGroupName --location $location --sku Y1 --is-linux

# Create a Function App
az functionapp create --name $functionAppName --storage-account $storageAccountName --plan $appServicePlanName --resource-group $resourceGroupName --runtime python --runtime-version 3.8 --os-type Linux

# Configure Function App settings for deployment from a package
az functionapp config appsettings set --name $functionAppName --resource-group $resourceGroupName --settings \
    WEBSITE_RUN_FROM_PACKAGE=$zipBlobUrl \
    FUNCTIONS_EXTENSION_VERSION=~4 \
    FUNCTIONS_WORKER_RUNTIME=python

# Retrieve and print the Function App URL
functionAppUrl=$(az functionapp show --name $functionAppName --resource-group $resourceGroupName --query "defaultHostName" --output tsv)
echo "Function App URL: https://$functionAppUrl"