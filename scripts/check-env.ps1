# check-env.ps1 - Read-only check of the local Cloudflare toolchain.
# Works on Windows PowerShell 5.1. Changes nothing; only prints status.
# Messages are ASCII on purpose: PS 5.1 misreads UTF-8 files without a BOM.

$ErrorActionPreference = 'Continue'
$results = @()

function Add-Result($name, $ok, $detail) {
    $script:results += [pscustomobject]@{ Check = $name; Status = $(if ($ok) { 'OK' } else { 'FAIL' }); Detail = $detail }
}

# 1. Node.js >= 22
$node = Get-Command node -ErrorAction SilentlyContinue
if ($node) {
    $v = (node --version).Trim()
    $major = [int]($v.TrimStart('v').Split('.')[0])
    Add-Result 'Node.js' ($major -ge 22) "$v (wrangler 4.x needs >= 22)"
} else {
    Add-Result 'Node.js' $false 'not found - install LTS from https://nodejs.org'
}

# 2. wrangler
$wr = Get-Command wrangler -ErrorAction SilentlyContinue
if ($wr) {
    $wv = (wrangler --version 2>$null | Select-Object -Last 1)
    Add-Result 'wrangler' $true "$wv"
} else {
    Add-Result 'wrangler' $false 'not found - run: npm install -g wrangler'
}

if ($wr) {
    # 3. login
    $who = (wrangler whoami 2>&1 | Out-String)
    $loggedIn = $who -match 'logged in'
    $email = ''
    if ($who -match 'associated with the email\s+(\S+?)\.?\s') { $email = $Matches[1] }
    Add-Result 'wrangler login' $loggedIn $(if ($loggedIn) { "logged in as $email" } else { 'not logged in - run: wrangler login' })

    if ($loggedIn) {
        # 4. D1
        $d1 = (wrangler d1 list 2>&1 | Out-String)
        $d1ok = ($LASTEXITCODE -eq 0)
        Add-Result 'D1 access' $d1ok $(if ($d1ok) { 'can list databases' } else { ($d1.Trim() -split "`n")[-1] })

        # 5. R2 (10042 = not activated, which is expected if you have not added a payment method)
        $r2 = (wrangler r2 bucket list 2>&1 | Out-String)
        if ($LASTEXITCODE -eq 0) {
            Add-Result 'R2' $true 'activated'
        } elseif ($r2 -match '10042') {
            Add-Result 'R2' $false 'not activated (code 10042) - optional, needs payment method; see docs/r2.md'
        } else {
            Add-Result 'R2' $false (($r2.Trim() -split "`n")[-1])
        }
    }
}

$results | Format-Table -AutoSize
$fail = @($results | Where-Object { $_.Status -eq 'FAIL' -and $_.Check -ne 'R2' })
if ($fail.Count -eq 0) { Write-Output 'Ready: core toolchain is set up.'; exit 0 } else { Write-Output 'Not ready: fix the FAIL rows above.'; exit 1 }
