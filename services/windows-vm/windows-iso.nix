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

  # Windows ISO download script using Microsoft's direct download API
  windowsDownloadScript = pkgs.writeShellScript "download-windows-iso" ''
    set -u  # Only error on unset variables, not on command failures

    ISO_DIR="${isoDir}"
    WINDOWS_ISO="${windowsIso}"
    VIRTIO_ISO="${virtioIso}"
    AUTOUNATTEND_ISO="${autounattendIso}"

    log() {
      echo "[windows-iso] $1"
    }

    err() {
      echo "[windows-iso] ERROR: $1" >&2
    }

    # Create directory
    mkdir -p "$ISO_DIR"

    # Download VirtIO drivers if not present
    if [ ! -f "$VIRTIO_ISO" ]; then
      log "Downloading VirtIO drivers..."
      ${pkgs.aria2}/bin/aria2c -x 16 -s 16 -d "$ISO_DIR" -o "virtio-win.iso" "${virtioUrl}" || {
        err "Failed to download VirtIO drivers"
        exit 1
      }
    else
      log "VirtIO drivers ISO already exists."
    fi

    # Create autounattend ISO
    log "Creating autounattend ISO..."
    ${createAutounattendIso} || {
      err "Failed to create autounattend ISO"
      exit 1
    }

    # Check if Windows ISO already exists
    if [ -f "$WINDOWS_ISO" ]; then
      log "Windows 11 ISO already exists at $WINDOWS_ISO"
      exit 0
    fi

    log "Windows 11 ISO not found. Starting download from Microsoft..."

    WORK_DIR=$(mktemp -d)
    trap "rm -rf $WORK_DIR" EXIT
    cd "$WORK_DIR"

    # Fido-style download using Microsoft's official API
    # Reference: https://github.com/pbatard/Fido
    USER_AGENT="Mozilla/5.0 (X11; Linux x86_64; rv:100.0) Gecko/20100101 Firefox/100.0"
    DOWNLOAD_URL=""

    log "Using Microsoft's official download API (Fido method)..."

    # Windows 11 product info
    WINDOWS_VERSION="11"
    LANG_CODE="English"
    ARCH="x64"

    # Step 1: Get the download page and extract session data
    log "Step 1: Fetching download page..."
    DOWNLOAD_PAGE_URL="https://www.microsoft.com/en-us/software-download/windows11"

    # Get initial page to establish session
    COOKIES=$(mktemp)
    trap "rm -f $COOKIES" EXIT

    ${pkgs.curl}/bin/curl -s -L -c "$COOKIES" -b "$COOKIES" \
      -H "User-Agent: $USER_AGENT" \
      -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
      -o /dev/null \
      "$DOWNLOAD_PAGE_URL" || true

    # Step 2: Request the download with product ID for Windows 11
    log "Step 2: Requesting product download..."

    # Windows 11 multi-edition ISO
    PRODUCT_EDITION_ID="2935"

    LANG_RESPONSE=$(${pkgs.curl}/bin/curl -s -L -c "$COOKIES" -b "$COOKIES" \
      -H "User-Agent: $USER_AGENT" \
      -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
      -H "Referer: $DOWNLOAD_PAGE_URL" \
      -X POST \
      -d "profile=retail" \
      -d "productEditionId=$PRODUCT_EDITION_ID" \
      -d "SKU=professional" \
      "https://www.microsoft.com/en-us/api/controls/contentinclude/html?pageId=a8f8f489-4c7f-463a-9ca6-5cff94d8d041&host=www.microsoft.com&segments=software-download,windows11&query=&action=getskuinformationbyproductedition" 2>&1) || true

    log "Language response length: ''${#LANG_RESPONSE} bytes"

    # Extract SKU ID for English
    SKU_ID=$(echo "$LANG_RESPONSE" | ${pkgs.gnugrep}/bin/grep -oP 'value="\K[0-9]+' | ${pkgs.coreutils}/bin/tail -1) || true

    if [ -z "$SKU_ID" ]; then
      log "Could not extract SKU ID from Microsoft response, trying alternative..."
      # Fallback: Use known SKU ID for Windows 11 English
      SKU_ID="2936"
    fi
    log "Using SKU ID: $SKU_ID"

    # Step 3: Get the actual download link
    log "Step 3: Requesting download link..."

    DOWNLOAD_RESPONSE=$(${pkgs.curl}/bin/curl -s -L -c "$COOKIES" -b "$COOKIES" \
      -H "User-Agent: $USER_AGENT" \
      -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
      -H "Referer: $DOWNLOAD_PAGE_URL" \
      -X POST \
      -d "profile=retail" \
      -d "SKU=$SKU_ID" \
      -d "Language=English" \
      "https://www.microsoft.com/en-us/api/controls/contentinclude/html?pageId=cfa9e580-a81e-4a4b-a846-7b21bf4e2e5b&host=www.microsoft.com&segments=software-download,windows11&query=&action=GetProductDownloadLinksBySku" 2>&1) || true

    log "Download response length: ''${#DOWNLOAD_RESPONSE} bytes"

    # Extract the ISO download URL (look for 64-bit)
    DOWNLOAD_URL=$(echo "$DOWNLOAD_RESPONSE" | ${pkgs.gnugrep}/bin/grep -oP 'https://software[^"]+x64[^"]+\.iso' | ${pkgs.coreutils}/bin/tail -1) || true

    if [ -z "$DOWNLOAD_URL" ]; then
      # Try alternative pattern
      DOWNLOAD_URL=$(echo "$DOWNLOAD_RESPONSE" | ${pkgs.gnugrep}/bin/grep -oP 'https://software\.download\.prss\.microsoft\.com/[^"]+\.iso' | ${pkgs.coreutils}/bin/tail -1) || true
    fi

    # Fallback: Try UUP dump API
    if [ -z "$DOWNLOAD_URL" ]; then
      log "Microsoft API failed, trying UUP dump API..."

      # UUP dump provides pre-built download packages
      UUP_RESPONSE=$(${pkgs.curl}/bin/curl -s \
        -H "User-Agent: $USER_AGENT" \
        "https://api.uupdump.net/listid.php" 2>&1) || true

      # Get latest Windows 11 build ID
      BUILD_ID=$(echo "$UUP_RESPONSE" | ${pkgs.jq}/bin/jq -r '.response.builds[] | select(.title | contains("Windows 11")) | .uuid' 2>/dev/null | ${pkgs.coreutils}/bin/tail -1) || true

      if [ -n "$BUILD_ID" ]; then
        log "Found UUP build ID: $BUILD_ID"
        err "UUP dump requires manual ISO creation. Run the following:"
        err "  Visit: https://uupdump.net/selectlang.php?id=$BUILD_ID"
        err "  Download and run the conversion script"
        err "  Place ISO at: $WINDOWS_ISO"
      fi
    fi

    if [ -z "$DOWNLOAD_URL" ]; then
      err "Could not obtain Windows 11 download URL"
      err "Microsoft's download API may have changed or be rate-limited."
      err ""
      err "Manual download instructions:"
      err "  1. Visit: https://www.microsoft.com/software-download/windows11"
      err "  2. Select 'Windows 11 (multi-edition ISO for x64 devices)'"
      err "  3. Select 'English' and click Download"
      err "  4. Move the downloaded ISO to: $WINDOWS_ISO"
      exit 1
    fi

    log "Download URL obtained: $DOWNLOAD_URL"
    log "Starting download (this will take a while for ~6GB)..."

    # Download with aria2 for speed (16 connections)
    ${pkgs.aria2}/bin/aria2c -x 16 -s 16 \
      --user-agent="$USER_AGENT" \
      --continue=true \
      --max-tries=5 \
      --retry-wait=10 \
      --file-allocation=none \
      -d "$ISO_DIR" -o "windows11.iso.tmp" \
      "$DOWNLOAD_URL"

    ARIA_EXIT=$?
    if [ $ARIA_EXIT -ne 0 ]; then
      err "aria2 download failed with exit code $ARIA_EXIT"
      err "Trying curl as fallback..."
      ${pkgs.curl}/bin/curl -L -# -o "$ISO_DIR/windows11.iso.tmp" \
        -H "User-Agent: $USER_AGENT" \
        "$DOWNLOAD_URL"
      CURL_EXIT=$?
      if [ $CURL_EXIT -ne 0 ]; then
        err "curl also failed with exit code $CURL_EXIT"
        exit 1
      fi
    fi

    # Verify the download is actually an ISO (should be > 4GB)
    if [ -f "$ISO_DIR/windows11.iso.tmp" ]; then
      SIZE=$(${pkgs.coreutils}/bin/stat -c%s "$ISO_DIR/windows11.iso.tmp")
      log "Downloaded file size: $SIZE bytes"

      # Windows 11 ISO should be at least 4GB
      MIN_SIZE=4000000000
      if [ "$SIZE" -lt "$MIN_SIZE" ]; then
        err "Downloaded file is too small ($SIZE bytes). Expected > 4GB."
        err "This is likely an error page, not the ISO."
        rm -f "$ISO_DIR/windows11.iso.tmp"
        exit 1
      fi

      # Rename to final name
      mv "$ISO_DIR/windows11.iso.tmp" "$WINDOWS_ISO"
      log "Windows 11 ISO downloaded successfully: $WINDOWS_ISO ($SIZE bytes)"
    else
      err "Download failed - file not created"
      exit 1
    fi
  '';
in {
  # Activation script for ISO download (blocking, runs during activation)
  activationScript = {
    text = ''
      # Ensure directory exists first
      ${pkgs.coreutils}/bin/mkdir -p "${isoDir}"

      # Skip if all ISOs present
      if [ -f "${windowsIso}" ] && [ -f "${virtioIso}" ] && [ -f "${autounattendIso}" ]; then
        echo "[windows-iso] All ISOs present - skipping"
      else
        echo "[windows-iso] Starting Windows ISO download..."

        # Run the download script directly (blocking)
        if ${windowsDownloadScript}; then
          echo "[windows-iso] Download completed successfully"
        else
          echo "[windows-iso] Download failed"
          # Don't fail activation, just warn
        fi
      fi
    '';
    deps = [];
  };

  # Export paths for use in VM XML
  inherit windowsIso virtioIso autounattendIso isoDir;
}
