#Requires -Version 5.1
<#
.SYNOPSIS
    VBAF Tutorial 02 - Your First Classification Model
    Beginner Series | Estimated time: 20 minutes
.DESCRIPTION
    Learn how to:
      - Load and explore a dataset
      - Train a Naive Bayes classifier
      - Evaluate with accuracy and confusion matrix
      - Compare multiple classifiers
    Run this script section by section in PowerShell ISE
    or paste blocks into the PS console.
#>

# ============================================================
# SECTION 1: Load the framework
# ============================================================
# Uncomment the line below if you haven't loaded VBAF yet:
# . "C:\Path\To\VBAF\VBAF.LoadAll.ps1"

Write-Host "=== VBAF Tutorial 02: Your First Classifier ===" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# SECTION 2: Load a classification dataset
# ============================================================
# The Iris3Class dataset has 3 flower species:
#   0 = Setosa, 1 = Versicolor, 2 = Virginica
# Features: sepal length, sepal width, petal length, petal width

$data = Get-VBAFNBDataset -Name "Iris3Class"

Write-Host "Dataset loaded!" -ForegroundColor Green
Write-Host "  Samples : $($data.X.Length)"
Write-Host "  Classes : $($data.ClassNames -join ', ')"
Write-Host ""

# ============================================================
# SECTION 3: Split into train and test sets
# ============================================================
# TEACHING: Never evaluate on training data!
# Split 80% train / 20% test to get honest performance estimate.

$split  = Split-TrainTest -X $data.X -y $data.y -TestSize 0.2 -Seed 42

Write-Host "Train samples: $($split.XTrain.Length)" -ForegroundColor White
Write-Host "Test  samples: $($split.XTest.Length)"  -ForegroundColor White
Write-Host ""

# ============================================================
# SECTION 4: Train a Gaussian Naive Bayes classifier
# ============================================================
# TEACHING: Naive Bayes assumes each feature is independent.
# "Naive" because this is rarely true, but it works surprisingly well!
# For each class, it learns: P(class) and P(feature | class)
# Then predicts the class with highest probability.

Write-Host "Training Gaussian Naive Bayes..." -ForegroundColor Yellow
$gnb = [GaussianNaiveBayes]::new()
$gnb.Fit($split.XTrain, $split.yTrain)
$gnb.PrintSummary()

# ============================================================
# SECTION 5: Evaluate on test set
# ============================================================

$predictions = $gnb.Predict($split.XTest)
$metrics     = Get-ClassificationMetrics $split.yTest $predictions

Write-Host "Test Results:" -ForegroundColor Green
Write-Host "  Accuracy : $([Math]::Round($metrics.Accuracy * 100, 1))%" -ForegroundColor White
Write-Host ""

# ============================================================
# SECTION 6: Compare multiple classifiers
# ============================================================
# TEACHING: Always compare against baselines!
# Here we compare GaussianNB, LogisticRegression, DecisionTree

Write-Host "=== Classifier Comparison ===" -ForegroundColor Cyan
Write-Host ""

$scaler = [StandardScaler]::new()
$trainXs = $scaler.FitTransform($split.XTrain)
$testXs  = $scaler.Transform($split.XTest)

$classifiers = @(
    @{ Name="GaussianNaiveBayes";  Model=$gnb },
    @{ Name="LogisticRegression";  Model=[LogisticRegression]::new() },
    @{ Name="DecisionTree(d=3)";   Model=[DecisionTree]::new("classification", 3, 2) }
)

foreach ($clf in $classifiers) {
    if ($clf.Name -ne "GaussianNaiveBayes") {
        $clf.Model.Fit($trainXs, $split.yTrain)
        $preds = $clf.Model.Predict($testXs)
    } else {
        $preds = $clf.Model.Predict($split.XTest)
    }
    $acc = Get-ClassificationMetrics $split.yTest $preds
    $bar = "¦" * [int]($acc.Accuracy * 20)
    Write-Host ("  {0,-25} Acc={1:P1}  {2}" -f $clf.Name, $acc.Accuracy, $bar) -ForegroundColor White
}

Write-Host ""
Write-Host "Tutorial 02 complete! Try Tutorial 03 next." -ForegroundColor Green
