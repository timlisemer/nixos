-- Sound Blaster Omni Device
rule11 = {
  matches = {
    {
      { "device.name", "equals", "alsa_card.usb-Creative_Technology_Ltd_SB_Omni_Surround_5.1_X00000ZT-00" },
    },
  },
  apply_properties = {
      ["device.description"] = "Sound Blaster Omni",
      ["device.nick"] = "Sound Blaster Omni",
  },
}

-- Sound Blaster Omni Headphone Node
rule12 = {
  matches = {
    {
      { "node.name", "equals", "alsa_output.usb-Creative_Technology_Ltd_SB_Omni_Surround_5.1_X00000ZT-00.analog-stereo-output" },
    },
  },
  apply_properties = {
    ["node.nick"] = "Headphones",
    ["node.description"] = "Headphones",
  },
}

-- Sound Blaster Omni Spdif Node
rule13 = {
  matches = {
    {
      { "node.name", "equals", "alsa_output.usb-Creative_Technology_Ltd_SB_Omni_Surround_5.1_X00000ZT-00.iec958-stereo" },
    },
  },
  apply_properties = {
    ["node.disabled"] = true,
    ["node.driver"] = false,
  },
}


-- Mainboard Spdif Device
rule21 = {
  matches = {
    {
      { "device.name", "equals", "alsa_card.pci-0000_0b_00.4" },
    },
  },
  apply_properties = {
      ["device.description"] = "Speakers",
      ["device.nick"] = "Speakers",
  },
}

-- Mainboard Spdif Node
rule22 = {
  matches = {
    {
      { "node.name", "equals", "alsa_output.pci-0000_0b_00.4.iec958-stereo" },
    },
  },
  apply_properties = {
    ["node.nick"] = "Speakers",
    ["node.description"] = "Speakers",
  },
}

-- Nvidia
rule3 = {
    matches = {
      {
        { "device.name", "equals", "alsa_card.pci-0000_09_00.1" },
      },
    },
    apply_properties = {
      ["device.disabled"] = true,
    },
}

-- Kaysuda Webcam
rule4 = {
  matches = {
    {
      { "device.name", "equals", "alsa_card.usb-Startime_Communication._Ltd._KAYSUDA_CA20_000000000000-00" },
    },
  },
  apply_properties = {
    ["device.disabled"] = true,
  },
}


-- Rhode Mic Output 1
rule5 = {
  matches = {
    {
      { "node.name", "equals", "alsa_output.usb-R__DE_R__DE_NT-USB__02447C32-00.iec958-stereo" },
    },
  },
  apply_properties = {
    ["node.disabled"] = true,
    ["node.driver"] = false,
  },
}


-- Rhode Mic Output 1
rule6 = {
  matches = {
    {
      { "node.name", "equals", "alsa_output.usb-R__DE_R__DE_NT-USB__02447C32-00.analog-stereo" },
    },
  },
  apply_properties = {
    ["node.disabled"] = true,
    ["node.driver"] = false,
  },
}

-- Sound Blaster Omni Mic
rule7 = {
  matches = {
    {
      { "node.name", "equals", "alsa_input.usb-Creative_Technology_Ltd_SB_Omni_Surround_5.1_X00000ZT-00.analog-stereo-input" },
    },
  },
  apply_properties = {
    ["node.disabled"] = true,
    ["node.driver"] = false,
  },
}
  
table.insert(alsa_monitor.rules, rule11)
table.insert(alsa_monitor.rules, rule12)
table.insert(alsa_monitor.rules, rule13)
table.insert(alsa_monitor.rules, rule21)
table.insert(alsa_monitor.rules, rule22)
table.insert(alsa_monitor.rules, rule3)
table.insert(alsa_monitor.rules, rule4)
table.insert(alsa_monitor.rules, rule5)
table.insert(alsa_monitor.rules, rule6)
table.insert(alsa_monitor.rules, rule7)
