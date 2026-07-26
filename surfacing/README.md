# surfacing/

Wasteboard surfacing G-code for the SRcnc machine.

Skim pass to flatten the MDF wasteboard and establish a true Z reference plane.
Run this after tramming the spindle, before any precision work.

## Workflow

1. Tram the spindle (dial indicator sweep in X and Y)
2. Home machine (`$H`)
3. Place touch plate on wasteboard, run **UGS macro 2** → sets G54 Z0 at wasteboard surface
4. Remove touch plate
5. Load `surfacing.nc` in UGS, run

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| Tool | 20.2mm HSS endmill | Flat 2-flute |
| Stepover | 40% = 8mm | Conservative for good finish |
| Depth | 0.5mm | Single skim pass |
| Feed XY | 2000 mm/min | |
| Feed Z | 200 mm/min | |
| Area | 210×370mm | Centered at machine X110 Y190 |
| Passes | 25 | Boustrophedon (zigzag) |

## Regenerate

```bash
make surfacing.nc

# Custom depth or feed
python3 surfacing.py --depth 1.0 --feed 1500 > surfacing.nc
```

## Notes

- Uses G53 (machine coordinates) for XY — no workpiece setup needed
- Uses G54 Z from touch plate probe — must probe Z before running
- Z0 = wasteboard surface as measured by touch plate
- Cuts at Z=-0.5 (or `--depth` value)
- After surfacing, re-probe Z before any subsequent job
