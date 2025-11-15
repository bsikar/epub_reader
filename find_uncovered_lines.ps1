$content = Get-Content coverage\lcov.info -Raw

$files = @(
    'book_list_item.dart',
    'book_grid_item.dart',
    'delete_book.dart',
    'library_provider.dart'
)

Write-Output "Uncovered Lines in Tested Files:"
Write-Output "================================="

foreach ($file in $files) {
    $pattern = "SF:.*\\$file"
    $matches = [regex]::Matches($content, "$pattern[\s\S]*?(?=SF:|`$)")

    foreach ($match in $matches) {
        $section = $match.Value

        # Extract line numbers that are NOT hit (DA:line,0)
        $uncovered = [regex]::Matches($section, 'DA:(\d+),0') | ForEach-Object { $_.Groups[1].Value }

        if ($uncovered.Count -gt 0) {
            Write-Output "`n$file"
            Write-Output "  Uncovered lines: $($uncovered -join ', ')"
            Write-Output "  Missing: $($uncovered.Count) lines"
        }
    }
}
