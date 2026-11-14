# Assembly guide

Read the **laser safety** section at the end before powering anything.
Part numbers and quantities are in [BOM.md](BOM.md). Every dimension referred to here is defined in
`lib/params.scad`, in world coordinates. The pan axis is Z, +X is where the laser points at pan 0 / tilt 0,
and the tilt drive is on the +Y side.

## Tools

- 2.5 mm hex key (M3 SHCS), 1.5 mm hex key (M3 grub and set screws), 2 mm hex key or small Phillips
  (M2/M2.5), two 13 mm spanners (M8)
- Soldering iron with a heat-set insert tip, side cutters, a flat file or deburring tool, a 3.4 mm drill
  (clean the clearance holes) and calipers
- CA glue or 5-minute epoxy (magnets, hall sensors), a multimeter, a strip of printer paper (about 0.1 mm,
  for the gear mesh)

## 1. Print the gear test first and tune `gear_backlash`

The pan pair (17T / 85T) and the tilt pair (17T / 51T) use the same module-1.25 herringbone tooth, so one
test tunes both.

1. Print `gear_test`, **one** `pinion` and the `tilt_gear` with the filament and settings you will use for the
   real gears (see the table below).
2. Drop the pinion onto the D-pin and the 51T wheel onto the round pin. They now sit at the real 42.5 mm
   centre distance (engraved on the plate).
3. Turn the wheel by hand through at least one full turn:
   - **Binds or has tight spots:** raise `gear_backlash` in `lib/params.scad` by 0.05.
   - **Rocks more than about 1 deg at the wheel rim** (about 0.3 mm at the tooth tips): lower it by 0.05.
   - **Turns smoothly with a barely perceptible rock:** keep it. The pinion and wheel are then real machine
     parts, so do not reprint them.
4. After any change, run `make` (it rebuilds every gear STL, because they all depend on `lib/`), then reprint
   the pinions, `tilt_gear`, `turntable` and, if you want to recheck, the coupon. The default is 0.15 mm.

The motor plates add a further +1.5 / -3 mm of mesh adjustment in the machine (step 9). The coupon only has
to get the tooth thickness right.

## 2. Print settings

