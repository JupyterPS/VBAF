# VBAF Documentation

Complete learning path from zero to VBAF expert.
Start at line 1. Work down. Skip nothing.

---

## FOUNDATION -- read first

1. [README.md](../README.md)                          -- what VBAF is and why
2. [GettingStarted.md](GettingStarted.md)             -- install, load, first run
3. [Architecture.md](Architecture.md)                 -- how the layers fit together
4. [Theory.md](Theory.md)                             -- the math behind everything
5. [VBAF.CheatSheet.md](../VBAF.CheatSheet.md)        -- one page quick reference

---

## EXAMPLES -- run in this exact order

6.  `examples\01-XOR-Network\Run-Example-01.ps1`           -- neural networks
7.  `examples\02-Castle-Learning\Run-Example-02.ps1`        -- Q-learning
8.  `examples\03-Market-Simulation\Run-Example-03.ps1`      -- multi-agent
9.  `examples\04-Learning-Dashboard\Run-Example-04.ps1`     -- visualisation
10. `examples\05-Validation-Dashboard\Run-Example-05.ps1`   -- validation
11. `examples\06-Custom-Agent\Run-Example-06.ps1`           -- build your own

---

## INTERACTIVE TOOLS -- guided learning

12. `Start-VBAFTeach -Topic "MachineLearning"`     -- what is ML?
13. `Start-VBAFTeach -Topic "NeuralNetwork"`       -- backpropagation
14. `Start-VBAFTeach -Topic "QLearning"`           -- Q-table and Bellman
15. `Start-VBAFTeach -Topic "DQN"`                 -- experience replay
16. `Start-VBAFTeach -Topic "MultiAgent"`          -- emergent behaviour
17. `Start-VBAFTeach -Topic "Enterprise"`          -- automation pillars
18. `Start-VBAFPlayground -Algorithm "Supervised"` -- experiment with ML
19. `Start-VBAFPlayground -Algorithm "QLearning"`  -- tune alpha and gamma
20. `Start-VBAFPlayground -Algorithm "DQN"`        -- tune hyperparameters
21. `Start-VBAFPlayground -Algorithm "Enterprise"` -- run any pillar

---

## TUTORIALS -- step by step code

22. `tutorials\01_Beginner_FirstNeuralNetwork.ps1`
23. `tutorials\02_Beginner_FirstClassifier.ps1`
24. `tutorials\03_Beginner_QLearningAgent.ps1`
25. `tutorials\06_Beginner_Regression.ps1`
26. `tutorials\07_Beginner_Clustering.ps1`
27. `tutorials\08_Beginner_LoadCSV.ps1`
28. `tutorials\09_Intermediate_FeatureEngineering.ps1`
29. `tutorials\10_Intermediate_ModelComparison.ps1`
30. `tutorials\11_Intermediate_CorrectPipeline.ps1`
31. `tutorials\12_Enterprise_YourFirstDQN.ps1`
32. `tutorials\13_Enterprise_CustomPillar.ps1`

---

## DASHBOARDS -- run from standalone PowerShell console

33. `VBAF.Visualization.Example-Dashboard.ps1`     -- learning curves live
34. `VBAF.Business.Dashboard-Demo.ps1`             -- market competition live
35. `VBAF.Core.Test-ValidationDashboard.ps1`       -- three panel validation
36. `VBAF.Art.Show20-QLearning.ps1`                -- Q-learning visualised
37. `VBAF.Art.CastleCompetition.ps1`               -- castle battle live

---

## BENCHMARKING

38. `Invoke-VBAFQuickBenchmark -AgentName "DQN" -Environment "CartPole"`
39. `Invoke-VBAFAgentBenchmark -Environment "CartPole" -Episodes 50`
40. `Invoke-VBAFAgentBenchmark -Agents @("DQN","PPO","A3C") -Episodes 100`

---

## SUPERVISED LEARNING -- read the source

