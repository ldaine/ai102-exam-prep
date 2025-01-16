<#
**********************************************************
Classify images
**********************************************************
#>

Exercise: https://microsoftlearning.github.io/mslearn-ai-vision/Instructions/Exercises/07-custom-vision-image-classification.html

# CONFIG
$RESOURCEGROUP="learn-ai102-vision-rg"
$LOCATION="westeurope" # Azure AI Vision 4.0 full feature sets are currently only available in these regions: East US, West US, France Central, Korea Central, North Europe, Southeast Asia, West Europe, or East Asia
$CUSTOM_VISION_NAME="ld-learn-ai102-custom-vision"
$PREDICTION_SUFFIX="-prediction"
$TRAINING_SUFFIX="-training"
$CUSTOM_VISION_PREDICTION_FULL_NAME = $CUSTOM_VISION_NAME + $PREDICTION_SUFFIX
$CUSTOM_VISION_TRAINING_FULL_NAME = $CUSTOM_VISION_NAME + $TRAINING_SUFFIX

#**********************************************************
# Exercise - Classify Images with Azure AI Custom Vision

#---------------------------------
# Create a Custom Vision project

az group create --name $RESOURCEGROUP --location $LOCATION
# to see all kind of Cognitive services: az cognitiveservices account list-kinds

$CUSTOM_VISION_TRAINING = az cognitiveservices account create -n $CUSTOM_VISION_TRAINING_FULL_NAME -g $RESOURCEGROUP --kind CustomVision.Training --sku S0 -l $LOCATION --yes
# get the data afterwards: $CUSTOM_VISION_TRAINING = az cognitiveservices account show --resource-group $RESOURCEGROUP --name $CUSTOM_VISION_TRAINING_FULL_NAME
$CUSTOM_VISION_TRAINING_CONVERTED = ConvertFrom-JSON -InputObject "$CUSTOM_VISION_TRAINING"

$CUSTOM_VISION_PREDICTION = az cognitiveservices account create -n $CUSTOM_VISION_PREDICTION_FULL_NAME -g $RESOURCEGROUP --kind CustomVision.Prediction --sku S0 -l $LOCATION --yes
# get the data afterwards: $CUSTOM_VISION_PREDICTION = az cognitiveservices account show --resource-group $RESOURCEGROUP --name $CUSTOM_VISION_PREDICTION_FULL_NAME
$CUSTOM_VISION_PREDICTION_CONVERTED = ConvertFrom-JSON -InputObject "$CUSTOM_VISION_PREDICTION"

#---------------------------------
# Get Endpoints and Keys 

$ENDPOINT_TRAINING = $CUSTOM_VISION_TRAINING_CONVERTED.properties.endpoint
$KEY_TRAINING = az cognitiveservices account keys list  --resource-group $RESOURCEGROUP --name $CUSTOM_VISION_TRAINING_FULL_NAME --query "key1" --output tsv

$ENDPOINT_PREDICTION = $CUSTOM_VISION_PREDICTION_CONVERTED.properties.endpoint
$KEY_PREDICTION = az cognitiveservices account keys list  --resource-group $RESOURCEGROUP --name $CUSTOM_VISION_PREDICTION_FULL_NAME --query "key1" --output tsv


#---------------------------------
# Create a Custom Vision project

# Go to https://customvision.ai/ and sign in with your Azure account.
# the createion of the progect in UI is NOT possible in Brave Browser. Use Edge or Chrome. 

# Follow exercise instructions

# you can also create the project using Custom Vision REST API. See https://learn.microsoft.com/en-us/rest/api/custom-vision/?view=rest-customvision-v3.3

# get project id as decribed in exercise:
$PROJECT_ID = "4e44e4f2-1e2d-48c8-ac18-2ac36c8d3100"

# ------------------------------------------------
# LOCALLY 
# Clone the Microsoft Lab
git clone https://github.com/MicrosoftLearning/mslearn-ai-vision

# ------------------------------------------------
# Use the training API
# create new Project: 
$APP_NAME_TRAIN = "ai102-custom-vision-training-console-app"

