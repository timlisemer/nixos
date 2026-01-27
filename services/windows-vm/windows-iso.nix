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

    # Create ISO (suppress verbose output)
    ${pkgs.xorriso}/bin/xorriso -as mkisofs \
      -quiet \
      -o "${autounattendIso}" \
      -joliet -joliet-long -rock \
      -volid "AUTOUNATTEND" \
      "$WORK_DIR" 2>/dev/null
  '';

  # Windows ISO download script using UUPDump
  # Downloads UUP files from Microsoft Update servers and converts to ISO
  # This bypasses the consumer download API which has IP-based blocking
  windowsDownloadScript = pkgs.writeShellScript "download-windows-iso" ''
    set -u

    ISO_DIR="${isoDir}"
    WINDOWS_ISO="${windowsIso}"
    VIRTIO_ISO="${virtioIso}"
    AUTOUNATTEND_ISO="${autounattendIso}"
    WORK_DIR="/var/lib/libvirt/uup-work"

    # Add required tools to PATH for UUPDump converter
    export PATH="${pkgs.cabextract}/bin:${pkgs.wimlib}/bin:${pkgs.chntpw}/bin:${pkgs.cdrtools}/bin:${pkgs.aria2}/bin:$PATH"

    log() {
      echo "[windows-iso] $1"
    }

    err() {
      echo "[windows-iso] ERROR: $1" >&2
    }

    # Skip if all ISOs already exist
    if [ -f "$WINDOWS_ISO" ] && [ -f "$VIRTIO_ISO" ] && [ -f "$AUTOUNATTEND_ISO" ]; then
      exit 0
    fi

    # Create directories
    mkdir -p "$ISO_DIR"
    mkdir -p "$WORK_DIR"

    # Download VirtIO drivers if not present
    if [ ! -f "$VIRTIO_ISO" ]; then
      log "Downloading VirtIO drivers..."
      ${pkgs.aria2}/bin/aria2c -x 16 -s 16 -d "$ISO_DIR" -o "virtio-win.iso" "${virtioUrl}" || {
        err "Failed to download VirtIO drivers"
        exit 1
      }
    fi

    # Create autounattend ISO if not present
    if [ ! -f "$AUTOUNATTEND_ISO" ]; then
      ${createAutounattendIso} || {
        err "Failed to create autounattend ISO"
        exit 1
      }
    fi

    # Check if Windows ISO already exists
    if [ -f "$WINDOWS_ISO" ]; then
      exit 0
    fi

    log "Downloading Windows 11 ISO via UUPDump..."

    # Step 1: Query UUPDump API for latest Windows 11 24H2 build
    log "Finding latest Windows 11 24H2 build..."
    BUILDS_JSON=$(${pkgs.curl}/bin/curl -sL "https://uupdump.net/json-api/listid.php") || {
      err "Failed to fetch UUPDump build list"
      exit 1
    }

    # Find latest Windows 11 24H2 (26100.x) amd64 build
    BUILD_UUID=$(echo "$BUILDS_JSON" | ${pkgs.jq}/bin/jq -r '
      [.response.builds[] |
        select(
          (.build | startswith("26100")) and
          .arch == "amd64" and
          (.title | contains("Windows 11, version 24H2"))
        )
      ] | .[0].uuid // empty
    ')

    if [ -z "$BUILD_UUID" ]; then
      err "Could not find Windows 11 24H2 build on UUPDump"
      exit 1
    fi

    BUILD_INFO=$(echo "$BUILDS_JSON" | ${pkgs.jq}/bin/jq -r ".response.builds[] | select(.uuid == \"$BUILD_UUID\") | \"\(.title) (\(.build))\"")
    log "Found: $BUILD_INFO"

    # Step 2: Download the UUPDump package (contains converter scripts)
    log "Downloading UUPDump converter package..."
    PACK_FILE="$WORK_DIR/uup_package.zip"
    ${pkgs.curl}/bin/curl -sL -X POST \
      "https://uupdump.net/get.php?id=$BUILD_UUID&pack=en-us&edition=professional" \
      -d "autodl=2" \
      -o "$PACK_FILE" || {
      err "Failed to download UUPDump package"
      exit 1
    }

    # Extract the package
    rm -rf "$WORK_DIR/uup_extract"
    ${pkgs.unzip}/bin/unzip -q -o "$PACK_FILE" -d "$WORK_DIR/uup_extract" || {
      err "Failed to extract UUPDump package"
      exit 1
    }

    # Download the aria2 script with file URLs
    log "Fetching download manifest..."
    ARIA2_SCRIPT="$WORK_DIR/uup_extract/aria2_script.txt"
    ${pkgs.curl}/bin/curl -sL \
      "https://uupdump.net/get.php?id=$BUILD_UUID&pack=en-us&edition=professional&aria2=2" \
      -o "$ARIA2_SCRIPT"

    # Check if we got rate limited (HTML instead of aria2 script)
    if ! ${pkgs.gnugrep}/bin/grep -q '^https://' "$ARIA2_SCRIPT" 2>/dev/null; then
      err "Rate limited by UUPDump. Try again in a few minutes."
      exit 1
    fi

    # Check for UUPDump errors
    if ${pkgs.gnugrep}/bin/grep -q '#UUPDUMP_ERROR:' "$ARIA2_SCRIPT"; then
      ERROR_MSG=$(${pkgs.gnugrep}/bin/grep '#UUPDUMP_ERROR:' "$ARIA2_SCRIPT" | ${pkgs.gnused}/bin/sed 's/#UUPDUMP_ERROR://g')
      err "UUPDump error: $ERROR_MSG"
      exit 1
    fi

    FILE_COUNT=$(${pkgs.gnugrep}/bin/grep -c '^https://' "$ARIA2_SCRIPT" || echo "0")
    log "Downloading $FILE_COUNT UUP files..."

    # Download converter tools
    CONVERTER_LIST="$WORK_DIR/uup_extract/files/converter_multi"
    if [ -f "$CONVERTER_LIST" ]; then
      ${pkgs.aria2}/bin/aria2c --no-conf \
        --console-log-level=error \
        --summary-interval=0 \
        -x16 -s16 -j2 \
        --allow-overwrite=true \
        --auto-file-renaming=false \
        -d "$WORK_DIR/uup_extract/files" \
        -i "$CONVERTER_LIST" || {
        err "Failed to download converter tools"
        exit 1
      }
    fi

    # Download all UUP files
    UUP_DIR="$WORK_DIR/uup_extract/UUPs"
    mkdir -p "$UUP_DIR"
    ${pkgs.aria2}/bin/aria2c --no-conf \
      --console-log-level=warn \
      --summary-interval=60 \
      -x16 -s16 -j5 \
      -c -R \
      --allow-overwrite=true \
      --auto-file-renaming=false \
      -d "$UUP_DIR" \
      -i "$ARIA2_SCRIPT" || {
      err "Failed to download UUP files"
      exit 1
    }

    # Convert UUP files to ISO
    log "Converting to ISO (this takes several minutes)..."
    CONVERT_SCRIPT="$WORK_DIR/uup_extract/files/convert.sh"
    if [ -f "$CONVERT_SCRIPT" ]; then
      chmod +x "$CONVERT_SCRIPT"

      # Run the converter with bash explicitly (NixOS has no /bin/bash)
      (
        cd "$WORK_DIR/uup_extract"
        ${pkgs.bash}/bin/bash ./files/convert.sh wim "$UUP_DIR" 0
      ) || {
        err "ISO conversion failed"
        exit 1
      }
    else
      err "Converter script not found"
      exit 1
    fi

    # Find and move the generated ISO
    GENERATED_ISO=$(find "$WORK_DIR/uup_extract" -maxdepth 1 -name "*.iso" -type f 2>/dev/null | ${pkgs.coreutils}/bin/head -1)

    if [ -z "$GENERATED_ISO" ] || [ ! -f "$GENERATED_ISO" ]; then
      err "No ISO file was generated. Check logs in $WORK_DIR"
      exit 1
    fi

    ISO_SIZE=$(${pkgs.coreutils}/bin/stat -c%s "$GENERATED_ISO")

    # Verify size (should be > 4GB)
    MIN_SIZE=4000000000
    if [ "$ISO_SIZE" -lt "$MIN_SIZE" ]; then
      err "Generated ISO is too small ($ISO_SIZE bytes). Expected > 4GB."
      exit 1
    fi

    # Move to final location
    mv "$GENERATED_ISO" "$WINDOWS_ISO" || {
      err "Failed to move ISO to final location"
      exit 1
    }

    # Cleanup work directory
    rm -rf "$UUP_DIR"
    rm -f "$PACK_FILE"

    log "Windows 11 ISO created: $WINDOWS_ISO ($(($ISO_SIZE / 1024 / 1024 / 1024))GB)"
  '';
in {
  # Activation script for ISO download (blocking, runs during activation)
  activationScript = {
    text = ''
      # Skip silently if all ISOs present
      if [ -f "${windowsIso}" ] && [ -f "${virtioIso}" ] && [ -f "${autounattendIso}" ]; then
        exit 0
      fi

      ${pkgs.coreutils}/bin/mkdir -p "${isoDir}"

      # Run the download script directly (blocking)
      if ! ${windowsDownloadScript}; then
        echo "[windows-iso] Download failed"
      fi
    '';
    deps = [];
  };

  # Export paths for use in VM XML
  inherit windowsIso virtioIso autounattendIso isoDir;
}