41. `VBAF.Core.AllClasses.ps1`                -- neural network from scratch
42. `VBAF.ML.Regression.ps1`                  -- linear, ridge, lasso
43. `VBAF.ML.Trees.ps1`                       -- decision tree, random forest
44. `VBAF.ML.Clustering.ps1`                  -- KMeans, DBSCAN, hierarchical
45. `VBAF.ML.NaiveBayes.ps1`                  -- Gaussian, Multinomial, Bernoulli
46. `VBAF.ML.DataPipeline.ps1`                -- imputation, scaling, encoding
47. `VBAF.ML.FeatureEngineering.ps1`          -- polynomial, PCA, pipeline
48. `VBAF.ML.DataIO.ps1`                      -- CSV, JSON, Excel, SQL, API
49. `VBAF.ML.TimeSeries.ps1`                  -- lag features, decomposition
50. `VBAF.ML.AutoML.ps1`                      -- grid, random, Bayesian search
51. `VBAF.ML.Explainability.ps1`              -- SHAP, LIME, permutation

---

## DEEP LEARNING -- read the source

52. `VBAF.ML.CNN.ps1`                         -- Conv2D, pooling, flatten
53. `VBAF.ML.RNN.ps1`                         -- LSTM, GRU, bidirectional
54. `VBAF.ML.Autoencoder.ps1`                 -- encode, latent space, decode
55. `VBAF.ML.TransferLearning.ps1`            -- freeze, extract, fine-tune

---

## ML PRODUCTION -- read the source

56. `VBAF.ML.ModelRegistry.ps1`               -- save, load, version, compare
57. `VBAF.ML.ModelServer.ps1`                 -- predict, A/B test, monitor
58. `VBAF.ML.MLOps.ps1`                       -- experiments, drift, CI/CD

---

## REINFORCEMENT LEARNING -- read the source

59. `VBAF.RL.QTable.ps1`                      -- hashtable Q-table structure
60. `VBAF.RL.ExperienceReplay.ps1`            -- circular buffer, sampling
61. `VBAF.RL.QLearningAgent.ps1`              -- Bellman, epsilon-greedy
62. `VBAF.RL.Environment.ps1`                 -- CartPole, GridWorld, RandomWalk
63. `VBAF.RL.DQN.ps1`                         -- main network, target network
64. `VBAF.RL.PPO.ps1`                         -- actor-critic, GAE, clip trick
65. `VBAF.RL.A3C.ps1`                         -- workers, shared network

---

## MULTI-AGENT -- read the source

66. `VBAF.Business.CompanyState.ps1`          -- company state variables
67. `VBAF.Business.BusinessAction.ps1`        -- action space definitions
68. `VBAF.Business.CompanyAgent.ps1`          -- Q-learning in business context
69. `VBAF.Business.MarketEnvironment.ps1`     -- Bertrand competition, HHI

---

## ENTERPRISE PILLARS -- read in phase order

