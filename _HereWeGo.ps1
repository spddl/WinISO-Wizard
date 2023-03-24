Set-StrictMode -Version 3.0

If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
    # Is not an admin, will restart as admin
    $filename = (Get-ChildItem $PSCommandPath).Name
    $CWD = [Environment]::CurrentDirectory
    Start-Process powershell.exe -ArgumentList ("-NoProfile -NoExit -Command &{cd '$CWD';.\\$filename}") -Verb RunAs
    Exit
}

Get-ChildItem .\DISM -Filter *.psm1 | ForEach-Object {
    Import-Module .\DISM\$_ -Force
}

$Global:ErrorActionPreference = 'Stop'
$Global:VerbosePreference = 'Continue'
$Global:DebugPreference = 'Continue'

$Global:Debug = $false
$Global:OSName = "WinISO_Wizard"

$data = @(
    [pscustomobject]@{ ProjectName = 'W10_22H2_19045.2788'; ISO_Image = '19045.2788.230317-1940.22H2_RELEASE_SVC_PROD3_CLIENTPRO_OEMRET_X64FRE_EN-US.ISO' }
    [pscustomobject]@{ ProjectName = 'W11_22H2_22621.1344'; ISO_Image = '22621.1344.230221-1654.NI_RELEASE_SVC_PROD3_CLIENTPRO_OEMRET_X64FRE_EN-US.ISO' }
    # [pscustomobject]@{ ProjectName = 'IsoName_Beta'; ISO_Image = '1.ISO' }
    # [pscustomobject]@{ ProjectName = 'IsoName_Dev'; ISO_Image = '2.ISO' }
)

foreach ($item in $data) {
    Clear-Variable settings -Scope Global -ErrorAction SilentlyContinue

    $item | Add-Member -MemberType NoteProperty -Name 'ISO_Root' -Value ''
    $item | Add-Member -MemberType NoteProperty -Name Version -Value {}
    $Global:settings = [pscustomobject]$item

    Write-Host ((Get-Date).ToString("HH:mm:ss"), "ISO: $($item.ProjectName) {0:hh}h:{0:mm}m:{0:ss}s" -f (Measure-Command {
        #
        0_Preparation
        1_ISO_unpack

        boot_1_Backup
        boot_2_TPM_ByPass
        boot_3_Dismount_Image

        image_1_Backup
        image_2_extractWIM
        image_3_AppxProvisionedPackage
        image_4_CleanUp
        image_5_AddDotNet
        image_6_CopyFileSystem
        image_7_Registry
        image_8_Dismount_Image

        2_CopyData
        3_ISO_create
        #
    })) -ForegroundColor Yellow
    [gc]::collect()
    [gc]::WaitForPendingFinalizers()
}
