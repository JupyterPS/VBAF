#Requires -Version 5.1
<#
.SYNOPSIS
    Model Registry - Save, Load, Version and Track ML Models
.DESCRIPTION
    Implements model persistence and versioning from scratch.
    Designed as a TEACHING resource - every step explained.
    Features included:
      - Save/load trained models  : serialize weights + metadata to JSON
      - Model versioning          : semantic versioning, auto-increment
      - Metadata tracking         : metrics, params, dataset, timestamp
      - Backwards compatibility   : schema version checking on load
      - Model registry            : central index of all saved models
    Works with all VBAF ML modules (Regression, Trees, CNN, RNN, etc.)
    Standalone - no external VBAF dependencies required.
.NOTES
    Part of VBAF - Phase 7 Production Features - v2.1.0
    PS 5.1 compatible
    Teaching project - MLOps concepts explained step by step!
#>
$basePath = $PSScriptRoot

# ============================================================
# TEACHING NOTE: Why model persistence?
# Training takes time. Once trained, you want to:
#   SAVE  : preserve the model so you don't retrain every time
#   LOAD  : restore and use without retraining
#   VERSION: track which model is which (v1.0, v1.1, v2.0)
#   COMPARE: pick the best version based on metrics
#   AUDIT : know exactly what data/params produced each model
#
# This is the foundation of MLOps (ML Operations) -
# treating models like software with proper versioning!
# ============================================================

# Registry storage location
$script:VBAFRegistryPath = Join-Path $env:USERPROFILE "VBAFRegistry"
$script:RegistryIndex    = Join-Path $script:VBAFRegistryPath "registry.json"
$script:SchemaVersion    = "2.1.0"

# ============================================================
# REGISTRY INITIALIZATION
# ============================================================

function Initialize-VBAFRegistry {
    param([string]$Path = $script:VBAFRegistryPath)

    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        Write-Host "📁 Registry created: $Path" -ForegroundColor Green
    }

    $indexPath = Join-Path $Path "registry.json"
    if (-not (Test-Path $indexPath)) {
        $index = @{
            SchemaVersion = $script:SchemaVersion
            Created       = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            Models        = @{}
        }
        $index | ConvertTo-Json -Depth 5 | Set-Content $indexPath -Encoding UTF8
        Write-Host "📋 Registry index created" -ForegroundColor Green
    }

    $script:VBAFRegistryPath = $Path
    $script:RegistryIndex    = $indexPath
    return $Path
}

function Get-VBAFRegistryIndex {
    if (-not (Test-Path $script:RegistryIndex)) {
        Initialize-VBAFRegistry | Out-Null
    }
    $content = Get-Content $script:RegistryIndex -Raw -Encoding UTF8
    return $content | ConvertFrom-Json
}

function Save-VBAFRegistryIndex {
    param([object]$Index)
    $Index | ConvertTo-Json -Depth 10 | Set-Content $script:RegistryIndex -Encoding UTF8
}

# ============================================================
# VERSION MANAGEMENT
# ============================================================
# TEACHING NOTE: Semantic versioning: MAJOR.MINOR.PATCH
#   MAJOR: breaking changes (new architecture)
#   MINOR: new features (new layers added)
#   PATCH: bug fixes (same architecture, retrained)
#
# Auto-increment strategy:
#   First save         -> 1.0.0
#   Retrain same model -> bump patch (1.0.1)
#   New hyperparams    -> bump minor (1.1.0)
#   New architecture   -> bump major (2.0.0)
# ============================================================

function Get-NextVersion {
    param([string]$ModelName, [string]$BumpType = "patch")

    $index = Get-VBAFRegistryIndex
    $modelEntry = $index.Models.$ModelName

    if ($null -eq $modelEntry -or $modelEntry.Versions.Count -eq 0) {
        return "1.0.0"
    }

    # Find latest version
    $versions  = $modelEntry.Versions.PSObject.Properties.Name
    $latest    = $versions | Sort-Object { 
        $parts = $_.Split('.')
        [int]$parts[0] * 10000 + [int]$parts[1] * 100 + [int]$parts[2]
    } | Select-Object -Last 1

    $parts = $latest.Split('.')
    $major = [int]$parts[0]
    $minor = [int]$parts[1]
    $patch = [int]$parts[2]

    switch ($BumpType) {
        "major" { $major++; $minor=0; $patch=0 }
        "minor" { $minor++; $patch=0 }
        "patch" { $patch++ }
    }

    return "$major.$minor.$patch"
}

