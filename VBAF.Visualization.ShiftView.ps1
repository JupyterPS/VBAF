#Requires -Version 5.1
<#
.SYNOPSIS
    "The shift" tab of Show-VBAFEvolutionWindow: one brain works one production-cell TEST shift, step by step (VBAF v5.0).
.DESCRIPTION
    Built on Get-VBAFShiftTrace (compute first, animate later). The machine timeline shows every step: green = order on
    time, red = late, light grey = waiting for orders (empty queue, NOT the brain's fault), orange = a wasted choice.
    The cards show the first 3 orders the brain can see; idle steps play 4x faster. ASCII only.
    Comes from VBAF-Evolution-Lab phase 5.2.
#>
function Get-VBAFShiftCounts($Trace, [int]$Upto) {
    $st = @($Trace.Steps)
    $c = @{ OnTime = 0; Late = 0; Idle = 0; Invalid = 0; Choice = 0 }
    for ($i = 0; $i -lt [Math]::Min($Upto, $st.Count); $i++) {
        switch ($st[$i].Outcome) { 'ontime' { $c.OnTime++ } 'late' { $c.Late++ } 'idle' { $c.Idle++ } default { $c.Invalid++ } }
        if (($st[$i].Outcome -eq 'ontime' -or $st[$i].Outcome -eq 'late') -and @($st[$i].Visible).Count -ge 2) { $c.Choice++ }
    }
    $c.Real = $c.OnTime + $c.Late
    return $c
}
function Get-VBAFShiftInterval($Trace, [int]$NextStep, [int]$Base) {
    $st = @($Trace.Steps)
    if ($NextStep -ge 1 -and $NextStep -le $st.Count -and $st[$NextStep - 1].Outcome -eq 'idle') { return [Math]::Max(25, [int]($Base / 4)) }
    return $Base
}
function Get-VBAFShiftStepText($Trace, [int]$Step) {
    $st = @($Trace.Steps); $n = $st.Count
    if ($Step -le 0) { return 'Press Play (or Step) to watch the brain work, one step at a time.' }
    $k = [Math]::Min($Step, $n); $s = $st[$k - 1]
    if ($s.Outcome -eq 'ontime' -or $s.Outcome -eq 'late') {
        $ch = @($s.Visible | Where-Object { $_.Id -eq $s.ChosenId })[0]
        $res = 'on time'; if ($s.Outcome -eq 'late') { $res = 'late' }
        $t = 'Step {0}/{1}: the clock is {2}. The brain chose order #{3} ({4} min, deadline {5}) -> done at {6}: {7} ({8:+0.00;-0.00}). Score now {9:F2}.' -f $k, $n, $s.ClockBefore, $s.ChosenId, $ch.Proc, $ch.Deadline, $s.ClockAfter, $res, $s.Reward, $s.Total
    } elseif ($s.Outcome -eq 'idle') {
        $t = 'Step {0}/{1}: the clock is {2}. The queue is empty, so the machine waits one minute (not the brain''s fault). Score now {3:F2}.' -f $k, $n, $s.ClockBefore, $s.Total
    } else {
        $t = 'Step {0}/{1}: the clock is {2}. The brain pointed at an empty slot: a wasted choice ({3:+0.00;-0.00}). Score now {4:F2}.' -f $k, $n, $s.ClockBefore, $s.Reward, $s.Total
    }
    if ($k -ge $n) { $t += ' The shift is over.' }
    return $t
}
function Invoke-VBAFDrawShift {
    param($g, [int]$w, [int]$h, $Trace, [int]$Step, [string]$Brain)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $g.Clear([System.Drawing.Color]::White)
    $font = [System.Drawing.Font]::new('Segoe UI', [single]9.5); $fontB = [System.Drawing.Font]::new('Segoe UI', [single]10, [System.Drawing.FontStyle]::Bold)
    $fontS = [System.Drawing.Font]::new('Segoe UI', [single]8); $fontM = [System.Drawing.Font]::new('Segoe UI', [single]12); $fontBig = [System.Drawing.Font]::new('Segoe UI', [single]16, [System.Drawing.FontStyle]::Bold)
    $txt = [System.Drawing.Brushes]::Black; $dim = [System.Drawing.Brushes]::DimGray
    $green = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::ForestGreen); $red = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::Firebrick)
    $idleB = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(205, 205, 205)); $orange = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(235, 125, 0))
    $track = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(242, 242, 242)); $procB = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::SteelBlue)
    $blueB = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::RoyalBlue)
    $sep = [System.Drawing.Pen]::new([System.Drawing.Color]::White, [single]1); $marker = [System.Drawing.Pen]::new([System.Drawing.Color]::Black, [single]2)
    $cardP = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(160, 160, 160), [single]1); $chosenP = [System.Drawing.Pen]::new([System.Drawing.Color]::RoyalBlue, [single]3)
    $emptyP = [System.Drawing.Pen]::new([System.Drawing.Color]::Silver, [single]1); $emptyP.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
    $ok = $true
    try {
        $st = @($Trace.Steps); $n = $st.Count
        $k = [Math]::Max(0, [Math]::Min($Step, $n))
        $L = 40; $R = $w - 40
        $g.DrawString(('{0}  --  test shift {1}' -f $Brain, $Trace.Seed), $fontB, $txt, [single]$L, [single]10)
        $maxClock = [Math]::Max(200, [int]$st[$n - 1].ClockAfter)
        $tY = 62; $tH = 34
        $g.DrawString('The machine, minute by minute: green = order on time, red = order late, light grey = waiting for orders (empty queue), orange = wasted choice', $fontS, $dim, [single]$L, [single]($tY - 18))
        $g.FillRectangle($track, [single]$L, [single]$tY, [single]($R - $L), [single]$tH)
        for ($i = 0; $i -lt $k; $i++) {
            $s = $st[$i]
            $x1 = $L + $s.ClockBefore / $maxClock * ($R - $L); $x2 = $L + $s.ClockAfter / $maxClock * ($R - $L)
            $br = $orange
            if ($s.Outcome -eq 'ontime') { $br = $green } elseif ($s.Outcome -eq 'late') { $br = $red } elseif ($s.Outcome -eq 'idle') { $br = $idleB }
            $g.FillRectangle($br, [single]$x1, [single]$tY, [single][Math]::Max(1.0, $x2 - $x1), [single]$tH)
            if ($s.Outcome -ne 'idle') { $g.DrawLine($sep, [single]$x2, [single]$tY, [single]$x2, [single]($tY + $tH)) }
        }
        for ($t = 0; $t -le $maxClock; $t += 25) { $x = $L + $t / $maxClock * ($R - $L); $g.DrawString([string]$t, $fontS, $dim, [single]($x - 8), [single]($tY + $tH + 2)) }
        $clock = 0; if ($k -gt 0) { $clock = [int]$st[$k - 1].ClockAfter }
        $xm = $L + $clock / $maxClock * ($R - $L)
        $g.DrawLine($marker, [single]$xm, [single]($tY - 6), [single]$xm, [single]($tY + $tH + 6))
        $cY = 160; $cH = 118
        $g.DrawString('What the brain can see: the first 3 orders in the queue', $fontB, $txt, [single]$L, [single]($cY - 24))
        if ($k -eq 0) {
            $g.DrawString('Press Play or Step.', $font, $dim, [single]$L, [single]($cY + 10))
        } elseif ($st[$k - 1].Outcome -eq 'idle') {
            $g.DrawString('The queue is empty: the machine waits for new orders. Not the brain''s fault.', $fontM, $dim, [single]$L, [single]($cY + 40))
        } else {
            $s = $st[$k - 1]; $vis = @($s.Visible)
            $cw = (($R - $L) - 40) / 3.0
            for ($slot = 0; $slot -lt 3; $slot++) {
                $x = $L + $slot * ($cw + 20)
                if ($slot -lt $vis.Count) {
                    $o = $vis[$slot]; $isChosen = ($o.Id -eq $s.ChosenId)
                    if ($isChosen) { $g.DrawRectangle($chosenP, [single]$x, [single]$cY, [single]$cw, [single]$cH) } else { $g.DrawRectangle($cardP, [single]$x, [single]$cY, [single]$cw, [single]$cH) }
                    $g.DrawString(('Slot {0}:  order #{1}' -f $slot, $o.Id), $fontB, $txt, [single]($x + 10), [single]($cY + 8))
                    if ($isChosen) { $g.DrawString('CHOSEN', $fontB, $blueB, [single]($x + $cw - 72), [single]($cY + 8)) }
                    $g.DrawString(('Processing time: {0} min' -f $o.Proc), $font, $txt, [single]($x + 10), [single]($cY + 36))
                    $g.FillRectangle($procB, [single]($x + 180), [single]($cY + 41), [single]($o.Proc * 16), [single]10)
                    $g.DrawString(('Deadline: at {0}' -f $o.Deadline), $font, $txt, [single]($x + 10), [single]($cY + 60))
                    $slBrush = $txt; if ($o.Slack -lt 0) { $slBrush = $red }
                    $g.DrawString(('Slack: {0} min' -f $o.Slack), $font, $slBrush, [single]($x + 10), [single]($cY + 84))
                } else {
                    $g.DrawRectangle($emptyP, [single]$x, [single]$cY, [single]$cw, [single]$cH)
                    $g.DrawString('empty slot', $font, $dim, [single]($x + 10), [single]($cY + 8))
                }
            }
            $more = [int]$s.QueueLen - $vis.Count
            if ($more -gt 0) { $g.DrawString(('+ {0} more orders wait in the queue, but the brain cannot see them.' -f $more), $font, $dim, [single]$L, [single]($cY + $cH + 8)) }
        }
        $sY = $cY + $cH + 44
        $total = 0.0; if ($k -gt 0) { $total = [double]$st[$k - 1].Total }
        $c = Get-VBAFShiftCounts $Trace $k; $cA = Get-VBAFShiftCounts $Trace $n
        $g.DrawString(('Score: {0:F2}' -f $total), $fontBig, $txt, [single]$L, [single]$sY)
        $g.DrawString(('On time: {0}    Late: {1}    Step {2} of {3}    Real choices: {4} of {5}    With a real choice (2-3 orders): {7}    Idle: {6}' -f $c.OnTime, $c.Late, $k, $n, $c.Real, $cA.Real, $c.Idle, $c.Choice), $font, $txt, [single]$L, [single]($sY + 36))
        if ($k -gt 0) {
            $rect = [System.Drawing.RectangleF]::new([single]$L, [single]($sY + 62), [single]($R - $L), [single]60)
            $g.DrawString((Get-VBAFShiftStepText $Trace $k), $font, $dim, $rect)
        }
    } catch {
        $ok = $false
        $g.DrawString(('Draw error: ' + $_.Exception.Message), $font, [System.Drawing.Brushes]::Red, [single]10, [single]10)
    } finally {
        foreach ($o in @($font, $fontB, $fontS, $fontM, $fontBig, $green, $red, $idleB, $orange, $track, $procB, $blueB, $sep, $marker, $cardP, $chosenP, $emptyP)) { $o.Dispose() }
    }
    return $ok
}
function Get-VBAFShiftTraceCached([string]$Brain, [int]$Seed) {
    $key = $Brain + '|' + $Seed
    if (-not $global:VBAFShiftCache.ContainsKey($key)) { $global:VBAFShiftCache[$key] = Get-VBAFShiftTraceFor $global:VBAFShiftWorld $global:VBAFShiftBrains[$Brain] $Seed }
    return $global:VBAFShiftCache[$key]
}
function Update-VBAFShiftView { $S = $global:VBAFShift; $S.Status.Text = Get-VBAFShiftStepText $S.Trace $S.Step; $S.Pb.Invalidate() }
function Select-VBAFShiftRun {
    $S = $global:VBAFShift
    $S.Timer.Stop()
    $S.Brain = [string]$S.BrainBox.SelectedItem; $S.Seed = [int]$S.SeedBox.SelectedItem
    $S.Trace = Get-VBAFShiftTraceCached $S.Brain $S.Seed; $S.Step = 0
    Update-VBAFShiftView
}
function Initialize-VBAFShiftTab($Page, [string]$ResultDir) {
    $global:VBAFShiftWorld  = [ProductionCellEnvironment]::new(1)
    $global:VBAFShiftCache  = @{}
    $global:VBAFShiftBrains = Get-VBAFShiftBrains $ResultDir
    $names = @($global:VBAFShiftBrains.Keys)
    $global:VBAFShift = @{ Step = 0; Brain = $names[$names.Count - 1]; Seed = 1001; BaseInterval = 400 }
    $S = $global:VBAFShift
    $S.Trace = Get-VBAFShiftTraceCached $S.Brain $S.Seed
    $pb = New-Object System.Windows.Forms.PictureBox; $pb.Dock = 'Fill'; $pb.BackColor = [System.Drawing.Color]::White
    $pb.Add_Paint({ param($sender, $e) $S2 = $global:VBAFShift; [void](Invoke-VBAFDrawShift $e.Graphics $sender.ClientSize.Width $sender.ClientSize.Height $S2.Trace $S2.Step $S2.Brain) })
    $pb.Add_Resize({ param($sender, $e) $sender.Invalidate() })
    $S.Pb = $pb
    $status = New-Object System.Windows.Forms.Label
    $status.Dock = 'Top'; $status.Height = 40; $status.Padding = New-Object System.Windows.Forms.Padding(8, 4, 8, 2)
    $status.Font = New-Object System.Drawing.Font('Segoe UI', 9.5, [System.Drawing.FontStyle]::Bold)
    $S.Status = $status
    $bar = New-Object System.Windows.Forms.FlowLayoutPanel; $bar.Dock = 'Top'; $bar.Height = 36; $bar.Padding = New-Object System.Windows.Forms.Padding(6, 4, 6, 0)
    $l1 = New-Object System.Windows.Forms.Label; $l1.Text = 'Brain:'; $l1.AutoSize = $true; $l1.Padding = New-Object System.Windows.Forms.Padding(0, 6, 0, 0)
    $bb = New-Object System.Windows.Forms.ComboBox; $bb.DropDownStyle = 'DropDownList'; $bb.Width = 260
    foreach ($nm in $names) { [void]$bb.Items.Add($nm) }
    $bb.SelectedIndex = $names.Count - 1
    $l2 = New-Object System.Windows.Forms.Label; $l2.Text = 'Shift:'; $l2.AutoSize = $true; $l2.Padding = New-Object System.Windows.Forms.Padding(8, 6, 0, 0)
    $sb = New-Object System.Windows.Forms.ComboBox; $sb.DropDownStyle = 'DropDownList'; $sb.Width = 70
    foreach ($sd in @(Get-VBAFProductionTestSeeds)) { [void]$sb.Items.Add($sd) }
    $sb.SelectedIndex = 0
    $S.BrainBox = $bb; $S.SeedBox = $sb
    $timer = New-Object System.Windows.Forms.Timer; $timer.Interval = $S.BaseInterval
    $timer.Add_Tick({
        $S2 = $global:VBAFShift; $n2 = @($S2.Trace.Steps).Count
        if ($S2.Step -lt $n2) { $S2.Step++; Update-VBAFShiftView }
        if ($S2.Step -ge $n2) { $S2.Timer.Stop() } else { $S2.Timer.Interval = Get-VBAFShiftInterval $S2.Trace ($S2.Step + 1) $S2.BaseInterval }
    })
    $S.Timer = $timer
    $bar.Controls.Add($l1); $bar.Controls.Add($bb); $bar.Controls.Add($l2); $bar.Controls.Add($sb)
    $buttons = @(
        @('Play',     { $S2 = $global:VBAFShift; if ($S2.Step -ge @($S2.Trace.Steps).Count) { $S2.Step = 0; Update-VBAFShiftView }; $S2.Timer.Interval = Get-VBAFShiftInterval $S2.Trace ($S2.Step + 1) $S2.BaseInterval; $S2.Timer.Start() }),
        @('Pause',    { $global:VBAFShift.Timer.Stop() }),
        @('Step',     { $S2 = $global:VBAFShift; $S2.Timer.Stop(); if ($S2.Step -lt @($S2.Trace.Steps).Count) { $S2.Step++ }; Update-VBAFShiftView }),
        @('Restart',  { $S2 = $global:VBAFShift; $S2.Timer.Stop(); $S2.Step = 0; Update-VBAFShiftView }),
        @('Show end', { $S2 = $global:VBAFShift; $S2.Timer.Stop(); $S2.Step = @($S2.Trace.Steps).Count; Update-VBAFShiftView }))
    foreach ($b in $buttons) { $btn = New-Object System.Windows.Forms.Button; $btn.Text = $b[0]; $btn.Width = 78; $btn.Height = 26; $btn.Add_Click($b[1]); $bar.Controls.Add($btn) }
    $l3 = New-Object System.Windows.Forms.Label; $l3.Text = 'Speed:'; $l3.AutoSize = $true; $l3.Padding = New-Object System.Windows.Forms.Padding(8, 6, 0, 0)
    $sp = New-Object System.Windows.Forms.ComboBox; $sp.DropDownStyle = 'DropDownList'; $sp.Width = 80
    foreach ($nm in @('Slow', 'Normal', 'Fast')) { [void]$sp.Items.Add($nm) }
    $sp.SelectedIndex = 1
    $sp.Add_SelectedIndexChanged({ param($sender, $e) $global:VBAFShift.BaseInterval = @(1200, 400, 100)[$sender.SelectedIndex] })
    $bar.Controls.Add($l3); $bar.Controls.Add($sp)
    $bb.Add_SelectedIndexChanged({ Select-VBAFShiftRun })
    $sb.Add_SelectedIndexChanged({ Select-VBAFShiftRun })
    $info = New-Object System.Windows.Forms.Label
    $info.Dock = 'Top'; $info.Height = 58; $info.Padding = New-Object System.Windows.Forms.Padding(8, 6, 8, 4)
    $info.Font = New-Object System.Drawing.Font('Segoe UI', 9.5)
    $info.Text = ('One brain works a test shift it has never trained on. At every choice it can see only the first 3 orders in the queue and picks one. ' +
        'The clock jumps by the order''s processing time: done before the deadline gives +1, late gives minus points. If the queue is empty, the machine waits a minute (light grey). Choose a brain and a shift, and press Play.')
    $Page.Controls.Add($pb); $Page.Controls.Add($status); $Page.Controls.Add($bar); $Page.Controls.Add($info)
    $status.Text = Get-VBAFShiftStepText $S.Trace $S.Step
}
function Get-VBAFShiftRenderStats($Trace, [int]$Step, [string]$Brain) {
    $bmp = [System.Drawing.Bitmap]::new(1200, 560)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $ok = Invoke-VBAFDrawShift $g 1200 560 $Trace $Step $Brain
    $g.Dispose()
    $nw = 0; $gr = 0; $rd = 0; $id = 0
    for ($y = 0; $y -lt $bmp.Height; $y += 3) { for ($x = 0; $x -lt $bmp.Width; $x += 3) {
        $c = $bmp.GetPixel($x, $y)
        if ($c.R -lt 245 -or $c.G -lt 245 -or $c.B -lt 245) { $nw++ }
        if ($c.G -gt 110 -and $c.R -lt 80 -and $c.B -lt 80) { $gr++ }
        if ($c.R -gt 150 -and $c.G -lt 70 -and $c.B -lt 70) { $rd++ }
        if ($c.R -eq 205 -and $c.G -eq 205 -and $c.B -eq 205) { $id++ } } }
    $bmp.Dispose()
    return @{ Ok = $ok; NonWhite = $nw; Green = $gr; Red = $rd; Idle = $id }
}
# Self-test for ANY study folder: returns check objects (Check, Pass, Detail). Renders to bitmaps, no window shown.
function Test-VBAFShiftView {
    param([Parameter(Mandatory = $true)][string]$ResultDir)
    $checks = @()
    $world = [ProductionCellEnvironment]::new(1)
    $brains = Get-VBAFShiftBrains $ResultDir
    $names = @($brains.Keys)
    $bad = @()
    foreach ($nm in $names) {
        $tr = Get-VBAFShiftTraceFor $world $brains[$nm] 1001
        $sum = [Math]::Round([double]((@($tr.Steps) | Measure-Object -Property Reward -Sum).Sum), 2)
        $c = Get-VBAFShiftCounts $tr @($tr.Steps).Count
        if ($sum -ne [Math]::Round([double]$tr.Stats.TotalReward, 2) -or $c.OnTime -ne [int]$tr.Stats.OnTime -or $c.Late -ne [int]$tr.Stats.Late -or $c.Invalid -ne [int]$tr.Stats.Invalid) { $bad += $nm }
    }
    $checks += [pscustomobject]@{ Check = 'every brain: step rewards add up and outcomes = shift stats (shift 1001)'; Pass = ($bad.Count -eq 0); Detail = ('{0} brains; inconsistent: [{1}]' -f $names.Count, ($bad -join ', ')) }
    $tl = Get-VBAFShiftTraceFor $world $brains[$names[$names.Count - 1]] 1001
    $ts = Get-VBAFShiftTraceFor $world $brains[$names[0]] 1001
    $nL = @($tl.Steps).Count
    $r1 = Get-VBAFShiftRenderStats $tl 1 $names[$names.Count - 1]
    $rN = Get-VBAFShiftRenderStats $tl $nL $names[$names.Count - 1]
    $rS = Get-VBAFShiftRenderStats $ts @($ts.Steps).Count $names[0]
    $checks += [pscustomobject]@{ Check = 'drawing works; the timeline grows (more green at the end)'; Pass = ($r1.Ok -and $rN.Ok -and $rS.Ok -and ($rN.Green -gt $r1.Green)); Detail = ('{0} -> {1}' -f $r1.Green, $rN.Green) }
    $checks += [pscustomobject]@{ Check = 'waiting minutes are drawn light grey'; Pass = ($rN.Idle -gt 0); Detail = ('sampled ' + $rN.Idle) }
    $checks += [pscustomobject]@{ Check = 'sensitivity: two brains draw the same shift differently'; Pass = (($names.Count -lt 2) -or ($rN.Green -ne $rS.Green) -or ($rN.Red -ne $rS.Red)); Detail = ('G/R {0}/{1} vs {2}/{3}' -f $rN.Green, $rN.Red, $rS.Green, $rS.Red) }
    $idle = @($tl.Steps | Where-Object { $_.Outcome -eq 'idle' })[0]
    $real = @($tl.Steps | Where-Object { $_.Outcome -eq 'ontime' -or $_.Outcome -eq 'late' })[0]
    $ti = ''; if ($null -ne $idle) { $ti = Get-VBAFShiftStepText $tl ([int]$idle.Step) }
    $checks += [pscustomobject]@{ Check = 'an idle step says the queue is empty, not chosen'; Pass = (($null -eq $idle) -or ($ti.Contains('queue is empty') -and -not $ti.Contains('chose'))); Detail = $ti }
    $iv1 = 400; if ($null -ne $idle) { $iv1 = Get-VBAFShiftInterval $tl ([int]$idle.Step) 400 }
    $iv2 = Get-VBAFShiftInterval $tl ([int]$real.Step) 400
    $checks += [pscustomobject]@{ Check = 'playback: idle steps 4x faster (100 ms vs 400 ms)'; Pass = (($null -eq $idle -or $iv1 -eq 100) -and ($iv2 -eq 400)); Detail = ('{0} / {1}' -f $iv1, $iv2) }
    $page = New-Object System.Windows.Forms.TabPage
    Initialize-VBAFShiftTab $page $ResultDir
    $checks += [pscustomobject]@{ Check = 'the shift tab builds (picture, status, buttons, text)'; Pass = ($page.Controls.Count -eq 4); Detail = ('controls ' + $page.Controls.Count) }
    $global:VBAFShift.Timer.Dispose(); $page.Dispose()
    return $checks
}
