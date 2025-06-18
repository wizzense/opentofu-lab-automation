# Test array handling behavior
$arrayList = [System.Collections.ArrayList]::new()

# Test empty ArrayList conversion
$emptyArray1 = @($arrayList.ToArray() | Write-Output)
$emptyArray2 = @($arrayList.ToArray())

Write-Host "Empty ArrayList conversion:"
Write-Host "emptyArray1 type: $($emptyArray1.GetType().Name)"
Write-Host "emptyArray1 count: $($emptyArray1.Count)"
Write-Host "emptyArray1 is null: $($null -eq $emptyArray1)"
Write-Host "emptyArray1 is empty: $($emptyArray1.Count -eq 0)"

Write-Host "emptyArray2 type: $($emptyArray2.GetType().Name)"
Write-Host "emptyArray2 count: $($emptyArray2.Count)"
Write-Host "emptyArray2 is null: $($null -eq $emptyArray2)"
Write-Host "emptyArray2 is empty: $($emptyArray2.Count -eq 0)"

# Test with items
$arrayList.Add("test1") | Out-Null
$arrayList.Add("test2") | Out-Null

$filledArray1 = @($arrayList.ToArray() | Write-Output)
$filledArray2 = @($arrayList.ToArray())

Write-Host "`nFilled ArrayList conversion:"
Write-Host "filledArray1 type: $($filledArray1.GetType().Name)"
Write-Host "filledArray1 count: $($filledArray1.Count)"
Write-Host "filledArray2 type: $($filledArray2.GetType().Name)"
Write-Host "filledArray2 count: $($filledArray2.Count)"

# Test hashtable storage
$testHashtable = @{
    EmptyArray1 = $emptyArray1
    EmptyArray2 = $emptyArray2
    FilledArray1 = $filledArray1
    FilledArray2 = $filledArray2
}

Write-Host "`nIn hashtable:"
Write-Host "testHashtable.EmptyArray1 is null: $($null -eq $testHashtable.EmptyArray1)"
Write-Host "testHashtable.EmptyArray1 count: $($testHashtable.EmptyArray1.Count)"
Write-Host "testHashtable.EmptyArray2 is null: $($null -eq $testHashtable.EmptyArray2)"
Write-Host "testHashtable.EmptyArray2 count: $($testHashtable.EmptyArray2.Count)"
