# Bill of materials

Machine-readable version: [`BOM.csv`](BOM.csv). Prices are rough 2026 USD single-unit street prices (packs
divided down), for budgeting only. Fastener lengths are counted from the CAD in `parts/` and `lib/params.scad`.

**Estimated total: about $318** (about $311 without the optional Pi cooler and perfboards), plus shipping.
**Printed plastic: about 650 g** (647 g estimate incl. the gear_test coupon; plan on one 1 kg spool to cover
brims, purge and a reprinted gear or two).

| Category | Subtotal (USD) |
|---|---|
| Electronics (Pi 5, camera + link, SKR Pico, sensors) | 166.75 |
| Power and safety (PSU, buck, laser driver + module, e-stop, key, fan) | 61.50 |
| Mechanical (motors, bearings, magnets, feet) | 37.40 |
| Wiring | 20.00 |
| Filament + consumables | 20.40 |
| Fasteners + heat-set inserts | 12.29 |
| **Total** | **318.34** |

## Printed parts (no supports on any part)

Gram estimates are STL volume (from `tools/check_stl.py`) x 1.24 g/cm3 x an effective-fill factor for the
listed settings (0.45 for big 20% parts, 0.6 for gears, 1.0 for 100% parts).

| Part | Qty | Est. g each | Print orientation | Settings |
|---|---|---|---|---|
| `gear_test` | 1 | 4 | flat, plate down | same filament + settings as the gears; **print first** |
| `pinion` | 2 | 4 | nut-slot face on the bed, axis vertical | PETG preferred (sits on the motor shaft), 100% infill, 0.12-0.16 mm layers |
| `tilt_gear` | 1 | 22 | -Y face on the bed, counterbores + magnet pocket up | 5 perimeters, 40% gyroid, 0.16 mm |
| `turntable` | 1 | 65 | gear top (z 110) on the bed, spigot up | 5 perimeters, 40% gyroid, 0.16 mm |
| `base` | 1 | 163 | upside down: top plate on the bed | 4 perimeters, 20% gyroid, 0.2 mm |
| `bay` | 1 | 196 | floor on the bed, as modelled | 3 perimeters, 15-20% gyroid, 0.2 mm |
| `yoke` | 1 | 72 | deck on the bed, arms vertical | 4 perimeters, 35% gyroid, 0.2 mm |
| `payload` | 1 | 91 | rear face on the bed, laser bore vertical | 4 perimeters, 25-30% gyroid, 5 top/bottom layers |
| `pan_motor_plate` | 1 | 11 | top face on the bed | PETG preferred (touches the motor), 4 perimeters, 50% |
| `tilt_motor_plate` | 1 | 8 | outer face on the bed | PETG preferred (touches the motor), 4 perimeters, 50% |
| `pan_collar` | 1 | 5 | top face on the bed | 4 perimeters, 60% |
| `tilt_spacer` | 2 | 0.9 | standing on an end | 100% infill (the part is symmetric, so the "mirrored" -Y one is the same print) |
| `axle_collar` | 2 | 0.1 | flat | 100% infill, or use steel 8 x 11.5 x 2 shims |
| `beam_stop` | 1 | 2 | end face on the bed | **black / opaque** filament, 100% infill |

Largest footprint: `base` and `bay`, 190 x 190 mm (250 x 250 bed).

## Purchased parts

