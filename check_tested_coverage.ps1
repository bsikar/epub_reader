$content = Get-Content coverage\lcov.info -Raw

$files = @(
    'book.dart',
    'failures.dart',
    'book_list_item.dart',
    'book_grid_item.dart',
    'delete_book.dart',
    'get_all_books.dart',
    'get_recent_books.dart',
    'update_reading_progress.dart',
    'library_provider.dart',
    'book_details_screen.dart',
    'library_search_delegate.dart',
    'reader_screen.dart'
)

$totalFound = 0
$totalHit = 0
$fileResults = @()

foreach ($file in $files) {
    $pattern = "SF:.*\\$file"
    $matches = [regex]::Matches($content, "$pattern[\s\S]*?(?=SF:|`$)")

    foreach ($match in $matches) {
        $section = $match.Value

        if ($section -match 'LF:(\d+)') {
            $found = [int]$Matches[1]
        } else { $found = 0 }

        if ($section -match 'LH:(\d+)') {
            $hit = [int]$Matches[1]
        } else { $hit = 0 }

        if ($found -gt 0) {
            $fileCoverage = [math]::Round(($hit / $found) * 100, 1)
            $fileResults += "$file : $hit/$found ($fileCoverage%)"
            $totalFound += $found
            $totalHit += $hit
        }
    }
}

Write-Output "`nCoverage of Tested Files:"
Write-Output "=========================="
foreach ($result in $fileResults) {
    Write-Output $result
}

Write-Output "`n--------------------------"
Write-Output "Total Lines: $totalFound"
Write-Output "Lines Hit: $totalHit"

if ($totalFound -gt 0) {
    $coverage = [math]::Round(($totalHit / $totalFound) * 100, 2)
    Write-Output "Coverage: $coverage%"
} else {
    Write-Output "Coverage: 0%"
}
