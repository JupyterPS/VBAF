# Henning's Local Setup Notes

Personal dev environment notes — not part of the official documentation.

## Local paths
- Framework: \C:\Users\henni\OneDrive\WindowsPowerShell\
- Registry: \C:\Users\henni\VBAFRegistry\
- Load all: \. .\VBAF.LoadAll.ps1\
- IDE: PowerShell ISE (PS 5.1)

## Workflow
1. Edit module in ISE
2. \. .\VBAF.LoadAll.ps1\ to reload
3. Run \Test-VBAF<Module>\ smoke test
4. \git add / commit / push --set-upstream origin master\
"@

# ==============================================================================
#  docs/case-studies/
# ==============================================================================

Write-Placeholder "docs/case-studies/README.md" @"
# Case Studies

> 🚧 **Placeholder** — case studies will document real VBAF applications.

| File | Topic | Status |
|---|---|---|
| castle-generation.md | RL agent learning to build castles | 🚧 Planned |
| email-triage.md | NaiveBayes email classification | 🚧 Planned |
| eport-optimization.md | AutoML on report generation | 🚧 Planned |
| esource-allocation.md | Multi-agent resource scheduling | 🚧 Planned |
