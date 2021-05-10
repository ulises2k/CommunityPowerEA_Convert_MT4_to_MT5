# Script to Convert Setting File from MT4 to MT5 for Community Power EA
# Run:
# Open cmd.exe and execute this
# powershell.exe -file ".\Convert_MT4_to_MT5.ps1" CP-EURUSD.set
# The file converted is CP-EURUSD-MT5.set
#
# Autor: Ulises Cune (@Ulises2k)
# v1.2
Function Get-IniFile ($file) {
    $ini = [ordered]@{}
    switch -regex -file $file {
        "^\s*(.+?)\s*=\s*(.*)$" {
            $name, $value = $matches[1..2]
            # skip comments that start with semicolon:
            if (!($name.StartsWith(";"))) {
                if ($value.Contains('||') ) {
                    $ini[$name] = $value.Split('||')[0]
                    continue
                }
                else {
                    $ini[$name] = $value
                    continue
                }
            }
        }
    }
    $ini
}

function Set-OrAddIniValue {
    Param(
        [string]$FilePath,
        [hashtable]$keyValueList
    )

    $content = Get-Content $FilePath
    $keyValueList.GetEnumerator() | ForEach-Object {
        if ($content -match "^$($_.Key)\s*=") {
            $content = $content -replace "$($_.Key)\s*=(.*)", "$($_.Key)=$($_.Value)"
        }
        else {
            $content += "$($_.Key)=$($_.Value)"
        }
    }

    $content | Set-Content $FilePath
}


function ConvertTFMT4toMT5 ([string]$value , [string]$file) {
    $rvalue = [int]$inifile[$value]

    #1 Hour
    if ($rvalue -eq 60) {
        Set-OrAddIniValue -FilePath $file  -keyValueList @{
            $value = "16385"
        }
    }

    #4 Hour
    if ($rvalue -eq 240) {
        Set-OrAddIniValue -FilePath $file  -keyValueList @{
            $value = "16388"
        }
    }

    #1 Day
    if ($rvalue -eq 1440) {
        Set-OrAddIniValue -FilePath $file  -keyValueList @{
            $value = "16408"
        }
    }

    #1 Week - Signal_TimeFrame=10080 -> 32769
    if ($rvalue -eq 10080) {
        Set-OrAddIniValue -FilePath $file  -keyValueList @{
            $value = "32769"
        }
    }

    #1 Month - Signal_TimeFrame=43200 -> 49153
    if ($rvalue -eq 43200) {
        Set-OrAddIniValue -FilePath $file  -keyValueList @{
            $value = "49153"
        }
    }
}

function ConvertPriceMT4toMT5 ([string]$value, [string]$file) {
    #Close Price = 0 => 1
    #Open Price = 1 => 2
    #High Price = 2 => 3
    #Low Price = 3 => 4
    #Median Price = 4 => 5
    #Tipical Price = 5 => 6
    #Weighted Price = 6 => 7
    $rvalue = [int]$inifile[$value]
    $rvalue = $rvalue + 1
    Set-OrAddIniValue -FilePath $file  -keyValueList @{
        $value = [string]$rvalue
    }
}

function ReplaceDefaultsValueMT4toMT5 ([string]$file) {
    (Get-Content $file).Replace("0.00000000", "0") | Set-Content $file
    (Get-Content $file).Replace("0.01000000", "0.01") | Set-Content $file
    (Get-Content $file).Replace("0.10000000", "0.1") | Set-Content $file
    (Get-Content $file).Replace("1.00000000", "1") | Set-Content $file
    #(Get-Content $file).Replace("MessagesToGrammy=1","MessagesToGrammy=0") | Set-Content $file
    #(Get-Content $file).Replace("BE_Alert_After=3","BE_Alert_After=0") | Set-Content $file
}



#$filePath = "test-mt4.set"
$filePath = $args[0]

$Destino = (Get-Item $filePath).BaseName + "-MT5.set"
$Destino1 = (Get-Item $filePath).BaseName + "-1-MT5.set"
$Destino2 = (Get-Item $filePath).BaseName + "-2-MT5.set"
$Destino3 = (Get-Item $filePath).BaseName + "-3-MT5.set"
Copy-Item "$filePath" -Destination "$Destino"

ReplaceDefaultsValueMT4toMT5 -file $Destino

Get-Content $Destino | Select-String -pattern ',F=' -notmatch | Out-File $Destino1
Get-Content $Destino1 | Select-String -pattern ',1=' -notmatch | Out-File $Destino2
Get-Content $Destino2 | Select-String -pattern ',2=' -notmatch | Out-File $Destino3
Get-Content $Destino3 | Select-String -pattern ',3=' -notmatch | Out-File $Destino
Remove-Item $Destino1
Remove-Item $Destino2
Remove-Item $Destino3


$inifile = Get-IniFile($Destino)
ConvertTFMT4toMT5 -value "VolPV_TF" -file $Destino
ConvertTFMT4toMT5 -value "BigCandle_TF" -file $Destino
ConvertTFMT4toMT5 -value "Oscillator2_TF" -file $Destino
ConvertTFMT4toMT5 -value "Oscillator3_TF" -file $Destino
ConvertTFMT4toMT5 -value "IdentifyTrend_TF" -file $Destino
ConvertTFMT4toMT5 -value "TDI_TF" -file $Destino
ConvertTFMT4toMT5 -value "FIBO_TF" -file $Destino
ConvertTFMT4toMT5 -value "FIB2_TF" -file $Destino
ConvertTFMT4toMT5 -value "MACD_TF" -file $Destino
ConvertTFMT4toMT5 -value "PSar_TF" -file $Destino
ConvertTFMT4toMT5 -value "MA_Filter_1_TF" -file $Destino
ConvertTFMT4toMT5 -value "MA_Filter_2_TF" -file $Destino
ConvertTFMT4toMT5 -value "MA_Filter_3_TF" -file $Destino
ConvertTFMT4toMT5 -value "ZZ_TF" -file $Destino
ConvertTFMT4toMT5 -value "VolMA_TF" -file $Destino
ConvertTFMT4toMT5 -value "VolFilter_TF" -file $Destino


ConvertPriceMT4toMT5 -value "Oscillators_Price" -file $Destino
ConvertPriceMT4toMT5 -value "Oscillator2_Price" -file $Destino
ConvertPriceMT4toMT5 -value "Oscillator3_Price" -file $Destino
ConvertPriceMT4toMT5 -value "TDI_AppliedPriceRSI" -file $Destino
ConvertPriceMT4toMT5 -value "MACD_Price" -file $Destino
ConvertPriceMT4toMT5 -value "MA_Filter_1_Price" -file $Destino
ConvertPriceMT4toMT5 -value "MA_Filter_2_Price" -file $Destino
ConvertPriceMT4toMT5 -value "MA_Filter_3_Price" -file $Destino

Write-Output "Successfully Converted"