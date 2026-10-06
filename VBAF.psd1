@{

RootModule        = 'VBAF.psm1'
ModuleVersion = '6.0.0'
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

Description = 'VBAF (Visual AI and Reinforcement Learning Framework) - An educational AI framework built entirely in PowerShell 5.1. No Python. No dependencies. Implements neural networks, Q-learning, DQN, PPO and A3C from scratch with full educational comments and original paper references. Includes 6 runnable examples, interactive console teacher, experiment playground, multi-agent market simulation, and 14 enterprise automation pillars. Runs on any Windows PC. GitHub: https://github.com/JupyterPS/VBAF'

FunctionsToExport = @('*')
CmdletsToExport   = @()
VariablesToExport = @()
AliasesToExport   = @()

PrivateData = @{
    PSData = @{
        Tags = @('AI','MachineLearning','ReinforcementLearning','NeuralNetwork','QLearning','DQN','PPO','A3C','MultiAgent','Automation','Visualization','PowerShell','Education','MLOps','DeepLearning','CNN','RNN','LSTM','AutoML','DataPipeline')
        LicenseUri = 'https://github.com/JupyterPS/VBAF/blob/master/LICENSE'
        ProjectUri = 'https://github.com/JupyterPS/VBAF'
        ReleaseNotes = '6.0.0 (October 2026) - The kernel learns, and proves it: 10 kernel fixes (DQN output layer, Predict copy, seeding, LoadAll outside ISE and more), a regression suite of 68 checks, Get-VBAFTrace, a production cell and evolution study (Invoke-VBAFEvolutionStudy), an evolution window, Teach topic 7 and an honest re-measurement of all 26 pillars. See CHANGELOG.md.'
    }
}

}




























