param (
    [switch]$install,
    [switch]$shortcut
)

function Download-Files($items, $basePath = "") {
    foreach ($item in $items) {
        if ($item.type -eq "file") {
            $filePath = if ($basePath) { "$basePath\$($item.name)" } else { $item.name }
            $downloadUrl = $item.download_url
            $outputDirectory = "$folderPath\$basePath"
            $outputFile = Join-Path -Path $outputDirectory -ChildPath $item.name
            New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
            Invoke-WebRequest -Uri $downloadUrl -OutFile $outputFile
        }
        elseif ($item.type -eq "dir") {
            $subFolderPath = if ($basePath) { "$basePath\$($item.name)" } else { $item.name }
            $subItemsUrl = $item.url
            $subItems = Invoke-RestMethod -Uri $subItemsUrl
            Download-Files $subItems $subFolderPath
        }
    }
}

function CreateShortcut($targetPath, $arguement, $shortcutPath, $iconPath) {
    $LogoURL = "https://raw.githubusercontent.com/eaaasun/CCStopper/dev/runFromWeb/icon.ico"
    Invoke-WebRequest -Uri $LogoURL -OutFile "$folderPath\icon.ico" -UseBasicParsing
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($shortcutPath)
    if ($arguement) {
        $Shortcut.Arguments = $arguement
    }
    $Shortcut.TargetPath = $targetPath
    $Shortcut.IconLocation = $iconPath
    $Shortcut.Save()
}

$apiUrl = "https://api.github.com/repos/eaaasun/CCStopper/contents/localScripts?ref=dev"

if ($install) {
    $folderPath = "$env:ProgramFiles\CCStopper"
    # check if $folderPath exists
    if (Test-Path -Path $folderPath) {
        Write-Host "CCStopper is already installed! Would you like to uninstall it?"
        $response = Read-Host "Y/N"
        if ($response -eq "Y") {
            Write-Host "Uninstalling CCStopper..."
            Remove-Item -Path $folderPath -Recurse -Force
            Write-Host "Uninstalled CCStopper! Goodbye!"
            pause
            exit
        }
        else {
            exit
        }
    }
    $items = Invoke-RestMethod -Uri $apiUrl
    Download-Files $items
    CreateShortcut -targetPath "$folderPath\CCStopper.bat" -shortcutPath "$env:USERPROFILE\Desktop\CCStopper.lnk" -iconPath "$folderPath\icon.ico"
}
elseif ($shortcut) {
    $folderPath = "$env:ProgramFiles\CCStopper"
    CreateShortcut -targetPath "powershell.exe" -arguement "-command ""irm https://ccstopper.netlify.app/run | iex""" -shortcutPath "$env:USERPROFILE\Desktop\CCStopper (Online).lnk" -iconPath "$folderPath\icon.ico"
    exit
}
else {
    $folderPath = "$env:TEMP\CCStopper"
    $response = Invoke-RestMethod -Uri $apiUrl
    Download-Files $response
    # start CCStopper.bat 
    Write-Host "Starting CCStopper..."
    Start-Process -FilePath "$folderPath\CCStopper.bat" -Wait
    Write-Host "Cleaning up..."
    # delete temp folder
    Remove-Item -Path $folderPath -Recurse -Force
    Write-Host "Cleaned up! Goodbye!"
    
}