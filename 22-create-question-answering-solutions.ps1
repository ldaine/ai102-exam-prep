<#
**********************************************************
Create question answering solutions with Azure AI Language
**********************************************************
#>

Exercise: https://microsoftlearning.github.io/mslearn-ai-language/Instructions/Exercises/02-qna.html

# CONFIG
$RESOURCEGROUP="learn-ai102-language-rg"
$LOCATION="northeurope" 
$AISERVICESNAME="ld-learn-ai102-language-service"
$SEARCHSERVICESNAME="ldlearnai102-qa-search"

#**********************************************************
# Create Resources

az group create --name $RESOURCEGROUP --location $LOCATION
# to see all kind of Cognitive services: az cognitiveservices account list-kinds
$AISERVICE = az cognitiveservices account create -n $AISERVICESNAME -g $RESOURCEGROUP --kind TextAnalytics --sku S -l $LOCATION --yes
# get the data afterwards: $AISERVICE = az cognitiveservices account show --resource-group $RESOURCEGROUP --name $AISERVICESNAME
$AISERVICE_CONVERTED = ConvertFrom-JSON -InputObject "$AISERVICE"

# Get AI SERVICE Endpoint and Key - this is needed to call AI SERVICE though SDK
$ENDPOINT = $AISERVICE_CONVERTED.properties.endpoint
$KEY = az cognitiveservices account keys list  --resource-group $RESOURCEGROUP --name $AISERVICESNAME --query "key1" --output tsv


$SEARCH_SERVICE = az search service create --name $SEARCHSERVICESNAME --resource-group $RESOURCEGROUP --sku standard --location $LOCATION
$SEARCH_SERVICE_CONVERTED = ConvertFrom-JSON -InputObject "$SEARCH_SERVICE"

az search service show --name $SEARCHSERVICESNAME --resource-group $RESOURCEGROUP

$SEARCH_ID = $SEARCH_SERVICE_CONVERTED.id
$SEARCH_KEY = az search admin-key show  --resource-group $RESOURCEGROUP --service-name $SEARCHSERVICESNAME --query "primaryKey" --output tsv

# lingk to Search Service
az cognitiveservices account update --name $AISERVICESNAME -g $RESOURCEGROUP --api-properties qnaAzureSearchEndpointId=$SEARCH_ID qnaAzureSearchEndpointKey=$SEARCH_KEY

# enable managed identity
az cognitiveservices account identity assign --name $AISERVICESNAME -g $RESOURCEGROUP

#------------------------------------------------
# Create a question answering project in https://language.cognitive.azure.com/

# follow exercise description

#------------------------------------------------
# Prepare to develop an app in Visual Studio Code

# LOCALLY 
# Clone the Microsoft Lab
git clone https://github.com/MicrosoftLearning/mslearn-ai-language

# create new Project: 
$APP_NAME = "ai102-language-qa-service-console-app"
dotnet new console --name $APP_NAME
cd $APP_NAME
# create app settings file
$APP_SETTINGS_TEMPLATE = @"
{
    "AIServicesEndpoint": "YOUR_AI_SERVICES_ENDPOINT",
    "AIServicesKey": "YOUR_AI_SERVICES_KEY",
    "QAProjectName": "LearnFAQ",
    "QADeploymentName": "production"
}
"@
# if you were running all az commands from local PoserShell: 
$APP_SETTINGS = $APP_SETTINGS_TEMPLATE `
-replace 'YOUR_AI_SERVICES_ENDPOINT', $ENDPOINT `
-replace 'YOUR_AI_SERVICES_KEY', $KEY

$APP_SETTINGS | Out-File appsettings.json

# otherwise: 
$APP_SETTINGS_TEMPLATE | Out-File appsettings.json
# update the appsettings.json file with the values of $ENDPOINT and $KEY

# Add appsetting.json to Project file: 
<#
  <ItemGroup>
    <None Update="appsettings.json">
      <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
    </None>
  </ItemGroup>
#>

# install necessary dependencies
dotnet add package Microsoft.Extensions.Configuration.Json -v 3.1.3
dotnet add package Azure.AI.Language.QuestionAnswering

# Add initial code to program.cs file

# Program.cs file should be same as in 'mslearn-ai-language\Labfiles\02-qna\C-Sharp\qna-app\Program.cs'
Copy-Item -Path ..\mslearn-ai-language\Labfiles\02-qna\C-Sharp\qna-app\Program.cs -Destination . -Recurse -Force

#------------------------------------------------
# Add code to the application

# Finalize code as described in exercise

# ------------------------------------------------
# RUN Program 
dotnet run

#**********************************************************
# CLEANUP
az group delete --name $RESOURCEGROUP -y

# permanently delete deleted accounts: 
$deletedAccounts = az cognitiveservices account list-deleted
$deletedAccounts | ConvertFrom-Json | ForEach-Object {az resource delete --ids $_.id}

# DELETE APP FOLDER
cd ..
Remove-Item -Recurse -Force $APP_NAME
