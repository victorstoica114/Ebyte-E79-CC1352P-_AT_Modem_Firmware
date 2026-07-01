param(
    [string]$PortA = 'COM19',
    [string]$PortB = 'COM22',
    [int]$BridgeBaud = 1000000,
    [int]$AtIterations = 1000,
    [int]$PacketsPerDirection = 250,
    [int]$SleepCycles = 50,
    [int]$ResetCycles = 10,
    [int]$TimeoutMs = 4000
)

$ErrorActionPreference = 'Stop'

$script:Devices = @()
$script:PassCount = 0
$script:FailCount = 0
$script:StartTime = [DateTime]::UtcNow

function Add-Result {
    param([bool]$Ok, [string]$Message)

    if ($Ok) {
        $script:PassCount++
    }
    else {
        $script:FailCount++
        Write-Host "[FAIL] $Message"
    }
}

function New-StressDevice {
    param([string]$Name, [string]$Port)

    $serial = [System.IO.Ports.SerialPort]::new($Port, 115200, [System.IO.Ports.Parity]::None, 8, [System.IO.Ports.StopBits]::One)
    $serial.Handshake = [System.IO.Ports.Handshake]::None
    $serial.DtrEnable = $false
    $serial.RtsEnable = $false
    $serial.ReadTimeout = 50
    $serial.WriteTimeout = 1000

    [PSCustomObject]@{
        Name = $Name
        Port = $Port
        Serial = $serial
        Buffer = ''
        Lines = [System.Collections.Generic.List[string]]::new()
        TxPackets = 0
        RxPackets = 0
    }
}

function Poll-Device {
    param([object]$Device)

    $chunk = $Device.Serial.ReadExisting()
    if ($chunk.Length -le 0) {
        return
    }

    $Device.Buffer += $chunk

    while ($true) {
        $idxR = $Device.Buffer.IndexOf("`r")
        $idxN = $Device.Buffer.IndexOf("`n")

        if ($idxR -lt 0 -and $idxN -lt 0) {
            break
        }

        if ($idxR -lt 0) {
            $idx = $idxN
        }
        elseif ($idxN -lt 0) {
            $idx = $idxR
        }
        else {
            $idx = [Math]::Min($idxR, $idxN)
        }

        $line = $Device.Buffer.Substring(0, $idx)
        $remove = $idx + 1
        while ($remove -lt $Device.Buffer.Length -and
               ($Device.Buffer[$remove] -eq "`r" -or $Device.Buffer[$remove] -eq "`n")) {
            $remove++
        }
        $Device.Buffer = $Device.Buffer.Substring($remove)

        if ($line.Length -gt 0) {
            $Device.Lines.Add($line)
        }
    }
}

function Poll-All {
    foreach ($dev in $script:Devices) {
        if ($dev.Serial.IsOpen) {
            Poll-Device -Device $dev
        }
    }
}

function Drain-All {
    param([int]$DurationMs = 200)

    $deadline = [DateTime]::UtcNow.AddMilliseconds($DurationMs)
    while ([DateTime]::UtcNow -lt $deadline) {
        Poll-All
        Start-Sleep -Milliseconds 10
    }
}

function Clear-Device {
    param([object]$Device)

    $Device.Buffer = ''
    $Device.Lines.Clear()
    if ($Device.Serial.IsOpen) {
        [void]$Device.Serial.ReadExisting()
    }
}

function Send-Command {
    param(
        [object]$Device,
        [string]$Command,
        [int]$CommandTimeoutMs = $TimeoutMs
    )

    $start = $Device.Lines.Count
    $Device.Serial.Write("$Command`r`n")
    try {
        $Device.Serial.BaseStream.Flush()
    }
    catch {
    }

    $deadline = [DateTime]::UtcNow.AddMilliseconds($CommandTimeoutMs)
    while ([DateTime]::UtcNow -lt $deadline) {
        Poll-All
        $newLines = @($Device.Lines | Select-Object -Skip $start)
        if ($newLines | Where-Object { $_ -eq 'OK' -or $_.StartsWith('#ERROR:') }) {
            return $newLines
        }
        Start-Sleep -Milliseconds 5
    }

    Poll-All
    return @($Device.Lines | Select-Object -Skip $start)
}

function Expect-Ok {
    param([object]$Device, [string]$Command, [string]$Message, [int]$CommandTimeoutMs = $TimeoutMs)

    $lines = Send-Command -Device $Device -Command $Command -CommandTimeoutMs $CommandTimeoutMs
    $ok = ($lines -contains 'OK')
    Add-Result -Ok $ok -Message $Message
    return $ok
}

