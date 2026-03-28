@{

RootModule        = 'VBAF.psm1'
ModuleVersion = '4.0.0'
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

Description = 'VBAF (Visual Business Automation Framework) - A complete Deep Q-Network (DQN) reinforcement learning framework built entirely in PowerShell 5.1. No Python. No dependencies. 27 phases: Core DQN engine, Q-Learning, Neural Networks, and 14 enterprise automation pillars including SelfHealing, AnomalyDetector, IncidentResponder, ComplianceReporter, UserBehaviorAnalytics, PatchIntelligence, BackupOptimizer, EnergyOptimizer, MultiSiteCoordinator, and AutoPilot (crown jewel — one agent orchestrating all 13 pillars). Real Windows data: WMI, Get-WinEvent, Get-Service, Get-HotFix. GitHub: https://github.com/JupyterPS/VBAF'

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




















