// =====================================================================
//  laser-gimbal :: payload = tilting head (one print)
//  world (tilt = 0, tilt axis = Y line through [0, 0, tilt_z]):
//    body     x -30..42, |y| <= 30, z 145..185, 2 mm chamfers on the edges || Y
//    axle     d 8.3 bore along Y (capped teardrop toward +X = up when printed)
//    rings    d 40 x 1 mm on both side faces (|y| 30..31): the 51T wheel and the
//             +Y tilt_spacer bear on the +Y ring, the -Y spacer on the -Y ring
//    wheel    3x M3 heat-set inserts in the +Y ring face at r 15, XZ 30/150/270 deg
//    stop     lug on the -Y face at XZ 174..186 deg, r 24 -> flat back x = -30,
//             y -44..-30; its radial faces hit the yoke blocks at -20 / +90 deg
//    laser    12 mm module slides in FROM THE FRONT through the exit collar
//             (OD 18, x 42..46, d 12.2 bore open end to end); rear stop = d 9 step
//             at x 8.9 (wires pass it into the slot, ~3 mm bend room); clamp =
//             M3 insert in the top face + M3x12 nylon-tip set screw; wires drop
//             through a slot behind the module out of the bottom face
//    camera   Raspberry Pi Camera Module 3 PCB flat on the front face (x 42) in a
//             1.2 mm recess, 4x M2 tap holes, FPC connector cavity behind the
//             board; the board is mounted CONNECTOR-EDGE DOWN (rotated 180 deg
//             about the optical axis -> set rotation 180 in software), so the
//             ribbon drops through a front-open slot and runs back in a groove
//             under the body next to the laser wires.
//  Camera numbers are from the official drawing RP-008153-DS-1 (board
//  25 x 23.862 x 1.12, holes M2 21 x 12.5 at 2.0 from the side edges, lens
//  centred in width and 14.4 from the far edge = 9.462 from the connector
//  edge, FPC connector 19.61 wide x 5.71 on the back at the connector edge).
//  Print: rear face (x = -30) on the bed: laser bore vertical, camera recess up,
//  stop lug on the bed. No supports.
// =====================================================================
include <../lib/params.scad>
use <../lib/gears.scad>

pl_x0      = payload_x[0];                    // -30
pl_x1      = payload_x[1];                    // 42
pl_z0      = tilt_z - payload_z_half;         // 145
pl_z1      = tilt_z + payload_z_half;         // 185
pl_hw      = payload_half_w;                  // 30
pl_chamfer = 2;
pl_ring_d  = 40;
pl_ring_fn = 96;

// tilt wheel inserts (WORLD XZ angles, must match parts/tilt_gear.scad)
pl_tg_angs = [30, 150, 270];
pl_ins_dep = m3_insert_h + 1;                 // 6

// laser
pl_las_y     = laser_axis[1];                 // 12
pl_las_bore  = laser_d + 0.2;                 // 12.2
pl_las_x0    = laser_x[0];                    // 6  bore floor
pl_stop_x    = 8.9;                           // module rear face stop (d 9 step below it)
pl_stop_d    = 9;
pl_col_x1    = pl_x1 + laser_collar[1];       // 46
pl_wire      = [[5.9, 12], [9.5, 14.5]];      // wire slot x, y (z: axis -> bottom face)
pl_clamp_x   = 24;