function Wait-For-Line {
    param(
        [object]$Device,
        [int]$StartIndex,
        [string]$Pattern,
        [int]$LineTimeoutMs = $TimeoutMs
    )

    $deadline = [DateTime]::UtcNow.AddMilliseconds($LineTimeoutMs)
    while ([DateTime]::UtcNow -lt $deadline) {
        Poll-All
        $newLines = @($Device.Lines | Select-Object -Skip $StartIndex)
        foreach ($line in $newLines) {
            if ($line -match $Pattern) {
                return $line
            }
        }
        Start-Sleep -Milliseconds 5
    }

    Poll-All
    return $null
}

function Configure-Bridge {
    param([object]$Device)

    Write-Host ("Opening {0} on {1}; target UART {2} baud" -f $Device.Name, $Device.Port, $BridgeBaud)
    $Device.Serial.Open()
    Start-Sleep -Milliseconds 500
    [void]$Device.Serial.ReadExisting()

    $Device.Serial.Write("~CC1352P_BAUD=$BridgeBaud`n")
    $Device.Serial.BaseStream.Flush()
    Drain-All -DurationMs 900

    Clear-Device -Device $Device
}

function Make-HexPayload {
    param([int]$Sequence, [int]$Direction)

    $bytes = New-Object byte[] 64
    $bytes[0] = [byte]($Direction -band 0xFF)
    $bytes[1] = [byte](($Sequence -shr 8) -band 0xFF)
    $bytes[2] = [byte]($Sequence -band 0xFF)
    for ($i = 3; $i -lt $bytes.Length; $i++) {
        $bytes[$i] = [byte](($Sequence * 31 + $Direction * 17 + $i * 13) -band 0xFF)
    }

    return (($bytes | ForEach-Object { $_.ToString('X2') }) -join '')
}

function Prepare-RadioPair {
    param([object]$A, [object]$B)

    foreach ($dev in @($A, $B)) {
        [void](Expect-Ok -Device $dev -Command 'AT+WAKE' -Message "$($dev.Name) wake")
        [void](Expect-Ok -Device $dev -Command 'AT+DEFAULT' -Message "$($dev.Name) default")
        [void](Expect-Ok -Device $dev -Command 'AT+FREQ=433920000' -Message "$($dev.Name) freq")
        [void](Expect-Ok -Device $dev -Command 'AT+RATE=50000' -Message "$($dev.Name) rate")
        [void](Expect-Ok -Device $dev -Command 'AT+PWR=13' -Message "$($dev.Name) pwr")
        [void](Expect-Ok -Device $dev -Command 'AT+SYNC=0x930B51DE' -Message "$($dev.Name) sync")
        [void](Expect-Ok -Device $dev -Command 'AT+RX=OFF' -Message "$($dev.Name) rx off")
    }
}

function Stress-AtCommands {
    param([object]$A, [object]$B)

    Write-Host ""
    Write-Host "AT command burst: $AtIterations commands at $BridgeBaud baud"
    $commands = @('AT', 'AT+STATUS?', 'AT+CFG?', 'AT+UPTIME?', 'AT+RANDOM?', 'AT+RSSI?', 'AT+LASTPKT?')
    $devices = @($A, $B)

    for ($i = 0; $i -lt $AtIterations; $i++) {
        $dev = $devices[$i % $devices.Count]
        $cmd = $commands[$i % $commands.Count]
        [void](Expect-Ok -Device $dev -Command $cmd -Message "$($dev.Name) AT burst $i $cmd")

        if ((($i + 1) % 100) -eq 0) {
            Write-Host ("  AT burst progress: {0}/{1}, failures={2}" -f ($i + 1), $AtIterations, $script:FailCount)
        }
    }
}

function Stress-RadioDirection {
    param(
        [object]$Sender,
        [object]$Receiver,
        [int]$Direction
    )

    Write-Host ""
    Write-Host ("RF stress {0}->{1}: {2} packets x 64 bytes" -f $Sender.Name, $Receiver.Name, $PacketsPerDirection)

    [void](Expect-Ok -Device $Sender -Command 'AT+RX=OFF' -Message "$($Sender.Name) sender RX off")
    [void](Expect-Ok -Device $Receiver -Command 'AT+RX=ON' -Message "$($Receiver.Name) receiver RX on")

    for ($i = 0; $i -lt $PacketsPerDirection; $i++) {
        $hex = Make-HexPayload -Sequence $i -Direction $Direction
        $rxStart = $Receiver.Lines.Count
        $sendOk = Expect-Ok -Device $Sender -Command "AT+SENDHEX=$hex" -Message "$($Sender.Name) send packet $i" -CommandTimeoutMs 6000
        if ($sendOk) {
            $Sender.TxPackets++
        }

        $pattern = '^\+RXHEX:64,-?\d+,' + [regex]::Escape($hex) + '$'
        $rxLine = Wait-For-Line -Device $Receiver -StartIndex $rxStart -Pattern $pattern -LineTimeoutMs 6000
        $rxOk = ($null -ne $rxLine)
        if ($rxOk) {
            $Receiver.RxPackets++
        }
        Add-Result -Ok $rxOk -Message "$($Receiver.Name) receive packet $i from $($Sender.Name)"

        if ((($i + 1) % 25) -eq 0) {
            Write-Host ("  RF {0}->{1}: {2}/{3}, failures={4}" -f $Sender.Name, $Receiver.Name, ($i + 1), $PacketsPerDirection, $script:FailCount)
        }

        if (($i % 50) -eq 49) {
            $Sender.Lines.Clear()
            $Receiver.Lines.Clear()
        }
    }

    [void](Expect-Ok -Device $Receiver -Command 'AT+RX=OFF' -Message "$($Receiver.Name) receiver RX off")
}

