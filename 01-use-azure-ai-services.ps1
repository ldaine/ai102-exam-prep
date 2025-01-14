<#
**********************************************************
Create and consume Azure AI Services
**********************************************************
#>

Exercise: https://microsoftlearning.github.io/mslearn-ai-services/Instructions/Exercises/01-use-azure-ai-services.html

# CONFIG
$RESOURCEGROUP="learn-ai102-rg"
$LOCATION="northeurope"
$AISERVICESNAME="ld-learn-ai102-service"

#**********************************************************
# Exercise - Use Azure AI services

az group create --name $RESOURCEGROUP --location $LOCATION
# to see all kind of Cognitive services: az cognitiveservices account list-kinds
$AISERVICE = az cognitiveservices account create -n $AISERVICESNAME -g $RESOURCEGROUP --kind CognitiveServices --sku S0 -l $LOCATION --yes
# get the data afterwards: $AISERVICE = az cognitiveservices account show --resource-group $RESOURCEGROUP --name $AISERVICESNAME
$AISERVICE_CONVERTED = ConvertFrom-JSON -InputObject "$AISERVICE"

# Get AI SERVICE Endpoint and Key - this is needed to call AI SERVICE though SDK
$ENDPOINT = $AISERVICE_CONVERTED.properties.endpoint
$KEY = az cognitiveservices account keys list  --resource-group $RESOURCEGROUP --name $AISERVICESNAME --query "key1" --output tsv

# ------------------------------------------------
# LOCALLY 
# Clone the Microsoft Lab
git clone https://github.com/MicrosoftLearning/mslearn-ai-services

# create new Project: 
$APP_NAME = "ai102-service-console-app"
dotnet new console --name $APP_NAME
cd $APP_NAME
# create app settings file
$APP_SETTINGS = @"
{
    "AIServicesEndpoint": "<ai-service-endpoint>",
    "AIServicesKey": "<ai-service-key>"
}
"@
$APP_SETTINGS | Out-File appsettings.json

# Add following to Project file: 
<#
<ItemGroup>
    <PackageReference Include="Azure.AI.TextAnalytics" Version="5.3.0" /><!-- AZURE AI SDK -->
    <PackageReference Include="Microsoft.Extensions.Configuration.Json" Version="7.0.0" />
    <PackageReference Include="Newtonsoft.Json" Version="13.0.3" />
  </ItemGroup>

  <ItemGroup>
    <None Update="appsettings.json">
      <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
    </None>
  </ItemGroup>
#>

# ------------------------------------------------
# RUN Program 
# WITH REST-API
# Program.cs file should be same as in 'mslearn-ai-services\Labfiles\01-use-azure-ai-services\C-Sharp\rest-client\Program.cs'
Run 'dotnet run'

# WITH SDK
# Program.cs file should be same as in 'mslearn-ai-services\Labfiles\01-use-azure-ai-services\C-Sharp\sdk-client\Program.cs'
Run 'dotnet run'

#**********************************************************
# CLEANUP
az group delete --name $RESOURCEGROUP -y

# permanently delete deleted accounts: 
$deletedAccounts = az cognitiveservices account list-deleted
$deletedAccounts | ConvertFrom-Json | ForEach-Object {az resource delete --ids $_.id}

# DELETE APP FOLDER
cd ..
Remove-Item -Recurse -Force $APP_NAME