| Category | Item | Spec | Qty | Used in | Unit USD | Line USD |
|---|---|---|---|---|---|---|
| mechanical | NEMA17 stepper | 17HS4401-class, 1.8 deg, 40 mm body, 1.5-1.7 A, 5 mm D-shaft >= 24 mm | 2 | pan (base) + tilt (+Y yoke arm) | 10.00 | 20.00 |
| mechanical | 6810-2RS bearing | 50 x 65 x 7 | 2 | pan hub, back-to-back | 7.00 | 14.00 |
| mechanical | 608-2RS bearing | 8 x 22 x 7 | 2 | tilt axle, both yoke arms | 1.00 | 2.00 |
| mechanical | Neodymium disc magnet | 6 x 3 mm, N35+ | 2 | turntable underside (pan home), wheel +Y face (tilt home) | 0.20 | 0.40 |
| mechanical | Rubber foot | <= 10 mm dia, self-adhesive | 4 | bay floor recesses | 0.25 | 1.00 |
| fastener | M8 x 120 hex bolt | ISO 4014, partial thread | 1 | tilt axle | 1.50 | 1.50 |
| fastener | M8 nylock nut | DIN 985 | 1 | tilt axle (+Y) | 0.20 | 0.20 |
| fastener | M3 x 50 SHCS | ISO 4762 | 4 | bay floor -> base post inserts | 0.25 | 1.00 |
| fastener | M3 x 8 SHCS | ISO 4762 | 16 | deck 4, pan plate -> base 4, tilt motor -> plate 4, tilt plate -> arm 4 | 0.08 | 1.28 |
| fastener | M3 x 6 SHCS | ISO 4762 | 16 | pan motor -> plate 4, SKR Pico 4, buck + laser driver 8 | 0.07 | 1.12 |
| fastener | M3 x 10 SHCS | ISO 4762 | 3 | pan_collar -> spigot (self-taps 2.6 mm holes) | 0.08 | 0.24 |
| fastener | M3 x 12 SHCS | ISO 4762 | 3 | tilt wheel -> payload inserts | 0.09 | 0.27 |
| fastener | M3 x 16 SHCS | ISO 4762 | 4 | 40 mm fan -> bay wall | 0.10 | 0.40 |
| fastener | M3 hex nut | ISO 4032 | 6 | fan 4, captive in the pinions 2 | 0.03 | 0.18 |
| fastener | M3 x 4 set screw, cup point | ISO 4029 | 2 | pinion grub screws | 0.10 | 0.20 |
| fastener | M3 x 12 set screw, nylon tip | | 1 | laser clamp | 0.30 | 0.30 |
| fastener | M2.5 x 6 pan-head screw | self-tapping | 4 | Pi 5 -> standoffs | 0.10 | 0.40 |
| fastener | M2 x 6 pan-head screw | self-tapping | 4 | Camera Module 3 -> payload | 0.10 | 0.40 |
| fastener | M3 heat-set insert | M3 x 5, OD 4.6 | 32 | base 4, pan plate 4, turntable 4, yoke 4, payload 4, bay 12 | 0.15 | 4.80 |
| consumable | Zip tie | 2.5 x 100 mm | 10 | deck anchor, deck + bay camera-link pads, bay anchor post | 0.03 | 0.30 |
| consumable | Tether cord | ~150 mm | 1 | beam_stop -> yoke | 0.10 | 0.10 |
| consumable | Filament | PLA 1 kg (+ ~30 g PETG optional) | 1 | all printed parts | 20.00 | 20.00 |
| electronics | Raspberry Pi 5 | 4 GB | 1 | bay, +Y | 70.00 | 70.00 |
| electronics | Raspberry Pi Camera Module 3 | standard lens | 1 | payload, connector edge down | 25.00 | 25.00 |
| electronics | Camera FFC | 15-pin 1.0 mm, 150 mm | 1 | camera -> deck adapter | 2.00 | 2.00 |
| electronics | CSI-to-HDMI extender pair | passive, all 15 lines | 1 | deck pad + bay pad | 12.00 | 12.00 |
| electronics | Slim HDMI cable | OD <= 6 mm, 0.5 m | 1 | down the pan bore | 7.00 | 7.00 |
| electronics | Pi 5 camera cable | 22-pin to 15-pin, 200 mm | 1 | bay adapter -> Pi 5 | 3.00 | 3.00 |
| electronics | microSD card | 32 GB A1/A2 | 1 | Pi 5 | 8.00 | 8.00 |
| electronics | Pi 5 Active Cooler | optional | 1 | Pi 5 | 5.00 | 5.00 |
| electronics | BTT SKR Pico V1.0 | RP2040 + 4x TMC2209 | 1 | bay, -Y | 30.00 | 30.00 |
| electronics | USB-A to USB-C cable | 0.3 m | 1 | Pi 5 <-> SKR Pico | 4.00 | 4.00 |
| electronics | A3144 hall sensor | unipolar, open collector | 2 | pan + tilt home | 0.30 | 0.60 |
| electronics | 10 k resistor | 1/4 W | 3 | 2 hall pull-ups, 1 laser TTL pull-down | 0.05 | 0.15 |
| power/safety | 12 -> 5 V buck | 5 A, 5.1 V | 1 | bay front, -Y grid | 8.00 | 8.00 |
| power/safety | Laser TTL driver | 12 V in, TTL/PWM enable | 1 | bay front, +Y grid | 6.00 | 6.00 |
| power/safety | **Laser module (default)** | **Class 2 (< 1 mW) 650 nm red dot, 12 mm x <= 35 mm** | 1 | payload | 6.00 | 6.00 |
| power/safety | 12 V PSU | 12 V 5 A (60 W), 5.5 x 2.1 plug, listed | 1 | barrel jack | 15.00 | 15.00 |
| power/safety | Panel barrel jack | 5.5 x 2.1, M11 | 1 | rear panel | 1.50 | 1.50 |
| power/safety | Inline fuse + holder | 5 A slow-blow | 1 | after the jack | 3.00 | 3.00 |
| power/safety | Key switch | 19 mm, 2-pos, NC, key out in OFF | 1 | rear panel | 8.00 | 8.00 |
| power/safety | Emergency stop | 16 mm latching mushroom, positive-opening NC (2 blocks) | 1 | rear panel | 10.00 | 10.00 |
| power/safety | 40 mm fan | 40 x 40 x 10, 12 V | 1 | bay +Y wall | 4.00 | 4.00 |
| wiring | Silicone wire 18 AWG | red/black 1 m each | 1 | 12 V distribution | 4.00 | 4.00 |
| wiring | Silicone wire 24 AWG | 3-4 colours, 2 m each | 1 | sensors, laser, fan | 6.00 | 6.00 |
| wiring | Connector + heat-shrink kit | JST-XH, Dupont | 1 | all | 8.00 | 8.00 |
| wiring | Perfboard 50 x 70 | optional | 2 | buck / driver adapter plates | 1.00 | 2.00 |

