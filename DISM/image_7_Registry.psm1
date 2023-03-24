function image_7_Registry {
	Write-Verbose "Start: $($MyInvocation.MyCommand)"
	$RootDir = $Global:settings.ISO_Root
	$Version = $Global:settings.Version
	$OSName = $Global:OSName

	Write-Host "Registry..."
	Write-Host ("Registry: {0:hh}h:{0:mm}m:{0:ss}s" -f (Measure-Command {
		$HKCU_RegFiles = "`"$RootDir\Registry\HKCU.reg`""
		$HKU_DEFAULT_RegFiles = "`"$RootDir\Registry\HKU_DEFAULT.reg`""
		$SYSTEM_RegFiles = "`"$RootDir\Registry\HKLM_SYSTEM.reg`""
		$SOFTWARE_RegFiles = "`"$RootDir\Registry\HKCR.reg`",`"$RootDir\Registry\HKLM_SOFTWARE.reg`""

		if (Test-Path -Path "$RootDir\Registry\HKLM_SOFTWARE_ProvisionedApps.reg" -PathType Leaf) {
			# Registry keys for provisioned apps https://docs.microsoft.com/en-us/windows/application-management/remove-provisioned-apps-during-update#registry-keys-for-provisioned-apps
			$SOFTWARE_RegFiles += ",`"$RootDir\Registry\HKLM_SOFTWARE_ProvisionedApps.reg`""
		}

		Get-ChildItem -Path "$RootDir\Registry\various" | ForEach-Object {
			$vers = ""
			$splits = ""
			if ($_.Name.Contains("#")) {
				$splits = $_.Name.Split("#")
				$vers = $splits[0]
			}
			else {
				Write-Error "invalid file $_"
				continue
			}

			$verSplit = $vers.Split(".")

			$script:skip = $false
			for ($index = 0; $index -lt $verSplit.count; $index++) {
				$result = switch($index) {
					0 { consonance $Version.MAJOR $verSplit[$index] }
					1 { consonance $Version.MINOR $verSplit[$index] }
					2 { consonance $Version.BUILD $verSplit[$index] }
					3 { consonance $Version.SPBUILD $verSplit[$index] }
					4 { consonance $Version.SPLEVEL $verSplit[$index] }
				}
				if (-Not $result) {
					$script:skip = $true
					break
				}
			}
			if ($script:skip) {
				Write-Host "$($_.Name) is ignored" -ForegroundColor DarkGray
				return
			}

			Write-Host "$($_.Name) is accepted" -ForegroundColor Green
			if ($splits[1] -eq "HKCU") {
				$HKCU_RegFiles += ",`"$RootDir\Registry\various\$($_.Name)`""
			}
			elseif ($splits[1] -eq "HKU") {
				$HKU_DEFAULT_RegFiles += ",`"$RootDir\Registry\various\$($_.Name)`""
			}
			elseif ($splits[1] -eq "HKLM_SYSTEM") {
				$SYSTEM_RegFiles += ",`"$RootDir\Registry\various\$($_.Name)`""
			}
			elseif ($splits[1] -eq "HKCR" -or $splits[1] -eq "HKLM_SOFTWARE") {
				$SOFTWARE_RegFiles += ",`"$RootDir\Registry\various\$($_.Name)`""
			}
			else {
				Write-Error "invalid file $_"
			}
		}

		Start-Process $RootDir\Tools\GoOfflineReg.exe -ArgumentList "-path `"$RootDir\extractWIMImage\Users\Default\NTUSER.DAT`" -import $HKCU_RegFiles -commit" -NoNewWindow -Wait
		Start-Process $RootDir\Tools\GoOfflineReg.exe -ArgumentList "-path `"$RootDir\extractWIMImage\Windows\System32\config\DEFAULT`" -import $HKU_DEFAULT_RegFiles -commit" -NoNewWindow -Wait
		Start-Process $RootDir\Tools\GoOfflineReg.exe -ArgumentList "-path `"$RootDir\extractWIMImage\Windows\System32\config\SYSTEM`" -import $SYSTEM_RegFiles -commit" -NoNewWindow -Wait
		Start-Process $RootDir\Tools\GoOfflineReg.exe -ArgumentList "-path `"$RootDir\extractWIMImage\Windows\System32\config\SOFTWARE`" -import $SOFTWARE_RegFiles -commit" -NoNewWindow -Wait
	})) -ForegroundColor Yellow

	[gc]::collect()
	[gc]::WaitForPendingFinalizers()
}

Export-ModuleMember -Function '*'