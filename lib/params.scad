// =====================================================================
//  laser-gimbal :: shared parameters & interface contract
//  Every part `include`s this file. Change a number here, not in a part.
// =====================================================================
//
//  WORLD FRAME (assembly, pan = 0, tilt = 0)
//    origin  = pan axis on the desk surface (bottom of electronics bay)
//    +Z      = up, pan axis is the Z axis
//    +X      = front: laser + camera point along +X at tilt 0
//    +Y      = left side looking from behind; the TILT DRIVE (motor,
//              pinion, 51T gear) is on the +Y side
//
//  Every part module is authored IN WORLD COORDINATES at pan=0, tilt=0.
//  Pan-stage parts (turntable, collar, yoke, tilt drive, payload) rotate
//  about Z by `pan`; payload parts + tilt gear additionally rotate about
//  the tilt axis (line through [0,0,tilt_z] parallel to Y) by `tilt`.
//  Positive tilt raises the muzzle: about the tilt axis apply
//  rotate([0,-tilt,0]).
//
//  Z STACK (bottom to top)
//    0 .. bay_h           electronics bay (tray)
//    bay_h .. base_top    base housing (pan motor hangs inside)
//    base_top+gap ..      turntable 85T gear, deck/yoke above it
//    tilt_z               tilt axis
// =====================================================================

$fn = 64;
eps = 0.01;

// ---------- printing ----------
nozzle      = 0.4;
wall        = 3.0;     // default structural wall
fit         = 0.20;    // radial clearance for printed-on-printed slip fits
press       = 0.10;    // bearing pocket = bearing OD - press + 0.15 (see bearing_bore)
bed_xy      = 250;     // max part footprint (Bambu P1S/X1 = 256)

// ---------- fasteners (metric) ----------
m2_clear  = 2.4;   m2_tap  = 1.8;
m25_clear = 2.9;   m25_tap = 2.2;
m3_clear  = 3.4;   m3_tap  = 2.6;
m3_head_d = 6.0;   m3_head_h = 3.2;   // socket head cap
m3_nut_af = 5.6;   m3_nut_h  = 2.6;   // across flats (+clearance)
m3_insert_d = 4.2; m3_insert_h = 5.0; // heat-set insert M3 x 5 (OD 4.6) -> hole 4.2
m4_clear  = 4.5;
m8_clear  = 8.3;

// ---------- gears (shared) ----------
gear_mod    = 1.25;    // module
gear_pa     = 20;      // pressure angle
gear_helix  = 20;      // herringbone helix angle (pinion +, wheel -)
gear_backlash = 0.15;  // total backlash per mesh (mm along pitch circle)
gear_w      = 10;      // face width of every gear in the machine

pinion_z    = 17;      // both axes use the same 17T pinion (print 2)
pan_gear_z  = 85;      // 5:1
tilt_gear_z = 51;      // 3:1

function pitch_r(z) = gear_mod * z / 2;
function outer_r(z) = pitch_r(z) + gear_mod;
function root_r(z)  = pitch_r(z) - 1.25 * gear_mod;
pan_cd  = pitch_r(pinion_z) + pitch_r(pan_gear_z);   // 63.75
tilt_cd = pitch_r(pinion_z) + pitch_r(tilt_gear_z);  // 42.5

pinion_bore    = 5.0 + 0.15;  // NEMA17 shaft 5 mm, D-flat
pinion_dflat   = 4.5 + 0.10;  // distance from flat to opposite side
// Pinions are HUBLESS (no room on either axis): D-bore through the 10 mm face width,
// one radial M3 grub screw at mid-width entering through a tooth gap, captive M3 nut
// in a slot opening to one face (nut sits between bore and root circle).
// pan pinion: world z 100..110 on the pan motor shaft (shaft top = z 110, flush: motor face z 86 on pan_motor_plate).
// tilt pinion: world y 31..41 on the tilt motor shaft (shaft end = y 29).

// ---------- NEMA 17 (42 stepper) ----------
nema_w        = 42.3;
nema_len      = 40;     // body length (17HS4401-class)
nema_hole_sp  = 31.0;   // M3 square pattern
nema_boss_d   = 22.0;   // pilot boss
nema_boss_h   = 2.0;
nema_shaft_d  = 5.0;
nema_shaft_l  = 24.0;   // from mounting face

// ---------- bearings ----------
b6810 = [50, 65, 7];    // [id, od, width]  pan axis, two stacked
b608  = [8, 22, 7];     // tilt axis, one per yoke arm
function bearing_bore(b) = b[1] - press + 0.15;  // printed pocket diameter (tune per printer)

