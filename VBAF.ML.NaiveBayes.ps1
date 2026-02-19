#Requires -Version 5.1
<#
.SYNOPSIS
    Naive Bayes Classification Algorithms
.DESCRIPTION
    Implements Naive Bayes variants from scratch.
    Designed as a TEACHING resource - every step explained.
    Algorithms included:
      - Gaussian Naive Bayes    : continuous features, assumes normal distribution
      - Multinomial Naive Bayes : count-based features (word counts, frequencies)
      - Bernoulli Naive Bayes   : binary features (word present/absent)
    Utilities included:
      - Text preprocessing      : tokenize, stopwords, feature vectors
      - Built-in datasets       : Iris-style numeric + spam-style text
    Standalone - no external VBAF dependencies required.
.NOTES
    Part of VBAF - Phase 4 Machine Learning Module
    PS 5.1 compatible
    Teaching project - Bayes theorem shown step by step!
#>
$basePath = $PSScriptRoot

# ============================================================
# TEACHING NOTE: What is Naive Bayes?
# Based on BAYES THEOREM:
#   P(class | features) = P(features | class) * P(class) / P(features)
#
# Translation:
#   "What is the probability this is class C, given these features?"
#   = "How likely are these features if it IS class C?"
#     * "How common is class C overall?"
#     / "How common are these features overall?"
#
# The "NAIVE" part: we assume all features are INDEPENDENT.
# This is rarely true in reality, but works surprisingly well!
#
# Three variants for different data types:
#   Gaussian    : features are continuous numbers (height, weight)
#   Multinomial : features are counts (word frequencies in text)
#   Bernoulli   : features are 0/1 (word present or absent)
# ============================================================

# ============================================================
# GAUSSIAN NAIVE BAYES
# ============================================================
# TEACHING NOTE: For continuous features, we assume each feature
# follows a Gaussian (normal) distribution within each class.
# We learn: mean and variance of each feature per class.
# Then for a new point:
#   P(feature_i | class) = Gaussian(feature_i; mean, variance)
#   Gaussian(x; mu, sigma^2) = (1/sqrt(2*pi*sigma^2)) * exp(-(x-mu)^2 / (2*sigma^2))
# ============================================================

class GaussianNaiveBayes {
    [hashtable] $ClassPriors      # P(class) for each class
    [hashtable] $FeatureMeans     # mean of each feature per class
    [hashtable] $FeatureVars      # variance of each feature per class
    [object[]]  $Classes          # unique class labels
    [bool]      $IsFitted = $false

    GaussianNaiveBayes() {}

    # Gaussian probability density
    hidden [double] GaussianPDF([double]$x, [double]$mean, [double]$variance) {
        $variance  = [Math]::Max($variance, 1e-9)  # avoid division by zero
        $exponent  = -($x - $mean) * ($x - $mean) / (2.0 * $variance)
        $coeff     = 1.0 / [Math]::Sqrt(2.0 * [Math]::PI * $variance)
        return $coeff * [Math]::Exp($exponent)
    }

    [void] Fit([double[][]]$X, [object[]]$y) {
        $n          = $X.Length
        $nFeatures  = $X[0].Length

        # Get unique classes
        $this.Classes = $y | Select-Object -Unique | Sort-Object
        $this.ClassPriors  = @{}
        $this.FeatureMeans = @{}
        $this.FeatureVars  = @{}

        foreach ($c in $this.Classes) {
            $key = "$c"

            # Collect rows for this class
            $classRows = @()
            for ($i = 0; $i -lt $n; $i++) {
                if ("$($y[$i])" -eq $key) { $classRows += ,$X[$i] }
            }

            # P(class) = count / total
            $this.ClassPriors[$key] = $classRows.Length / $n

            # Mean and variance per feature
            $means = @(0.0) * $nFeatures
            $vars  = @(0.0) * $nFeatures

            for ($f = 0; $f -lt $nFeatures; $f++) {
                $vals = $classRows | ForEach-Object { $_[$f] }
                $mu   = ($vals | Measure-Object -Average).Average
                $means[$f] = $mu
                $sumSq = 0.0
                foreach ($v in $vals) { $sumSq += ($v - $mu) * ($v - $mu) }
                $vars[$f] = $sumSq / $vals.Count
            }

            $this.FeatureMeans[$key] = $means
            $this.FeatureVars[$key]  = $vars
        }
        $this.IsFitted = $true
    }

