#Requires -Version 5.1
<#
.SYNOPSIS
    "Side by side" tab of Show-VBAFEvolutionWindow: the brains on the SAME test shift with the same clock, plus an
    honest board over ALL test shifts (VBAF v6.0).
.DESCRIPTION
    Top: one machine timeline per brain, played minute by minute (an order in progress is drawn lighter), live score.
    Bottom: champion minus SPT on every test shift, means, head-to-head (this champion vs SPT and vs the control), all
    champion brains of the study vs SPT (when their models are in the folder), and the average win and loss margin.
    Everything is computed from the study folder when the tab is first opened (a few seconds). ASCII only.
    Comes from VBAF-Evolution-Lab phase 5.3.
#>
function Get-VBAFHeadToHead($A, $B) {
    $w = 0; $t = 0; $l = 0
    for ($i = 0; $i -lt @($A).Count; $i++) { $x = [double]$A[$i] - [double]$B[$i]; if ($x -gt 0) { $w++ } elseif ($x -lt 0) { $l++ } else { $t++ } }
    return [pscustomobject]@{ W = $w; T = $t; L = $l }
}
function Get-VBAFSideData([string]$ResultDir) {
    $world  = [ProductionCellEnvironment]::new(1)
    $brains = Get-VBAFShiftBrains $ResultDir
    $seeds  = @(Get-VBAFProductionTestSeeds)
    $list = @()
    foreach ($nm in @($brains.Keys)) {
        $b = $brains[$nm]
        $pol = $b.Policy; if ($b.ContainsKey('Agent')) { $pol = Get-VBAFBrainPolicy -Agent $b.Agent }
        $m = Measure-VBAFProductionPolicy -World $world -Policy $pol -Seeds $seeds
        $list += [pscustomobject]@{ Name = $nm; Rewards = @($m.PerSeed | ForEach-Object { [double]$_.Reward }); Score = [double]$m.Score; ScoreStd = [double]$m.ScoreStd }
    }
    $h = [ordered]@{}
    if ($list.Count -ge 2) { $h.ChampionVsSPT = Get-VBAFHeadToHead $list[$list.Count - 1].Rewards $list[0].Rewards }
    if ($list.Count -ge 3) { $h.ChampionVsControl = Get-VBAFHeadToHead $list[$list.Count - 1].Rewards $list[1].Rewards }
    $all = $null; $seed0 = 0
    $s = (Get-Content (Get-VBAFEvolutionSummaryPath $ResultDir) -Raw -Encoding UTF8 | ConvertFrom-Json)
    $seed0 = [int]@($s.FinalSeeds)[0]
    $models = @(@($s.FinalSeeds) | ForEach-Object { Join-Path $ResultDir ('final-champion-s{0}-best.xml' -f $_) } | Where-Object { Test-Path $_ })
    if ($models.Count -ge 2) {
        $cg = ConvertTo-VBAFGenome $s.ChampionGenome
        $w = 0; $t = 0; $l = 0
        foreach ($fs in @($s.FinalSeeds)) {
            $mp = Join-Path $ResultDir ('final-champion-s{0}-best.xml' -f $fs)
            if (-not (Test-Path $mp)) { continue }
            $br = Restore-VBAFBrain -Genome $cg -BrainSeed ([int]$fs) -ModelPath $mp
            $mm = Measure-VBAFProductionPolicy -World $world -Policy (Get-VBAFBrainPolicy -Agent $br) -Seeds $seeds
            $hh = Get-VBAFHeadToHead @($mm.PerSeed | ForEach-Object { [double]$_.Reward }) $list[0].Rewards
            $w += $hh.W; $t += $hh.T; $l += $hh.L
        }
        $all = [pscustomobject]@{ Brains = $models.Count; W = $w; T = $t; L = $l; Shifts = $models.Count * $seeds.Count }
    }
    return [pscustomobject]@{ Seeds = $seeds; Brains = @($list); HeadToHead = $h; AllChampions = $all; ChampionSeed = $seed0 }
}
function Get-VBAFSideDiffs($Data) {
    $bl = @($Data.Brains); if ($bl.Count -lt 2) { return @() }
    $c = @($bl[$bl.Count - 1].Rewards); $s = @($bl[0].Rewards)
    $d = @(); for ($i = 0; $i -lt $c.Count; $i++) { $d += ([double]$c[$i] - [double]$s[$i]) }
    return $d
}
function Get-VBAFSideMargins($Data) {
    $d = Get-VBAFSideDiffs $Data
    $w = @($d | Where-Object { $_ -gt 0 }); $l = @($d | Where-Object { $_ -lt 0 })
    $wm = 0.0; if ($w.Count -gt 0) { $wm = [double](($w | Measure-Object -Average).Average) }
    $lm = 0.0; if ($l.Count -gt 0) { $lm = -1.0 * [double](($l | Measure-Object -Average).Average) }
    return [pscustomobject]@{ Wins = $w.Count; Losses = $l.Count; WinMean = $wm; LossMean = $lm }
}
function Get-VBAFScoreAtClock($Trace, [int]$T) {
    $sc = 0.0; $k = 0
    foreach ($s in @($Trace.Steps)) { if ([int]$s.ClockAfter -le $T) { $sc = [double]$s.Total; $k++ } else { break } }
    return [pscustomobject]@{ Score = $sc; Steps = $k }
}
function Get-VBAFSideMaxClock($Traces) {
    $m = 200
    foreach ($tr in @($Traces)) { $st = @($tr.Trace.Steps); $m = [Math]::Max($m, [int]$st[$st.Count - 1].ClockAfter) }
    return $m
}
function Invoke-VBAFDrawSide {
    param($g, [int]$w, [int]$h, $Traces, [int]$T, $Data, [int]$Seed)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $g.Clear([System.Drawing.Color]::White)
    $font = [System.Drawing.Font]::new('Segoe UI', [single]9.5); $fontB = [System.Drawing.Font]::new('Segoe UI', [single]10, [System.Drawing.FontStyle]::Bold)
    $fontS = [System.Drawing.Font]::new('Segoe UI', [single]8); $fontL = [System.Drawing.Font]::new('Segoe UI', [single]12, [System.Drawing.FontStyle]::Bold); $fontLn = [System.Drawing.Font]::new('Segoe UI', [single]12)
    $txt = [System.Drawing.Brushes]::Black; $dim = [System.Drawing.Brushes]::DimGray
    $cols = @{
        ontime  = @([System.Drawing.SolidBrush]::new([System.Drawing.Color]::ForestGreen), [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(120, 34, 139, 34)))
        late    = @([System.Drawing.SolidBrush]::new([System.Drawing.Color]::Firebrick), [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(120, 178, 34, 34)))
        idle    = @([System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(205, 205, 205)), [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(205, 205, 205)))
        invalid = @([System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(235, 125, 0)), [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(120, 235, 125, 0))) }
    $track = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(242, 242, 242)); $grayB = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(170, 170, 170))
    $sep = [System.Drawing.Pen]::new([System.Drawing.Color]::White, [single]1); $marker = [System.Drawing.Pen]::new([System.Drawing.Color]::Black, [single]2)
    $zero = [System.Drawing.Pen]::new([System.Drawing.Color]::Gray, [single]1); $selP = [System.Drawing.Pen]::new([System.Drawing.Color]::Black, [single]2)
    $ok = $true
    try {
        $L = 40; $R = $w - 40
        $tl = @($Traces); $nT = $tl.Count
        $maxClock = Get-VBAFSideMaxClock $tl
        $tt = [Math]::Max(0, [Math]::Min($T, $maxClock))
        $g.DrawString(('Same shift (test shift {0}), same clock: {1} of {2}' -f $Seed, $tt, $maxClock), $fontB, $txt, [single]$L, [single]10)
        $xL = $L + 260; $xR = $R - 120
        $scores = @(); foreach ($tr in $tl) { $scores += (Get-VBAFScoreAtClock $tr.Trace $tt).Score }
        $bestScore = ($scores | Measure-Object -Maximum).Maximum
        for ($i = 0; $i -lt $nT; $i++) {
            $tr = $tl[$i]; $y = 44 + $i * 56; $hh = 30
            $nf = $font; if ($tt -gt 0 -and $scores[$i] -eq $bestScore) { $nf = $fontB }
            $g.DrawString([string]$tr.Name, $nf, $txt, [single]$L, [single]($y + 6))
            $g.FillRectangle($track, [single]$xL, [single]$y, [single]($xR - $xL), [single]$hh)
            foreach ($s in @($tr.Trace.Steps)) {
                if ([int]$s.ClockBefore -ge $tt) { break }
                $done = ([int]$s.ClockAfter -le $tt)
                $x1 = $xL + $s.ClockBefore / $maxClock * ($xR - $xL); $x2 = $xL + [Math]::Min([int]$s.ClockAfter, $tt) / $maxClock * ($xR - $xL)
                $pair = $cols['invalid']; if ($cols.ContainsKey([string]$s.Outcome)) { $pair = $cols[[string]$s.Outcome] }
                $br = $pair[1]; if ($done) { $br = $pair[0] }
                $g.FillRectangle($br, [single]$x1, [single]$y, [single][Math]::Max(1.0, $x2 - $x1), [single]$hh)
                if ($done -and $s.Outcome -ne 'idle') { $g.DrawLine($sep, [single]$x2, [single]$y, [single]$x2, [single]($y + $hh)) }
            }
            $sf = $fontLn; if ($tt -gt 0 -and $scores[$i] -eq $bestScore) { $sf = $fontL }
            $g.DrawString(('{0:F2}' -f $scores[$i]), $sf, $txt, [single]($xR + 14), [single]($y + 3))
        }
        $yEnd = 44 + $nT * 56
        $xm = $xL + $tt / $maxClock * ($xR - $xL)
        $g.DrawLine($marker, [single]$xm, [single]38, [single]$xm, [single]($yEnd - 20))
        for ($t2 = 0; $t2 -le $maxClock; $t2 += 25) { $x = $xL + $t2 / $maxClock * ($xR - $xL); $g.DrawString([string]$t2, $fontS, $dim, [single]($x - 8), [single]($yEnd - 18)) }
        $yB = $yEnd + 16
        $diffs = Get-VBAFSideDiffs $Data
        if ($diffs.Count -eq 0) {
            $g.DrawString('This study folder has no trained models: there is nothing to compare with the SPT rule.', $font, $dim, [single]$L, [single]($yB + 10))
        } else {
            $seeds = @($Data.Seeds)
            $g.DrawString(('All {0} test shifts: the champion''s score minus the SPT rule''s, shift by shift (green = champion won, red = SPT won)' -f $seeds.Count), $fontB, $txt, [single]$L, [single]$yB)
            $cTop = $yB + 26; $cH = 150; $mid = $cTop + $cH / 2
            $maxAbs = [Math]::Max(1.0, [double](($diffs | ForEach-Object { [Math]::Abs($_) }) | Measure-Object -Maximum).Maximum)
            $g.DrawLine($zero, [single]$L, [single]$mid, [single]$R, [single]$mid)
            $bw = ($R - $L) / [double]$diffs.Count
            for ($i = 0; $i -lt $diffs.Count; $i++) {
                $x = $L + $i * $bw
                $hgt = [Math]::Abs($diffs[$i]) / $maxAbs * ($cH / 2 - 6)
                if ($diffs[$i] -gt 0) { $g.FillRectangle($cols['ontime'][0], [single]($x + 2), [single]($mid - $hgt), [single]($bw - 4), [single][Math]::Max(1.0, $hgt)) }
                elseif ($diffs[$i] -lt 0) { $g.FillRectangle($cols['late'][0], [single]($x + 2), [single]$mid, [single]($bw - 4), [single][Math]::Max(1.0, $hgt)) }
                else { $g.FillRectangle($grayB, [single]($x + 2), [single]($mid - 1), [single]($bw - 4), [single]2) }
                if ([int]$seeds[$i] -eq $Seed) { $g.DrawRectangle($selP, [single]($x + 1), [single]$cTop, [single]($bw - 2), [single]$cH) }
                if ($i % 5 -eq 0) { $g.DrawString([string]$seeds[$i], $fontS, $dim, [single]$x, [single]($cTop + $cH + 2)) }
            }
            $bl = @($Data.Brains)
            $lines = @()
            $means = 'Mean over the {0} test shifts:  ' -f $seeds.Count
            $means += (($bl | ForEach-Object { '{0} {1:F2}' -f ($_.Name -replace ' \(.*$', ''), $_.Score }) -join '   ')
            $lines += $means
            $hc = $Data.HeadToHead.ChampionVsSPT
            $l2 = 'This champion brain (seed {0}) vs SPT: {1} won, {2} tied, {3} lost.' -f $Data.ChampionSeed, $hc.W, $hc.T, $hc.L
            if ($null -ne $Data.HeadToHead.ChampionVsControl) { $hk = $Data.HeadToHead.ChampionVsControl; $l2 += ('   Vs the control: {0} won, {1} tied, {2} lost.' -f $hk.W, $hk.T, $hk.L) }
            $lines += $l2
            if ($null -ne $Data.AllChampions) { $a = $Data.AllChampions; $lines += ('All {0} champion brains of the study vs SPT: {1} won, {2} tied, {3} lost of {4} shifts. One brain is not the whole story.' -f $a.Brains, $a.W, $a.T, $a.L, $a.Shifts) }
            $mg = Get-VBAFSideMargins $Data
            $lines += ('When this champion beats SPT it wins by {0:F2} points on average ({1} shifts); when it loses, it loses by {2:F2} ({3} shifts).' -f $mg.WinMean, $mg.Wins, $mg.LossMean, $mg.Losses)
            $lines += ('Shifts differ a lot (SPT: +/- {0:F0} points), so single numbers say little: compare brains in pairs, on the same shift.' -f $bl[0].ScoreStd)
            $yT = $cTop + $cH + 22
            for ($i = 0; $i -lt $lines.Count; $i++) { $g.DrawString($lines[$i], $font, $txt, [single]$L, [single]($yT + $i * 22)) }
        }
    } catch {
        $ok = $false
        $g.DrawString(('Draw error: ' + $_.Exception.Message), $font, [System.Drawing.Brushes]::Red, [single]10, [single]10)
    } finally {
        foreach ($k in $cols.Keys) { $cols[$k][0].Dispose(); $cols[$k][1].Dispose() }
        foreach ($o in @($font, $fontB, $fontS, $fontL, $fontLn, $track, $grayB, $sep, $marker, $zero, $selP)) { $o.Dispose() }
    }
    return $ok
}
function Get-VBAFSideTraces([int]$Seed) {
    $list = @()
    foreach ($nm in @($global:VBAFShiftBrains.Keys)) { $list += @{ Name = $nm; Trace = (Get-VBAFShiftTraceCached $nm $Seed) } }
    return $list
}
function Get-VBAFSideStatus {
    $S = $global:VBAFSide
    $parts = @(); foreach ($tr in $S.Traces) { $parts += ('{0}: {1:F2}' -f ($tr.Name -replace ' \(.*$', ''), (Get-VBAFScoreAtClock $tr.Trace $S.T).Score) }
    return ('Test shift {0}, clock {1}:   ' -f $S.Seed, $S.T) + ($parts -join '    ')
}
function Update-VBAFSideView { $S = $global:VBAFSide; $S.Status.Text = Get-VBAFSideStatus; $S.Pb.Invalidate() }
function Initialize-VBAFSideTab($Page, [string]$ResultDir) {
    $Page.Controls.Clear()
    $old = [System.Windows.Forms.Cursor]::Current; [System.Windows.Forms.Cursor]::Current = [System.Windows.Forms.Cursors]::WaitCursor
    if (-not $global:VBAFShiftBrains) { $global:VBAFShiftWorld = [ProductionCellEnvironment]::new(1); $global:VBAFShiftCache = @{}; $global:VBAFShiftBrains = Get-VBAFShiftBrains $ResultDir }
    $global:VBAFSideData = Get-VBAFSideData $ResultDir
    $global:VBAFSide = @{ Seed = 1001; T = 0; MinPerTick = 2 }
    $S = $global:VBAFSide
    $S.Traces = Get-VBAFSideTraces $S.Seed; $S.Max = Get-VBAFSideMaxClock $S.Traces; $S.T = $S.Max
    $pb = New-Object System.Windows.Forms.PictureBox; $pb.Dock = 'Fill'; $pb.BackColor = [System.Drawing.Color]::White
    $pb.Add_Paint({ param($sender, $e) $S2 = $global:VBAFSide; [void](Invoke-VBAFDrawSide $e.Graphics $sender.ClientSize.Width $sender.ClientSize.Height $S2.Traces $S2.T $global:VBAFSideData $S2.Seed) })
    $pb.Add_Resize({ param($sender, $e) $sender.Invalidate() })
    $S.Pb = $pb
    $status = New-Object System.Windows.Forms.Label; $status.Dock = 'Top'; $status.Height = 30; $status.Padding = New-Object System.Windows.Forms.Padding(8, 4, 8, 2)
    $status.Font = New-Object System.Drawing.Font('Segoe UI', 9.5, [System.Drawing.FontStyle]::Bold)
    $S.Status = $status
    $bar = New-Object System.Windows.Forms.FlowLayoutPanel; $bar.Dock = 'Top'; $bar.Height = 36; $bar.Padding = New-Object System.Windows.Forms.Padding(6, 4, 6, 0)
    $l1 = New-Object System.Windows.Forms.Label; $l1.Text = 'Shift:'; $l1.AutoSize = $true; $l1.Padding = New-Object System.Windows.Forms.Padding(0, 6, 0, 0)
    $sb = New-Object System.Windows.Forms.ComboBox; $sb.DropDownStyle = 'DropDownList'; $sb.Width = 70
    foreach ($sd in @(Get-VBAFProductionTestSeeds)) { [void]$sb.Items.Add($sd) }
    $sb.SelectedIndex = 0
    $S.SeedBox = $sb
    $timer = New-Object System.Windows.Forms.Timer; $timer.Interval = 150
    $timer.Add_Tick({ $S2 = $global:VBAFSide; if ($S2.T -lt $S2.Max) { $S2.T = [Math]::Min($S2.Max, $S2.T + $S2.MinPerTick); Update-VBAFSideView }; if ($S2.T -ge $S2.Max) { $S2.Timer.Stop() } })
    $S.Timer = $timer
    $bar.Controls.Add($l1); $bar.Controls.Add($sb)
    $buttons = @(
        @('Play',     { $S2 = $global:VBAFSide; if ($S2.T -ge $S2.Max) { $S2.T = 0; Update-VBAFSideView }; $S2.Timer.Start() }),
        @('Pause',    { $global:VBAFSide.Timer.Stop() }),
        @('Restart',  { $S2 = $global:VBAFSide; $S2.Timer.Stop(); $S2.T = 0; Update-VBAFSideView }),
        @('Show end', { $S2 = $global:VBAFSide; $S2.Timer.Stop(); $S2.T = $S2.Max; Update-VBAFSideView }))
    foreach ($b in $buttons) { $btn = New-Object System.Windows.Forms.Button; $btn.Text = $b[0]; $btn.Width = 78; $btn.Height = 26; $btn.Add_Click($b[1]); $bar.Controls.Add($btn) }
    $l3 = New-Object System.Windows.Forms.Label; $l3.Text = 'Speed:'; $l3.AutoSize = $true; $l3.Padding = New-Object System.Windows.Forms.Padding(8, 6, 0, 0)
    $sp = New-Object System.Windows.Forms.ComboBox; $sp.DropDownStyle = 'DropDownList'; $sp.Width = 80
    foreach ($nm in @('Slow', 'Normal', 'Fast')) { [void]$sp.Items.Add($nm) }
    $sp.SelectedIndex = 1
    $sp.Add_SelectedIndexChanged({ param($sender, $e) $global:VBAFSide.MinPerTick = @(1, 2, 5)[$sender.SelectedIndex] })
    $bar.Controls.Add($l3); $bar.Controls.Add($sp)
    $sb.Add_SelectedIndexChanged({ $S2 = $global:VBAFSide; $S2.Timer.Stop(); $S2.Seed = [int]$S2.SeedBox.SelectedItem; $S2.Traces = Get-VBAFSideTraces $S2.Seed; $S2.Max = Get-VBAFSideMaxClock $S2.Traces; $S2.T = 0; Update-VBAFSideView })
    $info = New-Object System.Windows.Forms.Label; $info.Dock = 'Top'; $info.Height = 44; $info.Padding = New-Object System.Windows.Forms.Padding(8, 6, 8, 4)
    $info.Font = New-Object System.Drawing.Font('Segoe UI', 9.5)
    $info.Text = 'The brains on the same test shift with the same clock. An order in progress is drawn lighter until it is done. Bottom: all test shifts, so one shift never gets to tell the whole story.'
    $Page.Controls.Add($pb); $Page.Controls.Add($status); $Page.Controls.Add($bar); $Page.Controls.Add($info)
    $status.Text = Get-VBAFSideStatus
    $global:VBAFSideReady = $true
    [System.Windows.Forms.Cursor]::Current = $old
}
function Get-VBAFSideRenderSignature($Traces, [int]$T, $Data, [int]$Seed) {
    $bmp = [System.Drawing.Bitmap]::new(1200, 620)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $ok = Invoke-VBAFDrawSide $g 1200 620 $Traces $T $Data $Seed
    $g.Dispose()
    $nw = 0; $sig = 0
    for ($y = 0; $y -lt $bmp.Height; $y += 3) { for ($x = 0; $x -lt $bmp.Width; $x += 3) { $c = $bmp.GetPixel($x, $y); if ($c.R -lt 245 -or $c.G -lt 245 -or $c.B -lt 245) { $nw++; $sig = ($sig * 31 + $x * 7 + $y) % 1000003 } } }
    $bmp.Dispose()
    return @{ Ok = $ok; NonWhite = $nw; Signature = $sig }
}
# Self-test for ANY study folder. Returns @{ Checks = check objects (Check, Pass, Detail); Data = the side data }.
function Test-VBAFSideView {
    param([Parameter(Mandatory = $true)][string]$ResultDir)
    $checks = @()
    $global:VBAFShiftWorld = [ProductionCellEnvironment]::new(1); $global:VBAFShiftCache = @{}; $global:VBAFShiftBrains = Get-VBAFShiftBrains $ResultDir
    $d = Get-VBAFSideData $ResultDir
    $bl = @($d.Brains)
    $checks += [pscustomobject]@{ Check = 'side data: every brain measured on every test shift'; Pass = (($bl.Count -ge 1) -and (@($bl | Where-Object { @($_.Rewards).Count -ne @($d.Seeds).Count }).Count -eq 0)); Detail = ('{0} brains x {1} shifts' -f $bl.Count, @($d.Seeds).Count) }
    $diffs = Get-VBAFSideDiffs $d
    if ($bl.Count -ge 2) {
        $hc = $d.HeadToHead.ChampionVsSPT
        $checks += [pscustomobject]@{ Check = 'bars = head-to-head (green = won, red = lost)'; Pass = ((@($diffs | Where-Object { $_ -gt 0 }).Count -eq $hc.W) -and (@($diffs | Where-Object { $_ -lt 0 }).Count -eq $hc.L)); Detail = ('{0}/{1}/{2}' -f $hc.W, $hc.T, $hc.L) }
        $cR = @($bl[$bl.Count - 1].Rewards); $sR = @($bl[0].Rewards); $ws = 0.0; $wn = 0; $ls = 0.0; $ln = 0
        for ($i = 0; $i -lt $cR.Count; $i++) { $x = [double]$cR[$i] - [double]$sR[$i]; if ($x -gt 0) { $ws += $x; $wn++ } elseif ($x -lt 0) { $ls -= $x; $ln++ } }
        $mg = Get-VBAFSideMargins $d
        $okM = ($mg.Wins -eq $wn) -and ($mg.Losses -eq $ln) -and (($wn -eq 0) -or ([Math]::Round($mg.WinMean, 2) -eq [Math]::Round($ws / $wn, 2))) -and (($ln -eq 0) -or ([Math]::Round($mg.LossMean, 2) -eq [Math]::Round($ls / $ln, 2)))
        $checks += [pscustomobject]@{ Check = 'win/loss margins = an independent calculation'; Pass = $okM; Detail = ('win {0:F2} ({1}), loss {2:F2} ({3})' -f $mg.WinMean, $mg.Wins, $mg.LossMean, $mg.Losses) }
    }
    $t1 = Get-VBAFSideTraces 1001; $t2 = Get-VBAFSideTraces 1030
    $mx = Get-VBAFSideMaxClock $t1
    $endOk = $true; $zeroOk = $true
    foreach ($tr in $t1) { if ((Get-VBAFScoreAtClock $tr.Trace $mx).Score -ne [double]@($tr.Trace.Steps)[-1].Total) { $endOk = $false }; if ((Get-VBAFScoreAtClock $tr.Trace 0).Score -ne 0) { $zeroOk = $false } }
    $checks += [pscustomobject]@{ Check = 'score at the end = trace totals; score at clock 0 = 0'; Pass = ($endOk -and $zeroOk); Detail = '' }
    $r1 = Get-VBAFSideRenderSignature $t1 100 $d 1001; $r2 = Get-VBAFSideRenderSignature $t2 100 $d 1030
    $checks += [pscustomobject]@{ Check = 'drawing works; two shifts draw differently (sensitivity)'; Pass = ($r1.Ok -and $r2.Ok -and ($r1.Signature -ne $r2.Signature)); Detail = ('{0} vs {1}' -f $r1.Signature, $r2.Signature) }
    $page = New-Object System.Windows.Forms.TabPage
    Initialize-VBAFSideTab $page $ResultDir
    $checks += [pscustomobject]@{ Check = 'the side tab builds (picture, status, buttons, text)'; Pass = ($page.Controls.Count -eq 4); Detail = ('controls ' + $page.Controls.Count) }
    $global:VBAFSide.Timer.Dispose(); $page.Dispose()
    return @{ Checks = $checks; Data = $d }
}
