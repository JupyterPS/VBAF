#Requires -Version 5.1
<#
.SYNOPSIS
    Show-VBAFEvolutionWindow -- watch an evolution study: the lineage, the champion and the final test (VBAF v5.0).
.DESCRIPTION
    Reads evolution-summary.json written by Invoke-VBAFEvolutionStudy (the Lab's phase4c.json works too) and shows:
      Evolution   -- every candidate brain as a dot: fitness on VALIDATION shifts (mean of several training runs)
                     with its spread, lines from parent to child, the gene changes, the champion in gold. Play replays
                     the study candidate by candidate; the final test (TEST shifts, new seeds) is shown at the end.
    Validation and test scores are drawn in two panels, never on one axis. The bar (a pre-registered success
    criterion) is drawn only when the study has one. ASCII only.
    Comes from VBAF-Evolution-Lab phase 5 (the window). The tabs "The shift" and "Side by side" follow.
.EXAMPLE
    . .\VBAF.LoadAll.ps1
    Show-VBAFEvolutionWindow -ResultDir .\examples\07-Evolution\data
#>
function Get-VBAFEvolutionSummaryPath([string]$ResultDir) {
    foreach ($n in 'evolution-summary.json', 'phase4c.json') { $p = Join-Path $ResultDir $n; if (Test-Path $p) { return $p } }
    throw ('No evolution-summary.json in ' + $ResultDir + ' (run Invoke-VBAFEvolutionStudy first).')
}
function ConvertFrom-VBAFGenomeKey([string]$Key) {
    $d = [ordered]@{}
    foreach ($p in $Key.Split(';')) { $kv = $p.Split('=', 2); if ($kv.Count -eq 2) { $d[$kv[0]] = $kv[1] } }
    return $d
}
function Get-VBAFGeneDiff([string]$ChildKey, [string]$ParentKey) {
    $c = ConvertFrom-VBAFGenomeKey $ChildKey
    $p = ConvertFrom-VBAFGenomeKey $ParentKey
    $out = @()
    foreach ($k in $c.Keys) { if ($p.Contains($k) -and ([string]$p[$k] -cne [string]$c[$k])) { $out += ('{0} {1}->{2}' -f $k, $p[$k], $c[$k]) } }
    return ($out -join ', ')
}
function Get-VBAFEvolutionData([string]$ResultDir) {
    $s = (Get-Content (Get-VBAFEvolutionSummaryPath $ResultDir) -Raw -Encoding UTF8 | ConvertFrom-Json)
    $byId = @{}
    foreach ($n in @($s.Lineage)) { $byId[[string]$n.Id] = $n }
    $nodes = foreach ($n in @($s.Lineage)) {
        $id = [string]$n.Id; $parent = [string]$n.Parent
        $isRoot = -not $byId.ContainsKey($parent)
        $diff = 'start (baseline genome)'; $col = [int]$n.Generation + 1
        if ($isRoot) { $col = 0 } else { $diff = Get-VBAFGeneDiff ([string]$n.Key) ([string]$byId[$parent].Key) }
        [pscustomobject]@{ Id = $id; Generation = [int]$n.Generation; Parent = $parent; Fitness = [double]$n.Fitness; SD = [double]$n.FitnessSD
            RunScores = [string]$n.RunScores; Key = [string]$n.Key; Diff = $diff; Column = $col; IsChampion = ($id -eq [string]$s.Champion) }
    }
    $finals = foreach ($f in @($s.Final)) { [pscustomobject]@{ Label = [string]$f.Label; Seed = [int]$f.Seed; Test = [double]$f.TestScore; OnTime = [double]$f.OnTimePct } }
    $bar = $null
    if ($null -ne $s.Bar -and ([string]$s.Bar) -ne '') { $bar = [double]$s.Bar }
    $runs = 1; if (@($s.Lineage).Count -gt 0) { $runs = @(([string]@($s.Lineage)[0].RunScores) -split '/').Count }
    return [pscustomobject]@{ ResultDir = $ResultDir; Champion = [string]$s.Champion; Nodes = @($nodes); Finals = @($finals); FinalSeeds = @($s.FinalSeeds | ForEach-Object { [int]$_ })
        ChampionMean = [double]$s.ChampionTest.Mean; ChampionSD = [double]$s.ChampionTest.SD
        ControlMean = [double]$s.ControlTest.Mean; ControlSD = [double]$s.ControlTest.SD
        Brain0 = [double]$s.Brain0; Bar = $bar; Runs = $runs }
}
function Get-VBAFEvolutionLineageText($Data) {
    $lines = @('Lineage (fitness = mean of the training runs on validation shifts, +/- spread):', '')
    foreach ($m in @($Data.Nodes | Sort-Object Column, Id)) {
        $tag = ''; if ($m.IsChampion) { $tag = '   <- CHAMPION' }
        $lines += ('{0,-5}  gen {1}  from {2,-8} fitness {3,5:F2} +/- {4,4:F2}   ({5})   {6}{7}' -f $m.Id, $m.Generation, $m.Parent, $m.Fitness, $m.SD, $m.RunScores, $m.Diff, $tag)
    }
    return ($lines -join "`r`n")
}
# Best candidate among the first K revealed (training order). $null when K < 1.
function Get-VBAFEvolutionBestSoFar($Data, [int]$K) {
    $nodes = @($Data.Nodes)
    if ($K -lt 1) { return $null }
    $best = $nodes[0]
    for ($i = 1; $i -lt [Math]::Min($K, $nodes.Count); $i++) { if ($nodes[$i].Fitness -gt $best.Fitness) { $best = $nodes[$i] } }
    return $best
}
function Get-VBAFEvolutionStepText($Data, [int]$Step) {
    $nodes = @($Data.Nodes); $n = $nodes.Count; $total = $n + 1
    if ($Step -le 0) { return 'Press Play to watch the evolution, one candidate at a time.' }
    if ($Step -le $n) {
        $m = $nodes[$Step - 1]
        $t = 'Step {0}/{1}: {2} (gen {3}, child of {4}): {5} -> fitness {6:F2} +/- {7:F2}.' -f $Step, $total, $m.Id, $m.Generation, $m.Parent, $m.Diff, $m.Fitness, $m.SD
        $before = Get-VBAFEvolutionBestSoFar $Data ($Step - 1)
        if ($null -eq $before -or $m.Fitness -gt $before.Fitness) { $t += ' New best!' } else { $t += (' Best so far: {0} ({1:F2}).' -f $before.Id, $before.Fitness) }
        if ($Step -eq $n) { $t += ' Evolution is over: the champion is ' + $Data.Champion + '.' }
        return $t
    }
    $t = 'Step {0}/{0}: the final test. The champion {1} and the control are trained again with {2} new seeds and measured on the test shifts: {3:F2} +/- {4:F2} vs {5:F2} +/- {6:F2}.' -f $total, $Data.Champion, @($Data.FinalSeeds).Count, $Data.ChampionMean, $Data.ChampionSD, $Data.ControlMean, $Data.ControlSD
    if ($null -ne $Data.Bar) { $t += (' The bar was {0:F2}.' -f $Data.Bar) }
    return $t
}
function Write-VBAFWindowLabel($g, [string]$Text, $Font, $Brush, [single]$X, [single]$Y) {
    $sz = $g.MeasureString($Text, $Font)
    $bg = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(225, 255, 255, 255))
    $g.FillRectangle($bg, $X, [single]($Y + 1), [single]$sz.Width, [single]($sz.Height - 2))
    $bg.Dispose()
    $g.DrawString($Text, $Font, $Brush, $X, $Y)
}
# Draws the Evolution tab. Returns $true, or $false if drawing failed (the error is drawn in red).
function Invoke-VBAFDrawEvolution {
    param($g, [int]$w, [int]$h, $d, [int]$Step = 999)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $g.Clear([System.Drawing.Color]::White)
    $font  = [System.Drawing.Font]::new('Segoe UI', [single]9)
    $fontB = [System.Drawing.Font]::new('Segoe UI', [single]10, [System.Drawing.FontStyle]::Bold)
    $fontS = [System.Drawing.Font]::new('Segoe UI', [single]8)
    $txt   = [System.Drawing.Brushes]::Black
    $dim   = [System.Drawing.Brushes]::DimGray
    $grid  = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(232, 232, 232), [single]1)
    $link  = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(170, 170, 170), [single]1.5)
    $err   = [System.Drawing.Pen]::new([System.Drawing.Color]::SteelBlue, [single]1.5)
    $dot   = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::SteelBlue)
    $gold  = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(230, 170, 0))
    $goldP = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(150, 100, 0), [single]2)
    $bestP = [System.Drawing.Pen]::new([System.Drawing.Color]::ForestGreen, [single]2.5)
    $b0P   = [System.Drawing.Pen]::new([System.Drawing.Color]::DimGray, [single]1.5); $b0P.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
    $barP  = [System.Drawing.Pen]::new([System.Drawing.Color]::Firebrick, [single]1.5); $barP.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
    $meanP = [System.Drawing.Pen]::new([System.Drawing.Color]::Black, [single]3)
    $ok = $true
    try {
        $allNodes = @($d.Nodes); $nAll = $allNodes.Count
        $shown = [Math]::Max(0, [Math]::Min($Step, $nAll))
        $evoOver = ($Step -ge $nAll)
        # ---------- LEFT: evolution (validation) ----------
        $L = 60; $T = 45; $R = [int]($w * 0.6) - 30; $B = $h - 40
        $lo = [Math]::Floor([double](($allNodes | ForEach-Object { $_.Fitness - $_.SD }) | Measure-Object -Minimum).Minimum - 0.5)
        $hi = [Math]::Ceiling([double](($allNodes | ForEach-Object { $_.Fitness + $_.SD }) | Measure-Object -Maximum).Maximum + 0.5)
        $g.DrawString(('Evolution: fitness on validation shifts (mean of {0} training runs)' -f $d.Runs), $fontB, $txt, [single]$L, [single]12)
        for ($v = $lo; $v -le $hi; $v++) {
            $y = [single]($B - ($v - $lo) / ($hi - $lo) * ($B - $T))
            $g.DrawLine($grid, [single]$L, $y, [single]$R, $y)
            $g.DrawString([string]$v, $fontS, $dim, [single]($L - 28), [single]($y - 7))
        }
        $maxGen = [int](($allNodes | Measure-Object -Property Generation -Maximum).Maximum)
        $nCols = $maxGen + 2
        $colW = ($R - $L) / [double]$nCols
        for ($c = 0; $c -lt $nCols; $c++) {
            $name = 'Start'; if ($c -gt 0) { $name = 'Generation ' + ($c - 1) }
            $cx = $L + ($c + 0.5) * $colW
            $sz = $g.MeasureString($name, $font)
            $g.DrawString($name, $font, $dim, [single]($cx - $sz.Width / 2), [single]($B + 8))
        }
        $pos = @{}
        foreach ($grp in @($allNodes | Group-Object Column)) {
            $members = @($grp.Group | Sort-Object Id); $n = $members.Count
            $spread = [Math]::Min(34.0, $colW / ($n + 1))
            for ($k = 0; $k -lt $n; $k++) {
                $m = $members[$k]
                $x = $L + ([int]$grp.Name + 0.5) * $colW + ($k - ($n - 1) / 2.0) * $spread
                $y = $B - ($m.Fitness - $lo) / ($hi - $lo) * ($B - $T)
                $pos[$m.Id] = @([single]$x, [single]$y)
            }
        }
        $vis = @(); if ($shown -gt 0) { $vis = @($allNodes[0..($shown - 1)]) }
        $visIds = @{}; foreach ($m in $vis) { $visIds[$m.Id] = $true }
        foreach ($m in $vis) { if ($visIds.ContainsKey($m.Parent)) { $p = $pos[$m.Parent]; $q = $pos[$m.Id]; $g.DrawLine($link, $p[0], $p[1], $q[0], $q[1]) } }
        foreach ($m in $vis) {
            $q = $pos[$m.Id]
            $y1 = [single]($B - ($m.Fitness - $m.SD - $lo) / ($hi - $lo) * ($B - $T))
            $y2 = [single]($B - ($m.Fitness + $m.SD - $lo) / ($hi - $lo) * ($B - $T))
            $g.DrawLine($err, $q[0], $y1, $q[0], $y2)
            $g.DrawLine($err, [single]($q[0] - 4), $y1, [single]($q[0] + 4), $y1)
            $g.DrawLine($err, [single]($q[0] - 4), $y2, [single]($q[0] + 4), $y2)
        }
        $best = Get-VBAFEvolutionBestSoFar $d $shown
        foreach ($m in $vis) {
            $q = $pos[$m.Id]; $rad = 5
            if ($evoOver -and $m.IsChampion) {
                $rad = 8
                $g.FillEllipse($gold, [single]($q[0] - $rad), [single]($q[1] - $rad), [single](2 * $rad), [single](2 * $rad))
                $g.DrawEllipse($goldP, [single]($q[0] - $rad), [single]($q[1] - $rad), [single](2 * $rad), [single](2 * $rad))
            } else {
                $g.FillEllipse($dot, [single]($q[0] - $rad), [single]($q[1] - $rad), [single](2 * $rad), [single](2 * $rad))
            }
            if (-not $evoOver -and $null -ne $best -and $m.Id -eq $best.Id) { $g.DrawEllipse($bestP, [single]($q[0] - 10), [single]($q[1] - 10), [single]20, [single]20) }
            Write-VBAFWindowLabel $g $m.Id $fontS $txt ([single]($q[0] + $rad + 4)) ([single]($q[1] - 7))
        }
        # ---------- RIGHT: final test (test shifts) ----------
        $L2 = [int]($w * 0.6) + 40; $R2 = $w - 25
        $fs = @($d.FinalSeeds)
        $g.DrawString(('Final test: test shifts, {0} new seeds ({1})' -f $fs.Count, ($fs -join ', ')), $fontB, $txt, [single]$L2, [single]12)
        if ($Step -le $nAll) {
            $msg = 'The final test is shown at the end, when evolution is over.'
            $sz = $g.MeasureString($msg, $font)
            $g.DrawString($msg, $font, $dim, [single](($L2 + $R2) / 2 - $sz.Width / 2), [single](($T + $B) / 2))
        } else {
            $fin = @($d.Finals)
            $all = @($fin | ForEach-Object { $_.Test }) + @($d.Brain0, ($d.ChampionMean + $d.ChampionSD), ($d.ControlMean - $d.ControlSD))
            if ($null -ne $d.Bar) { $all += $d.Bar }
            $lo2 = [Math]::Floor([double]($all | Measure-Object -Minimum).Minimum - 0.5)
            $hi2 = [Math]::Ceiling([double]($all | Measure-Object -Maximum).Maximum + 0.5)
            for ($v = $lo2; $v -le $hi2; $v++) {
                $y = [single]($B - ($v - $lo2) / ($hi2 - $lo2) * ($B - $T))
                $g.DrawLine($grid, [single]$L2, $y, [single]$R2, $y)
                $g.DrawString([string]$v, $fontS, $dim, [single]($L2 - 28), [single]($y - 7))
            }
            $lines = @(, @($d.Brain0, $b0P, ('Brain 0 (SPT) {0:F2}' -f $d.Brain0)))
            if ($null -ne $d.Bar) { $lines += , @($d.Bar, $barP, ('Bar {0:F2}' -f $d.Bar)) }
            foreach ($ln in $lines) {
                $y = [single]($B - ($ln[0] - $lo2) / ($hi2 - $lo2) * ($B - $T))
                $g.DrawLine($ln[1], [single]$L2, $y, [single]$R2, $y)
                $sz = $g.MeasureString($ln[2], $fontS)
                $g.DrawString($ln[2], $fontS, $dim, [single]($R2 - $sz.Width), [single]($y - 15))
            }
            $cols = @(
                @{ Label = 'champion'; X = $L2 + 0.30 * ($R2 - $L2); Name = ('Champion ' + $d.Champion); Mean = $d.ChampionMean; SD = $d.ChampionSD; Brush = $gold },
                @{ Label = 'control';  X = $L2 + 0.72 * ($R2 - $L2); Name = 'Control (baseline genome)'; Mean = $d.ControlMean; SD = $d.ControlSD; Brush = $dot })
            foreach ($col in $cols) {
                foreach ($f in @($fin | Where-Object { $_.Label -eq $col.Label })) {
                    $idx = [Array]::IndexOf([int[]]$fs, [int]$f.Seed)
                    $x = [single]($col.X + ($idx - ($fs.Count - 1) / 2.0) * 9)
                    $y = [single]($B - ($f.Test - $lo2) / ($hi2 - $lo2) * ($B - $T))
                    $g.FillEllipse($col.Brush, [single]($x - 5), [single]($y - 5), [single]10, [single]10)
                }
                $ym = [single]($B - ($col.Mean - $lo2) / ($hi2 - $lo2) * ($B - $T))
                $g.DrawLine($meanP, [single]($col.X - 32), $ym, [single]($col.X + 32), $ym)
                $g.DrawString(('{0:F2} +/- {1:F2}' -f $col.Mean, $col.SD), $fontS, $txt, [single]($col.X + 36), [single]($ym - 7))
                $sz = $g.MeasureString($col.Name, $font)
                $g.DrawString($col.Name, $font, $dim, [single]($col.X - $sz.Width / 2), [single]($B + 8))
            }
        }
    } catch {
        $ok = $false
        $g.DrawString(('Draw error: ' + $_.Exception.Message), $font, [System.Drawing.Brushes]::Red, [single]10, [single]10)
    } finally {
        foreach ($o in @($font, $fontB, $fontS, $grid, $link, $err, $dot, $gold, $goldP, $bestP, $b0P, $barP, $meanP)) { $o.Dispose() }
    }
    return $ok
}
function Update-VBAFEvolutionView {
    $global:VBAFEvoStatus.Text = Get-VBAFEvolutionStepText $global:VBAFEvoData $global:VBAFEvoStep
    $global:VBAFEvoPb.Invalidate()
}
function New-VBAFEvolutionWindow($Data) {
    $global:VBAFEvoData = $Data
    $global:VBAFEvoLast = @($Data.Nodes).Count + 1
    $global:VBAFEvoStep = $global:VBAFEvoLast
    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'VBAF -- Evolution window'
    $form.Size = New-Object System.Drawing.Size(1250, 860)
    $form.StartPosition = 'CenterScreen'
    $tabs = New-Object System.Windows.Forms.TabControl
    $tabs.Dock = 'Fill'
    $tEvo = New-Object System.Windows.Forms.TabPage; $tEvo.Text = 'Evolution'
    $pb = New-Object System.Windows.Forms.PictureBox
    $pb.Dock = 'Fill'; $pb.BackColor = [System.Drawing.Color]::White
    $pb.Add_Paint({ param($sender, $e) [void](Invoke-VBAFDrawEvolution $e.Graphics $sender.ClientSize.Width $sender.ClientSize.Height $global:VBAFEvoData $global:VBAFEvoStep) })
    $pb.Add_Resize({ param($sender, $e) $sender.Invalidate() })
    $global:VBAFEvoPb = $pb
    $list = New-Object System.Windows.Forms.TextBox
    $list.Multiline = $true; $list.ReadOnly = $true; $list.ScrollBars = 'Vertical'; $list.Dock = 'Bottom'; $list.Height = 190
    $list.Font = New-Object System.Drawing.Font('Consolas', 9)
    $list.Text = Get-VBAFEvolutionLineageText $Data
    $status = New-Object System.Windows.Forms.Label
    $status.Dock = 'Top'; $status.Height = 40; $status.Padding = New-Object System.Windows.Forms.Padding(8, 4, 8, 2)
    $status.Font = New-Object System.Drawing.Font('Segoe UI', 9.5, [System.Drawing.FontStyle]::Bold)
    $global:VBAFEvoStatus = $status
    $bar = New-Object System.Windows.Forms.FlowLayoutPanel
    $bar.Dock = 'Top'; $bar.Height = 36; $bar.Padding = New-Object System.Windows.Forms.Padding(6, 4, 6, 0)
    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 1500
    $timer.Add_Tick({
        if ($global:VBAFEvoStep -lt $global:VBAFEvoLast) { $global:VBAFEvoStep++; Update-VBAFEvolutionView }
        if ($global:VBAFEvoStep -ge $global:VBAFEvoLast) { $global:VBAFEvoTimer.Stop() }
    })
    $global:VBAFEvoTimer = $timer
    $buttons = @(
        @('Play',     { if ($global:VBAFEvoStep -ge $global:VBAFEvoLast) { $global:VBAFEvoStep = 0; Update-VBAFEvolutionView }; $global:VBAFEvoTimer.Start() }),
        @('Pause',    { $global:VBAFEvoTimer.Stop() }),
        @('Restart',  { $global:VBAFEvoTimer.Stop(); $global:VBAFEvoStep = 0; Update-VBAFEvolutionView }),
        @('Show all', { $global:VBAFEvoTimer.Stop(); $global:VBAFEvoStep = $global:VBAFEvoLast; Update-VBAFEvolutionView }))
    foreach ($b in $buttons) {
        $btn = New-Object System.Windows.Forms.Button
        $btn.Text = $b[0]; $btn.Width = 90; $btn.Height = 26
        $btn.Add_Click($b[1])
        $bar.Controls.Add($btn)
    }
    $info = New-Object System.Windows.Forms.Label
    $info.Dock = 'Top'; $info.Height = 58; $info.Padding = New-Object System.Windows.Forms.Padding(8, 6, 8, 4)
    $info.Font = New-Object System.Drawing.Font('Segoe UI', 9.5)
    $info.Text = ('Each dot is a candidate brain (a set of genes). Its height is its fitness: the mean of several training runs, measured on validation shifts. ' +
        'The bar shows the spread, and the lines go from parent to child. If no child beats its parent, the parent is kept. ' +
        'The gold dot is the champion. Right: the final test on test shifts that no candidate has seen before.')
    $tEvo.Controls.Add($pb); $tEvo.Controls.Add($list); $tEvo.Controls.Add($status); $tEvo.Controls.Add($bar); $tEvo.Controls.Add($info)
    $tShift = New-Object System.Windows.Forms.TabPage; $tShift.Text = 'The shift'
    if ((Get-Command Initialize-VBAFShiftTab -ErrorAction SilentlyContinue) -and $Data.ResultDir -and ([System.Management.Automation.PSTypeName]'ProductionCellEnvironment').Type) { Initialize-VBAFShiftTab $tShift $Data.ResultDir } else { $l2 = New-Object System.Windows.Forms.Label; $l2.Text = 'Coming in the next step.'; $l2.Dock = 'Fill'; $l2.TextAlign = 'MiddleCenter'; $tShift.Controls.Add($l2) }
    $tSide = New-Object System.Windows.Forms.TabPage; $tSide.Text = 'Side by side'
    $global:VBAFSideReady = $false
    if ((Get-Command Initialize-VBAFSideTab -ErrorAction SilentlyContinue) -and $Data.ResultDir -and ([System.Management.Automation.PSTypeName]'ProductionCellEnvironment').Type) {
        $l3 = New-Object System.Windows.Forms.Label; $l3.Text = 'Open this tab to compute all test shifts (a few seconds).'; $l3.Dock = 'Fill'; $l3.TextAlign = 'MiddleCenter'; $tSide.Controls.Add($l3)
        $global:VBAFSidePage = $tSide; $global:VBAFSideDir = $Data.ResultDir
        $tabs.Add_SelectedIndexChanged({ param($sender, $e) if ($sender.SelectedTab -eq $global:VBAFSidePage -and -not $global:VBAFSideReady) { Initialize-VBAFSideTab $global:VBAFSidePage $global:VBAFSideDir } })
    } else { $l3 = New-Object System.Windows.Forms.Label; $l3.Text = 'Coming in the next step.'; $l3.Dock = 'Fill'; $l3.TextAlign = 'MiddleCenter'; $tSide.Controls.Add($l3) }
    $tabs.TabPages.Add($tEvo); $tabs.TabPages.Add($tShift); $tabs.TabPages.Add($tSide)
    $form.Controls.Add($tabs)
    $form.Add_FormClosing({ $global:VBAFEvoTimer.Stop() })
    $status.Text = Get-VBAFEvolutionStepText $Data $global:VBAFEvoStep
    return $form
}
function Show-VBAFEvolutionWindow {
    param([Parameter(Mandatory = $true)][string]$ResultDir)
    $data = Get-VBAFEvolutionData $ResultDir
    [System.Windows.Forms.Application]::EnableVisualStyles()
    $form = New-VBAFEvolutionWindow $data
    [void]$form.ShowDialog()
    if ($global:VBAFShift -and $global:VBAFShift.Timer) { $global:VBAFShift.Timer.Stop(); $global:VBAFShift.Timer.Dispose() }
    if ($global:VBAFSide -and $global:VBAFSide.Timer) { $global:VBAFSide.Timer.Stop(); $global:VBAFSide.Timer.Dispose() }
    $global:VBAFEvoTimer.Dispose()
    $form.Dispose()
}
function Get-VBAFEvolutionRenderStats($Data, [int]$Step, [string]$SavePath = '') {
    $bmp = [System.Drawing.Bitmap]::new(1200, 600)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $ok = Invoke-VBAFDrawEvolution $g 1200 600 $Data $Step
    $g.Dispose()
    $nw = 0; $gold = 0
    for ($y = 0; $y -lt $bmp.Height; $y += 4) {
        for ($x = 0; $x -lt $bmp.Width; $x += 4) {
            $c = $bmp.GetPixel($x, $y)
            if ($c.R -lt 245 -or $c.G -lt 245 -or $c.B -lt 245) { $nw++ }
            if ($c.R -gt 200 -and $c.G -gt 140 -and $c.G -lt 200 -and $c.B -lt 60) { $gold++ }
        }
    }
    if ($SavePath -ne '') { $bmp.Save($SavePath, [System.Drawing.Imaging.ImageFormat]::Png) }
    $bmp.Dispose()
    return @{ Ok = $ok; NonWhite = $nw; Gold = $gold }
}
# Self-test that works for ANY study: returns check objects (Check, Pass, Detail). Renders to bitmaps, no window shown.
function Test-VBAFEvolutionWindow {
    param([Parameter(Mandatory = $true)][string]$ResultDir, [string]$OutPng = '')
    $checks = @()
    $d = Get-VBAFEvolutionData $ResultDir
    $n = @($d.Nodes).Count
    $checks += [pscustomobject]@{ Check = 'study data loads (candidates and final-test rows)'; Pass = (($n -gt 0) -and (@($d.Finals).Count -gt 0)); Detail = ('{0} candidates, {1} final rows' -f $n, @($d.Finals).Count) }
    $checks += [pscustomobject]@{ Check = 'the champion is in the lineage'; Pass = (@($d.Nodes | Where-Object { $_.IsChampion }).Count -eq 1); Detail = $d.Champion }
    $r1 = Get-VBAFEvolutionRenderStats $d 1
    $rB = Get-VBAFEvolutionRenderStats $d ($n - 1)
    $rE = Get-VBAFEvolutionRenderStats $d $n
    $rF = Get-VBAFEvolutionRenderStats $d ($n + 1) $OutPng
    $checks += [pscustomobject]@{ Check = 'drawing works at every stage'; Pass = ($r1.Ok -and $rB.Ok -and $rE.Ok -and $rF.Ok); Detail = '' }
    $checks += [pscustomobject]@{ Check = 'playback reveals: step 1 draws less than the step before the end'; Pass = ($r1.NonWhite -lt $rB.NonWhite); Detail = ('{0} < {1}' -f $r1.NonWhite, $rB.NonWhite) }
    $checks += [pscustomobject]@{ Check = 'no gold before evolution is over'; Pass = (($r1.Gold -eq 0) -and ($rB.Gold -eq 0)); Detail = ('{0} / {1}' -f $r1.Gold, $rB.Gold) }
    $checks += [pscustomobject]@{ Check = 'gold when evolution is over, more gold with the final test'; Pass = (($rE.Gold -gt 0) -and ($rF.Gold -gt $rE.Gold)); Detail = ('{0} -> {1}' -f $rE.Gold, $rF.Gold) }
    $d2 = [pscustomobject]@{ Champion = $d.Champion; Finals = @(); FinalSeeds = $d.FinalSeeds; Runs = $d.Runs
        Nodes = @($d.Nodes | ForEach-Object { $c = $_.PSObject.Copy(); $c.IsChampion = $false; $c })
        ChampionMean = $d.ChampionMean; ChampionSD = $d.ChampionSD; ControlMean = $d.ControlMean; ControlSD = $d.ControlSD; Brain0 = $d.Brain0; Bar = $d.Bar }
    $rX = Get-VBAFEvolutionRenderStats $d2 ($n + 1)
    $checks += [pscustomobject]@{ Check = 'sensitivity: no champion marked -> no gold'; Pass = ($rX.Gold -eq 0); Detail = ('gold ' + $rX.Gold) }
    $d3 = $d.PSObject.Copy(); $d3.Bar = $null
    $rN = Get-VBAFEvolutionRenderStats $d3 ($n + 1)
    $checks += [pscustomobject]@{ Check = 'a study without a bar draws fine'; Pass = $rN.Ok; Detail = '' }
    $f = New-VBAFEvolutionWindow $d
    $nTabs = $f.Controls[0].TabPages.Count
    $global:VBAFEvoTimer.Dispose(); $f.Dispose()
    $checks += [pscustomobject]@{ Check = 'the window has 3 tabs'; Pass = ($nTabs -eq 3); Detail = ('tabs ' + $nTabs) }
    return $checks
}
