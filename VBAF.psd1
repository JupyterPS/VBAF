@{

RootModule        = 'VBAF.psm1'
ModuleVersion = '3.1.0'
GUID              = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
Author            = 'Henning'
CompanyName       = 'VBAF Project'
Copyright         = '(c) 2025-2026 Henning. All rights reserved.'
PowerShellVersion = '5.1'
CompatiblePSEditions   = @('Desktop')
DotNetFrameworkVersion = '4.5'

RequiredAssemblies = @(
    'System.Windows.Forms',
    'System.Drawing'
)

Description = 'VBAF (Visual Business Automation Framework) - A complete machine learning framework built entirely in PowerShell 5.1. No Python. No dependencies. 8 phases: Neural Networks, Q-Learning, DQN, PPO, A3C, Supervised Learning, Data Pipeline, Deep Learning (CNN/RNN/LSTM), MLOps, AutoML, Explainability. GitHub: https://github.com/JupyterPS/VBAF'

FunctionsToExport = @('*')
CmdletsToExport   = @()
VariablesToExport = @()
AliasesToExport   = @()

PrivateData = @{
    PSData = @{
        Tags = @('AI','MachineLearning','ReinforcementLearning','NeuralNetwork','QLearning','DQN','PPO','A3C','MultiAgent','Automation','Visualization','PowerShell','Education','MLOps','DeepLearning','CNN','RNN','LSTM','AutoML','DataPipeline')
        LicenseUri = 'https://github.com/JupyterPS/VBAF/blob/master/LICENSE'
        ProjectUri = 'https://github.com/JupyterPS/VBAF'
        ReleaseNotes = 'v3.0.0 (March 2026) - Full 8-phase ML framework complete. Phases 1-2: Neural Networks, Q-Learning, Dashboards. Phase 3: DQN, PPO, A3C. Phase 4: Supervised Learning. Phase 5: Data Pipeline. Phase 6: CNN, RNN, LSTM, Autoencoders, Transfer Learning. Phase 7: MLOps, Model Server, AutoML, Explainability. Phase 8: Tutorials, Examples, Templates.'
    }
}

}

















