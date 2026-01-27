{
  config,
  pkgs,
  lib,
  cfg,
}: let
  isoDir = "/var/lib/libvirt/images";
  windowsIso = "${isoDir}/windows11.iso";
  virtioIso = "${isoDir}/virtio-win.iso";
  autounattendIso = "${isoDir}/autounattend.iso";

  # VirtIO drivers ISO URL (stable release)
  virtioUrl = "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso";

  # Autounattend.xml for Windows 11 unattended installation
  # Bypasses Microsoft account, TPM checks, and OOBE
  autounattendXml = pkgs.writeText "autounattend.xml" ''
    <?xml version="1.0" encoding="utf-8"?>
    <unattend xmlns="urn:schemas-microsoft-com:unattend">
      <settings pass="windowsPE">
        <component name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
          <SetupUILanguage>
            <UILanguage>en-US</UILanguage>
          </SetupUILanguage>
          <InputLocale>0409:00000409</InputLocale>
          <SystemLocale>en-US</SystemLocale>
          <UILanguage>en-US</UILanguage>
          <UserLocale>en-US</UserLocale>
        </component>
        <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
          <DiskConfiguration>
            <Disk wcm:action="add">
              <CreatePartitions>
                <CreatePartition wcm:action="add">
                  <Order>1</Order>
                  <Type>EFI</Type>
                  <Size>512</Size>
                </CreatePartition>
                <CreatePartition wcm:action="add">
                  <Order>2</Order>
                  <Type>MSR</Type>
                  <Size>128</Size>
                </CreatePartition>
                <CreatePartition wcm:action="add">
                  <Order>3</Order>
                  <Type>Primary</Type>
                  <Extend>true</Extend>
                </CreatePartition>
              </CreatePartitions>
              <ModifyPartitions>
                <ModifyPartition wcm:action="add">
                  <Order>1</Order>
                  <PartitionID>1</PartitionID>
                  <Format>FAT32</Format>
                  <Label>System</Label>
                </ModifyPartition>
                <ModifyPartition wcm:action="add">
                  <Order>2</Order>
                  <PartitionID>2</PartitionID>
                </ModifyPartition>
                <ModifyPartition wcm:action="add">
                  <Order>3</Order>
                  <PartitionID>3</PartitionID>
                  <Format>NTFS</Format>
                  <Label>Windows</Label>
                  <Letter>C</Letter>
                </ModifyPartition>
              </ModifyPartitions>
              <DiskID>0</DiskID>
              <WillWipeDisk>true</WillWipeDisk>
            </Disk>
          </DiskConfiguration>
          <ImageInstall>
            <OSImage>
              <InstallTo>
                <DiskID>0</DiskID>
                <PartitionID>3</PartitionID>
              </InstallTo>
              <InstallToAvailablePartition>false</InstallToAvailablePartition>
            </OSImage>
          </ImageInstall>
          <UserData>
            <AcceptEula>true</AcceptEula>
            <ProductKey>
              <Key></Key>
              <WillShowUI>OnError</WillShowUI>
            </ProductKey>
          </UserData>
          <RunSynchronous>
            <RunSynchronousCommand wcm:action="add">
              <Order>1</Order>
              <Path>reg add HKLM\SYSTEM\Setup\LabConfig /v BypassTPMCheck /t REG_DWORD /d 1 /f</Path>
            </RunSynchronousCommand>
            <RunSynchronousCommand wcm:action="add">
              <Order>2</Order>
              <Path>reg add HKLM\SYSTEM\Setup\LabConfig /v BypassSecureBootCheck /t REG_DWORD /d 1 /f</Path>
            </RunSynchronousCommand>
            <RunSynchronousCommand wcm:action="add">
              <Order>3</Order>
              <Path>reg add HKLM\SYSTEM\Setup\LabConfig /v BypassRAMCheck /t REG_DWORD /d 1 /f</Path>
            </RunSynchronousCommand>
            <RunSynchronousCommand wcm:action="add">
              <Order>4</Order>
              <Path>reg add HKLM\SYSTEM\Setup\LabConfig /v BypassCPUCheck /t REG_DWORD /d 1 /f</Path>
            </RunSynchronousCommand>
          </RunSynchronous>
        </component>
      </settings>
      <settings pass="specialize">
        <component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
          <RunSynchronous>
            <RunSynchronousCommand wcm:action="add">
              <Order>1</Order>
              <Path>reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE" /v BypassNRO /t REG_DWORD /d 1 /f</Path>
            </RunSynchronousCommand>
            <RunSynchronousCommand wcm:action="add">
              <Order>2</Order>
              <Path>cmd /c echo. &gt; C:\Windows\System32\OOBE\BYPASSNRO</Path>
            </RunSynchronousCommand>
          </RunSynchronous>
        </component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
          <ComputerName>WINDOWS-VM</ComputerName>
          <TimeZone>W. Europe Standard Time</TimeZone>
        </component>
      </settings>
      <settings pass="oobeSystem">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
          <OOBE>
            <HideEULAPage>true</HideEULAPage>
            <HideLocalAccountScreen>false</HideLocalAccountScreen>
            <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
            <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
            <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
            <ProtectYourPC>3</ProtectYourPC>
            <SkipMachineOOBE>false</SkipMachineOOBE>
            <SkipUserOOBE>false</SkipUserOOBE>
          </OOBE>
          <UserAccounts>
            <LocalAccounts>
              <LocalAccount wcm:action="add">
                <Name>${cfg.username}</Name>
                <DisplayName>${cfg.username}</DisplayName>
                <Group>Administrators</Group>
                <Password>
                  <Value>${cfg.password}</Value>
                  <PlainText>true</PlainText>
                </Password>
              </LocalAccount>
            </LocalAccounts>
          </UserAccounts>
          <AutoLogon>
            <Enabled>true</Enabled>
            <Username>${cfg.username}</Username>
            <Password>
              <Value>${cfg.password}</Value>
              <PlainText>true</PlainText>
            </Password>
            <LogonCount>1</LogonCount>
          </AutoLogon>
          <FirstLogonCommands>
            <SynchronousCommand wcm:action="add">
              <Order>1</Order>
              <CommandLine>powershell -Command "Set-ExecutionPolicy Bypass -Scope LocalMachine -Force"</CommandLine>
            </SynchronousCommand>
            <SynchronousCommand wcm:action="add">
              <Order>2</Order>
              <CommandLine>E:\virtio-win-guest-tools.exe /S</CommandLine>
              <Description>Install VirtIO Guest Tools</Description>
            </SynchronousCommand>
          </FirstLogonCommands>
        </component>
        <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
          <InputLocale>0407:00000407</InputLocale>
          <SystemLocale>de-DE</SystemLocale>
          <UILanguage>en-US</UILanguage>
          <UserLocale>de-DE</UserLocale>
        </component>
      </settings>
    </unattend>
  '';

  # Script to create autounattend ISO
  createAutounattendIso = pkgs.writeShellScript "create-autounattend-iso" ''
    set -euo pipefail

    WORK_DIR=$(mktemp -d)
    trap "rm -rf $WORK_DIR" EXIT

    # Copy autounattend.xml
    cp ${autounattendXml} "$WORK_DIR/autounattend.xml"

    # Create ISO
    ${pkgs.xorriso}/bin/xorriso -as mkisofs \
      -o "${autounattendIso}" \
      -joliet -joliet-long -rock \
      -volid "AUTOUNATTEND" \
      "$WORK_DIR"
  '';

  # UUP dump download script
  uupDumpScript = pkgs.writeShellScript "download-windows-iso" ''
    set -euo pipefail

    ISO_DIR="${isoDir}"
    WINDOWS_ISO="${windowsIso}"
    VIRTIO_ISO="${virtioIso}"
    AUTOUNATTEND_ISO="${autounattendIso}"

    log() {
      echo "[windows-iso] $1" | ${pkgs.systemd}/bin/systemd-cat -t windows-iso -p info
      echo "[windows-iso] $1"
    }

    # Create directory
    mkdir -p "$ISO_DIR"

    # Download VirtIO drivers if not present
    if [ ! -f "$VIRTIO_ISO" ]; then
      log "Downloading VirtIO drivers..."
      ${pkgs.aria2}/bin/aria2c -x 16 -s 16 -d "$ISO_DIR" -o "virtio-win.iso" "${virtioUrl}"
    else
      log "VirtIO drivers ISO already exists."
    fi

    # Create autounattend ISO
    log "Creating autounattend ISO..."
    ${createAutounattendIso}

    # Check if Windows ISO already exists
    if [ -f "$WINDOWS_ISO" ]; then
      log "Windows 11 ISO already exists at $WINDOWS_ISO"
      exit 0
    fi

    # Download Windows 11 ISO using UUP dump
    log "Windows 11 ISO not found. Starting download via UUP dump..."

    WORK_DIR=$(mktemp -d)
    trap "rm -rf $WORK_DIR" EXIT
    cd "$WORK_DIR"

    # Download UUP dump converter script
    log "Downloading UUP dump converter..."
    ${pkgs.curl}/bin/curl -sL "https://uupdump.net/get.php?id=aadb9ec7-e8a6-4f89-ad16-caa0ec60cef0&pack=en-us&edition=professional" -o uup_download_linux.sh 2>/dev/null || {
      # Fallback: Direct download from MediaCreationTool
      log "UUP dump failed, using direct Microsoft download..."

      # Use the Windows 11 download page API
      ${pkgs.curl}/bin/curl -sL \
        "https://www.microsoft.com/en-us/software-download/windows11" \
        -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:100.0) Gecko/20100101 Firefox/100.0" \
        -o download_page.html

      log "Please manually download Windows 11 ISO from:"
      log "https://www.microsoft.com/en-us/software-download/windows11"
      log "And place it at: $WINDOWS_ISO"
      exit 1
    }

    # Run the download script
    chmod +x uup_download_linux.sh
    ./uup_download_linux.sh || {
      log "Download script failed. Manual download required."
      log "Visit: https://uupdump.net/"
      log "Place the ISO at: $WINDOWS_ISO"
      exit 1
    }

    # Move the generated ISO
    ISO_FILE=$(find . -name "*.iso" -type f | head -1)
    if [ -n "$ISO_FILE" ]; then
      mv "$ISO_FILE" "$WINDOWS_ISO"
      log "Windows 11 ISO downloaded successfully to $WINDOWS_ISO"
    else
      log "No ISO file generated. Check UUP dump logs."
      exit 1
    fi
  '';
