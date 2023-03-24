function image_4_CleanUp {
    Write-Verbose "Start: $($MyInvocation.MyCommand)"
    $RootDir = $Global:settings.ISO_Root

    $deleteFiles = {
        param($path)

        if (-Not (Test-Path -Path $path)) {
            Write-Warning "`"$path`" not found"
            return
        }

        if ($path.GetType() -eq [System.String]) {
            if ($path.Contains("*")) {
                Get-ChildItem -Path $path | ForEach-Object {
                    Invoke-Command $deleteFiles -ArgumentList "$_"
                }
                return
            }
        }

        try {
            # PowerRun
            if ((Get-Item $path) -is [System.IO.DirectoryInfo]) { # Folder
                Start-Process "$RootDir\Tools\PowerRun.exe" -ArgumentList "/SW:0 cmd.exe /c rd /S /Q `"$path`"" -Wait -NoNewWindow
            } else { # File
                Start-Process "$RootDir\Tools\PowerRun.exe" -ArgumentList "/SW:0 cmd.exe /c del /F /S /Q `"$path`"" -Wait -NoNewWindow
            }
            Write-Verbose "DELETE: `"$path`""
        }
        catch {
            Write-Host "`nError Message: " $_.Exception.Message
        }
        finally {
            if (Test-Path -Path $path) {
                Write-Warning "Failed: `"$path`""
            }
        }
    }

    # unwanted files and folders
    @(
        # "Program Files\WindowsApps", better use Remove-AppxProvisionedPackage
        "Program Files\Windows Defender",
        "Program Files (x86)\Windows Defender",
        "Program Files\Windows Defender Advanced Threat Protection",
        "Windows\System32\SecurityHealthAgent.dll",
        "Windows\System32\SecurityHealthService.exe",
        "Windows\System32\SecurityHealthSystray.exe"
    ) | ForEach-Object {
        Invoke-Command $deleteFiles -ArgumentList "$RootDir\extractWIMImage\$_"
    }

    Get-ChildItem -Path "$RootDir\extractWIMImage\ProgramData\Package" -ErrorAction SilentlyContinue -Force |
        Where-Object { $_.Name -ne "MicrosoftWindows.Client.CBS_cw5n1h2txyewy" } |
        ForEach-Object {
            Invoke-Command $deleteFiles -ArgumentList "$RootDir\extractWIMImage\ProgramData\Package\$_"
    }

    Get-ChildItem -Path "$RootDir\extractWIMImage\Users\*\AppData\Local\Microsoft\WindowsApps\" -ErrorAction SilentlyContinue -Force |
        Where-Object { $_.Name -ne "MicrosoftWindows.Client.CBS_cw5n1h2txyewy" } |
        ForEach-Object {
            Invoke-Command $deleteFiles -ArgumentList $_.FullName
    }

    Get-ChildItem -Path "$RootDir\extractWIMImage\Users\*\AppData\Local\Packages\" -ErrorAction SilentlyContinue -Force |
        Where-Object {
            $_.Name -ne "Microsoft.Windows.ShellExperienceHost_cw5n1h2txyewy" -and `
            $_.Name -ne "windows.immersivecontrolpanel_cw5n1h2txyewy" -and `
            $_.Name -ne "MicrosoftWindows.Client.CBS_cw5n1h2txyewy"
        } |
        ForEach-Object {
            Invoke-Command $deleteFiles -ArgumentList $_.FullName
    }

    if ($Global:settings.Version.MAJOR -eq 10 -and $Global:settings.Version.MINOR -eq 0) {
        if ($Global:settings.Version.BUILD -lt 22000) {
            Get-ChildItem -Path "$RootDir\extractWIMImage\Windows\SystemApps" | Where-Object {
                $_.Name -ne "Microsoft.Windows.Search_cw5n1h2txyewy" -and `
                $_.Name -ne "Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy" -and `
                $_.Name -ne "MicrosoftWindows.UndockedDevKit_cw5n1h2txyewy" -and `
                $_.Name -ne "ShellExperienceHost_cw5n1h2txyewy"
            } | ForEach-Object {
                Invoke-Command $deleteFiles -ArgumentList "$RootDir\extractWIMImage\Windows\SystemApps\$_"
            }
        }
        else {
            Get-ChildItem -Path "$RootDir\extractWIMImage\Windows\SystemApps" | Where-Object {
                $_.Name -ne "ShellExperienceHost_cw5n1h2txyewy" -and `
                $_.Name -ne "Microsoft.UI.Xaml.CBS_8wekyb3d8bbwe" -and `
                $_.Name -ne "MicrosoftWindows.Client.CBS_cw5n1h2txyewy" -and `
                $_.Name -ne "MicrosoftWindows.Client.Core_cw5n1h2txyewy" -and `
                $_.Name -ne "Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy"
            } | ForEach-Object {
                Invoke-Command $deleteFiles -ArgumentList "$RootDir\extractWIMImage\Windows\SystemApps\$_"
            }
        }
    }

    $wildcard_names = @(
        "flashplayer",
        "backgroundtaskhost",
        "mobsync",
        "smartscreen",
        "wsclient",
        "wscollect",
        "comppkgsrv",
        "upfc",
        "sihclient",
        "onedrive",
        "mcupdate_authenticamd",
        "mcupdate_genuineintel",
        "skype",
        "edge",
        "securitycenter"
    )
    Get-ChildItem -ErrorAction SilentlyContinue -Force -Path "$RootDir\extractWIMImage\" -Recurse | Where-Object {
        foreach ($name in $wildcard_names) {
            if ($_.FullName -ilike "*$name*" -and -not $_.FullName -ilike "./bin/*") {
                Invoke-Command $deleteFiles -ArgumentList $_.FullName
            }
        }
    }
}

Export-ModuleMember -Function '*'
