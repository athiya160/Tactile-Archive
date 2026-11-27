<#
.SYNOPSIS
Builds and deploys the Flutter Web App to Firebase Hosting.

.DESCRIPTION
Injects the production backend HTTPS URL via --dart-define=API_URL and deploys the release bundle to Firebase Hosting.
Requires an explicit, non-empty HTTPS backend URL.

.EXAMPLE
.\deploy_web.ps1 -BackendUrl "https://api.tactilearchive.org"
#>

param (
    [Parameter(Mandatory=$true, HelpMessage="Production backend HTTPS URL (e.g., https://api.tactilearchive.org)")]
    [string]$BackendUrl
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($BackendUrl) -or -not ($BackendUrl.StartsWith("https://"))) {
    Write-Host "❌ Error: -BackendUrl must be a valid, explicit HTTPS URL ('https://...'). Cleartext HTTP and empty URLs are prohibited in production." -ForegroundColor Red
    exit 1
}

$BackendUrl = $BackendUrl.TrimEnd('/')

Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "🚀 THE TACTILE ARCHIVE — FLUTTER WEB DEPLOYMENT" -ForegroundColor Cyan
Write-Host "🔗 Target Backend: $BackendUrl" -ForegroundColor Yellow
Write-Host "======================================================" -ForegroundColor Cyan

# 1. Check Flutter
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Flutter CLI is not installed or not in PATH." -ForegroundColor Red
    exit 1
}

# 2. Check Firebase CLI
if (-not (Get-Command firebase -ErrorAction SilentlyContinue)) {
    Write-Host "⚠️ Firebase CLI not found. Run 'npm install -g firebase-tools' and 'firebase login'." -ForegroundColor Yellow
}

# 3. Clean & Prepare Dependencies
Write-Host "`n📦 Fetching Flutter dependencies..." -ForegroundColor Green
flutter pub get

# 4. Build Production Web Bundle
Write-Host "`n🔨 Compiling Flutter Web Release (CanvasKit + PWA optimization)..." -ForegroundColor Green
flutter build web --release --dart-define=API_URL=$BackendUrl --base-href "/"

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n❌ Web compilation failed. Check errors above." -ForegroundColor Red
    exit 1
}

Write-Host "`n✅ Web bundle compiled successfully into: build/web" -ForegroundColor Green

# 4b. Inject production backend URL into static compliance pages
$AccountDeletionBuilt = "build/web/account_deletion.html"
if (Test-Path $AccountDeletionBuilt) {
    (Get-Content $AccountDeletionBuilt) -replace '<meta name="api-base-url" content="[^"]*">', ('<meta name="api-base-url" content="' + $BackendUrl + '">') | Set-Content $AccountDeletionBuilt -Encoding UTF8
    Write-Host "✅ Injected API base URL into $AccountDeletionBuilt" -ForegroundColor Green
}

# 5. Deploy to Firebase Hosting
if (Get-Command firebase -ErrorAction SilentlyContinue) {
    Write-Host "`n🚀 Deploying to Firebase Hosting..." -ForegroundColor Cyan
    firebase deploy --only hosting
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n🎉 Deployment Complete! Your app is live." -ForegroundColor Green
    } else {
        Write-Host "`n❌ Firebase deployment failed. Check authentication or project settings." -ForegroundColor Red
    }
} else {
    Write-Host "`n💡 To deploy manually to Firebase Hosting:" -ForegroundColor Yellow
    Write-Host "   1. npm install -g firebase-tools"
    Write-Host "   2. firebase login"
    Write-Host "   3. firebase deploy --only hosting"
}
