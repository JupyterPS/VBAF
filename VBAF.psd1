@{

RootModule        = 'VBAF.psm1'
ModuleVersion = '5.0.2'
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
        ReleaseNotes = 'v5.0.1 (June 2026) - Educational repositioning. 6 runnable examples with launchers. Full docs: Theory, Architecture, API-Reference, GettingStarted. Educational tools: Start-VBAFTeach, Start-VBAFPlayground, Invoke-VBAFAgentBenchmark. DQN, PPO, A3C implemented and benchmarkable. Multi-agent market simulation. 14 enterprise automation pillars. Runs on any Windows PC with no dependencies.'
    }
}

}


