    # Predict class probabilities (log scale for numerical stability)
    [hashtable] PredictProba([double[]]$x) {
        $logProbs = @{}
        foreach ($c in $this.Classes) {
            $key     = "$c"
            $logProb = [Math]::Log($this.ClassPriors[$key])
            for ($f = 0; $f -lt $x.Length; $f++) {
                $pdf      = $this.GaussianPDF($x[$f], $this.FeatureMeans[$key][$f], $this.FeatureVars[$key][$f])
                $logProb += [Math]::Log([Math]::Max($pdf, 1e-300))
            }
            $logProbs[$key] = $logProb
        }
        return $logProbs
    }

    [object] PredictOne([double[]]$x) {
        $logProbs = $this.PredictProba($x)
        $best     = $null
        $bestProb = [double]::MinValue
        foreach ($kv in $logProbs.GetEnumerator()) {
            if ($kv.Value -gt $bestProb) {
                $bestProb = $kv.Value
                $best     = $kv.Key
            }
        }
        return $best
    }

    [object[]] Predict([double[][]]$X) {
        $preds = @()
        foreach ($row in $X) { $preds += $this.PredictOne($row) }
        return $preds
    }

    [void] PrintSummary() {
        Write-Host ""
        Write-Host "╔══════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║      Gaussian Naive Bayes Summary    ║" -ForegroundColor Cyan
        Write-Host "╠══════════════════════════════════════╣" -ForegroundColor Cyan
        foreach ($c in $this.Classes) {
            $key   = "$c"
            $prior = [Math]::Round($this.ClassPriors[$key], 4)
            Write-Host ("║  Class {0}  prior={1,-28}║" -f $key, $prior) -ForegroundColor White
            $means = $this.FeatureMeans[$key]
            $vars  = $this.FeatureVars[$key]
            for ($f = 0; $f -lt $means.Length; $f++) {
                Write-Host ("║    f{0}: mean={1,-8} var={2,-16}║" -f $f,
                    [Math]::Round($means[$f],3), [Math]::Round($vars[$f],3)) -ForegroundColor DarkGray
            }
        }
        Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
    }
}

# ============================================================
# MULTINOMIAL NAIVE BAYES
# ============================================================
# TEACHING NOTE: For COUNT features (e.g. word frequencies).
# Instead of Gaussian, we use:
#   P(word_i | class) = (count of word_i in class + alpha) /
#                       (total words in class + alpha * vocab_size)
# The alpha is LAPLACE SMOOTHING - adds 1 to every count
# so we never get P=0 for unseen words!
# ============================================================

class MultinomialNaiveBayes {
    [hashtable] $ClassPriors      # P(class)
    [hashtable] $FeatureLogProbs  # log P(feature | class)
    [object[]]  $Classes
    [double]    $Alpha            # Laplace smoothing
    [bool]      $IsFitted = $false

    MultinomialNaiveBayes() { $this.Alpha = 1.0 }
    MultinomialNaiveBayes([double]$alpha) { $this.Alpha = $alpha }

