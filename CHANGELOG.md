# Changelog

All notable changes to VBAF are documented here.

## [6.1.0] - 2026-10-08 -- A frozen target and a battery

**Read this first.** 6.1 fixes kernel finding KF-13: the DQN target network was never frozen. DQN training results
therefore differ from 6.0.0 (runs saved with 6.0.0 are not reproduced bit for bit). The re-measured pillar figures
and the raw data are in `benchmarks/data/pillars-v6.1`.

### Fixed (kernel findings from VBAF-Evolution-Lab)
- KF-13: the DQN target network shared the main network's weight arrays (`Neuron.ExportState` handed out its live array and `ImportState` kept it), so the target followed every training step instead of staying frozen -- in every DQN agent. The A3C workers shared the global network's weights the same way. `ExportState` now gives copies and `ImportState` keeps its own copy. The suite checks it (no alias, no leak, values equal); the KF-3 seed-42 fingerprint and the locked Evolution run were re-locked, because the 6.0.0 values were made with the bug.

### Added
- `VBAF.Core.FastNet.ps1` -- the battery: an optional C# engine for `NeuralNetwork`, compiled in memory with Add-Type (no dependencies). Bit-identical to pure PowerShell, locked by the suite through a whole DQN run. Training is about 8x faster in the pillars.
- `Set-VBAFNetEngine` / `$global:VBAFNetEngine`: `PowerShell` (default, the readable kernel), `Auto` (the engine when it is available, otherwise PowerShell) or `Fast` (stops with a clear error when Add-Type is blocked, for example in Constrained Language Mode). `Get-VBAFNetEngine` shows the setting and why the engine is not available.
- `VBAFNetworkFactory` -- every network in VBAF is created here (all 66 places in 33 files), so the engine setting reaches every pillar and agent.
- `benchmarks\Measure-VBAFPillars.ps1 -Engine` -- passed to every child process; each result file records the engine it used.
- The regression suite has 71 checks (was 68): KF-13, battery = pure PowerShell bit for bit, and the fallback when the engine is blocked.

### Changed
- All 26 pillars were re-measured with the fixed target, with the same settings as 6.0 (30 training episodes, 3 seeds, 10 evaluation episodes), on the battery: 60 minutes instead of 13 hours. 21 of 26 pillars score higher than in 6.0, 3 lower and 2 the same -- mostly within one standard deviation, so read it as a consistent, moderate shift, not a breakthrough. 22 of 26 still beat the best fixed action on every seed.

### Known issues
- Unchanged from 6.0.0: the four pillars built on `New-EnterpriseEnvironment` (AlertRouter, JobScheduler, ResourceOptimizer, SupplyChain) do not beat the best fixed action, and KF-5 (26 pillars on 11 environments) still makes several pillars' figures identical.
- KF-11: AutoPilot does not orchestrate the other pillars. It decides from 4 simulated aggregate signals with the same dynamics as EnergyOptimizer and does not read the other pillars at all. Found on 6 Oct 2026 while confirming KF-5 (AutoPilot sat in the same environment group as EnergyOptimizer). The documentation was corrected everywhere it claimed otherwise (README, Architecture, Teach, Playground, GettingStarted, and the article via errata); the code is unchanged.
- KF-12: backprop reads weights that the layer above has already updated in the same step (classic backprop uses the old weights). Documented, not changed in 6.1 (one behaviour change at a time). The battery reproduces it on purpose, so both engines stay bit-identical.
- VBAF-Evolution-Lab has its own `FastNeuralNetwork` class; retire it when the Lab moves to kernel 6.1.
## [6.0.0] - 2026-10-06 -- The kernel learns, and proves it

**Read this first.** Before 6.0 the DQN agents did not learn (KF-1, KF-4 below). The "improvement over random"
figures in the older entries below (+24.5% to +292%) measured one fixed action against random choices, not learning.
They are withdrawn. The older entries are kept as they were written; the re-measured figures, the method and the raw
data are in [benchmarks/agent-learning-curves.md](benchmarks/agent-learning-curves.md).

