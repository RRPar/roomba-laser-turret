// =====================================================================
//  roomba-laser-turret :: ROBOT BASE interface contract
//  include AFTER lib/params.scad (uses bay_w, bay_screw_xy, m3_*):
//      include <../lib/params.scad>
//      include <../lib/robot_params.scad>
//
//  ROBOT FRAME (all robot parts are authored in it, like the gimbal parts):
//    origin = floor contact plane (z = 0) directly under the pan axis
//    +X = forward (the gimbal's pan 0 direction), +Y = left, +Z = up
//    The whole gimbal sits on the lid: gimbal world z 0 (bay bottom) = robot z rb_deck_z.
//    robot.scad places the gimbal with translate([0, 0, rb_deck_z]).
//
//  Styling comes from the original decorative model (legacy/roomba-turret,
//  120 mm): rounded top edge, groove ring on the lid, front bumper band with a
//  sensor window, round button on the rear lid. The cartoon gun is replaced by
//  the gimbal. Scale ~2.75x (body 120 -> 330 mm).
// =====================================================================

// ---------- body ----------
rb_R        = 165;      // body radius (330 mm, real robot-vacuum size); bay corners reach r ~129
rb_clear    = 14;       // floor plate underside above the floor
rb_floor_t  = 4;        // floor plate z 14 .. 18
rb_floor_top = rb_clear + rb_floor_t;   // 18
rb_deck_z   = 80;       // lid top surface = gimbal bay bottom
rb_lid_t    = 3;        // lid top skin z 77 .. 80
rb_wall_t   = 3;        // outer wall (part of the lid quadrants), r 162 .. 165
rb_edge_r   = 12;       // rounded outer top edge (model: 5 mm)
rb_groove   = [139, 141, 1];   // decorative groove ring on the lid: r0, r1, depth
rb_wall_z0  = rb_floor_top;    // lid wall bottom edge sits on the floor plate rim (z 18)

// Print split (bed 250): floor seams on the diagonals, lid seams on the axes, so
// the seams are staggered and the gimbal mounts (45 deg) sit mid-lid-quadrant.
rb_floor_seams = [45, 135, 225, 315];   // floor quadrants centred on +X, +Y, -X, -Y (box 165 x 233)
rb_lid_seams   = [0, 90, 180, 270];     // lid quadrants between the axes (box 167 x 167)
rb_seam_gap    = 0.3;                   // printed gap at every seam
// joints: floor quadrants overlap the neighbour with a 3 mm lap (half thickness each),
// 2x M3 + heat-set inserts per seam; lid quadrants join with an internal splice tab
// under the skin (2x M3 + inserts per seam). Lid -> floor: 8x M3 from below into
// inserts in wall bosses at r 156, >= 22.5 deg from every floor and lid seam and clear of
// the wheel wells (the two beside the rear of each well moved from 112.5 to 120 deg).
rb_lid_boss_angs = [22.5, 67.5, 120, 157.5, 202.5, 240, 292.5, 337.5];
rb_lid_boss_r    = 156;

// ---------- gimbal mount ----------
// The gimbal's own 4 bay screws (bay_screw_xy, +-60/+-60) become M3x60 DIN 912.
// They start under a 10 mm boss in the lid and clamp lid + bay + gimbal base; the tips
// land exactly where the original M3x50 did. Install them with the lid assembled but
// OFF the floor, then put lid + gimbal onto the floor and fit the 12 lid screws.
rb_mount_boss_t = 10;               // lid boss z 70 .. 80 at each bay_screw_xy
rb_mount_boss_d = 18;
rb_mount_screw  = [3, 60];
// 4 support pillars floor -> lid boss under the mounts (load path for the ~1.6 kg gimbal):
// tube OD 18 / ID 10 (screw head + hex key pass inside), z 18 .. 70, flange screwed to the
// floor with 4x M3 (rb_fix_pillar); the top just bears on the boss.
rb_pillar = [18, 10];
// cables bay <-> base: one 16 mm grommet hole through the lid AND the bay floor at
// rb_grommet_xy (= bay_grommet_xy, chosen clear of the bay's boards/standoffs/tubes). Carries: battery feed up, e-stop motor branch down, Pi 5 USB -> Pico.
rb_grommet_d  = bay_grommet_d;      // from lib/params.scad (bay section)
rb_grommet_xy = bay_grommet_xy;     // [30, 70]: in front of the Pi 5, clear of all bay features

