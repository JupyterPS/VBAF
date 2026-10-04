# Example 07 -- Evolution: build a better brain

`data\` holds the REAL result of VBAF-Evolution-Lab phase 4c (3-4 Oct 2026): 3 generations x 3 children,
fitness = mean of 3 brain seeds on validation shifts, 300 training shifts each, final test on 5 new seeds.
The champion G1-2 (the baseline genome with BatchSize 32 and ReplayEvery 2) scored 39.39 +/- 0.37 on the
test shifts, the control (baseline genome, same procedure) 37.17 +/- 1.64. The bar 39.17 was set in advance.

```powershell
. .\VBAF.LoadAll.ps1
Show-VBAFEvolutionWindow -ResultDir .\examples\07-Evolution\data
```

Run your own study (the defaults repeat phase 4c, about 12 hours; make it smaller to try it out):

```powershell
$world = [ProductionCellEnvironment]::new(1)
Invoke-VBAFEvolutionStudy -World $world -OutDir C:\Temp\my-study -Generations 1 -Children 2 -FitSeeds 101,102 -TrainShifts 50 -FinalSeeds 201,202
Show-VBAFEvolutionWindow -ResultDir C:\Temp\my-study
```

`final-champion-s201-best.xml` and `final-control-s201-best.xml` are the trained champion and control brains
(seed 201), used by the window's shift tabs.