    [void] Fit([double[][]]$X, [object[]]$y) {
        $n         = $X.Length
        $nFeatures = $X[0].Length

        $this.Classes         = $y | Select-Object -Unique | Sort-Object
        $this.ClassPriors     = @{}
        $this.FeatureLogProbs = @{}

        $nTotal = $y.Length   # store total count explicitly
        foreach ($c in $this.Classes) {
            $key = "$c"
            $classRows = @()
            for ($i = 0; $i -lt $nTotal; $i++) {
                if ("$($y[$i])" -eq $key) { $classRows += ,$X[$i] }
            }

            $this.ClassPriors[$key] = $classRows.Length / $nTotal

            # Sum counts per feature across all class documents
            $featureCounts = @(0.0) * $nFeatures
            foreach ($row in $classRows) {
                for ($f = 0; $f -lt $nFeatures; $f++) {
                    $featureCounts[$f] += $row[$f]
                }
            }

            # Total count + smoothing
            $totalCount = ($featureCounts | Measure-Object -Sum).Sum
            $totalSmoothed = $totalCount + $this.Alpha * $nFeatures

            # Log probabilities with Laplace smoothing
            $logProbs = @(0.0) * $nFeatures
            for ($f = 0; $f -lt $nFeatures; $f++) {
                $logProbs[$f] = [Math]::Log(($featureCounts[$f] + $this.Alpha) / $totalSmoothed)
            }
            $this.FeatureLogProbs[$key] = $logProbs
        }
        $this.IsFitted = $true
    }

    [object] PredictOne([double[]]$x) {
        $best     = $null
        $bestProb = [double]::MinValue
        foreach ($c in $this.Classes) {
            $key     = "$c"
            $logProb = [Math]::Log($this.ClassPriors[$key])
            for ($f = 0; $f -lt $x.Length; $f++) {
                if ($x[$f] -gt 0) {
                    $logProb += $x[$f] * $this.FeatureLogProbs[$key][$f]
                }
            }
            if ($logProb -gt $bestProb) {
                $bestProb = $logProb
                $best     = $key
            }
        }
        return $best
    }

    [object[]] Predict([double[][]]$X) {
        $preds = @()
        foreach ($row in $X) { $preds += $this.PredictOne($row) }
        return $preds
    }

    [void] PrintSummary() {
        Write-Host ""
        Write-Host "╔══════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║   Multinomial Naive Bayes Summary    ║" -ForegroundColor Cyan
        Write-Host "╠══════════════════════════════════════╣" -ForegroundColor Cyan
        Write-Host ("║  Alpha (smoothing): {0,-18}║" -f $this.Alpha) -ForegroundColor Yellow
        foreach ($c in $this.Classes) {
            $key   = "$c"
            $prior = [Math]::Round($this.ClassPriors[$key], 4)
            Write-Host ("║  Class {0}  prior={1,-28}║" -f $key, $prior) -ForegroundColor White
        }
        Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
    }
}

# ============================================================
# BERNOULLI NAIVE BAYES
# ============================================================
# TEACHING NOTE: For BINARY features (0 or 1).
# e.g. "does this email contain the word FREE? yes/no"
# P(feature_i=1 | class) = (count of docs with feature_i + alpha) /
#                          (count of class docs + 2*alpha)
# Key difference from Multinomial:
#   - Bernoulli explicitly models ABSENCE of features too
#   - "word NOT present" also carries information!
# ============================================================

class BernoulliNaiveBayes {
    [hashtable] $ClassPriors
    [hashtable] $FeatureProbs    # P(feature=1 | class)
    [object[]]  $Classes
    [double]    $Alpha
    [bool]      $IsFitted = $false

    BernoulliNaiveBayes() { $this.Alpha = 1.0 }
    BernoulliNaiveBayes([double]$alpha) { $this.Alpha = $alpha }