# ============================================================
# SAVE MODEL
# ============================================================
# TEACHING NOTE: Saving a model means serializing:
#   1. WEIGHTS  : the numbers learned during training
#   2. METADATA : what trained this model (hyperparams, dataset)
#   3. METRICS  : how well it performed (accuracy, loss)
#   4. VERSION  : when and what version this is
#
# We use JSON format - human readable, easy to inspect!
# ============================================================

function Save-VBAFModel {
    param(
        [string]    $ModelName,
        [object]    $Model,
        [string]    $ModelType,           # "LinearRegression", "DecisionTree", "CNN", etc.
        [hashtable] $Metrics      = @{},  # e.g. @{accuracy=0.95; loss=0.12}
        [hashtable] $Params       = @{},  # e.g. @{lr=0.01; epochs=100}
        [string]    $DatasetName  = "",
        [string]    $Description  = "",
        [string]    $BumpType     = "patch"  # "major", "minor", "patch"
    )

    Initialize-VBAFRegistry | Out-Null

    $version   = Get-NextVersion -ModelName $ModelName -BumpType $BumpType
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $modelDir  = Join-Path $script:VBAFRegistryPath "$ModelName\v$version"

    if (-not (Test-Path $modelDir)) {
        New-Item -ItemType Directory -Path $modelDir -Force | Out-Null
    }

    # Serialize weights based on model type
    $weights = Get-ModelWeights -Model $Model -ModelType $ModelType

    # Build model file
    $modelFile = @{
        SchemaVersion = $script:SchemaVersion
        ModelName     = $ModelName
        ModelType     = $ModelType
        Version       = $version
        Timestamp     = $timestamp
        Description   = $Description
        DatasetName   = $DatasetName
        Params        = $Params
        Metrics       = $Metrics
        Weights       = $weights
    }

    $modelPath = Join-Path $modelDir "model.json"
    $modelFile | ConvertTo-Json -Depth 10 | Set-Content $modelPath -Encoding UTF8

    # Update registry index
    $index = Get-VBAFRegistryIndex
    if ($null -eq $index.Models.$ModelName) {
        $index.Models | Add-Member -NotePropertyName $ModelName -NotePropertyValue ([PSCustomObject]@{
            ModelType = $ModelType
            Versions  = [PSCustomObject]@{}
            Latest    = $version
        }) -Force
    }

    $versionEntry = [PSCustomObject]@{
        Timestamp   = $timestamp
        Description = $Description
        Dataset     = $DatasetName
        Metrics     = $Metrics
        Path        = $modelPath
    }
    $index.Models.$ModelName.Versions | Add-Member -NotePropertyName $version -NotePropertyValue $versionEntry -Force
    $index.Models.$ModelName.Latest = $version

    Save-VBAFRegistryIndex -Index $index

    Write-Host ""
    Write-Host ("💾 Model saved: {0} v{1}" -f $ModelName, $version) -ForegroundColor Green
    Write-Host ("   Path    : {0}" -f $modelPath)     -ForegroundColor DarkGray
    Write-Host ("   Type    : {0}" -f $ModelType)     -ForegroundColor Cyan
    Write-Host ("   Dataset : {0}" -f $DatasetName)   -ForegroundColor Cyan
    if ($Metrics.Count -gt 0) {
        Write-Host "   Metrics :" -ForegroundColor Cyan -NoNewline
        foreach ($k in $Metrics.Keys) { Write-Host ("  {0}={1}" -f $k, $Metrics[$k]) -NoNewline -ForegroundColor White }
        Write-Host ""
    }
    Write-Host ""
    return $version
}

# ============================================================
# LOAD MODEL
# ============================================================

