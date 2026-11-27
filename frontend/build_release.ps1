<#
.SYNOPSIS
Builds the Flutter Android App Bundle (AAB) for production.

.DESCRIPTION
This script safely injects the verified production backend HTTPS URL into the Flutter release build process using the --dart-define flag.

.EXAMPLE
.\build_release.ps1 -ApiUrl "https://api.tactilearchive.org"
#>

param (
    [Parameter(Mandatory=$true, HelpMessage="The production HTTPS URL of your backend (e.g., https://api.tactilearchive.org)")]
    [string]$ApiUrl
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($ApiUrl) -or -not ($ApiUrl.StartsWith("https://"))) {
    Write-Host "❌ Error: -ApiUrl must be a valid, explicit HTTPS URL ('https://...'). Cleartext HTTP and empty URLs are prohibited in production." -ForegroundColor Red
    exit 1
}

$ApiUrl = $ApiUrl.TrimEnd('/')

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "🚀 Building Production Release for Android" -ForegroundColor Cyan
Write-Host "🔗 API URL: $ApiUrl" -ForegroundColor Yellow
Write-Host "=============================================" -ForegroundColor Cyan

# Check if flutter is available
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Flutter command not found. Please ensure Flutter is in your PATH." -ForegroundColor Red
    exit 1
}

# Run Flutter build with the Dart define
Write-Host "`n🧹 Cleaning previous builds..."
flutter clean
flutter pub get

Write-Host "`n🔨 Generating App Bundle..."
flutter build appbundle --release --dart-define=API_URL=$ApiUrl

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ Build Successful!" -ForegroundColor Green
    Write-Host "📂 Your release app bundle is located at: build\app\outputs\bundle\release\app-release.aab" -ForegroundColor Green
    Write-Host "Upload this file to the Google Play Console." -ForegroundColor Yellow
} else {
    Write-Host "`n❌ Build Failed!" -ForegroundColor Red
}