// ---------- electronics bay ----------
bay_w       = 190;      // square footprint, centred on pan axis
bay_h       = 48;       // z 0 .. 48
bay_floor   = 3;
bay_corner_r = 12;
// bay<->base joint: 4x M3x50 driven UP from under the bay floor (counterbored), through
// vertical tube bosses in the bay, into M3 heat-set inserts in bosses on the base bottom (z 48).
bay_screw_xy = [[60, 60], [-60, 60], [-60, -60], [60, -60]];
bay_tube_od  = 9;
// cable grommet hole through the bay floor (robot base: battery feed up, e-stop motor branch
// down, Pi USB -> Pico). Sits in the free strip in front of the Pi 5 (y 62..78), beside the
// fan (x >= 22) and clear of every standoff, tube, rib and anchor; >= 8 mm from both axes
// (lid seams) and from the lid mount bosses. The lid has the same hole.
bay_grommet_d  = 16;
bay_grommet_xy = [30, 70];
// boards occupy x in [-42.5, 42.5], y in [-58.5, 58.5] (Pi 5 at +Y, SKR Pico at -Y) on standoffs;
// keep the 4 tubes, the fan and panel parts clear of that zone.

// boards (verify against your actual boards before printing)
pi5_board   = [85, 56];  pi5_holes   = [58, 49];  pi5_hole_inset = 3.5;   // M2.5
// BTT SKR Pico V1.0 (BTT "SKR Pico V1.0-SIZE.pdf"): 85 x 56, holes 58 x 49 (Pi pattern), 3.5 in from
// one short and one long edge -> the other short edge (USB-C + power input) is 23.5 from its holes.
// In the bay the USB-C/power edge faces +X (front free zone: buck converter right in front of it,
// rear zone kept clear for the e-stop / key-switch bodies behind the -X panel). M3.
skr_pico_board = [85, 56];  skr_pico_holes = [58, 49];  skr_pico_hole_inset = 3.5;
fan40       = [40, 40, 10];  fan40_hole_sp = 32;     // M3
// rear panel: hole = nominal thread/body size + panel_fit (horizontal holes in a 3 mm wall print
// 0.2-0.4 mm undersize; bay.scad also circumscribes the polygons). Confirm vs the parts bought.
panel_fit   = 0.5;
dc_jack_hole = 11.0 + 0.4;          // panel-mount 5.5x2.1 barrel jack, M11 thread
key_switch_hole = 19.0 + panel_fit; // 19 mm key switch, 2 positions, NC contact (laser enable)
estop_hole  = 16.0 + panel_fit;     // 16 mm EMERGENCY STOP: red mushroom head (~28-30 mm), latching,
                                    // positive-opening NC contact block (IEC 60947-5-5) -- not a plain latching button
// LASER ENABLE CHAIN (hardware, independent of firmware) -- wire it exactly like this:
//   12 V jack -> fuse (5 A) -+-> e-stop NC #1 -> key switch NC -> laser driver SUPPLY (+12 V in)
//                            +-> e-stop NC #2 -> motor branch: SKR Pico VMOT (or a relay that pulls the
//                            |                    TMC2209 EN pins high)
//                            +-> 12->5 V buck -> Pi 5 (stays powered so the Pi can shut down cleanly)
//   * the key and e-stop interrupt the laser driver's POWER, never only its TTL line;
//   * 10 k pull-down from the driver TTL input to GND (RP2040 GPIOs float during reset/boot);
//   * drive TTL from the SKR Pico "Laser" header (IO20) ONLY. FAN3 is the same pin (IO20):
//     never connect a fan to FAN3, it would fire the laser whenever the fan runs;
//   * if the e-stop has only one NC block, use it in the common feed (laser + motors) before the buck tap.
// Always fit the beam_stop cap while assembling / testing.