in {
  # Activation script for ISO download (non-blocking)
  activationScript = {
    text = ''
      LOCK_FILE="${isoDir}/.windows-iso-download.lock"

      # Skip if all ISOs present
      if [ -f "${windowsIso}" ] && [ -f "${virtioIso}" ] && [ -f "${autounattendIso}" ]; then
        echo "[windows-iso] All ISOs present - skipping"
        exit 0
      fi

      # Check for in-progress download (lock file with live PID)
      if [ -f "$LOCK_FILE" ]; then
        PID=$(${pkgs.coreutils}/bin/cat "$LOCK_FILE" 2>/dev/null)
        if [ -n "$PID" ] && ${pkgs.coreutils}/bin/kill -0 "$PID" 2>/dev/null; then
          echo "[windows-iso] Download already in progress (PID $PID)"
          exit 0
        fi
        ${pkgs.coreutils}/bin/rm -f "$LOCK_FILE"
      fi

      echo "[windows-iso] Starting download in background..."
      echo "[windows-iso] Monitor: journalctl -t windows-iso -f"

      # Spawn detached background process
      (
        echo $$ > "$LOCK_FILE"
        trap '${pkgs.coreutils}/bin/rm -f "$LOCK_FILE"' EXIT

        # Redirect to journal
        exec > >(${pkgs.systemd}/bin/systemd-cat -t windows-iso -p info)
        exec 2> >(${pkgs.systemd}/bin/systemd-cat -t windows-iso -p err)

        # Wait for network before downloading
        ${pkgs.systemd}/bin/systemctl is-active --quiet network-online.target || \
          ${pkgs.systemd}/bin/systemctl start --wait network-online.target 2>/dev/null || true

        ${uupDumpScript}

        echo "[windows-iso] Download complete"
      ) &
      ${pkgs.coreutils}/bin/disown
    '';
    deps = [];
  };

  # Export paths for use in VM XML
  inherit windowsIso virtioIso autounattendIso isoDir;
}
