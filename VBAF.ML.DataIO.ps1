#Requires -Version 5.1
<#
.SYNOPSIS
    Data I/O - Import and Export Data in Multiple Formats
.DESCRIPTION
    Implements data import/export from scratch.
    Designed as a TEACHING resource - every step explained.
    Features included:
      - CSV import/export     : most common data format
      - JSON import/export    : web APIs, config files
      - Excel import/export   : business data via COM object
      - SQL connectivity      : query databases directly
      - API data fetching     : REST APIs with Invoke-RestMethod
      - Streaming data        : process large files in chunks
      - Data validation       : type checking, range, nulls on import
    Standalone - no external VBAF dependencies required.
.NOTES
    Part of VBAF - Phase 5 Data I/O Module
    PS 5.1 compatible
    Teaching project - real-world data wrangling explained!
    Excel requires Microsoft Excel to be installed.
    SQL requires accessible SQL Server or SQLite via ODBC.
#>
$basePath = $PSScriptRoot

# ============================================================
# TEACHING NOTE: Why does data format matter?
# Data lives in many places:
#   CSV    : spreadsheets, exports, Kaggle datasets
#   JSON   : web APIs, NoSQL databases, config files
#   Excel  : business reports, finance, HR data
#   SQL    : production databases, data warehouses
#   APIs   : live data, weather, stock prices, etc.
# Knowing how to READ from all these sources is the first
# step of any real ML project!
# ============================================================

# ============================================================
# DATA VALIDATION SCHEMA
# ============================================================
# TEACHING NOTE: Always validate data on import!
# Real data has:
#   - Wrong types  : "abc" where a number is expected
#   - Out of range : age=-5, price=-1000
#   - Missing required fields : null where value is mandatory
# Catch these EARLY before they corrupt your model!
# ============================================================

class DataValidator {
    [hashtable] $Schema      # field -> @{Type, Required, Min, Max}
    [System.Collections.ArrayList] $Errors
    [System.Collections.ArrayList] $Warnings

    DataValidator() {
        $this.Schema   = @{}
        $this.Errors   = [System.Collections.ArrayList]::new()
        $this.Warnings = [System.Collections.ArrayList]::new()
    }

    # Add a field rule
    # Type: "numeric", "string", "bool"
    [void] AddRule([string]$field, [string]$type, [bool]$required) {
        $this.Schema[$field] = @{ Type=$type; Required=$required; Min=$null; Max=$null }
    }

    [void] AddRule([string]$field, [string]$type, [bool]$required, [double]$min, [double]$max) {
        $this.Schema[$field] = @{ Type=$type; Required=$required; Min=$min; Max=$max }
    }

    # Validate a single row (hashtable)
    [bool] ValidateRow([hashtable]$row, [int]$rowNum) {
        $valid = $true
        foreach ($field in $this.Schema.Keys) {
            $rule = $this.Schema[$field]
            $val  = $row[$field]

            # Required check
            if ($rule.Required -and ($null -eq $val -or "$val" -eq "")) {
                $this.Errors.Add("Row $rowNum : '$field' is required but missing") | Out-Null
                $valid = $false
                continue
            }
            if ($null -eq $val -or "$val" -eq "") { continue }  # optional, skip

            # Type check
            if ($rule.Type -eq "numeric") {
                $d = 0.0
                if (-not [double]::TryParse("$val", [ref]$d)) {
                    $this.Errors.Add("Row $rowNum : '$field' = '$val' is not numeric") | Out-Null
                    $valid = $false
                    continue
                }
                # Range check
                if ($null -ne $rule.Min -and $d -lt $rule.Min) {
                    $this.Warnings.Add("Row $rowNum : '$field' = $d is below min ($($rule.Min))") | Out-Null
                }
                if ($null -ne $rule.Max -and $d -gt $rule.Max) {
                    $this.Warnings.Add("Row $rowNum : '$field' = $d is above max ($($rule.Max))") | Out-Null
                }
            }
        }
        return $valid
    }

    # Validate all rows
    [hashtable] Validate([hashtable[]]$rows) {
        $this.Errors.Clear()
        $this.Warnings.Clear()
        $validRows   = @()
        $invalidRows = @()

        for ($i = 0; $i -lt $rows.Length; $i++) {
            if ($this.ValidateRow($rows[$i], $i + 1)) {
                $validRows   += $rows[$i]
            } else {
                $invalidRows += $rows[$i]
            }
        }

        $this.PrintReport()
        return @{ Valid=$validRows; Invalid=$invalidRows }
    }

