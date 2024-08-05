# OpenWSN Firmware for Sulu-ADS1299

This is the OpenWSN firmware for the Sulu-ADS1299 EEG in MRI system.
To get started, follow the [Basic OpenMote Setup for scum-test-code](https://crystalfree.atlassian.net/wiki/spaces/SCUM/pages/2029879415/Basic+OpenMote+Setup+for+scum-test-code).

## Building and loading the firmware

The firmware for this system is at `projects/common/01bsp_radio_scumhunt/`

Build and bootload in your conda environment (from the OpenMote setup) with

```
scons board=openmote-b-24ghz toolchain=armgcc bootload=COM10 bsp_radio_scumhunt
```

Where `COM10` is the COM port to which the OpenMote is connected. Typically two COM ports will appear, always take the one with the higher number.