// ---------- base housing ----------
base_d      = 190;      // cylinder OD (pan motor outer corner reaches r = 87.5)
base_z0     = bay_h;    // 48
base_top    = 98;       // top surface of base top plate
base_top_t  = 6;        // top plate thickness (z 92..98)
pan_motor_xy = [-pan_cd, 0];               // pan motor axis (behind, -X)
// ---------- motor plates: backlash adjustable with everything assembled ----------
// Each stepper is screwed (4x M3) to a printed motor plate ON THE BENCH. The plate is clamped to the
// housing by screws whose heads stay reachable with the gears, turntable, yoke and payload fitted;
// it slides in X through slots: mesh_slot = [-3, +1.5] mm from nominal. -X moves the motor AWAY
// from its wheel: -3 mm (> 2 m = 2.5 mm) fully disengages the herringbone teeth, which can never be
// separated axially, so a motor can be removed without dismantling its axis.
mesh_slot = [-3, 1.5];
// pan: pan_motor_plate z 86..92 directly under the base top plate (ears z 84..92). Motor screws
// M3x8 from the plate top (counterbored, tightened on the bench). Plate -> base: 4x M3x8 from the
// BASE TOP (counterbored, X-slotted) into heat-set inserts in the plate ears. All 4 at r >= 64.8 from
// the pan axis (85T tip r 54.4, deck r 51): reachable with a hex key at pan = 0.
pan_mplate_t     = 6;
pan_mplate_ear_t = 8;
pan_mplate_screws = [[-60, 28], [-60, -28], [-78, 27.5], [-78, -27.5]];   // world XY (nominal)
pan_motor_face_z = base_top - base_top_t - pan_mplate_t;  // 86: shaft top z 110 = pan pinion top
pan_window_d     = 26;  // base top plate opening around the shaft: the pinion (OD 23.75) passes through it
// ---------- pan hard stop (+-175 deg, 350 deg travel) ----------
// Dog on the 85T gear underside (gear angle 270 at pan 0, radial faces) runs in a groove cut 4 mm
// into the base top (r 46.5..51.5, z 94..98); the groove is interrupted at world angle 90 (the
// "post"). Dog width + post width = 2 * (180 - pan_stop). Firmware soft limits +-170.
// Homing: if the A3144 sees the magnet -> home. Otherwise jog + at low current up to 360 deg: either
// the magnet is found (< 175 deg) or the dog stalls on the post (+175, StallGuard or step loss is
// harmless at low current); then run - to the magnet. The cables can never wind past +-175.
pan_stop      = 175;
pan_stop_r    = [46.5, 51.5];   // groove in the base
pan_stop_z    = 94;             // groove floor
pan_dog_r     = [47.25, 50.75]; // dog (inside the 85T root r 51.56: it never touches a tooth gap)
pan_dog_z0    = 94.75;          // dog bottom (0.75 above the groove floor)
pan_dog_ang   = 270;            // dog centre, gear frame (= world at pan 0)
pan_post_ang  = 90;             // post centre, world
pan_post_w    = 4.5;            // deg
pan_dog_w     = 2 * (180 - pan_stop) - pan_post_w;   // 5.5 deg
// pan hub: two 6810 bearings in a bore at the centre of the base
pan_hub_od      = 72;   // hub OD (clears motor body: pan_cd - nema_w/2 = 42.6 > 36)
pan_brg_upper_z = 90;   // bottom face of upper bearing (bearing z 90..97)
pan_brg_lower_z = 72;   // bottom face of lower bearing (bearing z 72..79)
pan_hub_bottom_z = 70;  // hub tube bottom
pan_brg_shoulder_id = 58;  // integral spacer between the bearings (z 79..90) holds both outer races
pan_hall_xy = [42, 0];  // hall sensor (A3144) under the 85T gear, front (r 42: 2.4 mm wall to the stop groove)
// Bearing load path (back-to-back): upper bearing outer race sits ON the shoulder top (z 90),
// its inner race is pushed DOWN by the turntable spigot shoulder (z 97..100). Lower bearing outer
// race sits UNDER the shoulder (z 79); its inner race is pushed UP by the collar (z 68..72).
// Upper bearing goes in from the top, lower bearing from below.
// Any screw head on the base top surface must be counterbored flush: the 85T gear sweeps 2 mm above.

// ---------- turntable (85T gear + spigot) ----------
gear_gap        = 2;                    // base top -> gear bottom
turntable_z0    = base_top + gear_gap;  // 100 : gear z 100..110
turntable_gear_top = turntable_z0 + gear_w;   // 110
spigot_od       = b6810[0] - 0.05;      // 49.95 slip into 6810 inner race
spigot_id       = 38;                   // cable bore
spigot_bottom_z = 72;                   // tube runs z 72..100 (flush with lower bearing bottom face)
spigot_shoulder_od = 55;                // ring z 97..100 bearing on upper inner race (6810 inner land ~55)
collar_z        = [68, 72];             // retaining collar under lower bearing inner race + spigot end
collar_od       = 55;                   // touches inner race only; shoulder ID 58 clears it
collar_screws_r = (spigot_od/2 + spigot_id/2) / 2;  // 3x M3 into heat-set inserts in spigot end face
pan_magnet      = [6, 3];               // 6x3 neodymium in gear underside at r = pan_hall_xy[0], angle 0