    [void] PrintReport() {
        Write-Host ""
        Write-Host "🔍 Validation Report" -ForegroundColor Green
        Write-Host ("   Errors   : {0}" -f $this.Errors.Count)   -ForegroundColor $(if ($this.Errors.Count -gt 0) {"Red"} else {"White"})
        Write-Host ("   Warnings : {0}" -f $this.Warnings.Count) -ForegroundColor $(if ($this.Warnings.Count -gt 0) {"Yellow"} else {"White"})
        if ($this.Errors.Count -gt 0) {
            Write-Host "   ❌ Errors:" -ForegroundColor Red
            foreach ($e in $this.Errors) { Write-Host "      $e" -ForegroundColor Red }
        }
        if ($this.Warnings.Count -gt 0) {
            Write-Host "   ⚠️  Warnings:" -ForegroundColor Yellow
            foreach ($w in $this.Warnings) { Write-Host "      $w" -ForegroundColor Yellow }
        }
        if ($this.Errors.Count -eq 0 -and $this.Warnings.Count -eq 0) {
            Write-Host "   ✅ All rows valid!" -ForegroundColor Green
        }
        Write-Host ""
    }
}

# ============================================================
# CSV IMPORT / EXPORT
# ============================================================
# TEACHING NOTE: CSV = Comma-Separated Values
# Simplest and most universal data format.
# Every spreadsheet, Kaggle dataset, database export
# can produce CSV. Always your first choice!
# ============================================================

function Import-VBAFCsv {
    param(
        [string]   $Path,
        [string]   $Delimiter  = ",",
        [bool]     $HasHeader  = $true,
        [string[]] $ColumnNames = @(),
        [object]   $Validator  = $null
    )

    if (-not (Test-Path $Path)) {
        Write-Host "❌ File not found: $Path" -ForegroundColor Red
        return $null
    }

    $lines = Get-Content -Path $Path -Encoding UTF8
    if ($lines.Length -eq 0) {
        Write-Host "⚠️  Empty file: $Path" -ForegroundColor Yellow
        return @()
    }

    # Parse header
    $headers = if ($HasHeader) {
        $lines[0] -split $Delimiter | ForEach-Object { $_.Trim().Trim('"') }
    } elseif ($ColumnNames.Length -gt 0) {
        $ColumnNames
    } else {
        $firstRow = $lines[0] -split $Delimiter
        0..($firstRow.Length-1) | ForEach-Object { "col$_" }
    }

    $dataLines = if ($HasHeader) { $lines[1..($lines.Length-1)] } else { $lines }
    $rows      = @()

    foreach ($line in $dataLines) {
        if ($line.Trim() -eq "") { continue }
        $vals = $line -split $Delimiter | ForEach-Object { $_.Trim().Trim('"') }
        $row  = @{}
        for ($i = 0; $i -lt $headers.Length; $i++) {
            $row[$headers[$i]] = if ($i -lt $vals.Length) { $vals[$i] } else { $null }
        }
        $rows += $row
    }

    Write-Host "📥 CSV imported: $Path" -ForegroundColor Green
    Write-Host ("   Rows    : {0}" -f $rows.Length)      -ForegroundColor Cyan
    Write-Host ("   Columns : {0}" -f $headers.Length)   -ForegroundColor Cyan
    Write-Host ("   Headers : {0}" -f ($headers -join ", ")) -ForegroundColor DarkGray

    # Validate if schema provided
    if ($null -ne $Validator) {
        $result = $Validator.Validate($rows)
        return $result.Valid
    }

    return $rows
}