function Stress-SleepWake {
    param([object]$A, [object]$B)

    Write-Host ""
    Write-Host "Sleep/wake stress: $SleepCycles cycles per module"

    foreach ($dev in @($A, $B)) {
        for ($i = 0; $i -lt $SleepCycles; $i++) {
            [void](Expect-Ok -Device $dev -Command 'AT+RX=OFF' -Message "$($dev.Name) sleep rx off $i")
            [void](Expect-Ok -Device $dev -Command 'AT+SLEEP' -Message "$($dev.Name) sleep $i")
            [void](Expect-Ok -Device $dev -Command 'AT+WAKE' -Message "$($dev.Name) wake $i")
        }
        Write-Host ("  {0} sleep/wake done, failures={1}" -f $dev.Name, $script:FailCount)
    }
}

function Stress-Reset {
    param([object]$A, [object]$B)

    Write-Host ""
    Write-Host "AT+RESET stress: $ResetCycles cycles per module"

    foreach ($dev in @($A, $B)) {
        for ($i = 0; $i -lt $ResetCycles; $i++) {
            [void](Expect-Ok -Device $dev -Command 'AT+RESET' -Message "$($dev.Name) reset command $i")
            Start-Sleep -Milliseconds 350
            [void](Expect-Ok -Device $dev -Command 'AT' -Message "$($dev.Name) AT after reset $i" -CommandTimeoutMs 6000)
        }
        Write-Host ("  {0} reset cycles done, failures={1}" -f $dev.Name, $script:FailCount)
    }
}

try {
    $devA = New-StressDevice -Name 'A' -Port $PortA
    $devB = New-StressDevice -Name 'B' -Port $PortB
    $script:Devices = @($devA, $devB)

    Configure-Bridge -Device $devA
    Configure-Bridge -Device $devB

    [void](Expect-Ok -Device $devA -Command 'AT' -Message 'A link alive')
    [void](Expect-Ok -Device $devB -Command 'AT' -Message 'B link alive')
    [void](Expect-Ok -Device $devA -Command 'AT+VERSION?' -Message 'A version')
    [void](Expect-Ok -Device $devB -Command 'AT+VERSION?' -Message 'B version')

    Prepare-RadioPair -A $devA -B $devB
    Stress-AtCommands -A $devA -B $devB
    Stress-RadioDirection -Sender $devA -Receiver $devB -Direction 1
    Stress-RadioDirection -Sender $devB -Receiver $devA -Direction 2
    Stress-SleepWake -A $devA -B $devB
    Stress-Reset -A $devA -B $devB

    [void](Expect-Ok -Device $devA -Command 'AT+STATUS?' -Message 'A final status')
    [void](Expect-Ok -Device $devB -Command 'AT+STATUS?' -Message 'B final status')
}
finally {
    foreach ($dev in $script:Devices) {
        if ($dev.Serial.IsOpen) {
            $dev.Serial.Close()
        }
        $dev.Serial.Dispose()
    }
}

$elapsed = [DateTime]::UtcNow - $script:StartTime

Write-Host ""
Write-Host "==== STRESS SUMMARY ===="
Write-Host ("Baud: {0}" -f $BridgeBaud)
Write-Host ("Elapsed: {0:n1}s" -f $elapsed.TotalSeconds)
Write-Host ("A TX/RX packets: {0}/{1}" -f $devA.TxPackets, $devA.RxPackets)
Write-Host ("B TX/RX packets: {0}/{1}" -f $devB.TxPackets, $devB.RxPackets)
Write-Host ("PASS: {0}" -f $script:PassCount)
Write-Host ("FAIL: {0}" -f $script:FailCount)

if ($script:FailCount -ne 0) {
    exit 1
}

exit 0