### Notes on specific lines

- **Laser module.** The default is a Class 2 (< 1 mW) visible red dot module. The 12 mm bore accepts other
  12 mm modules up to 35 mm long with thin, flexible leads, but this project does not recommend any
  higher-power module. Read the laser safety section of [ASSEMBLY.md](ASSEMBLY.md) first.
- **M8 axle.** The clamped stack is 110 mm: 2 axle_collars (2 x 2) + 2x 608 (2 x 7) + 2 tilt_spacers
  (2 x 15) + the payload with its side rings (62). Add 8 mm for the DIN 985 nylock and 2 mm of thread past it,
  which gives M8 x 120. No washers are used: a DIN 125 M8 washer (OD 16) would rub the 608 shields, and the
  printed OD 11.5 collars clamp only the inner races.
- **Pan motor screws.** The CAD comment says M3 x 8. That leaves 5.4 mm of thread in the motor, but
  17HS4401-class holes are usually only 4.5 mm deep. Use M3 x 6 (3.4 mm of engagement) unless your motor's
  holes are at least 6 mm deep. The tilt motor screws (M3 x 8 through a 4 mm plate) are fine.
- **Camera link.** The design deliberately avoids running the camera FFC through the pan axis: +-175 deg of
  twist would fatigue a flat cable. A short 15-pin FFC goes to a CSI-to-HDMI adapter on the yoke deck, a
  slim round HDMI cable goes down the bore, and a 200 mm 22-to-15-pin cable runs from the bay adapter to the
  Pi 5. The adapter pads in the CAD assume a 28 x 22 x 9 mm board envelope, so check this against the boards
  you buy.
- **Board pinouts.** Check the SKR Pico hole pattern (58 x 49, inset 3.5) and the buck / laser-driver hole
  patterns against your actual boards before printing the bay.

## Power budget (12 V)

| Load | Estimate |
|---|---|
| 2x NEMA17 via TMC2209 at about 1 A RMS (conservative, moving) | 24 W |
| Pi 5 + Camera Module 3 + USB link (about 15 W at 5 V, 90% buck) | 16.7 W |
| SKR Pico logic | 1 W |
| 40 mm fan | 1.2 W |
| Laser driver + Class 2 module | 0.5 W |
| **Worst case** | **about 43 W = 3.6 A** |

A **12 V 5 A (60 W)** supply leaves about 40% headroom and matches the 5 A slow-blow fuse in the
enable chain (`lib/params.scad`). The 5 A buck is sized for the Pi 5's full USB budget, not for the
average draw.
