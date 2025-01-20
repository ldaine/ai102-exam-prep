<#
**********************************************************
Analyze text with Azure AI Language
**********************************************************
#>

Exercise: https://microsoftlearning.github.io/mslearn-ai-language/Instructions/Exercises/01-analyze-text.html

# CONFIG
$RESOURCEGROUP="learn-ai102-language-rg"
$LOCATION="northeurope" 
$AISERVICESNAME="ld-learn-ai102-language-service"

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

# ------------------------------------------------
# LOCALLY 
# Clone the Microsoft Lab
git clone https://github.com/MicrosoftLearning/mslearn-ai-language

# create new Project: 
$APP_NAME = "ai102-language-service-console-app"
dotnet new console --name $APP_NAME
cd $APP_NAME
# create app settings file
$APP_SETTINGS_TEMPLATE = @"
{
    "AIServicesEndpoint": "YOUR_AZURE_AI_SERVICES_ENDPOINT",    
    "AIServicesKey": "YOUR_AZURE_AI_SERVICES_KEY"
}
"@
# if you were running all az commands from local PoserShell: 
$APP_SETTINGS = $APP_SETTINGS_TEMPLATE `
-replace 'YOUR_AZURE_AI_SERVICES_ENDPOINT', $ENDPOINT `
-replace 'YOUR_AZURE_AI_SERVICES_KEY', $KEY

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
dotnet add package Azure.AI.TextAnalytics --version 5.3.0

# ------------------------------------------------
# Add initial code to program.cs file

# Program.cs file should be same as in 'mslearn-ai-language\Labfiles\01-analyze-text\C-Sharp\text-analysis\Program.cs'
Copy-Item -Path ..\mslearn-ai-language\Labfiles\01-analyze-text\C-Sharp\text-analysis\Program.cs -Destination . -Recurse -Force
# Copy folder containing images  to the root of your app 'mslearn-ai-language\Labfiles\01-analyze-text\C-Sharp\text-analysis\reviews'
Copy-Item -Path ..\mslearn-ai-language\Labfiles\01-analyze-text\C-Sharp\text-analysis\reviews -Destination . -Recurse

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
