# Changelog

All notable changes to VBAF are documented here.
## [5.0.0] - unreleased (branch v5.0) -- The kernel learns, and proves it

**Read this first.** Before 5.0 the DQN agents did not learn (KF-1, KF-4 below). The "improvement over random"
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
- Environments follow three different contracts instead of one base class (documented in the Lab's kernel findings).

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

## Future Releases

See the [Project Roadmap](https://github.com/users/JupyterPS/projects/2) for planned features.

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

*Format based on [Keep a Changelog](https://keepachangelog.com)*


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

## [3.2.0] - 2026-03-11 — Phase 11: Multi-Agent Collaboration

### Added
- VBAF.Enterprise.MultiAgentCoordinator.ps1
  - DQN coordinator orchestrates decisions across multiple agents
  - Actions: Handle / Consult / Escalate / Override
  - Real data: Start-Job parallel agent execution confirmed
  - Result: +31.3% vs random baseline, 100% recall

## [3.3.0] - 2026-03-11 — Phase 12: Predictive Maintenance

### Added
- VBAF.Enterprise.PredictiveMaintenance.ps1
  - DQN agent predicts hardware failures before they occur
  - Actions: Monitor / Schedule / Warn / Act
  - Real data: WMI disk, CPU load, battery health
  - Result: +35.6% vs random baseline, 100% recall

## [3.4.0] - 2026-03-11 — Phase 13: Natural Language Interface

### Added
- VBAF.Enterprise.NLInterface.ps1
  - DQN agent routes NL commands to correct enterprise subsystem
  - Actions: Respond / Execute / Orchestrate / Escalate
  - Real data: PS ISE host, sample command routing demo
  - Result: +40.4% vs random baseline, 100% recall

## [3.5.0] - 2026-03-12 — Phase 14: Self-Healing Infrastructure

### Added
- VBAF.Enterprise.SelfHealing.ps1
  - DQN agent autonomously remediates system failures
  - Actions: Observe / Adjust / Restart / Rebuild
  - Real data: WMI OS, Get-Service, Get-Process CPU
  - Result: +63% vs random baseline — best result to date

## [3.6.0] - 2026-03-12 — Phase 15: Enterprise Dashboard

### Added
- VBAF.Enterprise.Dashboard.ps1
  - DQN agent manages dashboard resource allocation
  - Actions: Cache / Refresh / Prioritise / Rebuild
  - Real data: WMI memory, active sessions, event log
  - Fix: UrgencyScore replaces OffHours (dead daytime dimension)
  - Result: +59.1% vs random baseline

## [3.7.0] - 2026-03-12 — Phase 16: Federated Learning

### Added
- VBAF.Enterprise.FederatedLearning.ps1
  - DQN agent coordinates distributed model updates across nodes
  - Actions: Collect / Aggregate / Validate / Rollback
  - Real data: Get-Job, network latency, WMI CPU
  - Fix: UpdateQuality inverted to break monotonic collapse
  - Result: +62.1% vs random baseline

## [3.8.0] - 2026-03-12 — Phase 17: Cloud Bridge

### Added
- VBAF.Enterprise.CloudBridge.ps1
  - DQN agent manages hybrid cloud/on-premise workload routing
  - Actions: Local / Offload / Sync / Failover
  - Real data: Test-NetConnection latency, WMI memory, CPU
  - Fix: CloudBandwidth inverted to break monotonic collapse
  - Result: +24.5% vs random baseline

## [3.9.0] - 2026-03-12 — Phase 18: Anomaly Detection Engine

### Added
- VBAF.Enterprise.AnomalyDetector.ps1
  - DQN agent detects and responds to cross-pillar anomalies
  - Actions: Ignore / Flag / Alert / Escalate
  - Real data: Get-WinEvent, WMI memory, active processes
  - Fix: DeviationTrend inverted to break monotonic collapse
  - Result: +30.6% vs random baseline

## [3.10.0] - 2026-03-12 — Phase 19: Capacity Planning Intelligence

### Added
- VBAF.Enterprise.CapacityPlanner.ps1
  - DQN agent predicts and manages resource exhaustion
  - Actions: Monitor / Warn / Reserve / Escalate
  - Real data: Get-PSDrive disk usage, WMI free memory
  - Fix: AvailableHeadroom + TimeRemaining both inverted — dual inversion
  - Result: +32.6% vs random baseline

## [3.11.0] - 2026-03-13 — Phase 20: Incident Response Automation

### Added
- VBAF.Enterprise.IncidentResponder.ps1
  - DQN agent coordinates cross-pillar incident response
  - Actions: Investigate / Contain / Remediate / Report
  - Real data: Get-WinEvent critical events, Get-Service, WMI memory
  - Fix: Single inversion (SystemStability) — 3 up + 1 down sweet spot
  - Result: +26.9% vs random baseline

## [3.12.0] - 2026-03-14 — Phase 21: Compliance Reporting Engine

### Added
- VBAF.Enterprise.ComplianceReporter.ps1
  - DQN agent manages GDPR/ISO27001/NIS2 compliance evidence
  - Actions: Collect / Classify / Report / Archive
  - Real data: Security event log, local users, WMI last boot
  - Fix: Distribution 15/40/30/15 — math-guaranteed positive result
  - Result: +107.2% vs random baseline (first phase to go positive!)

## [3.13.0] - 2026-03-14 — Phase 22: User Behavior Analytics

### Added
- VBAF.Enterprise.UserBehaviorAnalytics.ps1
  - DQN agent detects and responds to anomalous user behavior
  - Actions: Ignore / Flag / Alert / Lock
  - Real data: Security log failed logons (4625), local users, admins
  - Fix: No inversion + distribution 15/40/30/15 — confirmed winning formula
  - Result: +103.4% vs random baseline (second phase to go positive!)

## [3.14.0] - 2026-03-14 — Phase 23: Patch Intelligence

### Added
- VBAF.Enterprise.PatchIntelligence.ps1
  - DQN agent manages enterprise patch deployment decisions
  - Actions: Defer / Schedule / Apply / Rollback
  - Real data: Get-HotFix, WMI OS build, System event errors
  - Formula: No inversion + distribution 15/40/30/15
  - Result: +65.5% vs random baseline

## [3.15.0] - 2026-03-14 — Phase 24: Backup Optimizer

### Added
- VBAF.Enterprise.BackupOptimizer.ps1
  - DQN agent manages enterprise backup strategy decisions
  - Actions: Skip / Incremental / Full / Replicate
  - Real data: Get-PSDrive, WMI memory, App event warnings
  - Formula: No inversion + distribution 15/40/30/15
  - Result: +116.3% vs random baseline (best result to date!)

## [3.16.0] - 2026-03-14 — Phase 25: Energy Optimizer

### Added
- VBAF.Enterprise.EnergyOptimizer.ps1
  - DQN agent manages enterprise energy consumption
  - Actions: Throttle / Sleep / Consolidate / Scale
  - Real data: WMI CPU load, memory free, process count
  - Formula: No inversion + distribution 15/40/30/15
  - Result: +117.5% vs random baseline (new best result!)

## [3.17.0] - 2026-03-14 — Phase 26: Multi-Site Coordinator

### Added
- VBAF.Enterprise.MultiSiteCoordinator.ps1
  - DQN agent coordinates cross-site workload distribution
  - Actions: Local / Sync / Failover / Rebalance
  - Real data: Test-NetConnection, WMI memory, CPU load
  - Formula: No inversion + distribution 15/40/30/15
  - Result: +47.4% vs random baseline (3rd run — initialization sensitive)

## [4.0.0] - 2026-03-14 — Phase 27: AutoPilot — Crown Jewel 👑

### Added
- VBAF.Enterprise.AutoPilot.ps1
  - Master DQN agent orchestrating ALL 13 enterprise pillars (Ph. 14-26)
  - Actions: Delegate / Override / Escalate / Autopilot
  - Real data: WinEvent, Get-Service, WMI memory+CPU
  - Formula: No inversion + distribution 15/40/30/15
  - Result: +63.3% vs random baseline — first try success
  - 13/13 pillars online at test time

