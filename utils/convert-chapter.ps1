param(
    [string]$FolderName = "chapter-02-java-foundations"
)

# Get the directory of this script to locate the code_filter.lua
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$CodeFilterPath = Join-Path $ScriptDir "code_filter.lua"

# Construct the full path to the target folder
$TargetFolder = Join-Path (Split-Path -Parent $ScriptDir) $FolderName

# Check if the target folder exists
if (-not (Test-Path $TargetFolder)) {
    Write-Error "Folder '$TargetFolder' does not exist."
    exit 1
}

# Construct paths for md and html subdirectories
$MdFolder = Join-Path $TargetFolder "md"
$HtmlFolder = Join-Path $TargetFolder "html"
$pdfFolder = Join-Path $TargetFolder "pdf"

# Check if the md subdirectory exists
if (-not (Test-Path $MdFolder)) {
    Write-Error "Markdown folder '$MdFolder' does not exist."
    exit 1
}

# Create html subdirectory if it doesn't exist
if (-not (Test-Path $HtmlFolder)) {
    New-Item -ItemType Directory -Path $HtmlFolder -Force
    Write-Host "Created html directory: $HtmlFolder"
}

# Create html subdirectory if it doesn't exist
if (-not (Test-Path $pdfFolder)) {
    New-Item -ItemType Directory -Path $pdfFolder -Force
    Write-Host "Created html directory: $pdfFolder"
}


# Remove existing combined chapter files if they exist
$CombinedMd = Join-Path $MdFolder ("$FolderName.md")
$CombinedHtml = Join-Path $HtmlFolder ("$FolderName.html")
if (Test-Path $CombinedMd) {
    Remove-Item $CombinedMd -Force
    Write-Host "Deleted old combined markdown: $CombinedMd"
}
if (Test-Path $CombinedHtml) {
    Remove-Item $CombinedHtml -Force
    Write-Host "Deleted old combined HTML: $CombinedHtml"
}

# Get all .md files in the md subdirectory
$MarkdownFiles = Get-ChildItem -Path $MdFolder -Filter "*.md" -File

if ($MarkdownFiles.Count -eq 0) {
    Write-Warning "No .md files found in '$MdFolder'"
    exit 0
}

Write-Host "Found $($MarkdownFiles.Count) markdown file(s) in '$MdFolder'"


### Process each markdown file individually
foreach ($File in $MarkdownFiles) {
    $BaseName = [System.IO.Path]::GetFileNameWithoutExtension($File.Name)
    $HtmlFile = Join-Path $HtmlFolder "$BaseName.html"
    Write-Host "Converting: $($File.Name) -> $BaseName.html"
    try {
        # Run pandoc command
        pandoc $File.FullName -o $HtmlFile --lua-filter $CodeFilterPath
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✓ Successfully converted $($File.Name)"
        } else {
            Write-Error "  ✗ Failed to convert $($File.Name)"
        }
    }
    catch {
        Write-Error "  ✗ Error converting $($File.Name): $($_.Exception.Message)"
    }
}

# Post-process all HTML files in the html directory to ensure <a> tags have target="_blank"
$AllHtmlFiles = Get-ChildItem -Path $HtmlFolder -Filter "*.html" -File
foreach ($HtmlFile in $AllHtmlFiles) {
    $htmlContent = Get-Content $HtmlFile.FullName -Raw -Encoding UTF8
    # Fix HTML entities and typography
    $htmlContent = $htmlContent -replace '&quot;', '"'
    $htmlContent = $htmlContent -replace '&apos;', "'"
    $htmlContent = $htmlContent -replace '&amp;', '&'
    $htmlContent = $htmlContent -replace '&lt;', '<'
    $htmlContent = $htmlContent -replace '&gt;', '>'
    $htmlContent = $htmlContent -replace '--', '—'
    # Ensure all <a> tags open in a new tab (add target="_blank" if not present)
    $htmlContent = [System.Text.RegularExpressions.Regex]::Replace($htmlContent, '<a(\s+[^>]*href="[^"]+"[^>]*)>', {
        param($m)
        if ($m.Value -match 'target=') { return $m.Value } else { return $m.Value -replace '>$', ' target="_blank">' }
    })
    [System.IO.File]::WriteAllText($HtmlFile.FullName, $htmlContent, [System.Text.Encoding]::UTF8)
}

# Combine all markdown files into one and convert to a single HTML file
$CombinedMd = Join-Path $MdFolder ("$FolderName.md")
$CombinedHtml = Join-Path $HtmlFolder ("$FolderName.html")

try {
    # Concatenate all markdown files in order
    Get-Content $MarkdownFiles.FullName | Set-Content $CombinedMd -Encoding UTF8
    Write-Host "Combining all markdown files into: $CombinedMd"
    # Convert combined markdown to HTML
    pandoc $CombinedMd -o $CombinedHtml --lua-filter $CodeFilterPath
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Successfully created combined HTML: $CombinedHtml"
    } else {
        Write-Error "  ✗ Failed to create combined HTML file"
    }
}
catch {
    Write-Error "  ✗ Error creating combined HTML: $($_.Exception.Message)"
}

# Convert combined markdown to PDF with error handling
# $CombinedPdf = Join-Path $pdfFolder ("$((Split-Path $CombinedMd -LeafBase)).pdf")
# try {
#     pandoc $CombinedMd -o $CombinedPdf --pdf-engine=xelatex
#     if ($LASTEXITCODE -eq 0) {
#         Write-Host "  ✓ Successfully created combined PDF: $CombinedPdf"
#     } else {
#         Write-Error "  ✗ Failed to create combined PDF file"
#     }
# }
# catch {
#     Write-Error "  ✗ Error creating combined PDF: $($_.Exception.Message)"
# }


Write-Host "`nConversion complete!"