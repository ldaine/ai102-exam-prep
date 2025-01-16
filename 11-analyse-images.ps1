<#
**********************************************************
Analyze images
**********************************************************
#>

Exercise: https://microsoftlearning.github.io/mslearn-ai-vision/Instructions/Exercises/01-analyze-images.html

# CONFIG
$RESOURCEGROUP="learn-ai102-vision-rg"
$LOCATION="westeurope" # Azure AI Vision 4.0 full feature sets are currently only available in these regions: East US, West US, France Central, Korea Central, North Europe, Southeast Asia, West Europe, or East Asia
$AISERVICESNAME="ld-learn-ai102-vision-service"

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
git clone https://github.com/MicrosoftLearning/mslearn-ai-vision

# create new Project: 
$APP_NAME = "ai102-vision-service-console-app"
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
dotnet add package System.Drawing.Common -v 8.0.1
dotnet add package Microsoft.Extensions.Configuration.Json -v 3.0.3
dotnet add package Azure.AI.Vision.ImageAnalysis -v 1.0.0-beta.3

# Add Code to program.cs file

# Program.cs file should be same as in 'mslearn-ai-vision\Labfiles\01-analyze-images\C-Sharp\image-analysis\Program.cs'

# Finalize code as described in exercise

# function to display results: 
# DisplaySummary(result);
<#
  private static void DisplaySummary(ImageAnalysisResult result)
  {
      // get image captions

      if (result.Caption.Text != null)
      {
          Console.WriteLine($"Caption: {result.Caption.Text}");
          Console.WriteLine($"Caption Confidence: {result.Caption.Confidence:0.00}\n");
      }

      // get image dense captions

      Console.WriteLine("Dense Captions:");
      foreach (var caption in result.DenseCaptions.Values)
      {
          Console.WriteLine($"  {caption.Text}");
          Console.WriteLine($"  Confidence: {caption.Confidence:0.00}\n");
      }

      // get image tags

      Console.WriteLine("Tags:");

      foreach (var tag in result.Tags.Values)
      {
          Console.WriteLine($"  {tag.Name} ({tag.Confidence:0.00})");
      }

      // get objects in image 

      Console.WriteLine("Objects:");

      foreach (DetectedObject obj in result.Objects.Values)
      {
          Console.WriteLine("Object Tags: ");
          foreach (var tag in obj.Tags)
          {
              Console.WriteLine($"  {tag.Name} ({tag.Confidence:0.00})");
          }
          Console.WriteLine("Object Box:");
          Console.WriteLine($"Object Bounding Box: {obj.BoundingBox.X}, {obj.BoundingBox.Y}, {obj.BoundingBox.Width}, {obj.BoundingBox.Height}");
      }

      // get people in the image

      Console.WriteLine("People:");

      foreach (DetectedPerson person in result.People.Values)
      {
          Console.WriteLine($"  Confidence: {person.Confidence:0.00}\n");
          Console.WriteLine($"Object Bounding Box: {person.BoundingBox.X}, {person.BoundingBox.Y}, {person.BoundingBox.Width}, {person.BoundingBox.Height}");
      }
  }
#>

# Function to show detected objects: 
# GenerateImageWithDetectedObjects(result.Objects, stream, imageFile);

<#
  private static void GenerateImageWithDetectedObjects(ObjectsResult objectsResult, FileStream stream, string originalImageFile)
  {
      if (objectsResult.Values.Count == 0){
          Console.WriteLine("No objects detected in the image");
          return;
      }

      // Prepare image for drawing
      stream.Close();
      System.Drawing.Image image = System.Drawing.Image.FromFile(originalImageFile);
      Graphics graphics = Graphics.FromImage(image);
      Pen pen = new Pen(Color.Cyan, 3);
      Font font = new Font("Arial", 16);
      SolidBrush brush = new SolidBrush(Color.WhiteSmoke);

      foreach (DetectedObject detectedObject in objectsResult.Values)
      {
          // Draw object bounding box
          var r = detectedObject.BoundingBox;
          Rectangle rect = new Rectangle(r.X, r.Y, r.Width, r.Height);
          graphics.DrawRectangle(pen, rect);
          graphics.DrawString(detectedObject.Tags[0].Name, font, brush, (float)r.X, (float)r.Y);
      }

      // Save annotated image
      String output_file = "objects.jpg";
      image.Save(output_file);
      Console.WriteLine("  Results saved in " + output_file + "\n");
  }
#>


# Function to show detected people: 
# GenerateImageWithDetectedPeople(result.People, stream, imageFile);

<#
  private static void GenerateImageWithDetectedPeople(PeopleResult peopleResult, FileStream stream, string originalImageFile)
  {
      if (peopleResult.Values.Count == 0){
          Console.WriteLine("No people detected in the image");
          return;
      }
      // Prepare image for drawing
      System.Drawing.Image image = System.Drawing.Image.FromFile(originalImageFile);
      Graphics graphics = Graphics.FromImage(image);
      Pen pen = new Pen(Color.Cyan, 3);
      Font font = new Font("Arial", 16);
      SolidBrush brush = new SolidBrush(Color.WhiteSmoke);

      foreach (DetectedPerson person in peopleResult.Values)
      {
          // Draw object bounding box
          var r = person.BoundingBox;
          Rectangle rect = new Rectangle(r.X, r.Y, r.Width, r.Height);
          graphics.DrawRectangle(pen, rect);
      }

      // Save annotated image
      String output_file = "persons.jpg";
      image.Save(output_file);
      Console.WriteLine("  Results saved in " + output_file + "\n");
  }
#>

# ------------------------------------------------
# RUN Program 
# you can get images from 'mslearn-ai-vision\Labfiles\01-analyze-images\C-Sharp\image-analysis\images'
# for convinience copy the folder to your console app folder
dotnet run images/street.jpg

#**********************************************************
# CLEANUP
az group delete --name $RESOURCEGROUP -y

# permanently delete deleted accounts: 
$deletedAccounts = az cognitiveservices account list-deleted
$deletedAccounts | ConvertFrom-Json | ForEach-Object {az resource delete --ids $_.id}

# DELETE APP FOLDER
cd ..
Remove-Item -Recurse -Force $APP_NAME
