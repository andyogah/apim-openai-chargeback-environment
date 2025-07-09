# Define the script path
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition

$resourceGroup = "rg20250412201304" # Replace with your resource group name
$backendAppName = "backendApp20250412201304" # Replace with your backend app name
$frontendAppName = "frontendApp20250412201304" # Replace with your frontend app name

# Function to zip a folder's content using Compress-Archive
function Compress-FolderContent($sourceFolder, $destinationZip) {
    if (Test-Path $destinationZip) {
        Remove-Item $destinationZip -Force
    }
    Push-Location $sourceFolder
    Compress-Archive -Path * -DestinationPath $destinationZip -Force
    Pop-Location
}

# Define the dist folder for storing zip files
$distFolderPath = Join-Path -Path $scriptPath -ChildPath "../dist"
if (-not (Test-Path $distFolderPath)) {
    New-Item -Path $distFolderPath -ItemType Directory
}

# Zip backend code
Write-Host "Zipping backend code..."
$backendFolderPath = Join-Path -Path $scriptPath -ChildPath "../app/backend"
$backendZipPath = Join-Path -Path $distFolderPath -ChildPath "backend.zip"
if (-not (Test-Path $backendFolderPath)) {
    Write-Host "Backend folder not found at $backendFolderPath. Please ensure it exists." -ForegroundColor Red
    exit 1
}
Compress-FolderContent -sourceFolder $backendFolderPath -destinationZip $backendZipPath
Write-Host "Backend code zipped successfully."

# Zip frontend code
Write-Host "Zipping frontend code..."
$frontendFolderPath = Join-Path -Path $scriptPath -ChildPath "../app/frontend"
$frontendZipPath = Join-Path -Path $distFolderPath -ChildPath "frontend.zip"
if (-not (Test-Path $frontendFolderPath)) {
    Write-Host "Frontend folder not found at $frontendFolderPath. Please ensure it exists." -ForegroundColor Red
    exit 1
}
Compress-FolderContent -sourceFolder $frontendFolderPath -destinationZip $frontendZipPath
Write-Host "Frontend code zipped successfully."

# Upload backend code
Write-Host "Uploading backend code..."
az webapp deploy --resource-group $resourceGroup --name $backendAppName --src-path $backendZipPath 
Write-Host "Backend code uploaded successfully."

# Upload frontend code
Write-Host "Uploading frontend code..."
az webapp deploy --resource-group $resourceGroup --name $frontendAppName --src-path $frontendZipPath
Write-Host "Frontend code uploaded successfully."

# Step 8: Run the app.py script
Write-Host "Starting the Quart application (app.py)..."

# Define the path to the Python executable and the app.py script
$pythonPath = "python" # Ensure Python is in your PATH, or provide the full path to the Python executable
$appScriptPath = Join-Path -Path $scriptPath -ChildPath "../app/backend/app.py"

# Start the app.py script
try {
    Start-Process -FilePath $pythonPath -ArgumentList $appScriptPath -NoNewWindow -PassThru
    Write-Host "Quart application started successfully."
} catch {
    Write-Host "Failed to start the Quart application. Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