// camera (official drawing; see header)
pc_board     = [25, 23.862, 1.12];            // width (y), height (z), thickness
pc_lens_from_conn = 23.862 - 14.4;            // 9.462
pc_hole_sp   = [21, 12.5];
pc_hole_edge = 2.0;
pc_conn      = [19.61, 5.71, 3.2];            // FPC connector on the back: width, height, depth
pc_y         = cam_axis[1];                   // -12 board centre in y (lens centred)
pc_zc        = tilt_z - pc_lens_from_conn;    // 155.538 connector edge (bottom)
pc_zf        = pc_zc + pc_board[1];           // 179.400 far edge (top)
pc_holes_z   = [pc_zf - pc_hole_edge - pc_hole_sp[1], pc_zf - pc_hole_edge];   // 164.9, 177.4
pc_holes_y   = [pc_y - pc_hole_sp[0] / 2, pc_y + pc_hole_sp[0] / 2];           // -22.5, -1.5
pc_rec       = [pc_board[0] + 0.4, pc_board[1] + 0.4, 1.2];                    // 25.4 x 24.262 x 1.2
pc_floor_x   = pl_x1 - pc_rec[2];             // 40.8
pc_tap_dep   = 6;
pc_ribbon_y  = [-20.5, -3.5];                 // 17 mm for the 16 mm FFC
pc_ribbon_x0 = 37;
pc_groove    = 2;

// ---------- helpers ----------
// extrude an XZ profile (2D x = world x, 2D y = world z) over world y in [y0, y1]
module pl_y_extrude(y0, y1) translate([0, y1, 0]) rotate([90, 0, 0]) linear_extrude(height = y1 - y0) children();
// along +X from x0 to x1, centred on (y, z)
module pl_x_cyl(x0, x1, y, z, d, fn = 64, rot = 0)
    translate([x0, y, z]) rotate([0, 90, 0]) rotate([0, 0, rot]) cylinder(h = x1 - x0, d = d, $fn = fn);
module pl_x_cone(x0, x1, y, z, d0, d1, fn = 64, rot = 0)
    translate([x0, y, z]) rotate([0, 90, 0]) rotate([0, 0, rot]) cylinder(h = x1 - x0, d1 = d0, d2 = d1, $fn = fn);
// capped teardrop, tip toward 2D +x (= world +X): bridge 0.83 r at the top when printed
module pl_tear2d(d) {
    r = d / 2;
    intersection() {
        hull() { circle(r = r, $fn = 64); polygon([[r * sqrt(2), -0.01], [r * sqrt(2), 0.01], [0, 0]]); }
        square([d, d + 1], center = true);
    }
}
module pl_sector2d(a0, a1, r0, r1, n = 12)
    polygon(concat([for (i = [0 : n]) let(a = a0 + (a1 - a0) * i / n) r1 * [cos(a), sin(a)]],
                   [for (i = [n : -1 : 0]) let(a = a0 + (a1 - a0) * i / n) r0 * [cos(a), sin(a)]]));
module pl_box(x, y, z) translate([x[0], y[0], z[0]]) cube([x[1] - x[0], y[1] - y[0], z[1] - z[0]]);

module pl_profile2d() {
    c = pl_chamfer;
    polygon([[pl_x0 + c, pl_z0], [pl_x1 - c, pl_z0], [pl_x1, pl_z0 + c], [pl_x1, pl_z1 - c],
             [pl_x1 - c, pl_z1], [pl_x0 + c, pl_z1], [pl_x0, pl_z1 - c], [pl_x0, pl_z0 + c]]);
}

// ---------- solid ----------
module pl_solid() {
    pl_y_extrude(-pl_hw, pl_hw) pl_profile2d();
    // side rings; polygon turned half a step so no vertex reaches the top/bottom faces
    for (s = [-1, 1]) {
        y0 = s > 0 ? pl_hw - 0.01 : -payload_wheel_standoff[1];
        pl_y_extrude(y0, y0 + payload_wheel_standoff[1] - pl_hw + 0.01)
            translate([0, tilt_z]) rotate(180 / pl_ring_fn) circle(d = pl_ring_d, $fn = pl_ring_fn);
    }
    // stop lug: exact radial contact faces, flat back on the print plane x = -30
    pl_y_extrude(stop_lug_y[0], -pl_hw + 0.5) intersection() {
        translate([0, tilt_z])
            pl_sector2d(stop_lug_ang - stop_w_deg / 2, stop_lug_ang + stop_w_deg / 2, stop_lug_r[0], 40);
        translate([pl_x0, pl_z0]) square([40, 2 * payload_z_half]);
    }
    // laser exit collar
    pl_x_cyl(pl_x1 - 0.01, pl_col_x1, pl_las_y, tilt_z, laser_collar[0], 96);
}

