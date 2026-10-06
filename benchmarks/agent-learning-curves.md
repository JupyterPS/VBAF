# Agent Learning Curves

## Enterprise pillars -- re-measured for VBAF v5.0 (5-6 Oct 2026)

**What changed.** Before v5.0 the pillars reported "improvement over random" (e.g. +117.5%). Nothing was learned
then: the DQN output layer could not represent the rewards and the replay buffer trained on aliased data (kernel
findings KF-1 and KF-4), so those figures measured *one fixed action vs random choices*. Several environments were
even designed so that one fixed action beats random ("Distribution 15/40/30/15 guarantees positive improvement").
Those figures are withdrawn.

**How v5.0 measures.** Each pillar is trained with its OWN training function (`-SimMode`, 30 episodes), then three
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

Raw data: [data/pillars-v5.0/](data/pillars-v5.0/) (one JSON file per pillar and seed, plus the summary).

## Q-Learning vs DQN

*These figures come from the v4 documentation and have not been re-measured for v5.0.*

| Agent | Episodes to stable policy | Final avg reward |
|-------|--------------------------|-----------------|
| Random baseline | N/A | -130 to -155 |
| Q-Learning | 200-400 | -80 to -60 |
| DQN (64x64) | 100-200 | +5 to +25 |
| DQN (24x24) | 80-150 | +3 to +20 |
