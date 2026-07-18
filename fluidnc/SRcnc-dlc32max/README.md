# SRcnc — MKS DLC32 MAX V1.1 Wiring

Pin assignments from MKS DLC32 MAX V1.0.002 pin diagram (KiCad, 2024-11-04).

## Board

MKS DLC32 MAX V1.1 (ESP32-S3)

## Board Connector Layout

```
                         TOP EDGE
 ┌─────────────────────────────────────────────────────────────────┐
 │  X-MOTOR  Y1-MOTOR  Y2-MOTOR  Z-MOTOR  A-MOTOR   AIR  BEEPER  │
 │  2B2A1B1A 2B2A1B1A  2B2A1B1A  2B2A1B1A 2B2A1B1A  IO1   IO42   │
 │                                                                  │
 ├────┐                                                      ┌─────┤
 │GND │                                                      │Z-LMT│
 │12- │                                                      │IO41 │
 │24V │                                                      │Y-LMT│
 │    │                                                      │IO40 │
 ├────┤             MKS DLC32 MAX V1.0                       │X-LMT│
 │Laser                                                      │IO39 │
 │IO2 │                                                      ├─────┤
 ├────┤                                                      │Door │
 │Laser                                                      │IO38 │
 │IO2 │                                                      │Flame│
 ├────┤                                                      │IO36 │
 │Spin│                                                      │Probe│
 │IO35│                                                      │IO37 │
 ├────┤                                                      │A-LMT│
 │SWIT│                                                      │IO48 │
 │CH  │                                                      ├─────┤
 ├────┘                                                      │ U1  │
 │  POWER        SD Card                                     │RJ11 │
 │  DC12V/24V    IO12,IO13,IO14,IO21                    GND RESET  │
 └─────────────────────────────────────────────────────────────────┘
                        BOTTOM EDGE
```

## Connector Pinout Table

### Top Edge — Motor Connectors

| Connector  | Function     | Pins              | Wire To           |
|------------|--------------|-------------------|-------------------|
| X-MOTOR    | X stepper    | Step: IO16, Dir: IO15 | DM542T #1    |
| Y1-MOTOR   | Y stepper    | Step: IO7, Dir: IO6   | DM542T #2    |
| Y2-MOTOR   | Y2 stepper   | (unused)          | —                 |
| Z-MOTOR    | Z stepper    | Step: IO5, Dir: IO4   | DM542T #3    |
| A-MOTOR    | A stepper    | Step: IO20, Dir: IO19 | (spare)      |
| AIR        | Air assist   | IO1               | (unused)          |
| BEEPER     | Buzzer       | IO42              | (unused)          |

All motors share enable on **IO8**.

### Right Edge — Limit Switches & Sensors

| Connector  | Pin    | Signal      | Wire To               |
|------------|--------|-------------|------------------------|
| Z- LMT    | IO41   | Z limit     | CR10 endstop (Z top)   |
| Y- LMT    | IO40   | Y limit     | CR10 endstop (Y min)   |
| X- LMT    | IO39   | X limit     | CR10 endstop (X home)  |
| Door       | IO38   | Safety door | (unused)               |
| Flame      | IO36   | Flame sensor| Z auto-zero touch plate|
| Probe      | IO37   | Probe input | HLTNC 3D Touch Probe   |
| A- LMT    | IO48   | A limit     | (unused)               |

Endstop wiring: connect "S" and "G" pins (Signal + GND). Board has internal pull-ups.

### Endstop Aviation Connector (GX12-4)

4-pin aviation connector between board and CR10 endstop:

| Pin | Signal | Board Pin | Wire Color |
|-----|--------|-----------|------------|
| 1   | GND    | G         | Black      |
| 2   | 3.3V   | V         | Red        |
| 3   | Signal | S         | Yellow     |
| 4   | (spare)| —         | —          |

Same pinout for all 3 axes. Pin 4 is unused — available for future use (e.g. second switch for max limit).

### Left Edge — Power & Outputs

| Connector  | Pin    | Function        | Wire To              |
|------------|--------|-----------------|----------------------|
| GND 12-24V | —     | Motor power GND | DM542T GND (shared)  |
| Laser IO2  | IO2   | PWM output      | (future: spindle PWM)|
| Laser IO2  | IO2   | PWM output (2nd)| Same signal, higher power connector |
| Spindle    | IO35  | Spindle enable  | (future: spindle on/off) |
| SWITCH     | —     | External power switch | (optional)    |

