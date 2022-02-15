Add-Type -AssemblyName System.Windows.Forms
$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ 
    InitialDirectory = [Environment]::GetFolderPath('Desktop') 
    Filter = 'Policy XML (*.xml)|*.xml'
}
$null = $FileBrowser.ShowDialog()

$Policy = [xml](Get-Content -Path $FileBrowser.FileName)

$printers = @()
$printers += $Policy.GetElementsByTagName("q1:SharedPrinter")
$printers += $Policy.GetElementsByTagName("q2:SharedPrinter")
$printers += $Policy.GetElementsByTagName("q3:SharedPrinter")
$printers += $Policy.GetElementsByTagName("q4:SharedPrinter")
$printers += $Policy.GetElementsByTagName("q5:SharedPrinter")
$printers += $Policy.GetElementsByTagName("q6:SharedPrinter")
$printers += $Policy.GetElementsByTagName("q7:SharedPrinter")
$printers += $Policy.GetElementsByTagName("q8:SharedPrinter")
$printers += $Policy.GetElementsByTagName("q9:SharedPrinter")

foreach($printer in $printers){
    
    $path = $printer.Properties.path
    $default = $printer.Properties.default
    $name = $printer.name
    $ExcludeGroup =@()
    $IncludeGroup =@()
    if($null -ne $printer.Filters.FilterGroup){
        foreach($Filter in $printer.Filters){
            if($Filter.FilterGroup.not -eq 0){
                $IncludeGroup += $Filter.FilterGroup.name
            } else {
                $ExcludeGroup += $Filter.FilterGroup.name
                Write-Warning "$path | $($Filter.FilterGroup.name) | NOT"
            }
            if($Filter.FilterGroup.bool -ne "AND"){
                Write-Warning "$path | $($Filter.FilterGroup.name) | OR"
            }
            if($Filter.FilterGroup.userContext -ne 1){
                Write-Warning "$path | $($Filter.FilterGroup.name) | Device Context"
            }
        }
    }
    '$printers += [pscustomobject]@{PrinterName="'+$name+'";PrintServer="'+$path+'";ADGroup="'+($IncludeGroup -join ",")+'";Default="'+$default+'"}' | Out-File -FilePath "PrinterInfo.txt" -Append
    '$printers += [pscustomobject]@{PrinterName="'+$name+'";PrintServer="'+$path+'";ADGroup="'+($IncludeGroup -join ",")+'";Default="'+$default+'"}'
}