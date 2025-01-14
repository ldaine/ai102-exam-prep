<#
**********************************************************
Deploy Azure AI services in containers
**********************************************************
#>

Exercise: https://microsoftlearning.github.io/mslearn-ai-services/Instructions/Exercises/04-use-a-container.html

# Follow ./01-use-azure-ai-services.ps1 to create necessary resources

# Get AI SERVICE Endpoint and Key
$ENDPOINT = $AISERVICE_CONVERTED.properties.endpoint
$KEY = az cognitiveservices account keys list  --resource-group $RESOURCEGROUP --name $AISERVICESNAME --query "key1" --output tsv

#---------------------------------
# Create Container Instance

$CONTAINER_NAME = "ld-learn-ai102-container"
$IMAGE = "mcr.microsoft.com/azure-cognitive-services/textanalytics/sentiment:latest"
az container create -g $RESOURCEGROUP `
--name $CONTAINER_NAME `
--image $IMAGE `
--sku Standard `
--os-type Linux `
--cpu 1 `
--memory 8 `
--restart-policy OnFailure `
--dns-name-label $CONTAINER_NAME `
--ports 5000 `
--ip-address Public `
--environment-variables ApiKey=$KEY Billing=$ENDPOINT Eula=accept

$CONTAINER_FQDN = az container show --name $CONTAINER_NAME --resource-group $RESOURCEGROUP --query "ipAddress.fqdn" --output tsv

curl -X POST "http://$($CONTAINER_FQDN):5000/text/analytics/v3.1/sentiment" -H "Content-Type: application/json" --data-ascii "{'documents':[{'id':1,'text':'The performance was amazing! The sound could have been clearer.'},{'id':2,'text':'The food and service were unacceptable. While the host was nice, the waiter was rude and food was cold.'}]}"

# container can be created on any docker host: 
docker run --rm -it -p 5000:5000 --memory 8g --cpus 1 $IMAGE Eula=accept Billing=$ENDPOINT ApiKey=$KEY

#**********************************************************
# CLEANUP
az group delete --name $RESOURCEGROUP -y

# permanently delete deleted accounts: 
$deletedAccounts = az cognitiveservices account list-deleted
$deletedAccounts | ConvertFrom-Json | ForEach-Object {az resource delete --ids $_.id}

# DELETE APP FOLDER
cd ..
Remove-Item -Recurse -Force $APP_NAME