### Bottom Edge

| Connector  | Function           | Wire To           |
|------------|--------------------|-------------------|
| POWER      | DC 12-24V input    | PSU               |
| U1 (RJ11) | UART TX:IO17 RX:IO18 | FluidDial pendant |
| GND RESET  | Reset / E-stop     | (optional)        |

## Wiring Summary — What Gets Connected

| Device                | Board Connector | Pin(s)        |
|-----------------------|-----------------|---------------|
| DM542T #1 (X)         | X-MOTOR (EXT)   | Step:IO16, Dir:IO15, En:IO8 |
| DM542T #2 (Y)         | Y1-MOTOR (EXT)  | Step:IO7, Dir:IO6, En:IO8 |
| DM542T #3 (Z)         | Z-MOTOR (EXT)   | Step:IO5, Dir:IO4, En:IO8 |
| CR10 endstop X        | X- LMT          | IO39          |
| CR10 endstop Y        | Y- LMT          | IO40          |
| CR10 endstop Z        | Z- LMT          | IO41          |
| HLTNC 3D Touch Probe  | Probe           | IO37          |
| Z auto-zero plate     | Flame           | IO36          |
| FluidDial pendant     | U1 (RJ11)       | TX:IO17, RX:IO18 |
| PSU 24V               | POWER           | DC 12-24V     |
| DM542T power          | (external)      | Separate 24-48V PSU |

## DM542T Wiring (per driver)

Each axis has an **ESDG** header in front of the driver sockets for external drivers:

| ESDG Pin | Signal    | DM542T Terminal | Wire Color |
|----------|-----------|-----------------|------------|
| E        | Enable    | ENA+            | Red        |
| S        | Step      | PUL+            | Yellow     |
| D        | Direction | DIR+            | Green      |
| G        | Ground    | ENA-, PUL-, DIR- (common GND) | Black |

### DM542T DIP Switch Settings

For SFU1204 ballscrew (4mm pitch, 1 start) with NEMA 23 (1.8°/step):

- Microsteps: 8 (gives 400 steps/mm with 4mm pitch)
- Current: set to match your NEMA 23 motor rating (typically 2-3A)

### Motor Aviation Connector (GX16-5)

5-pin aviation connector between DM542T and NEMA 23 motor:

| Pin | Signal | DM542T Terminal | Wire Color |
|-----|--------|-----------------|------------|
| 1   | A+     | A+              | Red        |
| 2   | A-     | A-              | Yellow     |
| 3   | GND/Shield | —           | Black      |
| 4   | B+     | B+              | Blue       |
| 5   | B-     | B-              | Green      |

Same pinout and color coding for all 3 axes.

Note: The cable colors are our convention for the interconnect wiring. Motor wire colors vary by
manufacturer — check your motor's datasheet to identify coil pairs and map them to the connector pins.

## Probes

### HLTNC 3D Touch Probe → Probe connector (IO37)

- Wiring: Signal "S" + GND "G"
- Signals LOW when triggered
- Used for edge finding, center finding, and surface probing

### Z Auto-zero Touch Plate → Flame connector (IO36)

- Wiring: Signal "S" + GND "G"
- Clip lead connects to the tool (spindle collet or bit)
- Place plate on workpiece surface
- Run G38.2 Z probing cycle to find Z zero
- IO36 is a dedicated input with proper signal conditioning — ideal for probe use

## Pendant (FluidDial) → U1 RJ11 telephone jack

| Function | Pin      |
|----------|----------|
| TX       | IO17     |
| RX       | IO18     |

Protocol: UART 1000000 baud, 8N1

Note: This connector is shared with the MKS 3.5" touch screen. Use either pendant OR screen, not both.

## Power

- Board input: 12-24V DC, max 10A (DC-007B-2.1mm connector)
- DM542T drivers: 24-48V DC (separate PSU recommended for 3 NEMA 23 motors)
- Logic signals (step/dir/enable) are 3.3V from ESP32-S3, compatible with DM542T optocoupled inputs
- The GND 12-24V connector on the left edge provides GND reference for external driver signal wiring

## Notes

- The board has Y1-MOTOR and Y2-MOTOR connectors for dual-Y setups. We only use Y1.
- Plug/unplug drivers and motors only with power off.
- The RJ11 connector is shared between display and UART pendant — cannot use both simultaneously.
- Door connector (IO38) is kept free for future use as emergency stop or safety door.