### Fixed (kernel findings from VBAF-Evolution-Lab)
- KF-1: the DQN output layer was Sigmoid, so Q-values could never exceed 1. DQN agents now use a Linear output (`NeuralNetwork.SetOutputActivation`).
- KF-2: `DQNAgent` trusted `DQNConfig.ActionSize` / `HiddenLayers` even when the network was different. It now uses the real network, warns about a mismatch and explores every real action.
- KF-3: 11 random generators were unseeded. All are seeded through `Set-VBAFSeed`; runs are reproducible.
- KF-4: `NeuralNetwork.Predict` returned its internal array, so experience replay trained on overwritten data. `Predict` returns a copy.
- KF-6: the JobScheduler pillar never trained (0 episodes) and threw away its own settings.
- KF-7: `New-EnterpriseEnvironment` ignored `-MaxSteps` for 3 of 4 environments, and ResourceOptimizer read the live PC on every `Reset`. Simulated by default now; `-Live` on request; `-Seed`.
- KF-8: `Layer.ImportState` did not restore the activation type (a saved Linear model came back as Sigmoid).
- KF-9: `VBAF.LoadAll.ps1` hung forever outside the PowerShell ISE (an invisible WinForms dialog).
- KF-10: `VBAF.Enterprise.HealthcareMonitor.ps1` was loaded by `VBAF.LoadAll.ps1` but had never been committed, so every GitHub / PSGallery user got an error on every load. It is included now.

### Added
- `tests\Test-VBAF.ps1`: a regression suite of 68 checks with locked results (about 3 minutes). See `tests\README.md`.
- `Get-VBAFTrace`: a step-by-step trace of one episode in any environment.
- `VBAF.RL.ProductionCell.ps1`: the production cell world (one machine, an order queue, deadlines), hand-written rules (SPT and others) and a measurer.
- `VBAF.RL.Evolution.ps1`: build, train and evolve a brain. `Invoke-VBAFEvolutionStudy` runs a whole study: evolution with several seeds per candidate, the champion, and a final test of the champion AND a control on new seeds.
- `Show-VBAFEvolutionWindow`: a window with three tabs (Evolution, The shift, Side by side) and a demo.
- `Start-VBAFTeach -Topic Evolution` (topic 7) and `examples\07-Evolution` with the real study data from VBAF-Evolution-Lab.
- `benchmarks\Measure-VBAFPillars.ps1`: measures every pillar honestly (random choices, every fixed action and the trained agent on the same episodes, several seeds). Resumable.

### Changed
- All 26 enterprise pillars were re-measured (30 training episodes, 3 seeds): 22 beat the best fixed action on every seed. README and benchmarks show the new figures.