// ---------- yoke (deck + two arms) ----------
deck_z0     = turntable_gear_top;       // 110 (deck sits on gear top)
deck_t      = 6;                        // z 110..116
deck_d      = 104;
deck_screws_r = 38;                     // 4x M3 deck -> turntable (heat-set inserts in gear top), at 45,135,225,315 deg
deck_cable_hole = 30;
tilt_z      = 165;                      // tilt axis height
arm_inner_y = 45;                       // inner face of each arm at |y| = 45
arm_t       = 8;                        // arms occupy |y| 45..53
arm_boss_d  = 34;                       // bearing boss around tilt axis
// 608 pocket opens to the OUTSIDE face: bearing at |y| 46..53, 1 mm inner lip at |y| 45..46
// with a 14 mm hole (clears the inner race, catches the outer race). The axle collars (d 11.5,
// under the M8 head / nut) bear on the inner races from outside; tilt_spacer tubes from inside.
tilt_brg_y  = [46, 53];
tilt_lip_hole = 14;
// Pan stage keep-out: the pan pinion (z 100..110, shaft top z 110) sweeps r 51.9..75.6 relative to
// the rotating yoke -> nothing on the pan stage may sit at r > 56 below z 117 (yoke: 45-deg cone).
// Only exception: the pan-stop dog on the gear underside (z < 100, r < 51.56).
pan_stage_keepout = [56, 117];
tilt_motor_xz = [-tilt_cd, tilt_z];     // tilt motor axis (parallel to Y), behind the tilt axis
tilt_motor_face_y = arm_inner_y + arm_t;// 53: motor face on the tilt_motor_plate outer face, flush with the arm outside
// tilt_motor_plate: sits in a pocket in the +Y arm's OUTER face (core y 48..53 under the motor,
// ears y 50..53), so the motor face stays at y 53 (shaft end y 29). Motor -> plate: 4x M3x8, heads
// on the plate inner face (1 mm counterbore), tightened on the bench; they sit in clearance holes in
// the 3 mm arm web. Plate -> arm: 4x M3x8 from OUTSIDE (+Y) through X-slots in the ears into heat-set
// inserts in the arm (2 mm bosses on the inner face). Ear screws at r >= 50 from the tilt axis, 4 mm
// above/below the motor body: reachable with a hex key along -Y at any tilt.
tilt_mplate_t     = [5, 3];             // core, ear thickness
tilt_mplate_half  = 21;                 // core half size (rounded square) around the motor axis
tilt_mplate_screws = [[-8, -28], [12, -28], [-8, 28], [12, 28]];     // ear screws, XZ RELATIVE to tilt_motor_xz
                                        // (shifted +X so the lower inserts stay above the yoke's 45-deg keep-out cone)
tilt_pinion_hole  = 24.75;              // arm web opening: the pinion (OD 23.75) passes with the motor
tilt_range  = [-20, 90];                // degrees; hard stops on the yoke

// ---------- tilt drive ----------
tilt_gear_y = [31, 41];                 // 51T wheel and pinion occupy this y range, +Y side
tilt_gear_bolt_r = 15;                  // 3x M3 wheel -> payload (heat-set inserts in payload), at 30,150,270 deg in XZ
                                        // (r 20 put the 270 deg insert on the payload's bottom edge z 145)
tilt_gear_hole = 13;                    // wheel centre hole; payload +Y boss (d 11.5) passes through
tilt_hall_r = 26;                       // 6x3 magnet in the wheel's +Y face (y=41) at radius 26, XZ-angle 90 at tilt 0
                                        // A3144 on the +Y arm inner face at world [0, 45, tilt_z + 26]