70. `VBAF.Enterprise.Environment.ps1`           -- base environment interface
71. `VBAF.Enterprise.JobScheduler.ps1`          -- Phase 4: adaptive scheduling
72. `VBAF.Enterprise.ResourceOptimizer.ps1`     -- Phase 5: IT optimisation
73. `VBAF.Enterprise.AlertRouter.ps1`           -- Phase 6: intelligent routing
74. `VBAF.Enterprise.SupplyChain.ps1`           -- Phase 7: supply chain
75. `VBAF.Enterprise.SecurityMonitor.ps1`       -- Phase 8: security threats
76. `VBAF.Enterprise.NetworkWatcher.ps1`        -- Phase 9: network intelligence
77. `VBAF.Enterprise.DataFlowOptimizer.ps1`     -- Phase 10: database optimisation
78. `VBAF.Enterprise.MultiAgentCoordinator.ps1` -- Phase 11: collaboration
79. `VBAF.Enterprise.PredictiveMaintenance.ps1` -- Phase 12: predict failures
80. `VBAF.Enterprise.NLInterface.ps1`           -- Phase 13: natural language
81. `VBAF.Enterprise.SelfHealing.ps1`           -- Phase 14: self-repair
82. `VBAF.Enterprise.Dashboard.ps1`             -- Phase 15: dashboard intel
83. `VBAF.Enterprise.FederatedLearning.ps1`     -- Phase 16: distributed ML
84. `VBAF.Enterprise.CloudBridge.ps1`           -- Phase 17: cloud workloads
85. `VBAF.Enterprise.AnomalyDetector.ps1`       -- Phase 18: anomaly detection
86. `VBAF.Enterprise.CapacityPlanner.ps1`       -- Phase 19: capacity planning
87. `VBAF.Enterprise.IncidentResponder.ps1`     -- Phase 20: incident response
88. `VBAF.Enterprise.ComplianceReporter.ps1`    -- Phase 21: compliance
89. `VBAF.Enterprise.UserBehaviorAnalytics.ps1` -- Phase 22: insider threats
90. `VBAF.Enterprise.PatchIntelligence.ps1`     -- Phase 23: smart patching
91. `VBAF.Enterprise.BackupOptimizer.ps1`       -- Phase 24: backup strategy
92. `VBAF.Enterprise.EnergyOptimizer.ps1`       -- Phase 25: power reduction
93. `VBAF.Enterprise.MultiSiteCoordinator.ps1`  -- Phase 26: multi-datacenter
94. `VBAF.Enterprise.AutoPilot.ps1`             -- Phase 27: crown jewel

---

## DOMAIN SPECIFIC

95. `VBAF.Enterprise.FleetDispatch.ps1`         -- truck company DK
96. `VBAF.Enterprise.HealthcareMonitor.ps1`     -- hospital bed management

---

## BUILD YOUR OWN

97. `tutorials\13_Enterprise_CustomPillar.ps1`  -- template for new pillar
98. [Architecture.md](Architecture.md)           -- re-read with new understanding

---

## TEACHING MATERIALS

99.  [teaching\course-outline.md](teaching/course-outline.md)   -- 4-week course plan
100. [teaching\exam-questions.md](teaching/exam-questions.md)   -- 34 questions, 6 topics
101. [teaching\semester-plan.md](teaching/semester-plan.md)     -- full semester structure
102. [teaching\README.md](teaching/README.md)                   -- teaching overview

---

## CASE STUDIES

103. [case-studies\castle-generation.md](case-studies/castle-generation.md)
104. [case-studies\email-triage.md](case-studies/email-triage.md)
105. [case-studies\report-optimization.md](case-studies/report-optimization.md)
106. [case-studies\resource-allocation.md](case-studies/resource-allocation.md)
107. [case-studies\README.md](case-studies/README.md)

---

## PAPERS AND RESEARCH

108. [papers\vbaf-main-paper.md](papers/vbaf-main-paper.md)           -- the full VBAF paper
109. [papers\education-evaluation.md](papers/education-evaluation.md) -- educational assessment
110. [papers\multi-agent-study.md](papers/multi-agent-study.md)       -- multi-agent research
111. [papers\README.md](papers/README.md)

---

## DEVELOPER DOCUMENTATION

112. [dev\coding-standards.md](dev/coding-standards.md)   -- how VBAF code is written
113. [dev\contributing.md](dev/contributing.md)           -- how to contribute
114. [dev\testing-guide.md](dev/testing-guide.md)         -- how to test
115. [dev\release-process.md](dev/release-process.md)     -- how releases work
116. [dev\README.md](dev/README.md)

---

## FINAL STEP

117. Build your own enterprise pillar
118. Submit a pull request to GitHub
119. Share VBAF with someone who needs it

---

*github.com/JupyterPS/VBAF · Install-Module VBAF · Built in Roskilde, Denmark 🇩🇰*

*"The best way to understand AI is to build it yourself -- line by line."*