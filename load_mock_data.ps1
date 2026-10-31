$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

$folder = Join-Path $PSScriptRoot 'исходные данные'
$files = @(Get-ChildItem -LiteralPath $folder -Filter '*.csv' -File | Sort-Object Name)
if ($files.Count -ne 10) {
    throw "Expected 10 CSV files, found $($files.Count)"
}

$headerLine = Get-Content -LiteralPath $files[0].FullName -TotalCount 1 -Encoding UTF8
$header = $headerLine.TrimStart([char]0xFEFF).Split(',')
if ($header.Count -ne 50 -or $header[0] -ne 'id') {
    throw 'Unexpected CSV header structure'
}

$quoted = @($header | ForEach-Object { '"' + $_.Replace('"', '""') + '"' })
$columns = @($quoted | ForEach-Object { "$_ TEXT" })
$createSql = "CREATE TABLE IF NOT EXISTS public.mock_data (row_id BIGSERIAL PRIMARY KEY, $($columns -join ', ')); TRUNCATE TABLE public.mock_data RESTART IDENTITY;"

$createSql | docker compose exec -T postgres psql -X -v ON_ERROR_STOP=1 -U student -d bigdata
if ($LASTEXITCODE -ne 0) { throw 'Could not initialize mock_data' }

foreach ($file in $files) {
    $name = $file.Name.Replace("'", "''")
    $copySql = "\copy public.mock_data ($($quoted -join ', ')) FROM '/data/$name' WITH (FORMAT csv, HEADER true)"
    $copySql | docker compose exec -T postgres psql -X -v ON_ERROR_STOP=1 -U student -d bigdata
    if ($LASTEXITCODE -ne 0) { throw "Could not import $($file.Name)" }
    Write-Host "Imported: $($file.Name)"
}

docker compose exec -T postgres psql -X -v ON_ERROR_STOP=1 -U student -d bigdata -c 'SELECT COUNT(*) AS total_rows, COUNT(DISTINCT row_id) AS unique_rows FROM public.mock_data;'
if ($LASTEXITCODE -ne 0) { throw 'Final check failed' }