    [void] Fit([double[][]]$X, [object[]]$y) {
        $n         = $X.Length
        $nFeatures = $X[0].Length

        $this.Classes      = $y | Select-Object -Unique | Sort-Object
        $this.ClassPriors  = @{}
        $this.FeatureProbs = @{}

        $nTotal2 = $y.Length
        foreach ($c in $this.Classes) {
            $key = "$c"
            $classRows = @()
            for ($i = 0; $i -lt $nTotal2; $i++) {
                if ("$($y[$i])" -eq $key) { $classRows += ,$X[$i] }
            }
            $nc = $classRows.Length
            $this.ClassPriors[$key] = $nc / $nTotal2

            # Count docs where each feature = 1
            $featurePresent = @(0.0) * $nFeatures
            foreach ($row in $classRows) {
                for ($f = 0; $f -lt $nFeatures; $f++) {
                    if ($row[$f] -gt 0) { $featurePresent[$f]++ }
                }
            }

            # P(feature=1 | class) with Laplace smoothing
            $probs = @(0.0) * $nFeatures
            for ($f = 0; $f -lt $nFeatures; $f++) {
                $probs[$f] = ($featurePresent[$f] + $this.Alpha) / ($nc + 2.0 * $this.Alpha)
            }
            $this.FeatureProbs[$key] = $probs
        }
        $this.IsFitted = $true
    }

    [object] PredictOne([double[]]$x) {
        $best     = $null
        $bestProb = [double]::MinValue
        foreach ($c in $this.Classes) {
            $key     = "$c"
            $logProb = [Math]::Log($this.ClassPriors[$key])
            for ($f = 0; $f -lt $x.Length; $f++) {
                $p = $this.FeatureProbs[$key][$f]
                $p = [Math]::Max(1e-10, [Math]::Min(1 - 1e-10, $p))
                if ($x[$f] -gt 0) {
                    $logProb += [Math]::Log($p)
                } else {
                    # Bernoulli explicitly penalizes absent features too!
                    $logProb += [Math]::Log(1.0 - $p)
                }
            }
            if ($logProb -gt $bestProb) {
                $bestProb = $logProb
                $best     = $key
            }
        }
        return $best
    }

    [object[]] Predict([double[][]]$X) {
        $preds = @()
        foreach ($row in $X) { $preds += $this.PredictOne($row) }
        return $preds
    }

    [void] PrintSummary() {
        Write-Host ""
        Write-Host "╔══════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║    Bernoulli Naive Bayes Summary     ║" -ForegroundColor Cyan
        Write-Host "╠══════════════════════════════════════╣" -ForegroundColor Cyan
        Write-Host ("║  Alpha (smoothing): {0,-18}║" -f $this.Alpha) -ForegroundColor Yellow
        foreach ($c in $this.Classes) {
            $key   = "$c"
            $prior = [Math]::Round($this.ClassPriors[$key], 4)
            Write-Host ("║  Class {0}  prior={1,-28}║" -f $key, $prior) -ForegroundColor White
            $probs = $this.FeatureProbs[$key]
            for ($f = 0; $f -lt [Math]::Min($probs.Length, 5); $f++) {
                Write-Host ("║    f{0}: P(present)={1,-22}║" -f $f,
                    [Math]::Round($probs[$f], 4)) -ForegroundColor DarkGray
            }
            if ($probs.Length -gt 5) {
                Write-Host ("║    ... ({0} features total){1,-12}║" -f $probs.Length, "") -ForegroundColor DarkGray
            }
        }
        Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
    }
}

# ============================================================
# TEXT PREPROCESSING UTILITIES
# ============================================================
# TEACHING NOTE: Before classifying text we need to:
#   1. Tokenize: split "Hello World" -> ["hello", "world"]
#   2. Remove stopwords: remove "the", "a", "is", etc.
#   3. Build vocabulary: list of all unique words
#   4. Vectorize: convert text to feature vector
#      Multinomial: count how many times each word appears
#      Bernoulli  : 1 if word appears, 0 if not
# ============================================================

$script:STOPWORDS = @("the","a","an","is","it","in","on","at","to","for",
                       "of","and","or","but","not","this","that","with","are","was")

function ConvertTo-Tokens {
    param([string]$text, [switch]$RemoveStopwords)
    $words = $text.ToLower() -replace '[^a-z\s]','' -split '\s+' |
             Where-Object { $_.Length -gt 1 }
    if ($RemoveStopwords) {
        $words = $words | Where-Object { $script:STOPWORDS -notcontains $_ }
    }
    return $words
}

