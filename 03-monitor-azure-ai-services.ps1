<#
**********************************************************
Monitor Azure AI services
**********************************************************
#>

Exercise: https://microsoftlearning.github.io/mslearn-ai-services/Instructions/Exercises/03-monitor-ai-services.html

# Follow ./01-use-azure-ai-services.ps1 to create necessary resources

# Get AI SERVICE Endpoint and Key - this is needed to call AI SERVICE though SDK
$ENDPOINT = $AISERVICE_CONVERTED.properties.endpoint

# set up monitoring as described in exercise

#**********************************************************
# CLEANUP
az group delete --name $RESOURCEGROUP -y

# permanently delete deleted accounts: 
$deletedAccounts = az cognitiveservices account list-deleted
$deletedAccounts | ConvertFrom-Json | ForEach-Object {az resource delete --ids $_.id}
