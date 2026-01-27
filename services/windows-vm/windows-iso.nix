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

  # Windows ISO download script using Microsoft's JSON API
  # Adapted from quickemu/quickget: https://github.com/quickemu-project/quickemu
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

    USER_AGENT="Mozilla/5.0 (X11; Linux x86_64; rv:100.0) Gecko/20100101 Firefox/100.0"
    DOWNLOAD_PAGE_URL="https://www.microsoft.com/en-us/software-download/windows11"
    PROFILE="606624d44113"

    # Step 1: Generate session UUID
    SESSION_ID=$(${pkgs.util-linux}/bin/uuidgen)
    log "Generated session ID: $SESSION_ID"

    # Step 2: Fetch download page to get product edition ID dynamically
    log "Step 1: Parsing download page..."
    PAGE_HTML=$(${pkgs.curl}/bin/curl --disable --silent \
      --user-agent "$USER_AGENT" \
      --header "Accept:" \
      --max-filesize 1M \
      --fail \
      --proto =https --tlsv1.2 --http1.1 \
      -- "$DOWNLOAD_PAGE_URL") || {
      err "Failed to fetch download page"
      exit 1
    }

    # Extract product edition ID from HTML (e.g., <option value="3113">Windows 11...)
    PRODUCT_EDITION_ID=$(echo "$PAGE_HTML" | ${pkgs.gnugrep}/bin/grep -oE '<option value="[0-9]+">Windows' | ${pkgs.coreutils}/bin/cut -d '"' -f 2 | ${pkgs.coreutils}/bin/head -n 1 | ${pkgs.coreutils}/bin/tr -cd '0-9' | ${pkgs.coreutils}/bin/head -c 16)

    if [ -z "$PRODUCT_EDITION_ID" ]; then
      err "Could not extract product edition ID from download page"
      err "Manual download instructions:"
      err "  1. Visit: https://www.microsoft.com/software-download/windows11"
      err "  2. Select 'Windows 11 (multi-edition ISO for x64 devices)'"
      err "  3. Select 'English' and click Download"
      err "  4. Move the downloaded ISO to: $WINDOWS_ISO"
      exit 1
    fi
    log "Product edition ID: $PRODUCT_EDITION_ID"

    # Step 3: Permit session ID with Microsoft
    log "Step 2: Validating session..."
    ${pkgs.curl}/bin/curl --disable --silent --output /dev/null \
      --user-agent "$USER_AGENT" \
      --header "Accept:" \
      --max-filesize 100K \
      --fail \
      --proto =https --tlsv1.2 --http1.1 \
      -- "https://vlscppe.microsoft.com/tags?org_id=y6jn8c31&session_id=$SESSION_ID" || {
      err "Session validation failed"
      exit 1
    }

    # Step 4: Get SKU ID for English
    log "Step 3: Getting language SKU ID..."
    SKU_RESPONSE=$(${pkgs.curl}/bin/curl --disable -s \
      --fail \
      --max-filesize 100K \
      --proto =https --tlsv1.2 --http1.1 \
      "https://www.microsoft.com/software-download-connector/api/getskuinformationbyproductedition?profile=$PROFILE&ProductEditionId=$PRODUCT_EDITION_ID&SKU=undefined&friendlyFileName=undefined&Locale=en-US&sessionID=$SESSION_ID") || {
      err "Failed to get SKU information from Microsoft"
      err "Manual download instructions:"
      err "  1. Visit: https://www.microsoft.com/software-download/windows11"
      err "  2. Select 'Windows 11 (multi-edition ISO for x64 devices)'"
      err "  3. Select 'English' and click Download"
      err "  4. Move the downloaded ISO to: $WINDOWS_ISO"
      exit 1
    }

    log "SKU response: $SKU_RESPONSE"

    # Extract SKU ID for English (United States) or any English variant
    SKU_ID=$(echo "$SKU_RESPONSE" | ${pkgs.jq}/bin/jq -r '.Skus[] | select(.LocalizedLanguage=="English (United States)" or .Language=="English (United States)") | .Id' 2>/dev/null) || true

    if [ -z "$SKU_ID" ] || [ "$SKU_ID" = "null" ]; then
      # Try to get any English variant
      SKU_ID=$(echo "$SKU_RESPONSE" | ${pkgs.jq}/bin/jq -r '.Skus[] | select(.LocalizedLanguage | contains("English")) | .Id' 2>/dev/null | ${pkgs.coreutils}/bin/head -1) || true
    fi

    if [ -z "$SKU_ID" ] || [ "$SKU_ID" = "null" ]; then
      err "Could not extract SKU ID from Microsoft response"
      err "Response: $SKU_RESPONSE"
      err ""
      err "Manual download instructions:"
      err "  1. Visit: https://www.microsoft.com/software-download/windows11"
      err "  2. Select 'Windows 11 (multi-edition ISO for x64 devices)'"
      err "  3. Select 'English' and click Download"
      err "  4. Move the downloaded ISO to: $WINDOWS_ISO"
      exit 1
    fi
    log "Found SKU ID: $SKU_ID"

    # Step 5: Get download URL (referer header is required!)
    log "Step 4: Getting ISO download link..."
    DOWNLOAD_RESPONSE=$(${pkgs.curl}/bin/curl --disable -s \
      --fail \
      --referer "$DOWNLOAD_PAGE_URL" \
      "https://www.microsoft.com/software-download-connector/api/GetProductDownloadLinksBySku?profile=$PROFILE&productEditionId=undefined&SKU=$SKU_ID&friendlyFileName=undefined&Locale=en-US&sessionID=$SESSION_ID") || true

    log "Download response length: ''${#DOWNLOAD_RESPONSE} bytes"

    # Check for blocked request
    if echo "$DOWNLOAD_RESPONSE" | ${pkgs.gnugrep}/bin/grep -q "Sentinel marked this request as rejected"; then
      err "Microsoft blocked the automated download request based on your IP address"
      err ""
      err "Manual download instructions:"
      err "  1. Visit: https://www.microsoft.com/software-download/windows11"
      err "  2. Select 'Windows 11 (multi-edition ISO for x64 devices)'"
      err "  3. Select 'English' and click Download"
      err "  4. Move the downloaded ISO to: $WINDOWS_ISO"
      exit 1
    fi

    # Extract the x64 ISO download URL
    DOWNLOAD_URL=$(echo "$DOWNLOAD_RESPONSE" | ${pkgs.jq}/bin/jq -r '.ProductDownloadOptions[].Uri' 2>/dev/null | ${pkgs.gnugrep}/bin/grep -i x64 | ${pkgs.coreutils}/bin/head -1) || true

    if [ -z "$DOWNLOAD_URL" ] || [ "$DOWNLOAD_URL" = "null" ]; then
      err "Could not obtain Windows 11 download URL"
      err "Response: $DOWNLOAD_RESPONSE"
      err ""
      err "Manual download instructions:"
      err "  1. Visit: https://www.microsoft.com/software-download/windows11"
      err "  2. Select 'Windows 11 (multi-edition ISO for x64 devices)'"
      err "  3. Select 'English' and click Download"
      err "  4. Move the downloaded ISO to: $WINDOWS_ISO"
      exit 1
    fi

    log "Download URL obtained: ''${DOWNLOAD_URL%%\?*}"
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
