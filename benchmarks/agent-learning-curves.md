# Agent Learning Curves

## Enterprise pillars -- re-measured for VBAF v6.1 (8 Oct 2026)

**What changed.** Kernel finding KF-13: before 6.1 the DQN target network shared the main network's weights, so it was
never frozen. 6.1 fixes it. All 26 pillars were re-measured exactly as for v6.0 (same script, same settings: 30 training
episodes, 10 evaluation episodes, seeds 1, 2, 3), on the battery (`-Engine Fast`, bit-identical to pure PowerShell): 60
minutes instead of 13 hours. Raw data: [data/pillars-v6.1](data/pillars-v6.1).

**Result.** 21 of 26 pillars score higher than in v6.0, 3 lower and 2 the same. Most differences are within one standard
deviation over 3 seeds, so read it as a consistent, moderate shift, not a breakthrough. 22 of 26 still beat the best fixed
action on every seed; the same four pillars do not (AlertRouter, JobScheduler, ResourceOptimizer, SupplyChain). Random
and best-fixed scores are unchanged, because they do not depend on the network. Environment groups as in the v6.0 table (KF-5).

| Pillar | Env. group | Trained 6.1 (mean +/- SD) | Trained 6.0 | Change | Trained minus best fixed, 6.1 | Beats best fixed, 6.1 |
|---|---|---|---|---|---|---|
| AnomalyDetector | A | 353.9 +/- 60.1 | 301.4 | +52.5 | +416 +/- 60.1 | 3 of 3 |
| CapacityPlanner | A | 356 +/- 41.1 | 308 | +48.0 | +419 +/- 41.1 | 3 of 3 |
| CloudBridge | A | 353.7 +/- 59.5 | 298.1 | +55.6 | +416 +/- 59.5 | 3 of 3 |
| FederatedLearning | A | 352.6 +/- 59.4 | 335.6 | +17.0 | +415 +/- 59.4 | 3 of 3 |
| IncidentResponder | A | 351.2 +/- 58.7 | 341.1 | +10.1 | +414 +/- 58.7 | 3 of 3 |
| DataFlowOptimizer | B | 296.2 +/- 88.1 | 291.3 | +4.9 | +353 +/- 88.1 | 3 of 3 |
| MultiAgentCoordinator | B | 330 +/- 59.9 | 318.1 | +11.9 | +387 +/- 59.9 | 3 of 3 |
| Dashboard | C | 338.7 +/- 94 | 305.9 | +32.8 | +390 +/- 94 | 3 of 3 |
| NLInterface | C | 299.3 +/- 69.4 | 240.5 | +58.8 | +351 +/- 69.4 | 3 of 3 |
| PredictiveMaintenance | C | 256.6 +/- 132 | 248.4 | +8.2 | +308 +/- 132 | 3 of 3 |
| SelfHealing | C | 262.4 +/- 134 | 258.8 | +3.6 | +314 +/- 134 | 3 of 3 |
| AutoPilot | D | 181.7 +/- 64.5 | 176.1 | +5.6 | +175 +/- 64.5 | 3 of 3 |
| BackupOptimizer | D | 181.7 +/- 64.5 | 176.1 | +5.6 | +175 +/- 64.5 | 3 of 3 |
| ComplianceReporter | D | 210.6 +/- 13.2 | 207.3 | +3.3 | +204 +/- 13.2 | 3 of 3 |
| EnergyOptimizer | D | 181.7 +/- 64.5 | 176.1 | +5.6 | +175 +/- 64.5 | 3 of 3 |
| MultiSiteCoordinator | D | 181.7 +/- 64.5 | 176.1 | +5.6 | +175 +/- 64.5 | 3 of 3 |
| PatchIntelligence | D | 181.7 +/- 64.5 | 176.1 | +5.6 | +175 +/- 64.5 | 3 of 3 |
| UserBehaviorAnalytics | D | 181.7 +/- 64.5 | 176.1 | +5.6 | +175 +/- 64.5 | 3 of 3 |
| NetworkWatcher | E | 156.7 +/- 36.7 | 141.8 | +14.9 | +214 +/- 36.7 | 3 of 3 |
| FleetDispatch | F | 201.6 +/- 81.6 | 202.6 | -1.0 | +192 +/- 81.6 | 3 of 3 |
| HealthcareMonitor | F | 201.6 +/- 81.6 | 202.6 | -1.0 | +192 +/- 81.6 | 3 of 3 |
| SecurityMonitor | G | 101.8 +/- 61.1 | 100.8 | +1.0 | +147 +/- 61.1 | 3 of 3 |
| AlertRouter | H | 32.3 +/- 0 | 32.3 | 0.0 | 0 +/- 0 | 0 of 3 |
| SupplyChain | I | -2.2 +/- 2.4 | -1.2 | -1.0 | -3 +/- 2.4 | 0 of 3 |
| JobScheduler | J | -3.7 +/- 7.9 | -8.3 | +4.5 | -5 +/- 7.9 | 0 of 3 |
| ResourceOptimizer | K | -31.5 +/- 39.9 | -31.5 | 0.0 | -53 +/- 39.9 | 0 of 3 |