// Tilt hard stops (XZ angles measured from +X toward +Z, about the tilt axis):
//  payload stop lug: y in [-44, -32], radial 24..30, centred at 180 deg (behind) at tilt 0, 12 deg wide
//  yoke stop blocks: on the -Y arm inner face, y in [-45, -40] (5 mm stub: prints unsupported), radial 22..32,
//                    block A centred 282 deg (stops +90), block B centred 148 deg (stops -20), 12 deg wide
stop_lug_y = [-44, -32];   stop_lug_r = [24, 30];   stop_lug_ang = 180;  stop_w_deg = 12;
stop_block_y = [-45, -40]; stop_block_r = [22, 32]; stop_block_angs = [282, 148];
// Tilt axle (pivot only; torque goes wheel -> payload directly). Clamped stack between the 608
// outer faces = 2 x 53 = 106 (608 7 | spacer 15 | payload + rings 62 | spacer 15 | 608 7), plus an
// axle_collar (printed, OD 11.5 < 608 inner-race land ~12, 2 mm) under the head and under the nut, so
// only the inner races are clamped (a 13 AF head/nut would rub the shields). Grip 110 + DIN 985
// nylock 8 -> M8x120 leaves 2 mm (>1 pitch) past the nut: the nylon ring is fully engaged.
// Head on -Y (y -60.3..-55), nut on +Y (y 55..63).
tilt_axle   = "M8x120 hex bolt (ISO 4014, partial thread) + M8 DIN 985 nylock + 2x axle_collar";
tilt_axle_len = 120;
axle_collar   = [11.5, 2];              // OD, thickness (ID = m8_clear)
m8_head       = [13, 5.3];              // across flats, height
m8_nylock     = [13, 8];                // across flats, height

// ---------- payload (tilting head) ----------
payload_half_w  = 30;                   // payload body |y| <= 30
payload_x       = [-30, 42];            // body extent along X at tilt 0
payload_z_half  = 20;                   // body z = tilt_z +- 20
payload_pivot_boss_d = 11.5;            // printed SPACER tubes (tilt_spacer.scad) |y| 31 .. 46 bear on the 608 inner races
                                        // through the 14 mm lip hole (integral bosses would print as unsupported overhangs)
payload_axle_bore = m8_clear;           // along Y through the tilt axis
payload_wheel_standoff = [30, 31];      // ring d 40 on BOTH side faces: wheel sits at y 31, spacers bear on the rings
// sweep radius = norm([42,20]) = 46.5  <  tilt_z - (deck_z0 + deck_t) = 49  -> clears deck at any tilt
laser_d     = 12;                       // 12 mm round module, clamp bore
laser_len   = 35;
laser_axis  = [0, 12, tilt_z];          // laser axis parallel to X through this (y,z) at tilt 0
laser_x     = [6, 41];                  // module rear face x=6 (clears the M8 axle, r 4.15) .. emitter x=41
laser_collar = [18, 4];                 // exit collar on the payload front face: OD 18, protrudes 4 (x 42..46)
                                        // beam_stop cap slides over it
cam_axis    = [0, -12, tilt_z];         // camera optical axis, 24 mm baseline to laser
// Camera Module 3 (official drawing RP-008153-DS-1). Integration fix: was [25,24,1.0] / [8.5,8.5,6] (approx).
// Mounted CONNECTOR EDGE DOWN on the payload (rotate the image 180 in software); lens is
// picam3_lens_from_conn above the connector edge. Only vitamins.scad uses these; payload.scad
// carries its own copies of the same numbers.
picam3_board = [25, 23.862, 1.12];      // width (y), height (z), thickness
picam3_holes = [21, 12.5];              // M2 holes
picam3_lens_block = [10.8, 10.8, 4.5];  // lens housing w, h, depth in front of the board
picam3_lens_from_conn = 9.462;          // optical axis above the connector (bottom) edge
picam3_conn  = [19.61, 5.71, 3.2];      // FPC connector on the back at the bottom edge: w, h, depth

// ---------- camera link through the pan axis ----------
// The camera FFC must NOT pass the pan axis: +-175 deg of twist over ~100 mm strains the edge
// conductors of a 16 mm FFC by ~2.5 % (fatigue limit ~0.25 %). Instead the camera link is a
// CSI-to-HDMI extender pair: a short camera FFC (payload -> deck adapter, it only BENDS with tilt),
// a thin round HDMI cable (OD <= 6 mm) down the spigot bore, and a short FFC from the bay adapter
// to the Pi 5 (22-pin "mini" CSI). Twist of a round cable at r <= 2.5 over the defined length
// (deck zip-tie anchor -> bay anchor post, ~110 mm) is <= 0.3 % on the outer strands.
// Both adapters are strapped with 2 zip ties each to printed pads with tunnels (board-agnostic).
camlink_board   = [28, 22, 9];          // adapter envelope: x, y, component height (VERIFY vs the boards bought)
camlink_pad_h   = 3;                    // deck pad (yoke) height above the deck top
camlink_deck_xy = [18.5, -11];          // deck adapter board corner (world, pan 0), on the pad top z 119
camlink_bay_xy  = [58, -11];            // bay adapter board corner, on its pad top (z = 9, board level)
cable_anchor_xy = [50, 0];              // static zip-tie post in the bay (fixes the twist length)
