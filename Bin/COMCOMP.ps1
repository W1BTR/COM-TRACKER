$counter = 0
# Define the path for the list file where COM port information is stored
$listFilePath = "Bin\COMLOG.log"
# Define the path for storing the name of the most recently added COM port
$recentPortFilePath = "Bin\RecentCOM.log"

# Clear the RecentCOM.log and COMLOG.log files at the start of the script
if (Test-Path $recentPortFilePath) {
    Remove-Item $recentPortFilePath -Force
}
if (Test-Path $listFilePath) {
    Remove-Item $listFilePath -Force
}
Write-Host "First Run"
$FirstRun = $true

# Retrieves the current COM ports and their descriptions from the system
function Get-ComPortsWithDescriptions {
    $comPorts = @{}
    $currentPorts = [System.IO.Ports.SerialPort]::GetPortNames()
    if ($currentPorts.Count -gt 0) {
        $wmiPorts = Get-WmiObject Win32_PnPEntity | Where-Object { $_.Name -match '^(.*\((COM\d+)\))$' }
        foreach ($port in $wmiPorts) {
            if ($port.Name -match '^(.*\((COM\d+)\))$') {
                $name = $matches[2]
                $description = $matches[1]
                $comPorts[$name] = $description
            }
        }
    }
    return $comPorts
}

# Logs the current COM ports and their descriptions to a file, marking the most recently added port
function LogComPortsToFile {
    $currentPortsInfo = Get-ComPortsWithDescriptions
    $previousPorts = @{}
    if (Test-Path $listFilePath) {
        # Import previous ports and convert to a hashtable for easier lookup
        $importedPorts = Import-Csv $listFilePath
        foreach ($port in $importedPorts) {
            $previousPorts[$port.Name] = $port
        }
    }

    $mostRecentPort = if (Test-Path $recentPortFilePath) { Get-Content $recentPortFilePath } else { $null }

    $listUpdated = $false
    # Determine if there's a change in the COM ports list
    if ($currentPortsInfo.Count -ne $previousPorts.Count) {
        $listUpdated = $true
        Write-Host "List Updated because count has changed"
    } else {
        foreach ($port in $currentPortsInfo.Keys) {
            if (-not $previousPorts.ContainsKey($port) -or $previousPorts[$port].Description -ne $currentPortsInfo[$port]) {
                $listUpdated = $true
                break
            }
        }
    }

    if ($listUpdated) {
        $newPortName = $null
        $currentPortsInfo.Keys | ForEach-Object {
            if (-not $previousPorts.ContainsKey($_)) {
                $newPortName = $_
                $mostRecentPort = $newPortName
                Set-Content -Path $recentPortFilePath -Value $mostRecentPort
                if ($FirstRun) {
                    Set-Content -Path $recentPortFilePath -Value "Null"
                    $mostRecentPort = "NULL"
                    Write-Host "Not setting to true because FirstRun is $FirstRun"
                }
            }
        }

        $portList = $currentPortsInfo.GetEnumerator() | ForEach-Object {
            $name = $_.Key
            $description = $_.Value
            $isNew = $name -eq $mostRecentPort
            [PSCustomObject]@{
                Name = $name
                Description = $description
                IsNew = $isNew
            }
        }

        $portList | Export-Csv $listFilePath -NoTypeInformation -Force
        Write-Host "COM port list updated."
    }
}

function CheckAndExit {
    Write-Host "$counter"
    if ($counter % 10 -eq 0) {
        $cmdProcesses = Get-Process cmd -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -like "*Programming Assistant*" }
        if ($cmdProcesses) {
            Write-Host "Programming Assistant is running."
        } else {
            Write-Host "Programming Assistant is not running. Closing..."
            Exit
        }
    }
}

# Infinite loop to continuously monitor COM ports and log changes
while ($true) {
    Start-Sleep -Seconds 3 # Adjust the frequency as needed
    LogComPortsToFile
    $FirstRun = $false
    $counter++
    CheckAndExit
}