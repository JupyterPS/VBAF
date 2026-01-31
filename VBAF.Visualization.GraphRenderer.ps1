#Requires -Version 5.1

<#
.SYNOPSIS
    Graph rendering utilities for learning visualization
.DESCRIPTION
    Provides methods to draw learning curves, heatmaps, and other
    visualizations using System.Drawing.
.NOTES
    Part of VBAF (Visual Business Automation Framework)
    FIXED: Array subtraction errors + Assembly loading order
#>

class GraphRenderer {
    
    # Draw line graph - FIXED: Accept ArrayList directly instead of array
    static [void] DrawLineGraph([System.Drawing.Graphics]$g, 
                                [System.Drawing.Rectangle]$bounds,
                                [System.Collections.ArrayList]$dataList,
                                [string]$title,
                                [System.Drawing.Color]$lineColor) {
        
        # Convert to array INSIDE this method to avoid scoping issues
        $data = @()
        foreach ($item in $dataList) {
            $data += [double]$item
        }
        
        if ($data.Count -eq 0) {
            # No data yet - show placeholder
            $font = New-Object Drawing.Font("Segoe UI", 10)
            $brush = New-Object Drawing.SolidBrush([Drawing.Color]::Gray)
            $text = "$title (No data yet)"
            $g.DrawString($text, $font, $brush, $bounds.X + 10, $bounds.Y + 10)
            $font.Dispose()
            $brush.Dispose()
            return
        }
        
        # Background
        $bgBrush = New-Object Drawing.SolidBrush([Drawing.Color]::FromArgb(30, 30, 40))
        $g.FillRectangle($bgBrush, $bounds)
        $bgBrush.Dispose()
        
        # Border
        $borderPen = New-Object Drawing.Pen([Drawing.Color]::FromArgb(60, 60, 80), 1)
        $g.DrawRectangle($borderPen, $bounds)
        $borderPen.Dispose()
        
        # Title
        $font = New-Object Drawing.Font("Segoe UI", 10, [Drawing.FontStyle]::Bold)
        $titleBrush = New-Object Drawing.SolidBrush([Drawing.Color]::White)
        $g.DrawString($title, $font, $titleBrush, $bounds.X + 10, $bounds.Y + 5)
        $font.Dispose()
        $titleBrush.Dispose()
        
        # Calculate scale
        $padding = 40
        $graphX = $bounds.X + $padding
        $graphY = $bounds.Y + 30
        $graphWidth = $bounds.Width - ($padding * 2)
        $graphHeight = $bounds.Height - 50
        
        # Find min/max using Measure-Object which is more reliable
        $stats = $data | Measure-Object -Minimum -Maximum
        $minVal = [double]$stats.Minimum
        $maxVal = [double]$stats.Maximum
        
        # Add padding to range
        $range = $maxVal - $minVal
        if ($range -eq 0) { $range = 1.0 }
        
        $padding10Percent = $range * 0.1
        $minVal = $minVal - $padding10Percent
        $maxVal = $maxVal + $padding10Percent
        $range = $maxVal - $minVal
        
        # Draw grid lines
        $gridPen = New-Object Drawing.Pen([Drawing.Color]::FromArgb(50, 50, 60), 1)
        $gridPen.DashStyle = [Drawing.Drawing2D.DashStyle]::Dot
        
        for ($i = 0; $i -le 4; $i++) {
            $yPos = $graphY + ($graphHeight * $i / 4)
            $g.DrawLine($gridPen, $graphX, $yPos, $graphX + $graphWidth, $yPos)
        }
        
        $gridPen.Dispose()
        
        # Draw axis labels
        $labelFont = New-Object Drawing.Font("Consolas", 8)
        $labelBrush = New-Object Drawing.SolidBrush([Drawing.Color]::LightGray)
        
        for ($i = 0; $i -le 4; $i++) {
            $fraction = $i / 4.0
            $value = $maxVal - ($range * $fraction)
            $yPos = $graphY + ($graphHeight * $i / 4)
            $g.DrawString($value.ToString("F2"), $labelFont, $labelBrush, $bounds.X + 5, $yPos - 7)
        }
        
        $labelFont.Dispose()
        $labelBrush.Dispose()
        
        # Draw line
        if ($data.Count -gt 1) {
            $points = New-Object System.Collections.ArrayList
            
            for ($i = 0; $i -lt $data.Count; $i++) {
                $xPos = $graphX + ($i * $graphWidth / ($data.Count - 1))
                
                # Safe normalization
                $dataValue = [double]$data[$i]
                $normalized = 0.5  # default
                
                if ($range -ne 0) {
                    $normalized = ($dataValue - $minVal) / $range
                }
                
                $yPos = $graphY + $graphHeight - ($normalized * $graphHeight)
                
                $point = New-Object Drawing.PointF($xPos, $yPos)
                [void]$points.Add($point)
            }
            
            if ($points.Count -gt 1) {
                $linePen = New-Object Drawing.Pen($lineColor, 2)
                $g.DrawLines($linePen, $points.ToArray([Drawing.PointF]))
                $linePen.Dispose()
            }
        }
        
        # Draw current value
        if ($data.Count -gt 0) {
            $currentVal = [double]$data[$data.Count - 1]
            $valueFont = New-Object Drawing.Font("Consolas", 9, [Drawing.FontStyle]::Bold)
            $valueBrush = New-Object Drawing.SolidBrush($lineColor)
            $valueText = "Current: $($currentVal.ToString('F4'))"
            $g.DrawString($valueText, $valueFont, $valueBrush, $bounds.X + $bounds.Width - 150, $bounds.Y + 5)
            $valueFont.Dispose()
            $valueBrush.Dispose()
        }
    }
    