The v6.0 section below is kept as it was written.

## Enterprise pillars -- re-measured for VBAF v6.0 (5-6 Oct 2026)

**What changed.** Before v6.0 the pillars reported "improvement over random" (e.g. +117.5%). Nothing was learned
then: the DQN output layer could not represent the rewards and the replay buffer trained on aliased data (kernel
findings KF-1 and KF-4), so those figures measured *one fixed action vs random choices*. Several environments were
even designed so that one fixed action beats random ("Distribution 15/40/30/15 guarantees positive improvement").
Those figures are withdrawn.

**How v6.0 measures.** Each pillar is trained with its OWN training function (`-SimMode`, 30 episodes), then three
kinds of policy are evaluated on the SAME 10 evaluation episodes (same seeds for all): random choices, EVERY fixed
action, and the trained agent. The honest bar is the **best fixed action**: a brain that cannot beat "always press
the same button" has not learned anything useful. Three training seeds (1, 2, 3) per pillar; the table shows mean
+/- standard deviation over the seeds. The measurement is deterministic: re-running a pillar gives identical numbers.

**Result.** 22 of 26 pillars beat the best fixed action on every seed (by +146 for SecurityMonitor up to +404 for IncidentResponder, mean
over seeds) and use more than one action. 4 pillars do not: AlertRouter, JobScheduler, ResourceOptimizer, SupplyChain --
exactly the four pillars built on `New-EnterpriseEnvironment`. That is the next thing to investigate.

**Environment groups (KF-5).** The 26 pillars run on only 11 distinct environments. Pillars in the same group (same
letter) share the environment; their evaluation of random and fixed actions is identical, and some are identical in
every number. Group letters are sorted by result, best first.

