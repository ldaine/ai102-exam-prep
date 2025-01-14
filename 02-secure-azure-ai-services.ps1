<#
**********************************************************
Secure Azure AI services
**********************************************************
#>

Exercise: https://microsoftlearning.github.io/mslearn-ai-services/Instructions/Exercises/02-ai-services-security.html

# Follow ./01-use-azure-ai-services.ps1 to create necessary resources

# Get AI SERVICE Endpoint and Key - this is needed to call AI SERVICE though SDK
$ENDPOINT = $AISERVICE_CONVERTED.properties.endpoint

#---------------------------------
# Manage authentication keys

$KEY = az cognitiveservices account keys list  --resource-group $RESOURCEGROUP --name $AISERVICESNAME --query "key1" --output tsv

# test language detection service
$URL = $ENDPOINT + "language/:analyze-text?api-version=2023-04-01"
$KEY_HEADER = "Ocp-Apim-Subscription-Key: " + $KEY

curl -X POST $URL -H "Content-Type: application/json" -H $KEY_HEADER --data-ascii "{'analysisInput':{'documents':[{'id':1,'text':'bonjour'}]}, 'kind': 'LanguageDetection'}"

# Regenerate KEY 
az cognitiveservices account keys regenerate --resource-group $RESOURCEGROUP --name $AISERVICESNAME --key-name key1

# test language detection service again -> this dhould not worl as the key is generated anew

#-------------------------------------------------
# Secure key access with Azure Key Vault
#-------------------------------------------------

#-------------------------------------------------
# create key vault in Azure Portal as described in exercise. 
$KEYVALUT_NAME = "learn-ai102-keyvault"
<#
Name : learn-ai102-keyvault
SKU: Standart
RESOURCE GROUP: $RESOURCEGROUP
LOCATION : north europe
Permission model: Vault access policy
Access policies: select your user

Simplified CLI command (without access policies): az keyvault create --location $LOCATION --name $KEY_VALUT_NAME --resource-group $RESOURCEGROUP --sku "standard"
#>
# add key in Azure Portal as described in exercise. 

#-------------------------------------------------
# Create a service principal - enable your app to use key vault
# get subscription ID

$SUBSCRIPTION_ID = az account show --query "id" --output tsv
$SP_NAME = "ai102-service-app"

$RBAC_RESULT = az ad sp create-for-rbac -n "api://$SP_NAME" --role owner --scopes subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCEGROUP
$RBAC_RESULT_CONVERTED = ConvertFrom-JSON -InputObject "RBAC_RESULT"

$APP_ID = $RBAC_RESULT_CONVERTED.appId
$APP_PSW = $RBAC_RESULT_CONVERTED.password
$APP_TENANT = $RBAC_RESULT_CONVERTED.tenant

$APP_OBJECT_ID = az ad sp show --id $APP_ID --query "id" --output tsv

# give permission to your app to use key vault
az keyvault set-policy -n $KEYVALUT_NAME --object-id $APP_OBJECT_ID --secret-permissions get list

#-------------------------------------------------
# Use the service principal in an application

# LOCALLY 
# Clone the Microsoft Lab
git clone https://github.com/MicrosoftLearning/mslearn-ai-services

# create new Project: 
$APP_NAME = "ai102-service-console-app"
dotnet new console --name $APP_NAME
cd $APP_NAME
# create app settings file
$APP_SETTINGS_TEMPLATE = @"
{
    "AIServicesEndpoint": "YOUR_AI_SERVICES_ENDPOINT",
    "KeyVault": "YOUR_KEY_VAULT_NAME",
    "TenantId": "YOUR_SERVICE_PRINCIPAL_TENANT_ID",
    "AppId": "YOUR_SERVICE_PRINCIPAL_APP_ID",
    "AppPassword": "YOUR_SERVICE_PRINCIPAL_PASSWORD"
}
"@
# if you were running all az commands from local PoserShell: 
$APP_SETTINGS = $APP_SETTINGS_TEMPLATE `
-replace 'YOUR_AI_SERVICES_ENDPOINT', $ENDPOINT `
-replace 'YOUR_KEY_VAULT_NAME', $KEYVALUT_NAME `
-replace 'YOUR_SERVICE_PRINCIPAL_TENANT_ID', $APP_TENANT `
-replace 'YOUR_SERVICE_PRINCIPAL_APP_ID', $APP_ID `
-replace 'YOUR_SERVICE_PRINCIPAL_PASSWORD', $APP_PSW

$APP_SETTINGS | Out-File appsettings.json

# otherwise: 
$APP_SETTINGS_TEMPLATE | Out-File appsettings.json

# Add following to Project file: 
<#
<ItemGroup>
    <PackageReference Include="Microsoft.Extensions.Configuration.Json" Version="7.0.0" />
  </ItemGroup>

  <ItemGroup>
    <None Update="appsettings.json">
      <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
    </None>
  </ItemGroup>
#>

dotnet add package Azure.AI.TextAnalytics --version 5.3.0
dotnet add package Azure.Identity --version 1.12.0
dotnet add package Azure.Security.KeyVault.Secrets --version 4.6.0

# ------------------------------------------------
# RUN Program 
# Program.cs file should be same as in 'mslearn-ai-services\Labfiles\02-ai-services-security\C-Sharp\keyvault_client\Program.cs'
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
