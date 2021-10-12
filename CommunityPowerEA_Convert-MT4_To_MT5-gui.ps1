# Script to Convert Setting File from MT4 to MT5 for Community Power EA
# Drag and Drop file in Windows Forms and press button
#
# Autor: Ulises Cune (@Ulises2k)
# v2.7


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

Function ConvertINItoProfileVersion ([string]$FilePath) {
    $content = Get-Content $FilePath
    switch -regex -file $FilePath {
        "^\s*(.+?)\s*=\s*(.*)$" {
            $name, $value = $matches[1..2]
            # skip comments that start with semicolon:
            if (!($name.StartsWith(";"))) {
                if ($value.Contains('||') ) {
                    $content = $content -replace "$($name)\s*=(.*)", "$($name)=$($value.Split('||')[0])"
                }
                else {
                    $content = $content -replace "$($name)\s*=(.*)", "$($name)=$($value)"
                }
            }
        }
    }
    $content | Set-Content $FilePath
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
    $inifile = Get-IniFile($file)
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
    $inifile = Get-IniFile($file)
    $rvalue = [int]$inifile[$value]
    $rvalue = $rvalue + 1
    Set-OrAddIniValue -FilePath $file  -keyValueList @{
        $value = [string]$rvalue
    }
}

function ConvertBoolMT4toMT5 ([string]$value, [string]$file) {
    $inifile = Get-IniFile($file)

    if ([string]$inifile[$value] -eq "0") {
        Set-OrAddIniValue -FilePath $file  -keyValueList @{
            $value = "false"
        }
    }

    if ([string]$inifile[$value] -eq "1") {
        Set-OrAddIniValue -FilePath $file  -keyValueList @{
            $value = "true"
        }
    }
}


function ReplaceDefaultsValueMT4toMT5 ([string]$file) {
    #Remove and Replace
    (Get-Content $file).Replace("0.00000000", "0") | Set-Content $file
    (Get-Content $file).Replace("0.01000000", "0.01") | Set-Content $file
    (Get-Content $file).Replace("0.10000000", "0.1") | Set-Content $file
    (Get-Content $file).Replace(".00000000", "") | Set-Content $file
    (Get-Content $file).Replace("000000", "") | Set-Content $file
    (Get-Content $file).Replace("0000000", "") | Set-Content $file

    #My Defaults values
    #Set-OrAddIniValue -FilePath $file  -keyValueList @{
    #    MessagesToGrammy = "0"
    #    BE_Alert_After   = "0"
    #    GUI_Enabled      = "0"
    #    Alerts_Enabled   = "0"
    #    Sounds_Enabled   = "0"
    #    Show_Opened      = "1"
    #    Show_Closed      = "1"
    #    Show_Pending     = "1"
    #    GUI_ShowSignals  = "1"
    #}
}