function Export-VBAFCsv {
    param(
        [hashtable[]] $Data,
        [string]      $Path,
        [string]      $Delimiter = ","
    )

    if ($Data.Length -eq 0) {
        Write-Host "⚠️  No data to export" -ForegroundColor Yellow
        return
    }

    $headers = $Data[0].Keys | Sort-Object
    $lines   = @($headers -join $Delimiter)

    foreach ($row in $Data) {
        $vals  = $headers | ForEach-Object {
            $v = $row[$_]
            if ("$v" -match $Delimiter) { "`"$v`"" } else { "$v" }
        }
        $lines += $vals -join $Delimiter
    }

    $lines | Set-Content -Path $Path -Encoding UTF8
    Write-Host "📤 CSV exported: $Path" -ForegroundColor Green
    Write-Host ("   Rows    : {0}" -f ($lines.Length - 1)) -ForegroundColor Cyan
}

# ============================================================
# JSON IMPORT / EXPORT
# ============================================================
# TEACHING NOTE: JSON = JavaScript Object Notation
# Standard format for web APIs and config files.
# Supports nested structures - more flexible than CSV!
# PS 5.1 has built-in ConvertFrom-Json / ConvertTo-Json
# ============================================================

function Import-VBAFJson {
    param(
        [string] $Path,
        [object] $Validator = $null
    )

    if (-not (Test-Path $Path)) {
        Write-Host "❌ File not found: $Path" -ForegroundColor Red
        return $null
    }

    $content = Get-Content -Path $Path -Raw -Encoding UTF8
    $parsed  = $content | ConvertFrom-Json

    # Convert PSCustomObject array to hashtable array
    $rows = @()
    foreach ($item in $parsed) {
        $row = @{}
        $item.PSObject.Properties | ForEach-Object { $row[$_.Name] = $_.Value }
        $rows += $row
    }

    Write-Host "📥 JSON imported: $Path" -ForegroundColor Green
    Write-Host ("   Records : {0}" -f $rows.Length) -ForegroundColor Cyan

    if ($null -ne $Validator -and $rows.Length -gt 0) {
        $result = $Validator.Validate($rows)
        return $result.Valid
    }

    return $rows
}

function Export-VBAFJson {
    param(
        [hashtable[]] $Data,
        [string]      $Path,
        [int]         $Depth = 3
    )

    $Data | ConvertTo-Json -Depth $Depth | Set-Content -Path $Path -Encoding UTF8
    Write-Host "📤 JSON exported: $Path" -ForegroundColor Green
    Write-Host ("   Records : {0}" -f $Data.Length) -ForegroundColor Cyan
}

# ============================================================
# EXCEL IMPORT / EXPORT (via COM)
# ============================================================
# TEACHING NOTE: Excel uses COM automation in PS 5.1.
# COM = Component Object Model - Windows technology that
# lets PowerShell control Excel as if a human was using it!
# Requires Microsoft Excel to be installed.
# ============================================================

function Import-VBAFExcel {
    param(
        [string] $Path,
        [string] $SheetName  = "",
        [int]    $SheetIndex = 1,
        [bool]   $HasHeader  = $true,
        [object] $Validator  = $null
    )

    if (-not (Test-Path $Path)) {
        Write-Host "❌ File not found: $Path" -ForegroundColor Red
        return $null
    }

    try {
        $excel    = New-Object -ComObject Excel.Application
        $excel.Visible = $false
        $excel.DisplayAlerts = $false
        $workbook = $excel.Workbooks.Open((Resolve-Path $Path).Path)

        $sheet = if ($SheetName -ne "") {
            $workbook.Sheets.Item($SheetName)
        } else {
            $workbook.Sheets.Item($SheetIndex)
        }

        $usedRange = $sheet.UsedRange
        $nRows     = $usedRange.Rows.Count
        $nCols     = $usedRange.Columns.Count

        # Read headers
        $headers = @()
        for ($c = 1; $c -le $nCols; $c++) {
            $headers += if ($HasHeader) {
                "$($usedRange.Cells.Item(1, $c).Value2)"
            } else { "col$($c-1)" }
        }

        # Read data rows
        $startRow = if ($HasHeader) { 2 } else { 1 }
        $rows     = @()
        for ($r = $startRow; $r -le $nRows; $r++) {
            $row = @{}
            for ($c = 1; $c -le $nCols; $c++) {
                $row[$headers[$c-1]] = $usedRange.Cells.Item($r, $c).Value2
            }
            $rows += $row
        }

        $workbook.Close($false)
        $excel.Quit()
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null

        Write-Host "📥 Excel imported: $Path" -ForegroundColor Green
        Write-Host ("   Sheet   : {0}" -f $sheet.Name)    -ForegroundColor Cyan
        Write-Host ("   Rows    : {0}" -f $rows.Length)   -ForegroundColor Cyan
        Write-Host ("   Columns : {0}" -f $headers.Length) -ForegroundColor Cyan

        if ($null -ne $Validator -and $rows.Length -gt 0) {
            $result = $Validator.Validate($rows)
            return $result.Valid
        }

        return $rows

    } catch {
        Write-Host "❌ Excel error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "   Is Microsoft Excel installed?" -ForegroundColor Yellow
        return $null
    }
}

function Export-VBAFExcel {
    param(
        [hashtable[]] $Data,
        [string]      $Path,
        [string]      $SheetName = "Sheet1"
    )

    try {
        $excel   = New-Object -ComObject Excel.Application
        $excel.Visible = $false
        $excel.DisplayAlerts = $false
        $workbook = $excel.Workbooks.Add()
        $sheet    = $workbook.Sheets.Item(1)
        $sheet.Name = $SheetName

        if ($Data.Length -eq 0) {
            Write-Host "⚠️  No data to export" -ForegroundColor Yellow
            return
        }

        $headers = $Data[0].Keys | Sort-Object

        # Write headers
        for ($c = 0; $c -lt $headers.Length; $c++) {
            $sheet.Cells.Item(1, $c + 1) = $headers[$c]
            $sheet.Cells.Item(1, $c + 1).Font.Bold = $true
        }

        # Write data
        for ($r = 0; $r -lt $Data.Length; $r++) {
            for ($c = 0; $c -lt $headers.Length; $c++) {
                $sheet.Cells.Item($r + 2, $c + 1) = $Data[$r][$headers[$c]]
            }
        }

        $sheet.UsedRange.Columns.AutoFit() | Out-Null
        $workbook.SaveAs((Resolve-Path (Split-Path $Path)).Path + "\" + (Split-Path $Path -Leaf))
        $workbook.Close($false)
        $excel.Quit()
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null

        Write-Host "📤 Excel exported: $Path" -ForegroundColor Green
        Write-Host ("   Rows    : {0}" -f $Data.Length) -ForegroundColor Cyan

    } catch {
        Write-Host "❌ Excel error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "   Is Microsoft Excel installed?" -ForegroundColor Yellow
    }
}

# ============================================================
# SQL CONNECTIVITY
# ============================================================
# TEACHING NOTE: SQL = Structured Query Language
# Used to query relational databases (SQL Server, MySQL, etc.)
# PS 5.1 uses ADO.NET - the same technology C# uses!
# Connection string format varies by database type.
# ============================================================

function Invoke-VBAFSqlQuery {
    param(
        [string] $ConnectionString,
        [string] $Query,
        [int]    $Timeout = 30
    )

    # TEACHING: ADO.NET pattern:
    # 1. Open connection
    # 2. Create command
    # 3. Execute and read results
    # 4. Always close connection!

    $conn = $null
    try {
        $conn = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
        $conn.Open()
        Write-Host "🔌 SQL connected: $($conn.DataSource)" -ForegroundColor Green

        $cmd             = $conn.CreateCommand()
        $cmd.CommandText = $Query
        $cmd.CommandTimeout = $Timeout

        $adapter  = New-Object System.Data.SqlClient.SqlDataAdapter($cmd)
        $table    = New-Object System.Data.DataTable
        $adapter.Fill($table) | Out-Null

        # Convert DataTable to hashtable array
        $rows = @()
        foreach ($row in $table.Rows) {
            $ht = @{}
            foreach ($col in $table.Columns) {
                $ht[$col.ColumnName] = if ($row[$col] -is [System.DBNull]) { $null } else { $row[$col] }
            }
            $rows += $ht
        }

        Write-Host ("   Rows returned: {0}" -f $rows.Length) -ForegroundColor Cyan
        return $rows

    } catch {
        Write-Host "❌ SQL error: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    } finally {
        if ($null -ne $conn -and $conn.State -eq "Open") {
            $conn.Close()
            Write-Host "🔌 SQL connection closed" -ForegroundColor DarkGray
        }
    }
}

function Export-VBAFSqlTable {
    param(
        [string]      $ConnectionString,
        [string]      $TableName,
        [hashtable[]] $Data,
        [bool]        $CreateTable = $false
    )

    $conn = $null
    try {
        $conn = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
        $conn.Open()

        if ($Data.Length -eq 0) { Write-Host "⚠️  No data" -ForegroundColor Yellow; return }
        $headers = $Data[0].Keys | Sort-Object

        if ($CreateTable) {
            $cols    = ($headers | ForEach-Object { "[$_] NVARCHAR(255)" }) -join ", "
            $createQ = "IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='$TableName') CREATE TABLE [$TableName] ($cols)"
            $cmd     = $conn.CreateCommand()
            $cmd.CommandText = $createQ
            $cmd.ExecuteNonQuery() | Out-Null
        }

        $inserted = 0
        foreach ($row in $Data) {
            $cols   = ($headers | ForEach-Object { "[$_]" }) -join ", "
            $vals   = ($headers | ForEach-Object { "'" + "$($row[$_])".Replace("'","''") + "'" }) -join ", "
            $insQ   = "INSERT INTO [$TableName] ($cols) VALUES ($vals)"
            $cmd    = $conn.CreateCommand()
            $cmd.CommandText = $insQ
            $cmd.ExecuteNonQuery() | Out-Null
            $inserted++
        }

        Write-Host "📤 SQL exported: $TableName ($inserted rows)" -ForegroundColor Green

    } catch {
        Write-Host "❌ SQL error: $($_.Exception.Message)" -ForegroundColor Red
    } finally {
        if ($null -ne $conn -and $conn.State -eq "Open") { $conn.Close() }
    }
}

# ============================================================
# API DATA FETCHING
# ============================================================
# TEACHING NOTE: APIs = Application Programming Interfaces
# Web services that return data as JSON (usually).
# Common APIs: weather, stock prices, public datasets.
# PS 5.1 uses Invoke-RestMethod - handles JSON automatically!
#
# Rate limiting: most APIs limit how many calls per minute.
# Always add -Delay between calls in loops!
# Authentication: many APIs need an API key in headers.
# ============================================================

function Get-VBAFApiData {
    param(
        [string]    $Url,
        [hashtable] $Headers    = @{},
        [hashtable] $QueryParams = @{},
        [string]    $Method     = "GET",
        [object]    $Body       = $null,
        [int]       $Timeout    = 30,
        [int]       $RetryCount = 3,
        [object]    $Validator  = $null
    )

    # Build query string
    if ($QueryParams.Count -gt 0) {
        $qs  = ($QueryParams.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join "&"
        $Url = "$Url`?$qs"
    }

    $attempt = 0
    while ($attempt -lt $RetryCount) {
        $attempt++
        try {
            $params = @{
                Uri     = $Url
                Method  = $Method
                Headers = $Headers
                TimeoutSec = $Timeout
                UseBasicParsing = $true
            }
            if ($null -ne $Body) {
                $params.Body        = $Body | ConvertTo-Json
                $params.ContentType = "application/json"
            }

            $response = Invoke-RestMethod @params

            # Normalize to array
            $rows = @()
            if ($response -is [array]) {
                foreach ($item in $response) {
                    $row = @{}
                    $item.PSObject.Properties | ForEach-Object { $row[$_.Name] = $_.Value }
                    $rows += $row
                }
            } elseif ($response -is [System.Management.Automation.PSCustomObject]) {
                $row = @{}
                $response.PSObject.Properties | ForEach-Object { $row[$_.Name] = $_.Value }
                $rows += $row
            }

            Write-Host "🌐 API fetched: $Url" -ForegroundColor Green
            Write-Host ("   Records : {0}" -f $rows.Length) -ForegroundColor Cyan

            if ($null -ne $Validator -and $rows.Length -gt 0) {
                $result = $Validator.Validate($rows)
                return $result.Valid
            }

            return $rows

        } catch {
            Write-Host ("⚠️  API attempt {0}/{1}: {2}" -f $attempt, $RetryCount, $_.Exception.Message) -ForegroundColor Yellow
            if ($attempt -lt $RetryCount) { Start-Sleep -Seconds 2 }
        }
    }

    Write-Host "❌ API failed after $RetryCount attempts" -ForegroundColor Red
    return $null
}

# ============================================================
# STREAMING / CHUNKED FILE READING
# ============================================================
# TEACHING NOTE: What if your CSV has 10 MILLION rows?
# Loading it all into memory crashes PowerShell!
# Streaming reads and processes ONE CHUNK AT A TIME.
# Memory usage stays constant regardless of file size.
# This is how production data pipelines work!
# ============================================================

function Import-VBAFCsvStreaming {
    param(
        [string]     $Path,
        [int]        $ChunkSize  = 1000,
        [scriptblock]$ProcessChunk,       # called with each chunk
        [string]     $Delimiter  = ","
    )

    if (-not (Test-Path $Path)) {
        Write-Host "❌ File not found: $Path" -ForegroundColor Red
        return
    }

    $reader    = [System.IO.StreamReader]::new($Path, [System.Text.Encoding]::UTF8)
    $headerLine = $reader.ReadLine()
    $headers   = $headerLine -split $Delimiter | ForEach-Object { $_.Trim().Trim('"') }

    $chunk     = @()
    $totalRows = 0
    $chunkNum  = 0

    Write-Host "🌊 Streaming: $Path" -ForegroundColor Green
    Write-Host ("   Chunk size: {0} rows" -f $ChunkSize) -ForegroundColor Cyan

    while (-not $reader.EndOfStream) {
        $line = $reader.ReadLine()
        if ($line.Trim() -eq "") { continue }

        $vals = $line -split $Delimiter | ForEach-Object { $_.Trim().Trim('"') }
        $row  = @{}
        for ($i = 0; $i -lt $headers.Length; $i++) {
            $row[$headers[$i]] = if ($i -lt $vals.Length) { $vals[$i] } else { $null }
        }
        $chunk    += $row
        $totalRows++

        if ($chunk.Length -ge $ChunkSize) {
            $chunkNum++
            Write-Host ("   Processing chunk {0} ({1} rows)..." -f $chunkNum, $chunk.Length) -ForegroundColor DarkGray
            if ($null -ne $ProcessChunk) {
                & $ProcessChunk $chunk $chunkNum
            }
            $chunk = @()
        }
    }

    # Process final partial chunk
    if ($chunk.Length -gt 0) {
        $chunkNum++
        Write-Host ("   Processing chunk {0} ({1} rows)..." -f $chunkNum, $chunk.Length) -ForegroundColor DarkGray
        if ($null -ne $ProcessChunk) {
            & $ProcessChunk $chunk $chunkNum
        }
    }

    $reader.Close()
    Write-Host ("✅ Streaming complete: {0} rows in {1} chunks" -f $totalRows, $chunkNum) -ForegroundColor Green
}

# ============================================================
# CONVENIENCE: Convert rows to ML matrix format
# ============================================================
# TEACHING NOTE: ML algorithms expect double[][] matrices.
# This converts hashtable rows to the format VBAF expects.
# Specify which columns to use as features and which as target.
# ============================================================

function Convert-RowsToMatrix {
    param(
        [hashtable[]] $Rows,
        [string[]]    $FeatureColumns,
        [string]      $TargetColumn = ""
    )

    $X = @()
    $y = @()

    foreach ($row in $Rows) {
        $featureVec = @(0.0) * $FeatureColumns.Length
        for ($f = 0; $f -lt $FeatureColumns.Length; $f++) {
            $val = $row[$FeatureColumns[$f]]
            $d   = 0.0
            $featureVec[$f] = if ([double]::TryParse("$val", [ref]$d)) { $d } else { 0.0 }
        }
        $X += ,$featureVec

        if ($TargetColumn -ne "") {
            $val = $row[$TargetColumn]
            $d   = 0.0
            $y  += if ([double]::TryParse("$val", [ref]$d)) { $d } else { 0.0 }
        }
    }

    $result = @{ X=$X; FeatureNames=$FeatureColumns }
    if ($TargetColumn -ne "") { $result.y = $y }
    return $result
}

# ============================================================
# TEST
# 1. Run VBAF.LoadAll.ps1
#
# --- CSV round-trip ---
# 2. $data = Get-VBAFTreeDataset -Name "HousePrice"
#    # Convert to rows for export
#    $rows = @()
#    for ($i = 0; $i -lt $data.X.Length; $i++) {
#        $rows += @{
#            size_sqm  = $data.X[$i][0]
#            bedrooms  = $data.X[$i][1]
#            age_years = $data.X[$i][2]
#            price     = $data.yRaw[$i]
#        }
#    }
#    Export-VBAFCsv -Data $rows -Path "C:\Temp\houses.csv"
#    $imported = Import-VBAFCsv -Path "C:\Temp\houses.csv"
#    Write-Host "Rows imported: $($imported.Length)"
#
# --- CSV with validation ---
# 3. $validator = [DataValidator]::new()
#    $validator.AddRule("size_sqm", "numeric", $true,  10.0, 500.0)
#    $validator.AddRule("bedrooms", "numeric", $true,   1.0,  10.0)
#    $validator.AddRule("price",    "numeric", $true,   0.0, 2000.0)
#    $validated = Import-VBAFCsv -Path "C:\Temp\houses.csv" -Validator $validator
#
# --- JSON round-trip ---
# 4. Export-VBAFJson -Data $rows -Path "C:\Temp\houses.json"
#    $jdata = Import-VBAFJson -Path "C:\Temp\houses.json"
#    Write-Host "JSON records: $($jdata.Length)"
#
# --- Convert to ML matrix ---
# 5. $matrix = Convert-RowsToMatrix -Rows $imported -FeatureColumns @("size_sqm","bedrooms","age_years") -TargetColumn "price"
#    Write-Host "X shape: $($matrix.X.Length) x $($matrix.X[0].Length)"
#
# --- API fetch (public API, no key needed) ---
# 6. $posts = Get-VBAFApiData -Url "https://jsonplaceholder.typicode.com/posts" -QueryParams @{_limit=5}
#    Write-Host "Posts fetched: $($posts.Length)"
#    $posts[0]
#
# --- Streaming (create a large test CSV first) ---
# 7. # Create test file
#    $bigRows = 1..5000 | ForEach-Object { "row$_,value$_,$([Math]::Round((Get-Random)/1000,2))" }
#    @("id,name,value") + $bigRows | Set-Content "C:\Temp\bigfile.csv"
#    # Stream it in chunks of 1000
#    $totals = @{count=0}
#    Import-VBAFCsvStreaming -Path "C:\Temp\bigfile.csv" -ChunkSize 1000 -ProcessChunk {
#        param($chunk, $chunkNum)
#        $totals.count += $chunk.Length
#        Write-Host "    Chunk $chunkNum processed, running total: $($totals.count)"
#    }
#
# --- Excel (requires Excel installed) ---
# 8. Export-VBAFExcel -Data $rows -Path "C:\Temp\houses.xlsx" -SheetName "HouseData"
#    $xdata = Import-VBAFExcel -Path "C:\Temp\houses.xlsx"
# ============================================================
Write-Host "📦 VBAF.ML.DataIO.ps1 loaded" -ForegroundColor Green
Write-Host "   Classes   : DataValidator"                -ForegroundColor Cyan
Write-Host "   Functions : Import-VBAFCsv"              -ForegroundColor Cyan
Write-Host "              Export-VBAFCsv"               -ForegroundColor Cyan
Write-Host "              Import-VBAFJson"              -ForegroundColor Cyan
Write-Host "              Export-VBAFJson"              -ForegroundColor Cyan
Write-Host "              Import-VBAFExcel"             -ForegroundColor Cyan
Write-Host "              Export-VBAFExcel"             -ForegroundColor Cyan
Write-Host "              Invoke-VBAFSqlQuery"          -ForegroundColor Cyan
Write-Host "              Export-VBAFSqlTable"          -ForegroundColor Cyan
Write-Host "              Get-VBAFApiData"              -ForegroundColor Cyan
Write-Host "              Import-VBAFCsvStreaming"      -ForegroundColor Cyan
Write-Host "              Convert-RowsToMatrix"         -ForegroundColor Cyan
Write-Host ""
Write-Host "   Quick start:" -ForegroundColor Yellow
Write-Host '   Export-VBAFCsv -Data $rows -Path "C:\Temp\houses.csv"'                         -ForegroundColor White
Write-Host '   $imported = Import-VBAFCsv -Path "C:\Temp\houses.csv"'                         -ForegroundColor White
Write-Host '   $matrix   = Convert-RowsToMatrix -Rows $imported -FeatureColumns @("size_sqm") -TargetColumn "price"' -ForegroundColor White
Write-Host ""