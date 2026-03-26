# VBAF Tutorials

A complete learning path from beginner to enterprise automation engineer.
All tutorials are runnable PowerShell scripts in the `tutorials/` folder.

## Learning Path

### Beginner
| File | Topic | Time |
|------|-------|------|
| [02_Beginner_FirstClassifier.ps1](../../tutorials/02_Beginner_FirstClassifier.ps1) | Your first classification model | 15 min |
| [06_Beginner_Regression.ps1](../../tutorials/06_Beginner_Regression.ps1) | Your first regression model | 20 min |
| [07_Beginner_Clustering.ps1](../../tutorials/07_Beginner_Clustering.ps1) | KMeans clustering | 20 min |
| [08_Beginner_YourOwnData.ps1](../../tutorials/08_Beginner_YourOwnData.ps1) | Load any CSV into VBAF | 25 min |

### Intermediate
| File | Topic | Time |
|------|-------|------|
| [03_Advanced_FullPipeline.ps1](../../tutorials/03_Advanced_FullPipeline.ps1) | Full ML pipeline | 30 min |
| [09_Intermediate_FeatureEngineering.ps1](../../tutorials/09_Intermediate_FeatureEngineering.ps1) | Feature engineering | 25 min |
| [10_Intermediate_ModelComparison.ps1](../../tutorials/10_Intermediate_ModelComparison.ps1) | Model comparison and HPO | 25 min |
| [11_Intermediate_Pipelines.ps1](../../tutorials/11_Intermediate_Pipelines.ps1) | Avoiding data leakage | 25 min |

### Real-World Projects
| File | Topic | Time |
|------|-------|------|
| [04_Project_HousePriceMLOps.ps1](../../tutorials/04_Project_HousePriceMLOps.ps1) | House price MLOps | 45 min |
| [05_Project_AnomalyDetection.ps1](../../tutorials/05_Project_AnomalyDetection.ps1) | Anomaly detection | 30 min |

### Enterprise
| File | Topic | Time |
|------|-------|------|
| [12_Enterprise_YourFirstDQN.ps1](../../tutorials/12_Enterprise_YourFirstDQN.ps1) | Your first DQN agent | 30 min |
| [13_Enterprise_CustomPillar.ps1](../../tutorials/13_Enterprise_CustomPillar.ps1) | Build your own pillar | 30 min |

## How to Run
```powershell
. .\VBAF.LoadAll.ps1
& ".\tutorials\02_Beginner_FirstClassifier.ps1"
```