    # Draw heatmap (for Q-values)
    static [void] DrawHeatmap([System.Drawing.Graphics]$g,
                             [System.Drawing.Rectangle]$bounds,
                             [hashtable]$data,
                             [string]$title) {
        
        # Background
        $bgBrush = New-Object Drawing.SolidBrush([Drawing.Color]::FromArgb(30, 30, 40))
        $g.FillRectangle($bgBrush, $bounds)
        $bgBrush.Dispose()
        
        # Border
        $borderPen = New-Object Drawing.Pen([Drawing.Color]::FromArgb(60, 60, 80), 1)
        $g.DrawRectangle($borderPen, $bounds)
        $borderPen.Dispose()
        
        # Title
        $font = New-Object Drawing.Font("Segoe UI", 10, [Drawing.FontStyle]::Bold)
        $titleBrush = New-Object Drawing.SolidBrush([Drawing.Color]::White)
        $g.DrawString($title, $font, $titleBrush, $bounds.X + 10, $bounds.Y + 5)
        $font.Dispose()
        $titleBrush.Dispose()
        
        if ($data.Count -eq 0) {
            $font2 = New-Object Drawing.Font("Segoe UI", 9)
            $brush2 = New-Object Drawing.SolidBrush([Drawing.Color]::Gray)
            $g.DrawString("No Q-values yet", $font2, $brush2, $bounds.X + 10, $bounds.Y + 30)
            $font2.Dispose()
            $brush2.Dispose()
            return
        }
        
        # Sort data by value and get min/max using Measure-Object
        $sorted = $data.GetEnumerator() | Sort-Object Value -Descending
        $values = @($sorted | ForEach-Object { [double]$_.Value })
        $stats = $values | Measure-Object -Minimum -Maximum
        
        $minVal = [double]$stats.Minimum
        $maxVal = [double]$stats.Maximum
        $range = $maxVal - $minVal
        if ($range -eq 0) { $range = 1.0 }
        
        # Draw bars
        $barHeight = 25
        $startY = $bounds.Y + 30
        $barWidth = $bounds.Width - 200
        $labelFont = New-Object Drawing.Font("Consolas", 9)
        
        $index = 0
        foreach ($item in $sorted) {
            $yPos = $startY + ($index * $barHeight)
            
            if ($yPos + $barHeight -gt $bounds.Y + $bounds.Height) {
                break
            }
            
            # Color based on value
            $itemValue = [double]$item.Value
            $normalized = ($itemValue - $minVal) / $range
            
            $red = [int](255 * (1.0 - $normalized))
            $green = [int](255 * $normalized)
            $barColor = [Drawing.Color]::FromArgb(150, $red, $green, 0)
            
            # Draw bar
            $barActualWidth = [int]($barWidth * $normalized)
            $barBrush = New-Object Drawing.SolidBrush($barColor)
            $g.FillRectangle($barBrush, $bounds.X + 120, $yPos, $barActualWidth, $barHeight - 2)
            $barBrush.Dispose()
            
            # Label
            $labelBrush = New-Object Drawing.SolidBrush([Drawing.Color]::White)
            $g.DrawString($item.Key, $labelFont, $labelBrush, $bounds.X + 10, $yPos + 5)
            
            # Value
            $valueText = $itemValue.ToString("F4")
            $g.DrawString($valueText, $labelFont, $labelBrush, $bounds.X + $bounds.Width - 80, $yPos + 5)
            
            $labelBrush.Dispose()
            
            $index++
        }
        
        $labelFont.Dispose()
    }
    
    # Draw progress bar
    static [void] DrawProgressBar([System.Drawing.Graphics]$g,
                                  [System.Drawing.Rectangle]$bounds,
                                  [double]$value,
                                  [double]$max,
                                  [string]$label,
                                  [System.Drawing.Color]$color) {
        
        # Background
        $bgBrush = New-Object Drawing.SolidBrush([Drawing.Color]::FromArgb(50, 50, 60))
        $g.FillRectangle($bgBrush, $bounds)
        $bgBrush.Dispose()
        
        # Progress
        $progress = if ($max -gt 0) { $value / $max } else { 0 }
        $progressWidth = [int]($bounds.Width * $progress)
        
        $progressBrush = New-Object Drawing.SolidBrush($color)
        $g.FillRectangle($progressBrush, $bounds.X, $bounds.Y, $progressWidth, $bounds.Height)
        $progressBrush.Dispose()
        
        # Label
        $font = New-Object Drawing.Font("Consolas", 10, [Drawing.FontStyle]::Bold)
        $textBrush = New-Object Drawing.SolidBrush([Drawing.Color]::White)
        $text = "$label : $($value.ToString('F2')) / $($max.ToString('F2'))"
        $textSize = $g.MeasureString($text, $font)
        $textX = $bounds.X + ($bounds.Width - $textSize.Width) / 2
        $textY = $bounds.Y + ($bounds.Height - $textSize.Height) / 2
        $g.DrawString($text, $font, $textBrush, $textX, $textY)
        $font.Dispose()
        $textBrush.Dispose()
    }
}