// ---------- drive ----------
// Axle 20 mm BEHIND the pan axis: both gimbal steppers sit at -X, so the robot's CoG is
// near x = 0; with the axle at -20 the front caster carries load and the robot cannot
// rock back at rest (the viewer's stability check reports the real margin).
rb_axle_x   = -20;
rb_axle_z   = 32.5;                 // = wheel radius
rb_wheel_d  = 65;                   // over the tire
rb_wheel_w  = 26;
rb_wheel_y  = 128;                  // wheel centre |y| -> track 256, wheel |y| 115 .. 141
rb_tire_t   = 3;                    // TPU tire (95A) on a printed hub: hub OD 59
rb_well     = [rb_wheel_d / 2 + 5, 112, rb_axle_z + rb_wheel_d / 2 + 5];
                                    // wheel well: |x - axle_x| <= 37.5, |y| >= 112, z <= 70 cut
                                    // through floor + wall (arch opening; lid skin above stays)
// JGA25-370 12 V 170 rpm gear motor with Hall encoder (11 PPR at the motor, ~34:1 gearbox).
// Axis = wheel axis (along Y, at x = rb_axle_x, z = rb_axle_z). Envelope, gearbox face first:
jga25_gear   = [25, 21];            // gearbox d, length
jga25_motor  = [24.4, 31];          // motor can d, length
jga25_enc    = [24.4, 17];          // encoder cap d, length (wires exit its end)
jga25_shaft  = [4, 9, 0.5];         // D-shaft d, length from the gearbox face, flat depth
jga25_face_holes = [17, 3];         // 2x M3 on the gearbox face, spacing (vertical when mounted)
rb_motor_face_y = 113;              // gearbox face |y|; shaft 113 .. 122 -> 7 mm into the hub
                                    // body |y| 113 .. 44 (21 + 31 + 17 = 69)
// motor bracket: printed saddle clamp on the floor around the gearbox and can, 2 straps,
// M3 into floor inserts; the face holes are NOT used (face sits free at |y| 113).
// wheel hub: |y| 115 .. 141, D-bore 4.1 with a flat, M3 set screw onto the flat (M3 insert),
// 2 mm gap to the bracket. Wheel hub ID side faces the body.

// ---------- support ----------
rb_caster_xy  = [135, 0];           // front ball caster, 3/4" steel ball (Pololu #955 class)
rb_caster_h   = 23;                 // floor contact -> mounting face (set with its spacers)
rb_caster_holes = [28, 3];          // 2x M3 at this spacing along Y (placeholder: confirm vs part)
rb_skid_xy    = [-140, 0];          // rear tip skid (printed dome), lowest point:
rb_skid_z     = 3;                  //   3 mm above the floor at rest

// ---------- power + electronics ----------
// 3S2P 18650 Li-ion pack with a 20 A 3S BMS: 11.1 V nominal (9.0 .. 12.6 V), ~7 Ah, ~78 Wh.
rb_batt      = [58, 72, 40];        // pack envelope x, y, z (cells 3 wide x 2 high, 65 long, + BMS)
rb_batt_xy   = [86, 0];             // pack centre: x 57 .. 115, on a tray, 2 strap slots (moved 3 mm back: caster mount clearance)
rb_batt_z0   = rb_floor_top;        // pack on the floor plate (tray floor = floor plate)
// rear electronics tray x -125 .. -50, |y| <= 45 (motors only occupy x -32.5 .. -7.5):
//   Cytron MDD3A dual motor driver (placeholder 52 x 44 x 13), Raspberry Pi Pico (51 x 21),
//   10 A blade fuse holder (35 x 15 x 12), Wago 221 splice block.
rb_ebay_x    = [-125, -50];
rb_mdd3a     = [52, 44, 13];
rb_pico      = [51, 21, 4];
// rear wall (angles measured from +X): main rocker switch KCD1 (cutout 21 x 15) at 195 deg,
// 5.5 x 2.1 charge jack (M8 thread, hole 8.4) at 165 deg, both at z 45.
rb_rocker_ang = 195;  rb_rocker_cut = [21, 15];
rb_jack_ang   = 165;  rb_jack_hole  = 8.4;
rb_panel_z    = 45;
// lid: 16 mm momentary illuminated button ("home": Pico input + LED) in the model's
// "clean button" spot, moved to the rear lid annulus clear of the gimbal, off the 180 deg seam.
rb_button_xy = [135 * cos(172), 135 * sin(172)];   rb_button_hole = 16.5;