function MainConvert2MT5 ([string]$filePath) {

    $Destino = (Get-Item $filePath).BaseName + "-MT5.set"
    $Destino1 = (Get-Item $filePath).BaseName + "-1-MT5.set"
    $Destino2 = (Get-Item $filePath).BaseName + "-2-MT5.set"
    $Destino3 = (Get-Item $filePath).BaseName + "-3-MT5.set"
    $CurrentDir = Split-Path -Path "$filePath"
    Copy-Item "$filePath" -Destination "$CurrentDir\$Destino"

    Get-Content "$CurrentDir\$Destino" | Select-String -pattern ',F=' -notmatch | Out-File "$CurrentDir\$Destino1"
    Get-Content "$CurrentDir\$Destino1" | Select-String -pattern ',1=' -notmatch | Out-File "$CurrentDir\$Destino2"
    Get-Content "$CurrentDir\$Destino2" | Select-String -pattern ',2=' -notmatch | Out-File "$CurrentDir\$Destino3"
    Get-Content "$CurrentDir\$Destino3" | Select-String -pattern ',3=' -notmatch | Out-File "$CurrentDir\$Destino"
    Remove-Item "$CurrentDir\$Destino1"
    Remove-Item "$CurrentDir\$Destino2"
    Remove-Item "$CurrentDir\$Destino3"

    ReplaceDefaultsValueMT4toMT5 -file "$CurrentDir\$Destino"

    $Destino = "$CurrentDir\$Destino"
    ConvertINItoProfileVersion -FilePath $Destino


    #Convert TimeFrame
    ConvertTFMT4toMT5 -value "Signal_TimeFrame" -file $Destino
    ConvertTFMT4toMT5 -value "VolPV_TF" -file $Destino
    ConvertTFMT4toMT5 -value "BigCandle_TF" -file $Destino
    ConvertTFMT4toMT5 -value "Oscillators_TF" -file $Destino
    ConvertTFMT4toMT5 -value "Oscillator2_TF" -file $Destino
    ConvertTFMT4toMT5 -value "Oscillator3_TF" -file $Destino
    ConvertTFMT4toMT5 -value "IdentifyTrend_TF" -file $Destino
    ConvertTFMT4toMT5 -value "TDI_TF" -file $Destino
    ConvertTFMT4toMT5 -value "FIBO_TF" -file $Destino
    ConvertTFMT4toMT5 -value "FIB2_TF" -file $Destino
    ConvertTFMT4toMT5 -value "MACD_TF" -file $Destino
    ConvertTFMT4toMT5 -value "MACD2_TF" -file $Destino
    ConvertTFMT4toMT5 -value "DTrend_TF" -file $Destino
    ConvertTFMT4toMT5 -value "PSar_TF" -file $Destino
    ConvertTFMT4toMT5 -value "MA_Filter_1_TF" -file $Destino
    ConvertTFMT4toMT5 -value "MA_Filter_2_TF" -file $Destino
    ConvertTFMT4toMT5 -value "MA_Filter_3_TF" -file $Destino
    ConvertTFMT4toMT5 -value "ZZ_TF" -file $Destino
    ConvertTFMT4toMT5 -value "VolMA_TF" -file $Destino
    ConvertTFMT4toMT5 -value "VolFilter_TF" -file $Destino

    #Convert Price
    ConvertPriceMT4toMT5 -value "Oscillators_Price" -file $Destino
    ConvertPriceMT4toMT5 -value "Oscillator2_Price" -file $Destino
    ConvertPriceMT4toMT5 -value "Oscillator3_Price" -file $Destino
    ConvertPriceMT4toMT5 -value "IdentifyTrend_AppliedPrice" -file $Destino
    ConvertPriceMT4toMT5 -value "TDI_AppliedPriceRSI" -file $Destino
    ConvertPriceMT4toMT5 -value "MACD_Price" -file $Destino
    ConvertPriceMT4toMT5 -value "MACD2_Price" -file $Destino
    ConvertPriceMT4toMT5 -value "MA_Filter_1_Price" -file $Destino
    ConvertPriceMT4toMT5 -value "MA_Filter_2_Price" -file $Destino
    ConvertPriceMT4toMT5 -value "MA_Filter_3_Price" -file $Destino

    #; Expert properties
    ConvertBoolMT4toMT5 -value "NewDealOnNewBar" -file $Destino
    ConvertBoolMT4toMT5 -value "ManageManual" -file $Destino
    #; Hedge properties
    ConvertBoolMT4toMT5 -value "AllowHedge" -file $Destino
    #; Pending entry properties
    ConvertBoolMT4toMT5 -value "Pending_CancelOnOpposite" -file $Destino
    ConvertBoolMT4toMT5 -value "Pending_DisableForOpposite" -file $Destino
    #; StopLoss properties
    ConvertBoolMT4toMT5 -value "UseVirtualSL" -file $Destino
    #; TakeProfit properties
    ConvertBoolMT4toMT5 -value "GlobalTakeProfit_OnlyLock" -file $Destino
    ConvertBoolMT4toMT5 -value "UseVirtualTP" -file $Destino
    #; Martingail properties
    ConvertBoolMT4toMT5 -value "MartingailOnTheBarEnd" -file $Destino
    ConvertBoolMT4toMT5 -value "ApplyAfterClosedLoss" -file $Destino

    #; Anti-Martingale properties
    ConvertBoolMT4toMT5 -value "AntiMartingail_AllowTP" -file $Destino
    ConvertBoolMT4toMT5 -value "AllowBothMartinAndAntiMartin" -file $Destino

    #; Partial close properties
    ConvertBoolMT4toMT5 -value "PartialCloseHedge_MainToMain" -file $Destino
    ConvertBoolMT4toMT5 -value "PartialCloseHedge_BothWays" -file $Destino

    #; Big candle properties
    ConvertBoolMT4toMT5 -value "BigCandle_CurrentBar" -file $Destino

    #; Oscillator #1 properties
    ConvertBoolMT4toMT5 -value "Oscillators_ContrTrend" -file $Destino
    ConvertBoolMT4toMT5 -value "Oscillators_UseClosedBars" -file $Destino

    #; Oscillator #2 properties
    ConvertBoolMT4toMT5 -value "Oscillator2_ContrTrend" -file $Destino
    ConvertBoolMT4toMT5 -value "Oscillator2_UseClosedBars" -file $Destino

    #; Oscillator #3 properties
    ConvertBoolMT4toMT5 -value "Oscillator3_ContrTrend" -file $Destino
    ConvertBoolMT4toMT5 -value "Oscillator3_UseClosedBars" -file $Destino

    #; IdentifyTrend properties
    ConvertBoolMT4toMT5 -value "IdentifyTrend_Enable" -file $Destino
    ConvertBoolMT4toMT5 -value "IdentifyTrend_Reverse" -file $Destino
    ConvertBoolMT4toMT5 -value "IdentifyTrend_UseClosedBars" -file $Destino
    #; TDI properties
    ConvertBoolMT4toMT5 -value "TDI_Reverse" -file $Destino
    ConvertBoolMT4toMT5 -value "TDI_UseClosedBars" -file $Destino
    #; MACD properties
    ConvertBoolMT4toMT5 -value "MACD_Reverse" -file $Destino
    ConvertBoolMT4toMT5 -value "MACD_UseClosedBars" -file $Destino
    #; MACD2 properties
    ConvertBoolMT4toMT5 -value "MACD2_Reverse" -file $Destino
    ConvertBoolMT4toMT5 -value "MACD2_UseClosedBars" -file $Destino
    #; DTrend properties
    ConvertBoolMT4toMT5 -value "DTrend_Reverse" -file $Destino
    ConvertBoolMT4toMT5 -value "DTrend_UseClosedBars" -file $Destino
    #; Parabolic SAR properties
    ConvertBoolMT4toMT5 -value "PSar_Reverse" -file $Destino
    #; ZigZag properties
    ConvertBoolMT4toMT5 -value "ZZ_UseClosedBars" -file $Destino
    #; FIBO #1 properties
    ConvertBoolMT4toMT5 -value "FIBO_UseClosedBars" -file $Destino
    #; FIBO #2 properties
    ConvertBoolMT4toMT5 -value "FIB2_UseClosedBars" -file $Destino
    #; Custom Schedule
    ConvertBoolMT4toMT5 -value "Custom_Schedule_On" -file $Destino
    #; News settings
    ConvertBoolMT4toMT5 -value "News_Impact_H" -file $Destino
    ConvertBoolMT4toMT5 -value "News_Impact_M" -file $Destino
    ConvertBoolMT4toMT5 -value "News_Impact_L" -file $Destino
    ConvertBoolMT4toMT5 -value "News_Impact_N" -file $Destino
    ConvertBoolMT4toMT5 -value "News_ShowOnChart" -file $Destino
    #; GUI settings
    ConvertBoolMT4toMT5 -value "GUI_Enabled" -file $Destino
    ConvertBoolMT4toMT5 -value "GUI_ShowSignals" -file $Destino
    #; Show orders
    ConvertBoolMT4toMT5 -value "Show_Closed" -file $Destino
    ConvertBoolMT4toMT5 -value "Show_Pending" -file $Destino
    ConvertBoolMT4toMT5 -value "Profit_ShowInMoney" -file $Destino
    ConvertBoolMT4toMT5 -value "Profit_ShowInPoints" -file $Destino
    ConvertBoolMT4toMT5 -value "Profit_ShowInPercents" -file $Destino
    ConvertBoolMT4toMT5 -value "Profit_Aggregate" -file $Destino
    ConvertBoolMT4toMT5 -value "SL_TP_Dashes_Show" -file $Destino
    #; Notifications settings
    ConvertBoolMT4toMT5 -value "MessagesToGrammy" -file $Destino
    ConvertBoolMT4toMT5 -value "Alerts_Enabled" -file $Destino
    ConvertBoolMT4toMT5 -value "Sounds_Enabled" -file $Destino

    Write-Output "Successfully Converted MT4 To MT5"
}