0.4 mm nozzle, PLA or PETG, **no supports on any gimbal part**. Every overhang in the CAD is 45 deg or less, and the
horizontal holes over 6 mm are capped teardrops. The robot base has its own print notes in [Robot base](#robot-base). Use at least 4 perimeters (1.6 mm) on every part with
inserts or tapped holes, so they sit in solid walls.

| Part | Qty | Orientation | Layer | Walls / infill | Notes |
|---|---|---|---|---|---|
| `pinion` | 2 | nut-slot face down | 0.12-0.16 | 100% | PETG preferred (the motor shaft gets warm); slow outer walls |
| `tilt_gear` | 1 | -Y face down (counterbores up) | 0.16 | 5 walls, 40% | |
| `turntable` | 1 | gear top down, spigot up | 0.16 | 5 walls, 40% | spigot must slide into the 6810s: check with calipers (49.95) |
| `base` | 1 | upside down (top plate on the bed) | 0.2 | 4 walls, 20% | 190 mm round; long print; brim optional |
| `bay` | 1 | floor down | 0.2 | 3 walls, 15-20% | panel labels are engraved in the rear wall |
| `yoke` | 1 | deck down | 0.2 | 4 walls, 35% | arms carry the 608s and the tilt motor |
| `payload` | 1 | rear face down (laser bore vertical) | 0.2 | 4 walls, 25-30%, 5 top/bottom | laser loads from the front; no supports |
| `pan_motor_plate` | 1 | top face down | 0.2 | 4 walls, 50% | PETG preferred |
| `tilt_motor_plate` | 1 | outer face down | 0.2 | 4 walls, 50% | PETG preferred |
| `pan_collar` | 1 | top face down | 0.2 | 4 walls, 60% | |
| `tilt_spacer` | 2 | on an end | 0.2 | 100% | symmetric: the -Y one is the same print |
| `axle_collar` | 2 | flat | 0.2 | 100% | or steel 8 x 11.5 x 2 shims |
| `beam_stop` | 1 | end face down | 0.2 | 100% | **black / opaque** filament only |

Stepper bodies can reach 50-60 C at full current, which is close to PLA's softening point. That is why
PETG is preferred for the motor plates and pinions, and why the motor currents in step 12 are modest.

## 3. Post-processing and heat-set inserts

1. Remove any elephant's foot. Clean the M3 clearance holes with a 3.4 mm drill by hand, and check the
   bearing pockets: the 6810s should press in with thumb pressure and the 608s should be a light push fit.
   If they are loose or tight, tune `press` in `params.scad`.
2. Fit the **M3 x 5 heat-set inserts (32 total)** with the iron at 200-220 C for PLA or 230-245 C for PETG.
   Keep the iron perpendicular, press until the insert is flush, then hold a flat steel part on it for a few
   seconds while it cools. Each hole is 4.2 mm wide and 6 mm deep. Turn the part so that every hole points
   **straight up** while you press:

| Part | Inserts | Where | How to hold the part |
|---|---|---|---|
| `base` | 4 | bottoms of the four bay-screw posts (z 48 face) | as printed (upside down): the post ends face up |
| `pan_motor_plate` | 4 | ear holes in the top face | top face up (flip from the print orientation) |
| `turntable` | 4 | gear top face at r 38 (45/135/225/315 deg) for the deck | gear top up (flip from the print orientation) |
| `yoke` | 4 | floors of the two ear pockets in the +Y arm's outer face | yoke on its -Y arm, +Y arm outer face up |
| `payload` | 3 + 1 | 3 in the +Y side ring at r 15 (tilt wheel); 1 in the top face (laser clamp) | +Y face up, payload propped on a block (the -Y stop lug sticks out); then top face up |
| `bay` | 12 | 4 SKR Pico standoffs, 8 on the two 30 x 30 grids at the front | floor down |

3. The Pi 5 standoffs (2.2 mm), camera holes (1.8 mm) and turntable spigot holes (2.6 mm) are
   **self-tap holes, not insert holes**. Drive the screw in once and back it out before final assembly so
   the thread is cut cleanly.

## 4. Bench sub-assemblies

**Pinions (both).** Each pinion is hubless, with one radial grub screw and a captive nut.
1. Drop an M3 nut into the slot from the flat (z = 0) face.
2. Drop an M3 x 4 cup-point set screw down the bore, tip it socket-end first into the radial hole, and
   push it out to the nut.
3. Thread it into the nut with a 1.5 mm hex key through the tooth gap, but do not tighten it yet.

The herringbone is symmetric about its mid-plane, so a pinion can go on either way round.

**Pan motor.** Screw the pan NEMA17 to `pan_motor_plate` with 4x **M3 x 6** from the plate's top face,
heads in the counterbores and the motor boss in the 22.4 mm centring hole. Slide a pinion onto the shaft
with the grub screw on the D-flat, **top face flush with the shaft end**, and tighten through the tooth gap.

**Tilt motor.** Screw the tilt NEMA17 to `tilt_motor_plate` with 4x **M3 x 8**. The heads sit in the 1 mm
seats on the plate's inner face and the motor sits on the outer face. Fit the second pinion with its face
**12 mm from the motor mounting face** (the pinion covers 12-22 mm and the shaft sticks out about 2 mm past
it). Tighten on the flat.

**Base.**
1. Press the upper 6810 in from the top until it sits on the shoulder, and the lower 6810 in from below,
   up against the shoulder.
2. Fit the pan A3144 into the pocket in the base top at r 42, angle 0 (front), branded face **up**, with
   the leads down the slot into the cavity.
3. Power it from 5 V and check it switches when a magnet passes (see 4. Turntable) before fixing it with a
   drop of CA.

**Turntable.** Glue a 6 x 3 magnet into the underside pocket at r 42, angle 0. The A3144 only responds to a
**south pole on its branded face**, so test the polarity against the powered sensor first. Its output
goes low on detection.

**Tilt wheel.**
1. Glue a 6 x 3 magnet into the pocket in the wheel's counterbored (+Y) face, south pole **outward**.
2. Bolt the wheel to the payload's +Y ring with 3x **M3 x 12** into the inserts, heads in the counterbores.
   The three-hole pattern allows three orientations. Use the one that puts the **magnet pocket at 12
   o'clock, centred between the two upper screws, when the laser axis is level**. That makes tilt home =
   0 deg.

**Payload.**
1. Connect the 150 mm camera FFC to the Camera Module 3, feed the ribbon down through the front-open
   ribbon slot, and seat the board in the front recess **connector edge down**. Fix it with 4x M2 x 6.
2. Lay the ribbon back along the groove under the body. The image is upside down: set rotation 180 in
   software (`rpicam-* --rotation 180`, or Picamera2 `Transform(hflip=1, vflip=1)`).
3. Feed the laser module's leads in through the front of the exit collar, down the bore and out of the
   wire slot in the bottom face, then slide the module in from the front until its rear face stops on the
   d 9 step (about 3 mm of bend room is left behind it for the leads). Snug the M3 x 12 nylon-tip set screw
   in the top-face insert lightly: there is a 1.85 mm wall to the axle bore. The set screw is what holds
   the module axially, so check it before every session.
4. Push the `beam_stop` cap over the exit collar and **leave it on** for all assembly and testing (see Laser safety). Tie its tab to the yoke
   later with the tether cord.

## 5. Pan stage on the base

Work with the base upright on blocks or a ring at least 5 mm tall. The pan motor will hang 2 mm below the
base's bottom rim.

1. Lower the turntable spigot through both 6810 inner races until the shoulder sits on the upper inner race.
2. From **below** (only possible before the bay is fitted), place `pan_collar` against the lower inner race,
   bed face up toward the bearing. Drive 3x **M3 x 10** into the spigot's self-tap holes evenly. The spigot
   end stops 0.2 mm short, so the collar clamps the inner race. The turntable must now spin freely with no
   axial play.
3. Slide the pan motor plate (with motor and pinion) to the **-X end of its slots (-3 mm)**. At that point
   the pinion teeth are clear of the 85T teeth. Herringbones cannot be meshed axially, so they always have
   to be engaged radially.
4. Push the pinion up through the window in the base top from below, and hold the plate against the
   underside of the top plate.
5. Drive 4x **M3 x 8** down from the base top through the X-slots into the plate's ear inserts, finger
   tight. All four heads are at r >= 64.8, outside the gear and the deck, so they stay reachable with a hex
   key with everything assembled.

## 6. Yoke

1. Fit the tilt A3144 into the pocket on the +Y arm's **inner** face (at [0, 45, 191]), branded face toward
   -Y (toward the wheel magnet). Run the leads up the groove and out through the hole to the outside of the
   arm.
2. Set the yoke on the turntable with the +Y arm (motor pocket) on +Y at pan 0, deck holes over the gear
   inserts. Drive 4x **M3 x 8** straight down. Do this **before the payload goes in**: once the payload is
   fitted it blocks the vertical access to these screws.
3. Strap the deck camera-link adapter to its pad with 2 zip ties through the tunnels. Do **not** fit the
   608s yet.

## 7. Payload into the yoke

The tilt motor is not fitted yet, so nothing occupies the pinion position.

1. Hold the payload (with the wheel, camera, laser and beam stop fitted) **muzzle-up at about 60-80 deg**
   and lower it straight down between the arms, wheel on the +Y side.
   At tilt 0 the -Y stop lug jams on the upper stop block. A muzzle-up descent at 60, 70 and 80 deg was
   checked collision-free against `yoke()` in CAD over the whole path.
2. Line the axle bore up with the arm holes.
3. Push one `tilt_spacer` in from **outside** each arm, through the empty 22 mm bearing pocket and the
   14 mm lip hole (on +Y also through the wheel's 13 mm hole), until it touches the payload's side ring.
   Its outer end is now flush with the bearing seat.
4. Slide an `axle_collar` and then a 608 onto the M8 x 120 bolt. Push the bolt in from **-Y** through the
   -Y spacer, the payload and the +Y spacer, and press that 608 into the -Y pocket until it seats on the
   lip.
5. On +Y, slide the second 608 over the bolt end into its pocket, then the second `axle_collar`, then the
   DIN 985 nylock.
6. Tighten with two 13 mm spanners until the stack (inner race | spacer | payload | spacer | inner race) is
   snug and the payload has no side play, then about 1/6 turn more. Do not crush it. The payload must
   still swing freely from -20 to +90 deg, stopping on the blocks.

## 8. Tilt motor

1. Slide the tilt motor plate (with motor and pinion) to the -3 mm end of its slots. Feed the pinion
   through the d 24.75 opening in the +Y arm web from outside, and seat the plate in the arm's outer pocket.
2. Drive 4x **M3 x 8** from outside (+Y) through the ear slots into the arm inserts, finger tight.

These heads are 4 mm above and below the motor body, and `tools/interference.sh` confirms that a hex key
reaches all eight motor-plate screws at every tilt angle.

## 9. Gear mesh adjustment (both axes, fully assembled)

1. Loosen the four plate screws of the axis. Lay a strip of printer paper (about 0.1 mm) over the wheel
   teeth, push the motor plate toward the wheel (+X, up to +1.5 mm past nominal) until the paper is
   gripped, and tighten the four screws. Turn the axis to roll the paper out.
2. With the motors unpowered, turn the axis by hand through its whole travel (pan +-175 deg, tilt -20 to
   +90 deg). It should have no tight spot and only a slight rock. If it binds somewhere, the wheel has
   runout, so set the mesh at the tightest point.
3. To remove a motor later, loosen its four screws, slide it to -3 mm and lift it out with its pinion. You do
   not have to dismantle the axis.

## 10. Cable routing (before closing the bay)

1. **Leaving the payload:** the camera FFC and the laser leads come out of the payload's underside (x 6-37).
   Leave a service loop down to the deck that does not snag or pull at -20 deg or +90 deg. Plug the FFC
   into the deck adapter.
2. **Down the pan axis:** the tilt motor cable, the tilt hall leads (3-core), the laser leads (2-core) and
   the slim HDMI cable go behind the deck cable hole. Zip-tie them to the deck anchor, then run them down
   through the d 30 deck hole and the d 38 spigot bore into the base cavity. Zip-tie them to the bay
   anchor post at [50, 0], using both tunnels. Those two ties fix the twisting length at about 110 mm, so
   +-175 deg of pan only twists the round cables.
3. The pan motor cable and the pan hall leads drop straight from the base cavity into the bay.
4. Turn pan slowly through +-175 deg and tilt through -20 to +90 deg by hand and watch every cable.

## 11. Electronics bay and wiring

**Mounting.**
1. Panel parts go in the rear (-X) wall:
   - e-stop (16 mm), "STOP"
   - key switch (19 mm), "LASER"
   - barrel jack (M11), "12V"
2. Fit the 40 mm fan inside the +Y wall, blowing **in**, with 4x M3 x 16 and nuts. The vents are on -Y.
3. Mount the boards:
   - Pi 5 on its 4 standoffs (+Y) with M2.5 x 6.
   - SKR Pico on 4 inserts (-Y) with M3 x 6, USB-C/power edge toward +X.
   - 12 -> 5 V buck on the front -Y grid and the laser driver on the front +Y grid, with M3 x 6 or on
     perfboard adapters.
   - Bay camera-link adapter strapped to its pad with 2 zip ties.
4. Stick the 4 rubber feet into the floor recesses.

**Power and laser enable chain** (hardware interlock, independent of software, as in `lib/params.scad`):

```
12 V PSU -> barrel jack -> 5 A slow-blow fuse -+-> E-STOP NC #1 -> KEY SWITCH NC -> laser driver +12 V SUPPLY
                                               +-> E-STOP NC #2 -> SKR Pico VIN (motor + board power)
                                               +-> 12->5 V buck -> Pi 5 (5 V via USB-C pigtail or 5V/GND pins)
                                               +-> 40 mm fan (or SKR FAN1/FAN2)
```

- The e-stop and key switch interrupt the laser driver's **power**, never only its TTL line.
- Use 18 AWG wire for the 12 V runs and 24 AWG for signals.
- The Pi stays powered when the e-stop is pressed so that it can shut down cleanly.
- If your e-stop has only one NC block, put it in the common feed (laser and motors) before the buck tap.
- Pressing the e-stop also resets the SKR Pico, so the host must re-home after it is released. That is
  intended: nothing restarts by itself.
- Leave the SKR Pico's USB-power jumper **off**, so the Pi's USB cannot back-feed the board.
- If the Pi 5 warns about its supply on a non-PD 5 V input, set `PSU_MAX_CURRENT=5000` in its EEPROM
  config (the buck supplies 5 A).

**Laser TTL.**
- Connect the driver's TTL/enable input to the SKR Pico **Laser header (IO20) only**, with a **10 k
  pull-down** from TTL to GND. The RP2040 pins float during reset and boot.
- **Never connect anything to FAN3.** It is the same pin (IO20), so a fan there would fire the laser
  whenever the fan runs.

**Steppers.** Pan motor to the **X** driver socket, tilt motor to the **Y** driver socket (TMC2209 in UART
mode, 16 microsteps with interpolation). The 1 m cable that comes with the motor is long enough for the tilt
route through the pan bore.

**Endstops (hall sensors).**
- Wire each A3144 as VCC = **5 V** (it needs 4.5-24 V), GND, and OUT to an endstop input: pan to
  X-STOP, tilt to Y-STOP.
- The outputs are open collector. Pull each one up with **10 k to 3.3 V**, or use the input's own 3.3 V
  pull-up. **Never pull up to 5 V**, because the RP2040 is not 5 V tolerant.
- Check the endstop header pinout of your board revision.

**Pi <-> SKR Pico.** Use a USB-A (Pi) to USB-C (SKR Pico) cable. The SKR Pico runs the motion firmware (for
example Klipper with two `manual_stepper`s: `rotation_distance: 360` with `gear_ratio: 85:17` for pan and
`51:17` for tilt gives units in degrees). The Pi runs the camera and the application.

**Camera.** Camera -> 150 mm FFC -> deck CSI-to-HDMI adapter -> slim HDMI down the bore -> bay adapter ->
200 mm 22-to-15-pin cable -> Pi 5 CAM port.

## 12. Close up, home and test

1. Lower the base onto the bay so the cylinder sits on the ledge and the corner lips centre it. Tip the
   unit on its side and drive 4x **M3 x 60** (DIN 912) up through the floor counterbores into the base post inserts.
   The tips land where the old M3 x 50 did. On the robot base the four M3 x 60 go in from under the lid instead
   (see [Robot base](#robot-base)).
2. First power-up: **beam_stop fitted, key OUT.** Check with a multimeter that the laser driver supply is
   0 V with the e-stop pressed and with the key off.
3. Set the motor currents: about 0.8 A RMS for running and 0.3-0.4 A for homing.
4. Set the soft limits: **pan +-170 deg** (the hard stop is at +-175) and tilt about -18 to +88 deg (the
   hard stops are at -20 / +90).

**Pan homing** (magnet under the turntable at angle 0, sensor in the base top at r 42):
1. If the sensor is already active, back off by about 10 deg first.
2. At homing current, jog + slowly for up to 360 deg. Either the magnet is found (< 175 deg away), or
   the dog under the gear stalls on the post at +175. The stall is harmless at low current: detect it
   with StallGuard or accept the step loss.
3. In the second case, run - until the magnet is found.
4. Always finish by approaching from the same direction at low speed. For the best repeatability, zero on
   the middle of the trigger window (the average of the rising and falling edges). The cables can never
   wind past +-175 deg.

**Tilt homing** (magnet in the wheel face at 12 o'clock, sensor on the +Y arm, home = 0 deg):
1. If the sensor is already active, back off upward.
2. At homing current, move muzzle-down for up to 115 deg. If the head starts between 0 and +90, it finds
   the magnet. If it starts between -20 and 0, it stalls softly on the -20 stop.
3. In the stall case, move up to the magnet.
4. Finish with the same one-direction, low-speed approach as pan.

## Robot base

The robot base (`robot.scad`, `lib/robot_params.scad`, `parts/robot_*.scad`) is a 330 mm driving base styled
after the original roomba-turret model (`legacy/roomba-turret/`). The gimbal sits on its lid. Its frame,
dimensions and wiring notes are in `lib/robot_params.scad`. Lid top is at 80 mm, and the total height is about
285 mm (80 mm deck + 204 mm gimbal at tilt 0). Mass is about 2.67 kg. The minimum stability margin is 13.8 mm.
The viewer checks these.

### Print notes

Use the same 0.4 mm nozzle rules as the gimbal, 4 perimeters on every part with inserts.

| Part | Qty | Material | Orientation and supports |
|---|---|---|---|
| `robot_floor_front`, `_left`, `_rear`, `_right` | 1 each | PLA | Top face down on the bed (upside down). **Thin support under the lower lap** only. |
| `robot_lid_fl`, `_fr`, `_rl`, `_rr` | 1 each | PLA | **Skin down.** Supports under the first ~3.5 mm of the rounded top edge. |
| `robot_pillar` | 4 | PLA | Flange down, no supports |
| `robot_motor_bracket` | 2 | PLA/PETG | Floor face down, saddle open upward, no supports |
| `robot_motor_strap` | 4 | PLA/PETG | Standing on a side face, no supports |
| `robot_wheel_hub` | 2 | **PETG** | Web face on the bed, cup open up, no supports |
| `robot_tire` | 2 | **TPU 95A** | Flat on the bed, slow, no supports |
| `robot_batt_tray` | 1 | PLA | As assembled, no supports |
| `robot_ebay_tray` | 1 | PLA | Plate on the bed, no supports |
| `robot_caster_mount` | 1 | PLA | Floor face down, no supports |
| `robot_bumper_left`, `robot_bumper_right` | 1 each | PLA | Standing on the bottom edge, no supports |
| `robot_bumper_splice` | 1 | PLA | Arc plate flat on the bed, no supports |

The floor quadrants are 243 mm long, so they need the full 250 mm bed.

### Assembly order

Do the gimbal's bench sub-assemblies (sections 1-4) first. Then:

1. **Floor quadrants.** Join the four quadrants with the lap screws (2 M3 per seam, into the boss inserts).
2. **Pillars.** Fit 4x M3 from below through each flange into the floor. Each pillar takes 4 screws.
3. **Motor brackets, motors, straps.** Fit each bracket on the floor with 4x M3 x 10 from below. Seat the
   JGA25 gear motor in the saddle (gearbox face at |y| 113). Close it with 2 straps per motor (2x M3 x 10 into
   the top inserts).
4. **Wheel hubs and tires.** Press an M3 insert into the hub boss. Slide the hub onto the D-shaft and tighten the
   M3 set screw onto the flat. Stretch the TPU tire over the hub flanges.
5. **Caster mount and caster.** Fit the 3 inserts. Fit the mount with 3x M3 x 10 from below and the caster with
   2x M3 screws.
6. **Battery tray and pack.** Screw the tray to the floor with 4x M3 x 10 from below. Set the pack in the tray
   and fasten it with the 25 mm hook-and-loop strap through the two strap slots.
7. **E-bay tray.** Fit the Cytron MDD3A on its 4 M3 standoffs and the Pico on its 4 M2 standoffs. Put the
   10 A fuse holder in its cradle. Screw the tray down with 4x M3 x 10 from below.
8. **Wiring.** See the wiring list below. Pass the battery feed and the e-stop branch through the 16 mm grommet.
9. **Lid quadrants.** Join with the splice screws inside the lid (M3 x 12 into the splice inserts). The
   180-degree seam has a wall tab with 3 screws.
10. **Gimbal onto the lid, lid OFF the floor.** Set the gimbal on the lid's 4 mount bosses. Fit the 4x
    **M3 x 60** from under the lid up into the gimbal bay. Pillars carry the load once the lid is on the floor.
11. **Lid and gimbal onto the floor.** Set the lid on the floor and drive 8x M3 from below into the lid's wall
    bosses (inserts at r 156).
12. **Bumper.** Put the two bumper halves on the 4 shoulder screws in their slots, with the 2 springs in their
    seats at +-15 deg. Fit the splice plate with its M3 x 8 screws. Fit the two KW10 switches in their
    pockets. Check that each lever closes at 2 mm of bumper travel.

### Wiring (hardware)

- Battery + -> 10 A fuse -> rocker switch -> up the 16 mm grommet -> the gimbal bay's 12 V input (where the DC
  jack's leads went; the bay jack is unused on the robot).
- The gimbal's laser enable chain is unchanged. Its e-stop NC #2 (motor branch) now also feeds the MDD3A VM,
  down the grommet. The e-stop therefore stops the wheels, the steppers and the laser. The Pi stays powered to
  shut down cleanly.
- Charge jack -> BMS charge port (12.6 V 2 A Li-ion charger). Never through the rocker.
- Pi 5 USB -> Pico (wheel controller): MDD3A PWM/DIR, 2 quadrature encoders on PIO, 2 bumper switches, lid
  button and LED, ToF sensor on I2C.
- Software rule: laser output only while the robot is stopped (wheel speed 0).

## Laser safety

- **Class 2 is the default and the recommendation.** The BOM specifies a Class 2 (< 1 mW) visible red dot
  module. A Class 2 beam is safe only because the blink reflex limits accidental exposure, so do not stare
  into it or defeat that reflex with optics.
- **Never aim the laser at people, pets, aircraft, vehicles or reflective surfaces** (mirrors, glass,
  polished metal, water). Point the gimbal at a matte, non-reflective backstop.
- **The beam_stop cap stays on during assembly, testing and tuning.** It is printed opaque at 100% infill
  and tethered to the yoke so that it is always at hand. Take it off only for supervised use.
- **Remove the key whenever the gimbal is unattended.** The key switch and e-stop cut the laser driver's
  supply in hardware. Keep it wired that way, and never bypass or jumper either of them.
- **On the robot base, the e-stop also cuts the drive motors.** Software must keep the laser off whenever the
  wheels are moving. The browser simulator enforces this.
- **Never drive the robot with the beam-stop cap off around people or pets.**
- **Software must refuse to fire without a confirmed target, and must never fire while a person is in the
  camera's view.**
  - If the camera feed, the detector or the homing state is missing or uncertain, the laser stays off.
  - The TTL line idles low (10 k pull-down), and firmware should enforce a maximum on-time with a watchdog.
  - Firing must stay inside the soft limits.
- **Higher-power modules.** The 12 mm bore physically accepts other modules, but this project does not
  recommend any module above Class 2. **Any Class 3B or Class 4 module requires certified laser safety
  eyewear rated for its exact wavelength and power, a controlled and enclosed area with no unprotected
  people, and compliance with your local laser regulations** (many jurisdictions restrict or license
  devices above Class 2/3R). The interlocks above are the minimum, not a sufficient safety case, for
  such modules.
