# SRcnc — Flexi-HAL Wiring

## Board

Flexi-HAL CNC Controller (Expatria Technologies, STM32F446)

Firmware: GRBLHAL

## Stepper Drivers

3x DM542T (external step/dir drivers)

Supply: 45V DC

### DM542T DIP Switch Settings

Motor: NEMA 23, 57x56mm, 3A, 1.8°, 1.2 N.m

| SW  | Position | Function          |
|-----|----------|-------------------|
| SW1 | OFF      | Peak current 3.0A |
| SW2 | OFF      |                   |
| SW3 | ON       |                   |
| SW4 | OFF      | Microstep: 8 (1600 pulses/rev) |
| SW5 | ON       |                   |
| SW6 | OFF      |                   |
| SW7 | OFF      | Self-test OFF     |
| SW8 | OFF      | No half-current at idle |

Result: 8 microsteps → 1600 pulses/rev → 400 steps/mm (with SFU1204, 4mm pitch)

### Flexi-HAL to DM542T Connection

8-pin IDC ribbon cable from Flexi-HAL stepper port to DM542T screw terminals.

Flexi-HAL stepper port pinout (active-low differential signals):

| IDC Pin | Signal | DM542T Terminal |
|---------|--------|-----------------|
| 1       | STEP+  | PUL+            |
| 2       | STEP-  | PUL-            |
| 3       | DIR+   | DIR+            |
| 4       | DIR-   | DIR-            |
| 5       | ENA+   | ENA+            |
| 6       | ENA-   | ENA-            |
| 7       | ALM    | ALM+ (future)   |
| 8       | GND    | ALM- (future)   |

Note: Verify exact pinout against Flexi-HAL documentation when board arrives.
The differential signals provide full 5V swing with proper isolation.

### Motor Aviation Connector (GX16-5)

5-pin aviation connector between DM542T and NEMA 23 motor:

| Pin | Signal | Connector Wire | Motor Wire (57BYG250B-8) |
|-----|--------|----------------|--------------------------|
| 1   | A+     | Red            | Black                    |
| 2   | A-     | Yellow         | Green                    |
| 3   | GND    | Black          | (shield)                 |
| 4   | B+     | Blue           | Red                      |
| 5   | B-     | Green          | Blue                     |

Same pinout and color coding for all 3 axes.

## Limit Switches

CR10 endstop switches (NO). Future upgrade: NPN NC inductive proximity sensors.

Connected to Flexi-HAL limit inputs (RJ45 breakout or direct PCB terminals).

Configure as NO in GRBLHAL: `$5=0`

### Endstop Aviation Connector (GX12-4)

| Pin | Signal | Current (CR10) | Future (inductive) |
|-----|--------|---------------|-------------------|
| 1   | GND    | GND           | GND               |
| 2   | 5V     | LED power     | (unused)          |
| 3   | Signal | Switch NO     | Signal NPN NC     |
| 4   | spare  | (unused)      | 12V sensor power  |

Per-axis cable colors:

| Pin | Signal | X Color | Y Color | Z Color |
|-----|--------|---------|---------|---------|
| 1   | GND    | Blue    | Black   | White   |
| 2   | 5V     | Red     | Yellow  | Brown   |
| 3   | Signal | Gray    | Green   | Green   |
| 4   | spare  | —       | —       | —       |

## Probes (future)

| Probe              | Connection        |
|--------------------|-------------------|
| HLTNC 3D Touch     | Limit RJ45 breakout (probe input) |
| Z Auto-zero plate  | Limit RJ45 breakout (toolsetter input) |

## USB Connection

Laptop → USB-C to USB-A cable → USB-A panel mount (enclosure) → USB-A to USB-C cable → Flexi-HAL

## Power

| Device       | Voltage | Source          |
|--------------|---------|-----------------|
| Flexi-HAL    | 12-24V  | 24V PSU         |
| DM542T (x3)  | 45V     | 45V PSU         |

## DIN Rail Layout

- Flexi-HAL (3D printed DIN mount from Expatria)
- 3x DM542T
- 24V PSU
- 45V PSU
- USB-A panel mount on enclosure wall

## GRBLHAL Settings

| Setting | Value | Description |
|---------|-------|-------------|
| $100    | 400   | X steps/mm  |
| $101    | 400   | Y steps/mm  |
| $102    | 400   | Z steps/mm  |
| $110    | 800   | X max rate mm/min |
| $111    | 800   | Y max rate mm/min |
| $112    | 400   | Z max rate mm/min |
| $120    | 20    | X acceleration mm/s² |
| $121    | 20    | Y acceleration mm/s² |
| $122    | 20    | Z acceleration mm/s² |
| $130    | 220   | X max travel mm |
| $131    | 380   | Y max travel mm |
| $132    | 95    | Z max travel mm |
| $5      | 0     | Limit pins invert (NO switches) |
| $20     | 1     | Soft limits enabled |
| $21     | 1     | Hard limits enabled |
| $22     | 1     | Homing enabled |

## Notes

- The Flexi-HAL uses isolated differential drivers for step/dir signals — no level shifter needed.
- Alarm feedback from DM542T is supported on pin 7/8 of the IDC connector (future wiring).
- The board communicates via USB-C serial to bCNC or UGS.
- FluidDial pendant is NOT compatible — use Jog2K or keyboard jogging via bCNC.

## Parts to Order

| Part | Quantity | Notes |
|------|----------|-------|
| 28AWG 8-conductor IDC flat ribbon cable | 1m | For Flexi-HAL to DM542T connections |
| 8-pin IDC female connectors | 3x | One per axis |
| USB-A to USB-C cable (~30cm) | 1x | Inside enclosure: panel mount to Flexi-HAL |

## Parts to Print

| File | Material | Notes |
|------|----------|-------|
| `parts/flexi-hal/DIN_Clip.stl` | PETG | DIN rail clip |
| `parts/flexi-hal/Flexi-HAL_Mount_Plate.stl` | PETG | Board mounting plate |