function Load-VBAFModel {
    param(
        [string] $ModelName,
        [string] $Version = "latest"
    )

    Initialize-VBAFRegistry | Out-Null
    $index = Get-VBAFRegistryIndex

    if ($null -eq $index.Models.$ModelName) {
        Write-Host "❌ Model not found: $ModelName" -ForegroundColor Red
        Write-Host "   Use Get-VBAFModelList to see available models" -ForegroundColor Yellow
        return $null
    }

    $resolvedVersion = if ($Version -eq "latest") {
        $index.Models.$ModelName.Latest
    } else { $Version }

    $modelPath = Join-Path $script:VBAFRegistryPath "$ModelName\v$resolvedVersion\model.json"
    if (-not (Test-Path $modelPath)) {
        Write-Host ("❌ Version {0} not found for {1}" -f $resolvedVersion, $ModelName) -ForegroundColor Red
        return $null
    }

    $modelFile = Get-Content $modelPath -Raw -Encoding UTF8 | ConvertFrom-Json

    # Schema version check - backwards compatibility
    if ($modelFile.SchemaVersion -ne $script:SchemaVersion) {
        Write-Host ("⚠️  Schema version mismatch: file={0} current={1}" -f $modelFile.SchemaVersion, $script:SchemaVersion) -ForegroundColor Yellow
        Write-Host "   Attempting load anyway..." -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host ("📂 Model loaded: {0} v{1}" -f $ModelName, $resolvedVersion) -ForegroundColor Green
    Write-Host ("   Type    : {0}" -f $modelFile.ModelType)    -ForegroundColor Cyan
    Write-Host ("   Saved   : {0}" -f $modelFile.Timestamp)    -ForegroundColor Cyan
    Write-Host ("   Dataset : {0}" -f $modelFile.DatasetName)  -ForegroundColor Cyan
    if ($null -ne $modelFile.Metrics) {
        Write-Host "   Metrics :" -ForegroundColor Cyan -NoNewline
        $modelFile.Metrics.PSObject.Properties | ForEach-Object {
            Write-Host ("  {0}={1}" -f $_.Name, $_.Value) -NoNewline -ForegroundColor White
        }
        Write-Host ""
    }
    Write-Host ""

    return $modelFile
}

# ============================================================
# WEIGHT EXTRACTION
# ============================================================
# TEACHING NOTE: Different model types store weights differently.
# We need a unified way to extract and restore them.
# ============================================================

function Get-ModelWeights {
    param([object]$Model, [string]$ModelType)

    switch ($ModelType) {
        "LinearRegression" {
            return @{ Weights=$Model.Weights; Bias=$Model.Bias }
        }
        "RidgeRegression" {
            return @{ Weights=$Model.Weights; Bias=$Model.Bias; Lambda=$Model.Lambda }
        }
        "LogisticRegression" {
            return @{ Weights=$Model.Weights; Bias=$Model.Bias }
        }
        "DecisionTree" {
            return @{ Serialized="DecisionTree weights not serializable - retrain required" }
        }
        "RandomForest" {
            return @{ Serialized="RandomForest weights not serializable - retrain required" }
        }
        "GaussianNaiveBayes" {
            return @{
                ClassPriors  = $Model.ClassPriors
                FeatureMeans = $Model.FeatureMeans
                FeatureVars  = $Model.FeatureVars
                Classes      = $Model.Classes
            }
        }
        "KMeans" {
            return @{ Centroids=$Model.Centroids; K=$Model.K }
        }
        "StandardScaler" {
            return @{ Mean=$Model.Mean; Std=$Model.Std }
        }
        "MinMaxScaler" {
            return @{ Min=$Model.Min; Max=$Model.Max }
        }
        "CNN" {
            # Use existing CNN weight serialization
            $layers = @()
            foreach ($layer in $Model.Layers) {
                $typeName = $layer.GetType().Name
                $layerData = @{ Type=$typeName }
                if ($typeName -eq "Conv2D") {
                    $layerData.Weights = $layer.Weights.Data
                    $layerData.Biases  = $layer.Biases
                }
                if ($typeName -eq "DenseLayer") {
                    $layerData.Weights = $layer.Weights
                    $layerData.Biases  = $layer.Biases
                }
                $layers += $layerData
            }
            return @{ Layers=$layers; InputH=$Model.InputH; InputW=$Model.InputW; InputC=$Model.InputC }
        }
        "Generic" {
            # Fallback - serialize whatever properties the model has
            $weights = @{}
            $Model.PSObject.Properties | ForEach-Object {
                $weights[$_.Name] = $_.Value
            }
            return $weights
        }
        default {
            return @{ Note="Unknown model type - manual weight extraction required" }
        }
    }
}

# ============================================================
# REGISTRY OPERATIONS
# ============================================================

function Get-VBAFModelList {
    param([string]$ModelName = "")

    Initialize-VBAFRegistry | Out-Null
    $index = Get-VBAFRegistryIndex

    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              VBAF Model Registry                        ║" -ForegroundColor Cyan
    Write-Host ("║  Path: {0,-51}║" -f ($script:VBAFRegistryPath -replace "^.{0,3}", "...")) -ForegroundColor DarkGray
    Write-Host "╠══════════════════════════════════════════════════════════╣" -ForegroundColor Cyan

    $models = $index.Models.PSObject.Properties
    if ($null -eq $models -or @($models).Count -eq 0) {
        Write-Host "║  No models saved yet                                    ║" -ForegroundColor Yellow
    } else {
        foreach ($modelProp in $models) {
            $name  = $modelProp.Name
            if ($ModelName -ne "" -and $name -ne $ModelName) { continue }
            $entry = $modelProp.Value
            Write-Host ("║  📦 {0,-52}║" -f $name) -ForegroundColor White
            Write-Host ("║     Type   : {0,-44}║" -f $entry.ModelType) -ForegroundColor DarkGray
            Write-Host ("║     Latest : v{0,-43}║" -f $entry.Latest) -ForegroundColor Green

            $versions = $entry.Versions.PSObject.Properties
            foreach ($vProp in $versions) {
                $vName = $vProp.Name
                $vData = $vProp.Value
                $metricsStr = ""
                if ($null -ne $vData.Metrics) {
                    $vData.Metrics.PSObject.Properties | ForEach-Object {
                        $metricsStr += "{0}={1} " -f $_.Name, $_.Value
                    }
                }
                Write-Host ("║       v{0,-8} {1,-41}║" -f $vName, $metricsStr.Trim()) -ForegroundColor DarkGray
            }
            Write-Host "║                                                         ║" -ForegroundColor Cyan
        }
    }
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Remove-VBAFModel {
    param([string]$ModelName, [string]$Version = "")

    $index = Get-VBAFRegistryIndex
    if ($null -eq $index.Models.$ModelName) {
        Write-Host "❌ Model not found: $ModelName" -ForegroundColor Red
        return
    }

    if ($Version -eq "") {
        # Remove all versions
        $modelDir = Join-Path $script:VBAFRegistryPath $ModelName
        if (Test-Path $modelDir) { Remove-Item $modelDir -Recurse -Force }
        $index.Models.PSObject.Properties.Remove($ModelName)
        Save-VBAFRegistryIndex -Index $index
        Write-Host "🗑️  Removed model: $ModelName (all versions)" -ForegroundColor Yellow
    } else {
        # Remove specific version
        $versionDir = Join-Path $script:VBAFRegistryPath "$ModelName\v$Version"
        if (Test-Path $versionDir) { Remove-Item $versionDir -Recurse -Force }
        $index.Models.$ModelName.Versions.PSObject.Properties.Remove($Version)
        # Update latest if needed
        $remaining = @($index.Models.$ModelName.Versions.PSObject.Properties.Name)
        if ($remaining.Length -gt 0) {
            $index.Models.$ModelName.Latest = $remaining | Sort-Object | Select-Object -Last 1
        } else {
            $index.Models.PSObject.Properties.Remove($ModelName)
        }
        Save-VBAFRegistryIndex -Index $index
        Write-Host ("🗑️  Removed: {0} v{1}" -f $ModelName, $Version) -ForegroundColor Yellow
    }
}

function Compare-VBAFModels {
    param([string]$ModelName)

    Initialize-VBAFRegistry | Out-Null
    $index = Get-VBAFRegistryIndex
    if ($null -eq $index.Models.$ModelName) {
        Write-Host "❌ Model not found: $ModelName" -ForegroundColor Red
        return
    }

    Write-Host ""
    Write-Host ("📊 Version Comparison: {0}" -f $ModelName) -ForegroundColor Green
    Write-Host ("   {0,-10} {1,-20} {2,-30}" -f "Version", "Saved", "Metrics") -ForegroundColor Yellow
    Write-Host ("   {0}" -f ("-" * 62)) -ForegroundColor DarkGray

    $entry    = $index.Models.$ModelName
    if ($null -eq $entry.Versions) { Write-Host "No versions found" -ForegroundColor Yellow; return }
    $versions = $entry.Versions.PSObject.Properties | Sort-Object Name

    foreach ($vProp in $versions) {
        $vName = $vProp.Name
        $vData = $vProp.Value
        $metricsStr = ""
        if ($null -ne $vData.Metrics) {
            $vData.Metrics.PSObject.Properties | ForEach-Object {
                $metricsStr += "{0}={1}  " -f $_.Name, [Math]::Round([double]$_.Value, 4)
            }
        }
        $isLatest = if ($vName -eq $entry.Latest) { " ← latest" } else { "" }
        $color    = if ($vName -eq $entry.Latest) { "Green" } else { "White" }
        Write-Host ("   {0,-10} {1,-20} {2}{3}" -f "v$vName", $vData.Timestamp, $metricsStr.Trim(), $isLatest) -ForegroundColor $color
    }
    Write-Host ""
}

function Set-VBAFRegistryPath {
    param([string]$Path)
    $script:VBAFRegistryPath = $Path
    $script:RegistryIndex    = Join-Path $Path "registry.json"
    Initialize-VBAFRegistry -Path $Path | Out-Null
    Write-Host "📁 Registry path set: $Path" -ForegroundColor Green
}

# ============================================================
# METADATA HELPERS
# ============================================================

function New-VBAFModelMetadata {
    param(
        [string]    $ModelName,
        [string]    $ModelType,
        [string]    $Description  = "",
        [string]    $DatasetName  = "",
        [hashtable] $Params       = @{},
        [hashtable] $Metrics      = @{}
    )
    return @{
        ModelName   = $ModelName
        ModelType   = $ModelType
        Description = $Description
        DatasetName = $DatasetName
        Params      = $Params
        Metrics     = $Metrics
    }
}

function Get-VBAFModelInfo {
    param([string]$ModelName, [string]$Version = "latest")
    $modelFile = Load-VBAFModel -ModelName $ModelName -Version $Version
    if ($null -eq $modelFile) { return }

    Write-Host "╔══════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host ("║  Model: {0,-29}║" -f $ModelName) -ForegroundColor White
    Write-Host ("║  Version: {0,-27}║" -f $modelFile.Version) -ForegroundColor White
    Write-Host ("║  Type   : {0,-27}║" -f $modelFile.ModelType) -ForegroundColor White
    Write-Host ("║  Saved  : {0,-27}║" -f $modelFile.Timestamp) -ForegroundColor White
    Write-Host ("║  Dataset: {0,-27}║" -f $modelFile.DatasetName) -ForegroundColor White
    if ($modelFile.Description -ne "") {
        Write-Host ("║  Desc   : {0,-27}║" -f $modelFile.Description) -ForegroundColor DarkGray
    }
    Write-Host "╠══════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "║  Params:" -ForegroundColor Yellow
    if ($null -ne $modelFile.Params) {
        $modelFile.Params.PSObject.Properties | ForEach-Object {
            Write-Host ("║    {0,-34}║" -f ("{0} = {1}" -f $_.Name, $_.Value)) -ForegroundColor White
        }
    }
    Write-Host "║  Metrics:" -ForegroundColor Yellow
    if ($null -ne $modelFile.Metrics) {
        $modelFile.Metrics.PSObject.Properties | ForEach-Object {
            Write-Host ("║    {0,-34}║" -f ("{0} = {1}" -f $_.Name, $_.Value)) -ForegroundColor Green
        }
    }
    Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Cyan
}

# ============================================================
# TEST
# 1. Run VBAF.LoadAll.ps1
#
# --- Initialize registry ---
# 2. Initialize-VBAFRegistry
#    Get-VBAFModelList
#
# --- Save a regression model ---
# 3. $data   = Get-VBAFDataset -Name "HousePrice"
#    $scaler = [StandardScaler]::new()
#    $Xs     = $scaler.FitTransform($data.X)
#    $model  = [LinearRegression]::new()
#    $model.Fit($Xs, $data.y)
#    $metrics = @{ R2=0.998; RMSE=2.1 }
#    $params  = @{ LearningRate=0.01; Epochs=1000 }
#    Save-VBAFModel -ModelName "HousePricePredictor" -Model $model `
#        -ModelType "LinearRegression" -Metrics $metrics -Params $params `
#        -DatasetName "HousePrice" -Description "Baseline linear model"
#
# --- List and inspect ---
# 4. Get-VBAFModelList
#    Get-VBAFModelInfo -ModelName "HousePricePredictor"
#
# --- Save v2 with better metrics ---
# 5. $model2 = [RidgeRegression]::new(0.1)
#    $model2.Fit($Xs, $data.y)
#    $metrics2 = @{ R2=0.999; RMSE=1.8 }
#    Save-VBAFModel -ModelName "HousePricePredictor" -Model $model2 `
#        -ModelType "RidgeRegression" -Metrics $metrics2 `
#        -DatasetName "HousePrice" -Description "Ridge regularization" -BumpType "minor"
#
# --- Compare versions ---
# 6. Compare-VBAFModels -ModelName "HousePricePredictor"
#
# --- Load specific version ---
# 7. $loaded = Load-VBAFModel -ModelName "HousePricePredictor" -Version "1.0.0"
#    $loaded.Metrics
#    $loaded.Weights
#
# --- Save a KMeans model ---
# 8. $data2 = Get-VBAFClusterDataset -Name "Blobs"
#    $km    = [KMeans]::new(3)
#    $km.Fit($data2.X)
#    Save-VBAFModel -ModelName "BlobClusterer" -Model $km -ModelType "KMeans" `
#        -Metrics @{ Silhouette=0.92 } -DatasetName "Blobs"
#
# --- Full registry view ---
# 9. Get-VBAFModelList
# ============================================================
Write-Host "📦 VBAF.ML.ModelRegistry.ps1 loaded  [v2.1.0 🏭]" -ForegroundColor Green
Write-Host "   Functions : Initialize-VBAFRegistry"            -ForegroundColor Cyan
Write-Host "              Save-VBAFModel"                      -ForegroundColor Cyan
Write-Host "              Load-VBAFModel"                      -ForegroundColor Cyan
Write-Host "              Get-VBAFModelList"                   -ForegroundColor Cyan
Write-Host "              Get-VBAFModelInfo"                   -ForegroundColor Cyan
Write-Host "              Compare-VBAFModels"                  -ForegroundColor Cyan
Write-Host "              Remove-VBAFModel"                    -ForegroundColor Cyan
Write-Host "              Set-VBAFRegistryPath"                -ForegroundColor Cyan
Write-Host "              New-VBAFModelMetadata"               -ForegroundColor Cyan
Write-Host "              Get-NextVersion"                     -ForegroundColor Cyan
Write-Host ""
Write-Host "   Registry  : $($script:VBAFRegistryPath)"        -ForegroundColor DarkGray
Write-Host ""
Write-Host "   Quick start:" -ForegroundColor Yellow
Write-Host '   Initialize-VBAFRegistry'                                        -ForegroundColor White
Write-Host '   Save-VBAFModel -ModelName "MyModel" -Model $model -ModelType "LinearRegression" -Metrics @{R2=0.99}' -ForegroundColor White
Write-Host '   Get-VBAFModelList'                                              -ForegroundColor White
Write-Host '   Compare-VBAFModels -ModelName "MyModel"'                       -ForegroundColor White
Write-Host ""