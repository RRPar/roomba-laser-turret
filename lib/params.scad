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
// pan pinion: world z 100..110 on the pan motor shaft (shaft top = z 116).
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
// boards occupy x in [-42.5, 42.5], y in [-58.5, 58.5] (Pi 5 at +Y, SKR Pico at -Y) on standoffs;
// keep the 4 tubes, the fan and panel parts clear of that zone.

// boards (verify against your actual boards before printing)
pi5_board   = [85, 56];  pi5_holes   = [58, 49];  pi5_hole_inset = 3.5;   // M2.5
skr_pico_board = [85, 56];  skr_pico_holes = [78, 48]; // M3 -- VERIFY vs BTT SKR Pico datasheet
fan40       = [40, 40, 10];  fan40_hole_sp = 32;     // M3
dc_jack_hole = 11.0;    // panel-mount 5.5x2.1 barrel jack
key_switch_hole = 19.0; // 19 mm key switch (laser enable)
estop_hole  = 16.0;     // 16 mm latching button (motor/laser kill)

// ---------- base housing ----------
base_d      = 190;      // cylinder OD (pan motor outer corner reaches r = 87.5)
base_z0     = bay_h;    // 48
base_top    = 98;       // top surface of base top plate
base_top_t  = 6;        // top plate thickness (z 92..98)
pan_motor_xy = [-pan_cd, 0];               // pan motor axis (behind, -X)
pan_motor_face_z = base_top - base_top_t;  // motor face screwed to underside of top plate (z 92)
// pan hub: two 6810 bearings in a bore at the centre of the base
pan_hub_od      = 72;   // hub OD (clears motor body: pan_cd - nema_w/2 = 42.6 > 36)
pan_brg_upper_z = 90;   // bottom face of upper bearing (bearing z 90..97)
pan_brg_lower_z = 72;   // bottom face of lower bearing (bearing z 72..79)
pan_hub_bottom_z = 70;  // hub tube bottom
pan_brg_shoulder_id = 58;  // integral spacer between the bearings (z 79..90) holds both outer races
pan_hall_xy = [45, 0];  // hall sensor (A3144) under the 85T gear, front
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
pan_magnet      = [6, 3];               // 6x3 neodymium in gear underside at r = 45, angle 0

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
// with a 14 mm hole (clears the inner race, catches the outer race). M8 bolt head/nut bear
// on the inner races from outside; payload bosses bear on them from inside.
tilt_brg_y  = [46, 53];
tilt_lip_hole = 14;
// Pan stage keep-out: the pan pinion + motor shaft sweep r 61..66.5 below z 117 relative to the
// rotating yoke -> nothing on the pan stage may sit at r > 56 below z 117.
pan_stage_keepout = [56, 117];
tilt_motor_xz = [-tilt_cd, tilt_z];     // tilt motor axis (parallel to Y), behind the tilt axis
tilt_motor_face_y = arm_inner_y + arm_t;// 53: motor face on OUTSIDE of +Y arm, body extends to +Y
tilt_range  = [-20, 90];                // degrees; hard stops on the yoke

// ---------- tilt drive ----------
tilt_gear_y = [31, 41];                 // 51T wheel and pinion occupy this y range, +Y side
tilt_gear_bolt_r = 20;                  // 3x M3 wheel -> payload (heat-set inserts in payload), at 30,150,270 deg in XZ
tilt_gear_hole = 13;                    // wheel centre hole; payload +Y boss (d 11.5) passes through
tilt_hall_r = 26;                       // 6x3 magnet in the wheel's +Y face (y=41) at radius 26, XZ-angle 90 at tilt 0
                                        // A3144 on the +Y arm inner face at world [0, 45, tilt_z + 26]
// Tilt hard stops (XZ angles measured from +X toward +Z, about the tilt axis):
//  payload stop lug: y in [-40, -32], radial 24..30, centred at 180 deg (behind) at tilt 0, 12 deg wide
//  yoke stop blocks: on the -Y arm inner face, y in [-45, -32], radial 22..32,
//                    block A centred 282 deg (stops +90), block B centred 148 deg (stops -20), 12 deg wide
stop_lug_y = [-40, -32];   stop_lug_r = [24, 30];   stop_lug_ang = 180;  stop_w_deg = 12;
stop_block_y = [-45, -32]; stop_block_r = [22, 32]; stop_block_angs = [282, 148];
tilt_axle   = "M8x110 bolt + nylock";   // pivot only; torque goes wheel -> payload directly

// ---------- payload (tilting head) ----------
payload_half_w  = 30;                   // payload body |y| <= 30
payload_x       = [-30, 42];            // body extent along X at tilt 0
payload_z_half  = 20;                   // body z = tilt_z +- 20
payload_pivot_boss_d = 11.5;            // bosses |y| 30 .. 46 bear on 608 inner races through the 14 mm lip hole
payload_axle_bore = m8_clear;           // along Y through the tilt axis
payload_wheel_standoff = [30, 31];      // ring d 40 on the +Y face so the wheel sits at y 31
// sweep radius = norm([42,20]) = 46.5  <  tilt_z - (deck_z0 + deck_t) = 49  -> clears deck at any tilt
laser_d     = 12;                       // 12 mm round module, clamp bore
laser_len   = 35;
laser_axis  = [0, 12, tilt_z];          // laser axis parallel to X through this (y,z) at tilt 0
laser_x     = [6, 41];                  // module rear face x=6 (clears the M8 axle, r 4.15) .. emitter x=41
laser_collar = [18, 4];                 // exit collar on the payload front face: OD 18, protrudes 4 (x 42..46)
                                        // beam_stop cap slides over it
cam_axis    = [0, -12, tilt_z];         // camera optical axis, 24 mm baseline to laser
picam3_board = [25, 24, 1.0];           // Camera Module 3 PCB
picam3_holes = [21, 12.5];              // M2 holes
picam3_lens_block = [8.5, 8.5, 6.0];    // sensor/lens housing (approx)
