$content = Get-Content coverage\lcov.info
$linesFound = 0
$linesHit = 0

foreach ($line in $content) {
    if ($line -match '^LF:(\d+)') {
        $linesFound += [int]$matches[1]
    }
    if ($line -match '^LH:(\d+)') {
        $linesHit += [int]$matches[1]
    }
}

$coverage = [math]::Round(($linesHit / $linesFound) * 100, 2)
Write-Output "Lines Found: $linesFound"
Write-Output "Lines Hit: $linesHit"
Write-Output "Coverage: $coverage%"