#######################GUI################################################################
### API Windows Forms ###
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")



### Create form ###
$form = New-Object System.Windows.Forms.Form
$form.Text = "Convert from MT4 to MT5 - CommunityPower EA"
$form.Size = '512,320'
$form.StartPosition = "CenterScreen"
$form.MinimumSize = $form.Size
$form.MaximizeBox = $False
$form.Topmost = $True


### Define controls ###
$button = New-Object System.Windows.Forms.Button
$button.Location = '5,5'
$button.Size = '75,23'
$button.Width = 120
$button.Text = "Convert to MT5"

$checkbox = New-Object Windows.Forms.Checkbox
$checkbox.Location = '140,8'
$checkbox.AutoSize = $True
$checkbox.Text = "Clear afterwards"

$label = New-Object Windows.Forms.Label
$label.Location = '5,40'
$label.AutoSize = $True
$label.Text = "Drag and Drop files settings MT4 here:"

$listBox = New-Object Windows.Forms.ListBox
$listBox.Location = '5,60'
$listBox.Height = 200
$listBox.Width = 480
$listBox.Anchor = ([System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right -bor [System.Windows.Forms.AnchorStyles]::Top)
$listBox.IntegralHeight = $False
$listBox.AllowDrop = $True

$statusBar = New-Object System.Windows.Forms.StatusBar
$statusBar.Text = "Ready"


### Add controls to form ###
$form.SuspendLayout()
$form.Controls.Add($button)
$form.Controls.Add($checkbox)
$form.Controls.Add($label)
$form.Controls.Add($listBox)
$form.Controls.Add($statusBar)
$form.ResumeLayout()


### Write event handlers ###
$button_Click = {
    foreach ($item in $listBox.Items) {
        if (!($i -is [System.IO.DirectoryInfo])) {
            MainConvert2MT5 -file $item
            [System.Windows.Forms.MessageBox]::Show('Successfully convert MT4 to MT5 Community Power EA', 'Convert from MT4 to MT5', 0, 64)
        }
    }

    if ($checkbox.Checked -eq $True) {
        $listBox.Items.Clear()
    }

    $statusBar.Text = ("List contains $($listBox.Items.Count) items")
}

$listBox_DragOver = [System.Windows.Forms.DragEventHandler] {
    if ($_.Data.GetDataPresent([Windows.Forms.DataFormats]::FileDrop)) {
        # $_ = [System.Windows.Forms.DragEventArgs]
        $_.Effect = 'Copy'
    }
    else {
        $_.Effect = 'None'
    }
}

$listBox_DragDrop = [System.Windows.Forms.DragEventHandler] {
    foreach ($filename in $_.Data.GetData([Windows.Forms.DataFormats]::FileDrop)) {
        # $_ = [System.Windows.Forms.DragEventArgs]
        $listBox.Items.Add($filename)
    }
    $statusBar.Text = ("List contains $($listBox.Items.Count) items")
}

$form_FormClosed = {
    try {
        $listBox.remove_Click($button_Click)
        $listBox.remove_DragOver($listBox_DragOver)
        $listBox.remove_DragDrop($listBox_DragDrop)
        $listBox.remove_DragDrop($listBox_DragDrop)
        $form.remove_FormClosed($Form_Cleanup_FormClosed)
    }
    catch [Exception]
    { }
}


### Wire up events ###
$button.Add_Click($button_Click)
$listBox.Add_DragOver($listBox_DragOver)
$listBox.Add_DragDrop($listBox_DragDrop)
$form.Add_FormClosed($form_FormClosed)


#### Show form ###
[void] $form.ShowDialog()
