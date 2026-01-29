{
  config,
  pkgs,
  lib,
  cfg,
  pciToDomain,
}: let
  isoDir = "/var/lib/libvirt/images";
  windowsIso = "${isoDir}/windows11.iso";
  virtioIso = "${isoDir}/virtio-win.iso";
  autounattendIso = "${isoDir}/autounattend.iso";

  # Parse PCI address (03:00.0) into components for Nix-side generation
  parsePci = addr: let
    parts = lib.splitString ":" addr;
    bus = lib.elemAt parts 0;
    devFn = lib.elemAt parts 1;
    devFnParts = lib.splitString "." devFn;
    slot = lib.elemAt devFnParts 0;
    func = lib.elemAt devFnParts 1;
  in {
    inherit bus slot func;
  };

  # Generate PCI hostdev XML entry
  pciHostdevXml = addr: let
    pci = parsePci addr;
  in ''
    <hostdev mode='subsystem' type='pci' managed='yes'>
      <source>
        <address domain='0x0000' bus='0x${pci.bus}' slot='0x${pci.slot}' function='0x${pci.func}'/>
      </source>
    </hostdev>
  '';

  # Storage configuration (static, known at build time)
  storageXml =
    if cfg.storage.type == "raw"
    then ''
      <disk type='block' device='disk'>
        <driver name='qemu' type='raw' cache='none' io='native' discard='unmap'/>
        <source dev='${cfg.storage.device}'/>
        <target dev='sda' bus='sata'/>
        <boot order='1'/>
      </disk>
    ''
    else ''
      <disk type='file' device='disk'>
        <driver name='qemu' type='qcow2' cache='none' io='native' discard='unmap'/>
        <source file='${cfg.storage.path}'/>
        <target dev='sda' bus='sata'/>
        <boot order='1'/>
      </disk>
    '';

  # PCI passthrough XML (static, known at build time)
  gpuPassthroughXml = lib.concatMapStrings pciHostdevXml cfg.passthrough.gpu;
  usbPassthroughXml = lib.concatMapStrings pciHostdevXml cfg.passthrough.usb;
  audioPassthroughXml = lib.concatMapStrings pciHostdevXml cfg.passthrough.audio;

  # Script to create qcow2 image if needed
  createQcow2Script = pkgs.writeShellScript "create-qcow2" ''
    set -euo pipefail

    if [ "${cfg.storage.type}" = "qcow2" ]; then
      IMAGE_PATH="${cfg.storage.path}"
      IMAGE_SIZE="${cfg.storage.size}"

      if [ ! -f "$IMAGE_PATH" ]; then
        echo "Creating qcow2 image at $IMAGE_PATH with size $IMAGE_SIZE..."
        ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$IMAGE_PATH")"
        ${pkgs.qemu}/bin/qemu-img create -f qcow2 "$IMAGE_PATH" "$IMAGE_SIZE"
        echo "qcow2 image created successfully."
      else
        echo "qcow2 image already exists at $IMAGE_PATH"
      fi
    fi
  '';

  # Script to define VM with dynamic resource detection
  defineVmScript = pkgs.writeShellScript "define-vm" ''
    set -euo pipefail

    # Create qcow2 image if needed
    ${createQcow2Script}

    # Wait for libvirtd to be ready
    for i in {1..30}; do
      if ${pkgs.libvirt}/bin/virsh list --all >/dev/null 2>&1; then
        break
      fi
      sleep 1
    done

    # ═══════════════════════════════════════════════════════════════════
    # Auto-detect resources: RAM - 2GB for host, CPU cores - 2 for host
    # ═══════════════════════════════════════════════════════════════════
    TOTAL_MEM_KB=$(${pkgs.gawk}/bin/awk '/MemTotal/ {print $2}' /proc/meminfo)
    TOTAL_MEM_MB=$((TOTAL_MEM_KB / 1024))
    VM_MEM_MB=$((TOTAL_MEM_MB - 2048))  # Reserve 2GB for host
    echo "Auto-detected memory: ''${TOTAL_MEM_MB}MB total, allocating ''${VM_MEM_MB}MB to VM (2GB reserved for host)"

    TOTAL_THREADS=$(${pkgs.coreutils}/bin/nproc)
    # Reserve 2 threads for host, minimum 2 for VM
    VM_THREADS=$((TOTAL_THREADS - 2))
    if [ "$VM_THREADS" -lt 2 ]; then
      VM_THREADS=2
    fi
    echo "Auto-detected CPU: ''${TOTAL_THREADS} threads total, allocating ''${VM_THREADS} to VM (2 reserved for host)"

    # Generate VM XML with dynamic values
    VM_XML_PATH="/var/lib/libvirt/images/${cfg.vmName}.xml"
    ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$VM_XML_PATH")"

    cat > "$VM_XML_PATH" << 'XMLEOF'
    <domain type='kvm'>
      <name>${cfg.vmName}</name>
      <uuid></uuid>
      <metadata>
        <libosinfo:libosinfo xmlns:libosinfo="http://libosinfo.org/xmlns/libvirt/domain/1.0">
          <libosinfo:os id="http://microsoft.com/win/11"/>
        </libosinfo:libosinfo>
      </metadata>
      <memory unit='MiB'>VM_MEM_PLACEHOLDER</memory>
      <currentMemory unit='MiB'>VM_MEM_PLACEHOLDER</currentMemory>
      <vcpu placement='static'>VM_VCPU_PLACEHOLDER</vcpu>
      <os firmware='efi'>
        <type arch='x86_64' machine='q35'>hvm</type>
      </os>
      <features>
        <acpi/>
        <apic/>
        <hyperv mode='custom'>
          <relaxed state='on'/>
          <vapic state='on'/>
          <spinlocks state='on' retries='8191'/>
          <vpindex state='on'/>
          <runtime state='on'/>
          <synic state='on'/>
          <stimer state='on'/>
          <reset state='on'/>
          <vendor_id state='on' value='randomid'/>
          <frequencies state='on'/>
        </hyperv>
        <kvm>
          <hidden state='on'/>
        </kvm>
        <vmport state='off'/>
        <ioapic driver='kvm'/>
      </features>
      <cpu mode='host-passthrough' check='none' migratable='off'>
        <topology sockets='1' dies='1' cores='VM_VCPU_PLACEHOLDER' threads='1'/>
        <cache mode='passthrough'/>
        <feature policy='require' name='topoext'/>
      </cpu>
      <clock offset='localtime'>
        <timer name='rtc' tickpolicy='catchup'/>
        <timer name='pit' tickpolicy='delay'/>
        <timer name='hpet' present='no'/>
        <timer name='hypervclock' present='yes'/>
        <timer name='tsc' present='yes' mode='native'/>
      </clock>
      <on_poweroff>destroy</on_poweroff>
      <on_reboot>restart</on_reboot>
      <on_crash>destroy</on_crash>
      <pm>
        <suspend-to-mem enabled='no'/>
        <suspend-to-disk enabled='no'/>
      </pm>
      <devices>
        <emulator>/run/libvirt/nix-emulators/qemu-system-x86_64</emulator>

        ${storageXml}

        <!-- Windows 11 Installation ISO -->
        <disk type='file' device='cdrom'>
          <driver name='qemu' type='raw'/>
          <source file='${windowsIso}'/>
          <target dev='sdb' bus='sata'/>
          <readonly/>
          <boot order='2'/>
        </disk>

        <!-- VirtIO Drivers ISO -->
        <disk type='file' device='cdrom'>
          <driver name='qemu' type='raw'/>
          <source file='${virtioIso}'/>
          <target dev='sdc' bus='sata'/>
          <readonly/>
        </disk>

        <!-- Autounattend ISO -->
        <disk type='file' device='cdrom'>
          <driver name='qemu' type='raw'/>
          <source file='${autounattendIso}'/>
          <target dev='sdd' bus='sata'/>
          <readonly/>
        </disk>

        <controller type='usb' index='0' model='qemu-xhci' ports='15'>
          <address type='pci' domain='0x0000' bus='0x02' slot='0x00' function='0x0'/>
        </controller>
        <controller type='sata' index='0'>
          <address type='pci' domain='0x0000' bus='0x00' slot='0x1f' function='0x2'/>
        </controller>
        <controller type='pci' index='0' model='pcie-root'/>
        <controller type='pci' index='1' model='pcie-root-port'>
          <model name='pcie-root-port'/>
          <target chassis='1' port='0x10'/>
          <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x0' multifunction='on'/>
        </controller>
        <controller type='pci' index='2' model='pcie-root-port'>
          <model name='pcie-root-port'/>
          <target chassis='2' port='0x11'/>
          <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x1'/>
        </controller>
        <controller type='pci' index='3' model='pcie-root-port'>
          <model name='pcie-root-port'/>
          <target chassis='3' port='0x12'/>
          <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x2'/>
        </controller>
        <controller type='pci' index='4' model='pcie-root-port'>
          <model name='pcie-root-port'/>
          <target chassis='4' port='0x13'/>
          <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x3'/>
        </controller>
        <controller type='pci' index='5' model='pcie-root-port'>
          <model name='pcie-root-port'/>
          <target chassis='5' port='0x14'/>
          <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x4'/>
        </controller>
        <controller type='pci' index='6' model='pcie-root-port'>
          <model name='pcie-root-port'/>
          <target chassis='6' port='0x15'/>
          <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x5'/>
        </controller>
        <controller type='pci' index='7' model='pcie-root-port'>
          <model name='pcie-root-port'/>
          <target chassis='7' port='0x16'/>
          <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x6'/>
        </controller>
        <controller type='pci' index='8' model='pcie-root-port'>
          <model name='pcie-root-port'/>
          <target chassis='8' port='0x17'/>
          <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x7'/>
        </controller>
        <controller type='virtio-serial' index='0'>
          <address type='pci' domain='0x0000' bus='0x03' slot='0x00' function='0x0'/>
        </controller>

        <!-- Network: virtio for best performance -->
        <interface type='network'>
          <source network='default'/>
          <model type='virtio'/>
          <address type='pci' domain='0x0000' bus='0x01' slot='0x00' function='0x0'/>
        </interface>

        <serial type='pty'>
          <target type='isa-serial' port='0'>
            <model name='isa-serial'/>
          </target>
        </serial>
        <console type='pty'>
          <target type='serial' port='0'/>
        </console>

        <input type='mouse' bus='ps2'/>
        <input type='keyboard' bus='ps2'/>

        <!-- TPM 2.0 for Windows 11 -->
        <tpm model='tpm-crb'>
          <backend type='emulator' version='2.0'/>
        </tpm>

        <!-- GPU Passthrough Devices -->
        ${gpuPassthroughXml}

        <!-- USB Controller Passthrough -->
        ${usbPassthroughXml}

        <!-- Audio Passthrough -->
        ${audioPassthroughXml}

        <memballoon model='virtio'>
          <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x0'/>
        </memballoon>
      </devices>
    </domain>
    XMLEOF

    # Replace placeholders with actual detected values
    ${pkgs.gnused}/bin/sed -i "s/VM_MEM_PLACEHOLDER/$VM_MEM_MB/g" "$VM_XML_PATH"
    ${pkgs.gnused}/bin/sed -i "s/VM_VCPU_PLACEHOLDER/$VM_THREADS/g" "$VM_XML_PATH"

    # Check if VM already exists
    if ${pkgs.libvirt}/bin/virsh dominfo ${cfg.vmName} >/dev/null 2>&1; then
      echo "VM ${cfg.vmName} already exists, updating definition..."
      ${pkgs.libvirt}/bin/virsh undefine ${cfg.vmName} --nvram 2>/dev/null || true
    fi

    # Define the VM
    echo "Defining VM ${cfg.vmName}..."
    ${pkgs.libvirt}/bin/virsh define "$VM_XML_PATH"

    # Ensure default network exists and is active
    if ! ${pkgs.libvirt}/bin/virsh net-info default >/dev/null 2>&1; then
      echo "Creating default network..."
      ${pkgs.libvirt}/bin/virsh net-define /run/current-system/sw/etc/libvirt/qemu/networks/default.xml 2>/dev/null || true
    fi

    if ! ${pkgs.libvirt}/bin/virsh net-info default 2>&1 | ${pkgs.gnugrep}/bin/grep -q "Active:.*yes"; then
      echo "Starting default network..."
      ${pkgs.libvirt}/bin/virsh net-start default 2>/dev/null || true
      ${pkgs.libvirt}/bin/virsh net-autostart default 2>/dev/null || true
    fi

    echo "VM ${cfg.vmName} defined successfully with ''${VM_MEM_MB}MB RAM and ''${VM_THREADS} CPU threads."
  '';
in {
  # Systemd service to define VM
  defineService = {
    description = "Define Windows VM in libvirt";
    wantedBy = ["multi-user.target"];
    after = ["libvirtd.service" "windows-iso-download.service"];
    wants = ["libvirtd.service"];
    requires = ["libvirtd.service"];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${defineVmScript}";
    };
  };
}