| Pillar | Env. group | Trained (mean +/- SD) | Random | Best fixed action | Trained minus best fixed (mean +/- SD) | Beats best fixed | Uses >1 action |
|---|---|---|---|---|---|---|---|
| AnomalyDetector | A | 301 +/- 49.5 | -149 | -62.5 | +364 +/- 49.5 | 3 of 3 | 3 of 3 |
| CapacityPlanner | A | 308 +/- 58.2 | -149 | -62.5 | +371 +/- 58.2 | 3 of 3 | 3 of 3 |
| CloudBridge | A | 298 +/- 56.7 | -149 | -62.5 | +361 +/- 56.7 | 3 of 3 | 3 of 3 |
| FederatedLearning | A | 336 +/- 43.1 | -149 | -62.5 | +398 +/- 43.1 | 3 of 3 | 3 of 3 |
| IncidentResponder | A | 341 +/- 51.8 | -149 | -62.5 | +404 +/- 51.8 | 3 of 3 | 3 of 3 |
| DataFlowOptimizer | B | 291 +/- 83.2 | -149 | -56.5 | +348 +/- 83.2 | 3 of 3 | 3 of 3 |
| MultiAgentCoordinator | B | 318 +/- 68.1 | -149 | -56.5 | +375 +/- 68.1 | 3 of 3 | 3 of 3 |
| Dashboard | C | 306 +/- 153 | -151 | -51.5 | +357 +/- 153 | 3 of 3 | 3 of 3 |
| NLInterface | C | 241 +/- 90.3 | -151 | -51.5 | +292 +/- 90.3 | 3 of 3 | 3 of 3 |
| PredictiveMaintenance | C | 248 +/- 119 | -151 | -51.5 | +300 +/- 119 | 3 of 3 | 3 of 3 |
| SelfHealing | C | 259 +/- 135 | -151 | -51.5 | +310 +/- 135 | 3 of 3 | 3 of 3 |
| AutoPilot | D | 176 +/- 77.3 | -140 | 6.30 | +170 +/- 77.3 | 3 of 3 | 3 of 3 |
| BackupOptimizer | D | 176 +/- 77.3 | -140 | 6.30 | +170 +/- 77.3 | 3 of 3 | 3 of 3 |
| ComplianceReporter | D | 207 +/- 23.6 | -140 | 6.30 | +201 +/- 23.6 | 3 of 3 | 3 of 3 |
| EnergyOptimizer | D | 176 +/- 77.3 | -140 | 6.30 | +170 +/- 77.3 | 3 of 3 | 3 of 3 |
| MultiSiteCoordinator | D | 176 +/- 77.3 | -140 | 6.30 | +170 +/- 77.3 | 3 of 3 | 3 of 3 |
| PatchIntelligence | D | 176 +/- 77.3 | -140 | 6.30 | +170 +/- 77.3 | 3 of 3 | 3 of 3 |
| UserBehaviorAnalytics | D | 176 +/- 77.3 | -140 | 6.30 | +170 +/- 77.3 | 3 of 3 | 3 of 3 |
| NetworkWatcher | E | 142 +/- 60.8 | -161 | -57.6 | +199 +/- 60.8 | 3 of 3 | 3 of 3 |
| FleetDispatch | F | 203 +/- 76.0 | -127 | 10.0 | +193 +/- 76.0 | 3 of 3 | 3 of 3 |
| HealthcareMonitor | F | 203 +/- 76.0 | -127 | 10.0 | +193 +/- 76.0 | 3 of 3 | 3 of 3 |
| SecurityMonitor | G | 101 +/- 37.0 | -142 | -45.1 | +146 +/- 37.0 | 3 of 3 | 3 of 3 |
| AlertRouter | H | 32.3 +/- 0.00 | 8.70 | 32.3 | 0.00 +/- 0.00 | 0 of 3 | 0 of 3 |
| SupplyChain | I | -1.19 +/- 3.56 | 1.20 | 1.26 | -2.44 +/- 3.56 | 1 of 3 | 2 of 3 |
| JobScheduler | J | -8.27 +/- 7.85 | -0.10 | 0.80 | -9.07 +/- 7.85 | 0 of 3 | 0 of 3 |
| ResourceOptimizer | K | -31.5 +/- 39.9 | 13.8 | 22.0 | -53.5 +/- 39.9 | 0 of 3 | 0 of 3 |

Seeds matter: for example Dashboard beat the best fixed action by about +450, +442 and +181 on seeds 1, 2 and 3.
One seed is not a result.

**Reproduce it** (about 13 hours for all pillars; resumable, one result file per pillar and seed):

```powershell
.\benchmarks\Measure-VBAFPillars.ps1 -OutDir C:\Temp\pillars -Episodes 30 -Seeds 1,2,3 -EvalEpisodes 10
```

Raw data: [data/pillars-v6.0/](data/pillars-v6.0/) (one JSON file per pillar and seed, plus the summary).

## Q-Learning vs DQN

*These figures come from the v4 documentation and have not been re-measured for v6.0.*

| Agent | Episodes to stable policy | Final avg reward |
|-------|--------------------------|-----------------|
| Random baseline | N/A | -130 to -155 |
| Q-Learning | 200-400 | -80 to -60 |
| DQN (64x64) | 100-200 | +5 to +25 |
| DQN (24x24) | 80-150 | +3 to +20 |
