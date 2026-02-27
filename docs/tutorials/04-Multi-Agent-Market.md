[← Back to Tutorials](README.md) | [🏠 Home](../../README.md)

# Tutorial 04: Multi-Agent Market Simulation

**Watch 4 companies compete, learn, and develop strategies** 🏢

> **Prerequisites:** Tutorial 03 completed
> **Time:** 25-30 minutes
> **Difficulty:** Intermediate

---

## What You Will Learn

- How multiple RL agents interact in a shared environment
- How emergent behaviors arise without explicit programming
- How to run and interpret the VBAF market simulation
- What game theory concepts look like in practice

---

## The Concept: Multi-Agent Reinforcement Learning

In single-agent RL, one agent learns from one environment.
In **multi-agent RL**, multiple agents share the same environment and their
actions affect each other.

This creates emergent complexity:
- Agents must adapt to **other agents learning simultaneously**
- Strategies that work early may fail as competitors improve
- Cooperation and competition can emerge **without being programmed**

---

## The Simulation: 4 Companies, 20+ Quarters

Four company agents compete in a simulated market:

| Company | Sector | Starting Advantage |
|---------|--------|--------------------|
| Pharma Corp | Pharmaceuticals | High margins |
| Wine Estate | Premium goods | Brand loyalty |
| Capital Bank | Financial services | Stable returns |
| AI Ventures | Technology | High growth |

Each quarter, every company decides:
- **Price:** Set high (profit) or low (market share)?
- **Investment:** Spend on R&D or save cash?
- **Strategy:** Aggressive expansion or defensive stability?

Rewards come from profit, market share, and survival.

---

## Step 1: Load the Framework
```powershell
. .\VBAF.LoadAll.ps1
```

---

## Step 2: Launch the Market Dashboard

The easiest way to see the simulation:
```powershell
. .\VBAF.Business.Dashboard-Demo.ps1
```

You will see a live dashboard updating every quarter showing:
- Market share % for each company
- Quarterly profit and cumulative revenue
- Strategy choices each agent made
- Random economic events as they occur

---

## Step 3: Understanding What You See

### Market Share Panel
Watch how the 4 companies trade market share over time.
Early quarters: relatively equal shares.
Later quarters: one or two companies may dominate as their strategies improve.

### Strategy Evolution
Agents start with random strategies (high epsilon = exploring).
Over time epsilon decays and agents exploit what they have learned:
- Some agents learn aggressive pricing
- Others learn defensive cash preservation
- Cooperation patterns can emerge spontaneously

### Economic Events
Random shocks test agent resilience:
- **Recession:** All revenues drop 20-30%
- **Tech breakthrough:** AI Ventures gets a temporary boost
- **Regulation:** Pharma margins compressed for 2 quarters
- **Market boom:** All agents benefit, but some more than others

---

## Step 4: Run the Simulation Manually

To see the code in action without the dashboard:
```powershell
# Create the market environment
$market = New-Object MarketEnvironment

# Create 4 company agents
$companies = @(
    (New-Object CompanyAgent -ArgumentList "Pharma",  @("HighPrice","LowPrice","Invest","Save"), 0.1, 0.3),
    (New-Object CompanyAgent -ArgumentList "Wine",    @("HighPrice","LowPrice","Invest","Save"), 0.1, 0.3),
    (New-Object CompanyAgent -ArgumentList "Bank",    @("HighPrice","LowPrice","Invest","Save"), 0.1, 0.3),
    (New-Object CompanyAgent -ArgumentList "AI",      @("HighPrice","LowPrice","Invest","Save"), 0.1, 0.3)
)

Write-Host "Market simulation ready: 4 companies created" -ForegroundColor Green
```

---

## Step 5: Run 20 Quarters
```powershell
Write-Host "`nRunning 20 quarters..." -ForegroundColor Cyan

for ($quarter = 1; $quarter -le 20; $quarter++) {

    # Each company chooses an action
    $actions = @{}
    foreach ($company in $companies) {
        $state = $market.GetState($company.Name)
        $actions[$company.Name] = $company.ChooseAction($state)
    }

    # Market processes all actions simultaneously
    $results = $market.Step($actions)

    # Each company learns from the outcome
    foreach ($company in $companies) {
        $reward = $results[$company.Name].Reward
        $nextState = $market.GetState($company.Name)
        $company.Learn($market.GetState($company.Name), $actions[$company.Name], $reward, $nextState)
        $company.DecayEpsilon(0.98)
    }

    # Print quarterly summary
    if ($quarter % 5 -eq 0) {
        Write-Host ("`nQuarter {0}:" -f $quarter) -ForegroundColor Yellow
        foreach ($company in $companies) {
            $r = $results[$company.Name]
            Write-Host ("  {0,-10} Action: {1,-10} Reward: {2:F1}" -f $company.Name, $actions[$company.Name], $r.Reward)
        }
    }
}

Write-Host "`nSimulation complete!" -ForegroundColor Green
```

---

## Step 6: Analyse the Results
```powershell
Write-Host "`n=== Final Company Rankings ===" -ForegroundColor Cyan

$companies |
    Sort-Object { $_.TotalReward } -Descending |
    ForEach-Object {
        Write-Host ("  {0,-10} Total reward: {1:F1}  Final epsilon: {2:F3}" -f `
            $_.Name, $_.TotalReward, $_.Epsilon)
    }
```

---

## Game Theory Concepts You Will Observe

**Nash Equilibrium:** A state where no company can improve by changing strategy
alone. Watch for quarters where all 4 companies stabilize on the same action.

**Price Coordination:** Companies may independently converge on similar prices
without communicating — emergent cooperation driven purely by reward signals.

**Market Segmentation:** Companies may specialize in different strategies
(one aggressive, one conservative) to avoid direct competition.

**Prisoner Dilemma moments:** All companies would benefit from lowering prices
together, but individually each is tempted to raise prices for short-term gain.

---

## Troubleshooting

**Simulation runs but all rewards are zero?**
- Check that MarketEnvironment and CompanyAgent loaded correctly
- Run `. .\VBAF.LoadAll.ps1` again

**Dashboard does not open?**
- Make sure you are on Windows 10/11 with PowerShell 5.1
- WinForms requires Windows — it will not work on Linux/Mac PowerShell

---

## What You Learned

- Multi-agent RL produces emergent behaviors not explicitly programmed
- Agents must adapt to a moving target as competitors also learn
- Game theory patterns (Nash equilibrium, coordination) arise naturally
- Market simulations are a powerful way to study competitive AI strategy

---

## Next Steps

- **Tutorial 05:** Build your own custom RL environment
- **Tutorial 06:** Visualize learning with the VBAF dashboards
- **docs/case-studies/castle-generation.md:** See RL applied to generative art

---

*VBAF Version: 1.0.0 | PowerShell 5.1+ | Windows 10/11*


---
[← Back to Tutorials](README.md) | [Next: Tutorial 05 →](05-Custom-Environment.md)