// ---------- bumper ----------
// Front arc band (the model's bumper), +-80 deg, outer r 169 (4 mm proud of the body),
// z 22 .. 62, slides 4 mm along X on 4 shoulder screws in slots (wall bosses at +-25, +-65 deg),
// 2 compression springs, 2 microswitches (KW10 lever class, 20 x 10 x 6) at +-40 deg that
// close when the bumper is pushed 2 mm. Printed as 2 halves split at 0 deg + a rear splice plate.
rb_bumper_ang = 80;
rb_bumper_r   = [166, 169];         // inner (1 mm gap to the wall), outer
rb_bumper_z   = [22, 62];
rb_bumper_travel = 4;
rb_bumper_sw_angs = [-40, 40];
rb_sensor_win = [18, 6];            // ToF window (VL53L1X behind it) at 0 deg, centred in the band

// ---------- wiring (hardware) ----------
//   battery + -> 10 A fuse -> rocker -> up the grommet -> the gimbal bay's 12 V input
//   (lands where the DC jack's leads went; the bay jack is unused on the robot).
//   The gimbal's LASER ENABLE CHAIN (lib/params.scad) is unchanged. Its e-stop NC #2
//   "motor branch" now also feeds the MDD3A VM (down the grommet), so the e-stop stops the
//   wheels, the steppers and the laser; the Pi stays powered to shut down cleanly.
//   Charge jack -> BMS charge port (12.6 V 2 A Li-ion charger), never through the rocker.
//   Pi 5 USB -> Pico (wheel controller: MDD3A PWM/DIR, 2 quadrature encoders on PIO,
//   2 bumper switches, lid button + LED, ToF on I2C).
//   Software rule: laser output only while the robot is stopped (wheel speed 0).

// ---------- masses (kg) for the viewer's stability check ----------
// printed parts: from mesh volume (viewer), vitamins nominal:
rb_mass_vit = [["nema17", 0.28], ["jga25", 0.095], ["battery", 0.30], ["caster", 0.03],
               ["pi5", 0.05], ["skr_pico", 0.04], ["b6810", 0.026], ["b608", 0.012],
               ["laser", 0.02], ["camera", 0.005], ["mdd3a", 0.02], ["axle", 0.045]];

// ---------- floor fixings (shared by the floor quadrants and the parts bolted to them) ----------
// Every part that sits on the floor plate is held by M3 screws from BELOW: plain 3.4 holes
// in the floor (heads protrude under the floor, 14 mm clearance), M3 heat-set inserts in the
// bottom of the part. Positions [x, y] in the robot frame; none may fall within 6 mm of a
// floor seam (rb_floor_seams diagonals) -- the floor owner checks and reports any conflict.
rb_fix_motor   = [for (s = [-1, 1], x = [rb_axle_x - 16, rb_axle_x + 16], y = [52, 104]) [x, s * y]];
rb_fix_caster  = [[rb_caster_xy[0] - 12, -18], [rb_caster_xy[0] - 12, 18], [rb_caster_xy[0] + 14, 0]];
rb_fix_batt    = [[82, -44], [82, 44], [116, -44], [116, 44]];   // rear ears moved in: clear of the pillar flanges
rb_fix_ebay    = [[-121, -40], [-121, 40], [-54, -36], [-54, 36]];   // front pair clear of the pillar flanges
// the pillars stand ON the diagonal floor seams, so each flange bridges the seam (2 screws per
// side, 9.9 mm off the seam line):
rb_fix_pillar  = [for (p = bay_screw_xy, a = [0, 90, 180, 270]) p + 14 * [cos(a), sin(a)]];
rb_fix_lid     = [for (a = rb_lid_boss_angs) rb_lid_boss_r * [cos(a), sin(a)]];
// bumper retention: M3 shoulder screws (or M3 + 6 mm OD sleeve) radially into M3 inserts in
// lid-wall bosses at these angles, z 42; the bumper has slots elongated along X
// (length rb_bumper_travel + 6.4). Springs: 2x compression 6 x 10 mm, pockets at +-15 deg, z 42.
// Bumper switches: the lid wall has a through pocket at rb_bumper_sw_angs, z 42, for a KW10
// switch (20 tangential x 10 tall), held from inside by 2x M2 on a boss; its lever must close
// at 2 mm bumper travel.
rb_bumper_screw_angs  = [-65, -25, 25, 65];
rb_bumper_spring_angs = [-15, 15];
rb_bumper_mid_z       = 42;