function New-Vocabulary {
    param([string[]]$texts)
    $vocab = [System.Collections.Generic.List[string]]::new()
    foreach ($text in $texts) {
        $tokens = ConvertTo-Tokens -text $text -RemoveStopwords
        foreach ($token in $tokens) {
            if (-not $vocab.Contains($token)) { $vocab.Add($token) }
        }
    }
    return ($vocab | Sort-Object)
}

function ConvertTo-CountVector {
    param([string]$text, [string[]]$vocabulary)
    $tokens = ConvertTo-Tokens -text $text -RemoveStopwords
    $vec    = @(0.0) * $vocabulary.Length
    for ($i = 0; $i -lt $vocabulary.Length; $i++) {
        $vec[$i] = ($tokens | Where-Object { $_ -eq $vocabulary[$i] }).Count
    }
    return $vec
}

function ConvertTo-BinaryVector {
    param([string]$text, [string[]]$vocabulary)
    $tokens = ConvertTo-Tokens -text $text -RemoveStopwords
    $vec    = @(0.0) * $vocabulary.Length
    for ($i = 0; $i -lt $vocabulary.Length; $i++) {
        $vec[$i] = if ($tokens -contains $vocabulary[$i]) { 1.0 } else { 0.0 }
    }
    return $vec
}

# ============================================================
# BUILT-IN DATASETS
# ============================================================
function Get-VBAFNBDataset {
    param([string]$Name = "Iris3Class")

    switch ($Name) {
        "Iris3Class" {
            # 3-class Iris subset - good for Gaussian NB
            Write-Host "📊 Dataset: Iris3Class (30 samples)" -ForegroundColor Cyan
            Write-Host "   Features: [sepal_length, sepal_width, petal_length, petal_width]" -ForegroundColor Cyan
            Write-Host "   Target  : 0=Setosa, 1=Versicolor, 2=Virginica" -ForegroundColor Cyan
            $X = @(
                @(5.1,3.5,1.4,0.2),@(4.9,3.0,1.4,0.2),@(4.7,3.2,1.3,0.2),
                @(5.0,3.6,1.4,0.2),@(5.4,3.9,1.7,0.4),@(4.6,3.4,1.4,0.3),
                @(5.0,3.4,1.5,0.2),@(4.4,2.9,1.4,0.2),@(4.9,3.1,1.5,0.1),@(5.4,3.7,1.5,0.2),
                @(7.0,3.2,4.7,1.4),@(6.4,3.2,4.5,1.5),@(6.9,3.1,4.9,1.5),
                @(5.5,2.3,4.0,1.3),@(6.5,2.8,4.6,1.5),@(5.7,2.8,4.5,1.3),
                @(6.3,3.3,4.7,1.6),@(4.9,2.4,3.3,1.0),@(6.6,2.9,4.6,1.3),@(5.2,2.7,3.9,1.4),
                @(6.3,3.3,6.0,2.5),@(5.8,2.7,5.1,1.9),@(7.1,3.0,5.9,2.1),
                @(6.3,2.9,5.6,1.8),@(6.5,3.0,5.8,2.2),@(7.6,3.0,6.6,2.1),
                @(4.9,2.5,4.5,1.7),@(7.3,2.9,6.3,1.8),@(6.7,2.5,5.8,1.8),@(7.2,3.6,6.1,2.5)
            )
            $y = @(0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2)
            return @{ X=$X; y=[object[]]$y; Task="classification" }
        }
        "SpamHam" {
            # Simple spam/ham text classification
            Write-Host "📊 Dataset: SpamHam (16 messages)" -ForegroundColor Cyan
            Write-Host "   Features: text messages"        -ForegroundColor Cyan
            Write-Host "   Target  : spam / ham"           -ForegroundColor Cyan
            $texts = @(
                "free money win prize claim now",
                "win cash prize free offer limited",
                "click here free gift money now",
                "congratulations you won free prize",
                "free discount offer buy now limited",
                "urgent claim your free money prize",
                "exclusive free offer win cash today",
                "limited time free money win now",
                "hey are you coming to lunch today",
                "meeting at three pm conference room",
                "please review the report by friday",
                "can we reschedule our meeting tomorrow",
                "project update attached please review",
                "see you at the office tomorrow morning",
                "quarterly results report is ready",
                "team lunch wednesday at noon confirm"
            )
            $labels = @("spam","spam","spam","spam","spam","spam","spam","spam",
                        "ham","ham","ham","ham","ham","ham","ham","ham")
            return @{ Texts=$texts; Labels=$labels; Task="text" }
        }
        default {
            Write-Host "❌ Unknown dataset: $Name" -ForegroundColor Red
            Write-Host "   Available: Iris3Class, SpamHam" -ForegroundColor Yellow
            return $null
        }
    }
}

