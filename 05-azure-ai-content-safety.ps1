<#
**********************************************************
Use AI responsibly with Azure AI Content Safety
**********************************************************
#>

Exercise: https://microsoftlearning.github.io/mslearn-ai-services/Instructions/Exercises/05-implement-content-safety.html

# CONFIG
$RESOURCEGROUP="learn-ai102-rg"
$LOCATION="eastus"
$AISERVICESNAME="ld-learn-ai102-service"

#**********************************************************
# Exercise

az group create --name $RESOURCEGROUP --location $LOCATION
# to see all kind of Cognitive services: az cognitiveservices account list-kinds
az cognitiveservices account create -n $AISERVICESNAME -g $RESOURCEGROUP --kind ContentSafety --sku S0 -l $LOCATION --yes

# Restart CLI + define CONFIG params again
$AISERVICE = az cognitiveservices account show --resource-group $RESOURCEGROUP --name $AISERVICESNAME
$AISERVICE_CONVERTED = ConvertFrom-JSON -InputObject "$AISERVICE"

# $SUBSCRIPTION_ID = az account show --query "id" --output tsv
$USER_ID = az ad signed-in-user show --query 'id' -o tsv
az role assignment create --assignee $USER_ID --role "Cognitive Services User" --scope $AISERVICE_CONVERTED.id


# Get AI SERVICE Endpoint and Key - this is needed to call AI SERVICE though SDK
$ENDPOINT = $AISERVICE_CONVERTED.properties.endpoint
$KEY = az cognitiveservices account keys list  --resource-group $RESOURCEGROUP --name $AISERVICESNAME --query "key1" --output tsv


#**********************************************************
# CLEANUP
az group delete --name $RESOURCEGROUP -y

# permanently delete deleted accounts: 
$deletedAccounts = az cognitiveservices account list-deleted
$deletedAccounts | ConvertFrom-Json | ForEach-Object {az resource delete --ids $_.id}

# DELETE APP FOLDER
cd ..
Remove-Item -Recurse -Force $APP_NAME