### Known issues
- AlertRouter, JobScheduler, ResourceOptimizer and SupplyChain -- the four pillars built on `New-EnterpriseEnvironment` -- do not yet beat the best fixed action.
- KF-5: the 26 pillars run on only 11 distinct environments; several pillars are the same environment under another name, so their figures are identical.
- AutoPilot does not yet read the other 13 pillars: it decides from 4 simulated aggregate signals (same dynamics as EnergyOptimizer). The older entries below that say it orchestrates all 13 pillars describe the intention, not the code.
- Environments follow three different contracts instead of one base class (documented in the Lab's kernel findings).

## [4.0.0] - 2026-03-14 — Phase 27: AutoPilot — Crown Jewel 👑

### Added
- VBAF.Enterprise.AutoPilot.ps1
  - Master DQN agent orchestrating ALL 13 enterprise pillars (Ph. 14-26)
  - Actions: Delegate / Override / Escalate / Autopilot
  - Real data: WinEvent, Get-Service, WMI memory+CPU
  - Formula: No inversion + distribution 15/40/30/15
  - Result: +63.3% vs random baseline — first try success
  - 13/13 pillars online at test time

## [3.17.0] - 2026-03-14 — Phase 26: Multi-Site Coordinator

### Added
- VBAF.Enterprise.MultiSiteCoordinator.ps1
  - DQN agent coordinates cross-site workload distribution
  - Actions: Local / Sync / Failover / Rebalance
  - Real data: Test-NetConnection, WMI memory, CPU load
  - Formula: No inversion + distribution 15/40/30/15
  - Result: +47.4% vs random baseline (3rd run — initialization sensitive)

## [3.16.0] - 2026-03-14 — Phase 25: Energy Optimizer

### Added
- VBAF.Enterprise.EnergyOptimizer.ps1
  - DQN agent manages enterprise energy consumption
  - Actions: Throttle / Sleep / Consolidate / Scale
  - Real data: WMI CPU load, memory free, process count
  - Formula: No inversion + distribution 15/40/30/15
  - Result: +117.5% vs random baseline (new best result!)

## [3.15.0] - 2026-03-14 — Phase 24: Backup Optimizer

### Added
- VBAF.Enterprise.BackupOptimizer.ps1
  - DQN agent manages enterprise backup strategy decisions
  - Actions: Skip / Incremental / Full / Replicate
  - Real data: Get-PSDrive, WMI memory, App event warnings
  - Formula: No inversion + distribution 15/40/30/15
  - Result: +116.3% vs random baseline (best result to date!)

## [3.14.0] - 2026-03-14 — Phase 23: Patch Intelligence

### Added
- VBAF.Enterprise.PatchIntelligence.ps1
  - DQN agent manages enterprise patch deployment decisions
  - Actions: Defer / Schedule / Apply / Rollback
  - Real data: Get-HotFix, WMI OS build, System event errors
  - Formula: No inversion + distribution 15/40/30/15
  - Result: +65.5% vs random baseline

## [3.13.0] - 2026-03-14 — Phase 22: User Behavior Analytics

### Added
- VBAF.Enterprise.UserBehaviorAnalytics.ps1
  - DQN agent detects and responds to anomalous user behavior
  - Actions: Ignore / Flag / Alert / Lock
  - Real data: Security log failed logons (4625), local users, admins
  - Fix: No inversion + distribution 15/40/30/15 — confirmed winning formula
  - Result: +103.4% vs random baseline (second phase to go positive!)

## [3.12.0] - 2026-03-14 — Phase 21: Compliance Reporting Engine

### Added
- VBAF.Enterprise.ComplianceReporter.ps1
  - DQN agent manages GDPR/ISO27001/NIS2 compliance evidence
  - Actions: Collect / Classify / Report / Archive
  - Real data: Security event log, local users, WMI last boot
  - Fix: Distribution 15/40/30/15 — math-guaranteed positive result
  - Result: +107.2% vs random baseline (first phase to go positive!)

## [3.11.0] - 2026-03-13 — Phase 20: Incident Response Automation

### Added
- VBAF.Enterprise.IncidentResponder.ps1
  - DQN agent coordinates cross-pillar incident response
  - Actions: Investigate / Contain / Remediate / Report
  - Real data: Get-WinEvent critical events, Get-Service, WMI memory
  - Fix: Single inversion (SystemStability) — 3 up + 1 down sweet spot
  - Result: +26.9% vs random baseline

## [3.10.0] - 2026-03-12 — Phase 19: Capacity Planning Intelligence

### Added
- VBAF.Enterprise.CapacityPlanner.ps1
  - DQN agent predicts and manages resource exhaustion
  - Actions: Monitor / Warn / Reserve / Escalate
  - Real data: Get-PSDrive disk usage, WMI free memory
  - Fix: AvailableHeadroom + TimeRemaining both inverted — dual inversion
  - Result: +32.6% vs random baseline

## [3.9.0] - 2026-03-12 — Phase 18: Anomaly Detection Engine

### Added
- VBAF.Enterprise.AnomalyDetector.ps1
  - DQN agent detects and responds to cross-pillar anomalies
  - Actions: Ignore / Flag / Alert / Escalate
  - Real data: Get-WinEvent, WMI memory, active processes
  - Fix: DeviationTrend inverted to break monotonic collapse
  - Result: +30.6% vs random baseline

## [3.8.0] - 2026-03-12 — Phase 17: Cloud Bridge

### Added
- VBAF.Enterprise.CloudBridge.ps1
  - DQN agent manages hybrid cloud/on-premise workload routing
  - Actions: Local / Offload / Sync / Failover
  - Real data: Test-NetConnection latency, WMI memory, CPU
  - Fix: CloudBandwidth inverted to break monotonic collapse
  - Result: +24.5% vs random baseline

## [3.7.0] - 2026-03-12 — Phase 16: Federated Learning

### Added
- VBAF.Enterprise.FederatedLearning.ps1
  - DQN agent coordinates distributed model updates across nodes
  - Actions: Collect / Aggregate / Validate / Rollback
  - Real data: Get-Job, network latency, WMI CPU
  - Fix: UpdateQuality inverted to break monotonic collapse
  - Result: +62.1% vs random baseline

## [3.6.0] - 2026-03-12 — Phase 15: Enterprise Dashboard

### Added
- VBAF.Enterprise.Dashboard.ps1
  - DQN agent manages dashboard resource allocation
  - Actions: Cache / Refresh / Prioritise / Rebuild
  - Real data: WMI memory, active sessions, event log
  - Fix: UrgencyScore replaces OffHours (dead daytime dimension)
  - Result: +59.1% vs random baseline

## [3.5.0] - 2026-03-12 — Phase 14: Self-Healing Infrastructure

### Added
- VBAF.Enterprise.SelfHealing.ps1
  - DQN agent autonomously remediates system failures
  - Actions: Observe / Adjust / Restart / Rebuild
  - Real data: WMI OS, Get-Service, Get-Process CPU
  - Result: +63% vs random baseline — best result to date

## [3.4.0] - 2026-03-11 — Phase 13: Natural Language Interface

### Added
- VBAF.Enterprise.NLInterface.ps1
  - DQN agent routes NL commands to correct enterprise subsystem
  - Actions: Respond / Execute / Orchestrate / Escalate
  - Real data: PS ISE host, sample command routing demo
  - Result: +40.4% vs random baseline, 100% recall

## [3.3.0] - 2026-03-11 — Phase 12: Predictive Maintenance

### Added
- VBAF.Enterprise.PredictiveMaintenance.ps1
  - DQN agent predicts hardware failures before they occur
  - Actions: Monitor / Schedule / Warn / Act
  - Real data: WMI disk, CPU load, battery health
  - Result: +35.6% vs random baseline, 100% recall

## [3.2.0] - 2026-03-11 — Phase 11: Multi-Agent Collaboration

### Added
- VBAF.Enterprise.MultiAgentCoordinator.ps1
  - DQN coordinator orchestrates decisions across multiple agents
  - Actions: Handle / Consult / Escalate / Override
  - Real data: Start-Job parallel agent execution confirmed
  - Result: +31.3% vs random baseline, 100% recall

## [3.1.0] - 2026-03-11 — Phase 10: Enterprise Intelligence

### Added
- Pillar 8: VBAF.Enterprise.SecurityMonitor.ps1
  - DQN agent classifies Windows Security Events
  - Actions: Ignore / Log / Alert / Lock
  - Real data: Get-WinEvent -LogName Security
  - Result: +39.7% vs random baseline

- Pillar 9: VBAF.Enterprise.NetworkWatcher.ps1
  - DQN agent monitors network infrastructure health
  - Actions: Ignore / Monitor / Alert / Escalate
  - Real data: Test-NetConnection, Get-NetAdapter, WMI
  - Result: +35.4% vs random baseline

- Pillar 10: VBAF.Enterprise.DataFlowOptimizer.ps1
  - DQN agent optimizes data pipeline conditions
  - Actions: Throttle / Prioritize / Cache / Reroute
  - Real data: WMI disk I/O, CSV streams, SQL probe
  - Result: +59.8% vs random baseline

## [3.0.0] - March 2026 - Enterprise Automation Engine

### Phase 9 - Enterprise Automation Engine
- VBAF.Enterprise.Environment.ps1 - foundation, 4 environments
- Pillar 4: JobScheduler DQN agent - +292% improvement over random
- Pillar 5: ResourceOptimizer - real Windows CPU/memory data connected
- Pillar 6: AlertRouter DQN agent - +230% improvement over random
- Pillar 7: SupplyChain optimizer - learning curve confirmed
- VBAF.LoadCore.ps1 - pure core loader without Enterprise pillars

### Phase 10 - Planned (Pillars 8-10)
- Pillar 8: Security & Compliance Intelligence
- Pillar 9: Network & Infrastructure Intelligence
- Pillar 10: Database & Data Flow Optimization

---
---

## [1.0.0] - 2025

### Added
- 33 core neural network modules built from scratch
- Backpropagation algorithm with full transparency
- Q-Learning agent with epsilon-greedy exploration
- Experience replay for stable learning
- Q-table for state-action value storage
- Epsilon decay scheduling
- Multi-agent market simulation (Pharma, Wine, Banking, AI)
- Market environment with supply/demand economics
- Game theory interactions (Nash equilibrium, cooperation)
- Random economic events (recessions, breakthroughs)
- Dashboard 1: Learning Dashboard (neural network training curves)
- Dashboard 2: Market Dashboard (4 competing company agents)
- Dashboard 3: Validation Dashboard (XOR + Grid World side by side)
- Real-time WinForms visualization at 20-30 FPS
- XOR problem example (classic neural network validation)
- Castle generation example (Q-Learning for generative art)
- 6 complete tutorials (beginner to advanced)
- Full documentation in docs/ folder
- Published to PowerShell Gallery: Install-Module VBAF

### Architecture
- Phase 1: Neural network foundation (complete)
- Phase 2: Stability and polish (complete)
- Phase 3: RL algorithms - DQN, PPO, A3C (complete)
- Phase 4: Supervised learning - Regression, Trees, Clustering (complete)
- Phase 5: Data pipeline - Preprocessing, Feature Engineering (complete)
- Phase 6: Deep learning - CNN, RNN, Autoencoder (complete)
- Phase 7: Production features - ModelRegistry, REST API, MLOps (complete)
- Phase 8: Community and ecosystem (ongoing)

### Requirements
- PowerShell 5.1+
- Windows 10/11
- No additional dependencies

## Future Releases

See the [Project Roadmap](https://github.com/users/JupyterPS/projects/2) for planned features.

*Format based on [Keep a Changelog](https://keepachangelog.com)*