// ---------- cuts ----------
module pl_cuts() {
    // tilt axle
    pl_y_extrude(-payload_wheel_standoff[1] - 1, payload_wheel_standoff[1] + 1)
        translate([0, tilt_z]) pl_tear2d(payload_axle_bore);
    // tilt wheel heat-set inserts from the +Y ring face
    for (a = pl_tg_angs)
        translate([tilt_gear_bolt_r * cos(a), payload_wheel_standoff[1] - pl_ins_dep, tilt_z + tilt_gear_bolt_r * sin(a)])
            rotate([-90, 0, 0]) cylinder(h = pl_ins_dep + 1, d = m3_insert_d, $fn = 24);

    // --- laser ---
    // (was closed at both ends -> the module could not be inserted after printing)
    pl_x_cyl(pl_las_x0, pl_stop_x + 0.01, pl_las_y, tilt_z, pl_stop_d, 48, 180 / 48);
    pl_x_cyl(pl_stop_x, pl_col_x1 + 1, pl_las_y, tilt_z, pl_las_bore, 64);
    // mouth lead-in chamfer on the collar
    pl_x_cone(pl_col_x1 - 0.6, pl_col_x1 + 0.01, pl_las_y, tilt_z, pl_las_bore, pl_las_bore + 1.2, 64, 180 / 64);
    // wire slot behind the module rear, down through the bottom face
    pl_box(pl_wire[0], pl_wire[1], [pl_z0 - 1, tilt_z]);
    // clamp: insert from the top face, clearance down into the bore
    translate([pl_clamp_x, pl_las_y, pl_z1 - pl_ins_dep]) cylinder(h = pl_ins_dep + 1, d = m3_insert_d, $fn = 24);
    translate([pl_clamp_x, pl_las_y, tilt_z]) cylinder(h = payload_z_half - pl_ins_dep + 0.01, d = m3_clear, $fn = 24);

    // --- camera ---
    // board recess
    pl_box([pc_floor_x, pl_x1 + 1], [pc_y - pc_rec[0] / 2, pc_y + pc_rec[0] / 2],
           [pc_zc - 0.2, pc_zc - 0.2 + pc_rec[1]]);
    // M2 tap holes
    for (y = pc_holes_y, z = pc_holes_z) pl_x_cyl(pc_floor_x - pc_tap_dep, pc_floor_x + 0.01, y, z, m2_tap, 24);
    // FPC connector cavity behind the connector (bottom) edge
    pl_box([pc_floor_x - pc_conn[2] - 0.4, pc_floor_x + 0.05], [pc_y - pc_conn[0] / 2 - 0.5, pc_y + pc_conn[0] / 2 + 0.5],
           [pc_zc - 0.5, pc_zc + pc_conn[1] + 0.6]);
    // shallow relief for back-side SMD parts, between the hole columns
    pl_box([pc_floor_x - 2, pc_floor_x + 0.05], [-19.5, -4.5], [pc_zc + 1, pc_zf - 0.8]);
    // ribbon slot (open to the front) down through the bottom face
    pl_box([pc_ribbon_x0, pl_x1 + 1], pc_ribbon_y, [pl_z0 - 1, pc_zc + 0.5]);
    // ribbon groove under the body, back to the laser wire slot
    pl_box([pl_wire[0][0], pc_ribbon_x0 + 0.5], pc_ribbon_y, [pl_z0 - 1, pl_z0 + pc_groove]);
}

module payload() {
    difference() { pl_solid(); pl_cuts(); }
}

// rear face (world x = -30) on the bed, world +X -> print +Z
module payload_print() {
    translate([tilt_z, 0, -pl_x0]) rotate([0, -90, 0]) payload();
}

payload_print();
