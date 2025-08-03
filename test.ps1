# Simple test script for YouTube Automation System
# Run this from within the youtube-automation-system directory

Write-Host "=== YouTube Automation System - Quick Test ===" -ForegroundColor Blue

# Test 1: Check Node.js
Write-Host "`nTesting Node.js..." -ForegroundColor Cyan
try {
    $nodeVersion = & node --version 2>$null
    if ($nodeVersion) {
        Write-Host "✅ Node.js found: $nodeVersion" -ForegroundColor Green
    } else {
        Write-Host "❌ Node.js not found" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Node.js test failed" -ForegroundColor Red
}

# Test 2: Check npm
Write-Host "`nTesting npm..." -ForegroundColor Cyan
try {
    $npmVersion = & npm --version 2>$null
    if ($npmVersion) {
        Write-Host "✅ npm found: v$npmVersion" -ForegroundColor Green
    } else {
        Write-Host "❌ npm not found" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ npm test failed" -ForegroundColor Red
}

# Test 3: Check Git
Write-Host "`nTesting Git..." -ForegroundColor Cyan
try {
    $gitVersion = & git --version 2>$null
    if ($gitVersion) {
        Write-Host "✅ Git found: $gitVersion" -ForegroundColor Green
    } else {
        Write-Host "❌ Git not found" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Git test failed" -ForegroundColor Red
}

# Test 4: Check project structure
Write-Host "`nChecking project structure..." -ForegroundColor Cyan

$requiredFolders = @('n8n-workflows', 'ui-dashboard', 'docs', 'scripts', 'configs')
foreach ($folder in $requiredFolders) {
    if (Test-Path $folder) {
        Write-Host "✅ Folder exists: $folder" -ForegroundColor Green
    } else {
        Write-Host "❌ Missing folder: $folder" -ForegroundColor Red
    }
}

# Test 5: Check required files
Write-Host "`nChecking configuration files..." -ForegroundColor Cyan

$requiredFiles = @(
    'package.json',
    'Dockerfile', 
    'docker-compose.yml',
    'render.yaml',
    '.env.template',
    '.gitignore',
    'README.md'
)

foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "✅ File exists: $file" -ForegroundColor Green
    } else {
        Write-Host "❌ Missing file: $file" -ForegroundColor Red
    }
}

# Test 6: Check workflow files
Write-Host "`nChecking n8n workflow files..." -ForegroundColor Cyan

$workflowFiles = @(
    'n8n-workflows/workflow_1_main_automation.json',
    'n8n-workflows/workflow_2_video_scraper.json',
    'n8n-workflows/workflow_3_health_monitor.json',
    'n8n-workflows/workflow_4_enhanced_ai.json'
)

foreach ($file in $workflowFiles) {
    if (Test-Path $file) {
        $content = Get-Content $file -Raw
        if ($content -like "*Placeholder*") {
            Write-Host "⚠️  Placeholder file: $file (needs actual JSON content)" -ForegroundColor Yellow
        } else {
            Write-Host "✅ Workflow file ready: $file" -ForegroundColor Green
        }
    } else {
        Write-Host "❌ Missing workflow: $file" -ForegroundColor Red
    }
}

# Test 7: Check UI files
Write-Host "`nChecking UI dashboard files..." -ForegroundColor Cyan

if (Test-Path "ui-dashboard/index.html") {
    $uiContent = Get-Content "ui-dashboard/index.html" -Raw
    if ($uiContent.Length -gt 1000) {
        Write-Host "✅ Management UI file ready: ui-dashboard/index.html" -ForegroundColor Green
    } else {
        Write-Host "⚠️  UI file exists but may need content: ui-dashboard/index.html" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ Missing UI file: ui-dashboard/index.html" -ForegroundColor Red
}

# Test 8: Check environment configuration
Write-Host "`nChecking environment configuration..." -ForegroundColor Cyan

if (Test-Path ".env") {
    Write-Host "✅ Environment file exists: .env" -ForegroundColor Green
    
    $envContent = Get-Content ".env" -Raw
    if ($envContent -like "*your_*") {
        Write-Host "⚠️  Environment file needs API keys configuration" -ForegroundColor Yellow
    } else {
        Write-Host "✅ Environment file appears configured" -ForegroundColor Green
    }
} else {
    Write-Host "⚠️  Environment file not found - copy from .env.template" -ForegroundColor Yellow
}

# Test 9: Git repository status
Write-Host "`nChecking Git repository..." -ForegroundColor Cyan

if (Test-Path ".git") {
    Write-Host "✅ Git repository initialized" -ForegroundColor Green
    
    try {
        $gitStatus = & git status --porcelain 2>$null
        if ($gitStatus) {
            Write-Host "⚠️  Uncommitted changes detected" -ForegroundColor Yellow
        } else {
            Write-Host "✅ Git repository is clean" -ForegroundColor Green
        }
    } catch {
        Write-Host "⚠️  Could not check git status" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ Git repository not initialized" -ForegroundColor Red
}

# Summary
Write-Host "`n=== Test Summary ===" -ForegroundColor Blue
Write-Host "✅ = Ready to use" -ForegroundColor Green
Write-Host "⚠️  = Needs configuration" -ForegroundColor Yellow  
Write-Host "❌ = Missing or broken" -ForegroundColor Red

Write-Host "`nNext steps if everything looks good:" -ForegroundColor Cyan
Write-Host "1. Configure API keys in .env file"
Write-Host "2. Replace workflow JSON placeholders with actual content"
Write-Host "3. Add management UI HTML content"
Write-Host "4. Push to GitHub: git add . && git commit -m 'Setup complete' && git push"
Write-Host "5. Deploy to Render and Vercel"

Write-Host "`nTest completed!" -ForegroundColor Green