dotnet new console --name $APP_NAME_TRAIN
cd $APP_NAME
# create app settings file
$APP_SETTINGS_TEMPLATE = @"
{
  "TrainingEndpoint": "YOUR_TRAINING_ENDPOINT",
  "TrainingKey": "YOUR_TRAINING_KEY",
  "ProjectID": "YOUR_PROJECT_ID"
}
"@
# if you were running all az commands from local PoserShell: 
$APP_SETTINGS = $APP_SETTINGS_TEMPLATE `
-replace 'YOUR_TRAINING_ENDPOINT', $ENDPOINT_TRAINING `
-replace 'YOUR_TRAINING_KEY', $KEY_TRAINING `
-replace 'YOUR_PROJECT_ID', $PROJECT_ID

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
dotnet add package Microsoft.Extensions.Configuration.Json -v 3.1.9
dotnet add package Microsoft.Azure.CognitiveServices.Vision.CustomVision.Training --version 2.0.0

# Program.cs file should be same as in 'mslearn-ai-vision\Labfiles\07-custom-vision-image-classification\C-Sharp\train-classifier\Program.cs'
Copy-Item -Path ..\mslearn-ai-vision\Labfiles\07-custom-vision-image-classification\C-Sharp\train-classifier\Program.cs -Destination . -Recurse -Force

# Copy folder containing images  to the root of your app 'mslearn-ai-vision\Labfiles\07-custom-vision-image-classification\C-Sharp\train-classifier\more-training-images'
Copy-Item -Path ..\mslearn-ai-vision\Labfiles\07-custom-vision-image-classification\C-Sharp\train-classifier\more-training-images -Destination . -Recurse


dotnet run

# DELETE APP FOLDER
cd ..
Remove-Item -Recurse -Force $APP_NAME_TRAIN

# ------------------------------------------------
# Use the prediction API

# create new Project: 
$APP_NAME_PREDICTION = "ai102-custom-vision-predict-console-app"

dotnet new console --name $APP_NAME_PREDICTION
cd $APP_NAME_PREDICTION
# create app settings file
$APP_SETTINGS_TEMPLATE = @"
{
    "PredictionEndpoint": "YOUR_PREDICTION_ENDPOINT",
    "PredictionKey": "YOUR_PREDICTION_KEY",
    "ProjectID": "YOUR_PROJECT_ID",
    "ModelName": "fruit-classifier"
  }
"@
# if you were running all az commands from local PoserShell: 
$APP_SETTINGS = $APP_SETTINGS_TEMPLATE `
-replace 'YOUR_PREDICTION_ENDPOINT', $ENDPOINT_PREDICTION `
-replace 'YOUR_PREDICTION_KEY', $KEY_PREDICTION `
-replace 'YOUR_PROJECT_ID', $PROJECT_ID

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
dotnet add package Microsoft.Extensions.Configuration.Json -v 3.1.9
dotnet add package Microsoft.Azure.CognitiveServices.Vision.CustomVision.Prediction --version 2.0.0

# Program.cs file should be same as in 'mslearn-ai-vision\Labfiles\07-custom-vision-image-classification\C-Sharp\test-classifier\Program.cs'
Copy-Item -Path ..\mslearn-ai-vision\Labfiles\07-custom-vision-image-classification\C-Sharp\test-classifier\Program.cs -Destination . -Recurse -Force
# Copy folder containing images  to the root of your app 'mslearn-ai-vision\Labfiles\07-custom-vision-image-classification\C-Sharp\train-classifier\test-images'
Copy-Item -Path ..\mslearn-ai-vision\Labfiles\07-custom-vision-image-classification\C-Sharp\test-classifier\test-images -Destination . -Recurse

dotnet run

# DELETE APP FOLDER
cd ..
Remove-Item -Recurse -Force $APP_NAME_PREDICTION

#**********************************************************
# CLEANUP
az group delete --name $RESOURCEGROUP -y

# permanently delete deleted accounts: 
$deletedAccounts = az cognitiveservices account list-deleted
$deletedAccounts | ConvertFrom-Json | ForEach-Object {az resource delete --ids $_.id}

# DELETE APP FOLDER
cd ..
Remove-Item -Recurse -Force $APP_NAME