<#
.SYNOPSIS
    PowerShell script to control WeMos D1 Mini / ESP8266 MG90S Servos via UDP packets.
.DESCRIPTION
    Sends UDP packets to the target IP address on port 8888 with format "angle1,angle2,angle3".
#>

param(
    [string]$TargetIP = "255.255.255.255",
    [int]$Port = 8888
)

function Send-ServoAngles {
    param(
        [int]$Angle1,
        [int]$Angle2,
        [int]$Angle3,
        [string]$IP = $TargetIP,
        [int]$PortNum = $Port
    )

    # Clamp angles between 0 and 180
    $Angle1 = [Math]::Max(0, [Math]::Min(180, $Angle1))
    $Angle2 = [Math]::Max(0, [Math]::Min(180, $Angle2))
    $Angle3 = [Math]::Max(0, [Math]::Min(180, $Angle3))

    $udpClient = New-Object System.Net.Sockets.UdpClient
    try {
        $udpClient.EnableBroadcast = $true
        $payload = [System.Text.Encoding]::ASCII.GetBytes("$Angle1,$Angle2,$Angle3")
        $udpClient.Send($payload, $payload.Length, $IP, $PortNum) | Out-Null
        Write-Host "Sent UDP -> IP: $IP`:$PortNum | Servo1: $Angle1° | Servo2: $Angle2° | Servo3: $Angle3°" -ForegroundColor Green
    }
    catch {
        Write-Host "Error sending UDP packet: $_" -ForegroundColor Red
    }
    finally {
        $udpClient.Close()
    }
}

function Start-InteractiveMenu {
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "   ESP8266 Servo Arm Controller (UDP)    " -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan

    $ipInput = Read-Host "Enter Target IP Address (Default: $TargetIP [Broadcast])"
    if (-not [string]::IsNullOrWhiteSpace($ipInput)) {
        $script:TargetIP = $ipInput
    }

    Write-Host "Target set to: $TargetIP | Port: $Port" -ForegroundColor Yellow

    while ($true) {
        Write-Host ""
        Write-Host "Select an option:" -ForegroundColor Yellow
        Write-Host "1) Set custom angles (Servo 1, 2, 3)"
        Write-Host "2) Move all to 90° (Neutral)"
        Write-Host "3) Move all to 0° (Minimum)"
        Write-Host "4) Move all to 180° (Maximum)"
        Write-Host "5) Continuous Sweep Loop (0° <-> 180°)"
        Write-Host "6) Change Target IP Address"
        Write-Host "Q) Quit"
        
        $choice = Read-Host "Choice"
        switch ($choice.ToUpper()) {
            "1" {
                $a1 = Read-Host "Servo 1 Angle (0-180)"
                $a2 = Read-Host "Servo 2 Angle (0-180)"
                $a3 = Read-Host "Servo 3 Angle (0-180)"
                Send-ServoAngles -Angle1 ([int]$a1) -Angle2 ([int]$a2) -Angle3 ([int]$a3)
            }
            "2" {
                Send-ServoAngles -Angle1 90 -Angle2 90 -Angle3 90
            }
            "3" {
                Send-ServoAngles -Angle1 0 -Angle2 0 -Angle3 0
            }
            "4" {
                Send-ServoAngles -Angle1 180 -Angle2 180 -Angle3 180
            }
            "5" {
                Write-Host "Starting continuous sweep... Press Ctrl+C to stop." -ForegroundColor Cyan
                try {
                    while ($true) {
                        for ($pos = 0; $pos -le 180; $pos += 5) {
                            Send-ServoAngles -Angle1 $pos -Angle2 $pos -Angle3 $pos
                            Start-Sleep -Milliseconds 40
                        }
                        for ($pos = 180; $pos -ge 0; $pos -= 5) {
                            Send-ServoAngles -Angle1 $pos -Angle2 $pos -Angle3 $pos
                            Start-Sleep -Milliseconds 40
                        }
                    }
                }
                catch {
                    Write-Host "`nSweep stopped." -ForegroundColor Yellow
                }
            }
            "6" {
                $newIP = Read-Host "Enter new Target IP Address"
                if (-not [string]::IsNullOrWhiteSpace($newIP)) {
                    $script:TargetIP = $newIP
                    Write-Host "Target IP updated to $TargetIP" -ForegroundColor Green
                }
            }
            "Q" {
                Write-Host "Exiting script." -ForegroundColor Gray
                return
            }
            Default {
                Write-Host "Invalid choice. Please select a valid option." -ForegroundColor Red
            }
        }
    }
}

# Entry point
Start-InteractiveMenu