# ============================================================
# TEST
# 1. Run VBAF.LoadAll.ps1
#
# --- Gaussian NB on Iris ---
# 2. $data  = Get-VBAFNBDataset -Name "Iris3Class"
#    $gnb   = [GaussianNaiveBayes]::new()
#    $gnb.Fit($data.X, $data.y)
#    $gnb.PrintSummary()
#    $preds = $gnb.Predict($data.X)
#    # Count correct (compare $preds vs $data.y)
#
# --- Multinomial NB on spam text ---
# 3. $data2  = Get-VBAFNBDataset -Name "SpamHam"
#    $vocab  = New-Vocabulary -texts $data2.Texts
#    $Xcount = $data2.Texts | ForEach-Object { ConvertTo-CountVector -text $_ -vocabulary $vocab }
#    $mnb    = [MultinomialNaiveBayes]::new()
#    $mnb.Fit($Xcount, $data2.Labels)
#    $mnb.PrintSummary()
#    $preds2 = $mnb.Predict($Xcount)
#
# --- Bernoulli NB on spam text ---
# 4. $Xbin  = $data2.Texts | ForEach-Object { ConvertTo-BinaryVector -text $_ -vocabulary $vocab }
#    $bnb   = [BernoulliNaiveBayes]::new()
#    $bnb.Fit($Xbin, $data2.Labels)
#    $bnb.PrintSummary()
#    $preds3 = $bnb.Predict($Xbin)
#
# --- Classify new text ---
# 5. $newMsg = "win free money now prize"
#    $vec    = ConvertTo-CountVector -text $newMsg -vocabulary $vocab
#    $mnb.PredictOne($vec)    # should predict "spam"
#    $newMsg2 = "meeting tomorrow at the office"
#    $vec2   = ConvertTo-CountVector -text $newMsg2 -vocabulary $vocab
#    $mnb.PredictOne($vec2)   # should predict "ham"
# ============================================================
Write-Host "📦 VBAF.ML.NaiveBayes.ps1 loaded" -ForegroundColor Green
Write-Host "   Classes   : GaussianNaiveBayes"              -ForegroundColor Cyan
Write-Host "              MultinomialNaiveBayes"            -ForegroundColor Cyan
Write-Host "              BernoulliNaiveBayes"              -ForegroundColor Cyan
Write-Host "   Functions : ConvertTo-Tokens"                -ForegroundColor Cyan
Write-Host "              New-Vocabulary"                   -ForegroundColor Cyan
Write-Host "              ConvertTo-CountVector"            -ForegroundColor Cyan
Write-Host "              ConvertTo-BinaryVector"           -ForegroundColor Cyan
Write-Host "              Get-VBAFNBDataset"                -ForegroundColor Cyan
Write-Host ""
Write-Host "   Quick start:" -ForegroundColor Yellow
Write-Host '   $data = Get-VBAFNBDataset -Name "Iris3Class"'  -ForegroundColor White
Write-Host '   $gnb  = [GaussianNaiveBayes]::new()'           -ForegroundColor White
Write-Host '   $gnb.Fit($data.X, $data.y)'                    -ForegroundColor White
Write-Host '   $gnb.PrintSummary()'                           -ForegroundColor White
Write-Host ""