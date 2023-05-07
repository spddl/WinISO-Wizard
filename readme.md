###### translation [[PT]](https://github-com.translate.goog/spddl/WinISO-Wizard?_x_tr_sl=en&_x_tr_tl=pt#readme) [[DE]](https://github-com.translate.goog/spddl/WinISO-Wizard?_x_tr_sl=en&_x_tr_tl=de#readme) [[RU]](https://github-com.translate.goog/spddl/WinISO-Wizard?_x_tr_sl=en&_x_tr_tl=ru#readme) [[IT]](https://github-com.translate.goog/spddl/WinISO-Wizard?_x_tr_sl=en&_x_tr_tl=it#readme) [[FR]](https://github-com.translate.goog/spddl/WinISO-Wizard?_x_tr_sl=en&_x_tr_tl=fr#readme)
# WinISO Wizard

This is just a template for editing Windows ISOs, primarily used for Windows 11 ISOs from [UUP dump](https://uupdump.net), other Windows versions from other sources can certainly be edited as well after some modifications. If you want to make modifications please [create a fork](https://github.com/spddl/WinISO-Wizard/fork).

This is not a "menu-driven simple solution for everyone". **You need Powershell and Windows knowledge for this.**
Once the desired preset is created, it is possible to modify one or more ISOs unattended fully automatically.

With this template, you can use [DISM in combination with Powershell](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/use-dism-in-windows-powershell-s14?view=windows-11) and [Powerrun](https://www.sordum.org/9416/powerrun-v1-6-run-with-highest-privileges/) to open the image and customize everything.

For discussion with other users you can use this [Discord server](https://discord.gg/kwu4EkKQ8X)

---

First we need a Windows ISO, if it is not clear which build number from which channel is the latest recommend using the overview [changewindows.org](https://changewindows.org/timeline/pc).

The build number we can search and configure on [UUP dump](https://uupdump.net/).
- Language: (personal preferences)
- Edition: I recommend to select only "Windows Pro"
- Download method: "Download and convert to ISO" with the checkbox "Include updates (Windows converter only)".
We also want to include .Net 3.5 in the ISO later but we will do that afterwards (`DISM\image_5_AddDotNet.psm1`).

For showcase purposes I will take modifications from the [PC-Guide from AMIT](https://github.com/amitxv/PC-Tuning) and [Tweaks from CYNAR](https://github.com/CYNAR2k/Tweaks).

We can change the filesystem and therefore also the registry. Pretty much every setting is in the filesystem or registry so every setting can be changed before the ISO is deployed. And for user dependent settings (e.g. hardware) or settings created by Windows after the installation we use the postinstall. A postinstall is executed only once after the installation. To write/change what could not be changed before.

It is recommended to test a newly created ISO in a VM first (e.g. Oracle VM VirtualBox, Hyper-V or VMware Workstation).

### Short introduction to the folder structure:
<details>
<summary>Folder structure:</summary>

One thing in advance with the `_HereWeGo.ps1` the process is started, but the UUPDump ISO name must be inserted.

* \\_FINISH_ISO
    - The finished ISO will later be in this folder

* \\_UUPdump_ISO
    - The ISO created by UUP Dump belongs here (e.g. `22621.1344.230221-1654.NI_RELEASE_SVC_PROD3_CLIENTPRO_OEMRET_X64FRE_EN-US.ISO`)

* \\DISM

    * `0_Preparation.psm1`
        - here it is checked if the tools and the ISO are existing

    * `1_ISO_unpack.psm1`
        - the ISO is unpacked with 7zip and the Windows version is identified

    * `boot_1_Backup.psm1`
        - The image is copied to the root directory and mounted for customization

    * `boot_2_TPM_ByPass.psm1`
        - Here e.g. imported the TPM bypass and other settings

    * `boot_3_Dismount-Image.psm1`
        - The image is unmounted again

    * `image_1_Backup.psm1`
        - The image is copied to the root directory

    * `image_2_ExtractWIM.psm1`
        - The Windows image is mounted for customization

    * `image_3_AppxProvisionedPackage.psm1`
        - removes provisioned packages and turns off unnecessary windows features

    * `image_4_CleanUp.psm1`
        - Deletes files/folders that are left

    * `image_5_AddDotNet.psm1`
        - installs NetFx3

    * `image_6_CopyFileSystem.psm1`
        - Copies the "FileSystem" folder with our new files

    * `image_7_Registry.psm1`
        - Applies the registry files from the "Registry" folder

    * `image_8_Dismount-Image.psm1`
        - unmounted the image again

    * `2_CopyData.psm1`
        - replaces the original data (boot/image) with the modified ones

    * `3_ISO_create.psm1`
        - creates the ISO and creates a SHA-256 HASH value and renames the ISO with it.

* \\FileSystem
    - Here you can place files that should be found later after the Windows installation.

* \\Registry
    - The registry files in the folder are always applied, those in the `various` folder are applied only if the WinVer matches. The function `consonance` in `DISM\helper.psm1` helps to understand how the format must look like.

* \\Tools
    - Here are the tools that will be used
</details>

### Maybe helpful Windows basics:

<details>
<summary>OOBE</summary>

If you want to abbreviate the OOBE and don't know how to use an [autounattend.xml generator](https://www.google.com/search?q=autounattend.xml+generator). [documentation](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/update-windows-settings-and-scripts-create-your-own-answer-file-sxs)

</details>


<details>
<summary>Registry</summary>

It is possible to modify any part of the registry. It should be clear that we need to understand the structure and write the registry values to the correct file. [documentation](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry-hives)

For example, it is necessary to divide some paths by registry location. HKLM\Software get a file in the Registry folder and HKLM\System get another file in this folder. Later in the process both are written to different files (Windows\System32\config\SOFTWARE & SYSTEM).
</details>


<details>
<summary>FileSystem</summary>

The FileSystem is fully accessible and with the help of PowerRun files are fully editable even with TrustedInstaller.

The files and folders to be deleted can be specified in the `DISM\image_4_CleanUp.psm1` file
</details>


<details>
<summary>PostInstall Possibilities</summary>

The easiest way to find out which Registry values were not included is to check the Registry files after the Windows installation with [RegFileChecker](https://github.com/spddl/RegFileChecker). These should be included in the PostInstall.

**Works once**:
* HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\RunOnce ([documentation](https://learn.microsoft.com/en-us/windows/win32/setupapi/run-and-runonce-registry-keys))
* HKEY_LOCAL_MACHINE\Software\Microsoft\Active Setup\Installed Components ([unofficial documentation](https://helgeklein.com/blog/active-setup-explained/))

**Works every time you start**:

* Users\\%user%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup
* HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run ([documentation](https://learn.microsoft.com/en-us/windows/win32/setupapi/run-and-runonce-registry-keys))

services/drivers and task scheduler are other possibilities but not so easy to implement
</details>

The main tools in this project are:
* Powershell with the DISM library ([documentation](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/use-dism-in-windows-powershell-s14))
* Oscdimg ([documentation](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/oscdimg-command-line-options))
* GoOfflineReg (include) ([repo](https://github.com/spddl/GoOfflineReg))
* 7zip (include) ([homepage](https://www.7-zip.org))
* PowerRun (include) ([homepage](https://www.sordum.org/9416/powerrun-v1-6-run-with-highest-privileges/)) (alternatively NSudo, NanaRun would surely work as well)
