// =====================================================================
//  laser-gimbal :: yoke = deck + two arms (one print)
//  world (pan = 0):
//    deck     z 110..116 on the turntable gear top, 4x M3x8 into the gear's
//             heat-set inserts (heads counterbored), centre cable hole d 30
//    arms     |y| 45..53 up to the tilt axis (z 165); 608 pockets open to the
//             OUTSIDE (bearing |y| 46..53) behind a 1 mm lip with a 14 mm hole
//    +Y arm   tilt NEMA17 on tilt_motor_plate.scad, which sits in a pocket in the
//             arm's OUTER face (core y 48..53, ears y 50..53; open to the rear) and is
//             clamped by 4x M3x8 from OUTSIDE through X-slots into heat-set inserts
//             (2 mm bosses on the inner face, r >= 42 from the tilt axis): backlash is
//             set and the motor removed with the payload + wheel installed. The 3 mm
//             web has the pinion opening (d 24.75) and clearance for the 4 motor-screw
//             heads, all slotted over mesh_slot.
//             A3144 seat on the inside face at [0, 45, tilt_z + 26]
//    -Y arm   tilt hard-stop blocks (stop at -20 / +90 deg against the payload lug)
//    deck     zip-tie anchor behind the cable hole (camera-link round cable + wires),
//             camera-link adapter pad in front of it (2 zip-tie tunnels along Y)
//  Pan-stage keep-out: everything outside r = 50 is trimmed below a 45-deg cone
//  z = 110 + (r - 50) -> clears the pan pinion (z <= 110, shaft top z 110) at any pan
//  angle, and every underside stays <= 45 deg for printing.
//  Print: deck on the bed (as modelled, shifted down by 110). No supports.
// =====================================================================
include <../lib/params.scad>
use <../lib/gears.scad>

yk_deck_r   = deck_d / 2 - 1;                   // 51: inside the gear root (51.56)
yk_foot_p   = [[-45, 33], [deck_z0, 124]];      // +Y arm foot box (XZ): wide at the back for the motor plate
                                                // (x -45: the hull edge up to the motor plate corner stays <= 45 deg)
yk_foot_m   = [[-33, 33], [deck_z0, 124]];      // -Y arm foot box
yk_boss_r   = arm_boss_d / 2;                   // 17
yk_hall     = [0, tilt_z + tilt_hall_r];        // A3144 position (x, z) on the +Y inner face
yk_hall_tab = 7;
// arm area carrying the tilt motor plate pocket (+ walls): x -66 (pocket open to the rear) .. -17,
// z 131 .. 203.5 (above the 45-deg ceiling of the top ear pocket)
yk_mplate   = [[-66, -17], [131, 203.5]];
yk_cb       = [m3_head_d + 0.6, m3_head_h + 0.2];
yk_mp_fit   = 0.3;                              // plate -> pocket clearance (XZ)
yk_mp_web   = arm_inner_y + arm_t - tilt_mplate_t[0];   // 48: pocket floor under the plate core
yk_ins_boss = [9, 2];                           // inner-face boss d, height (insert y 44..50, 1 mm floor)
yk_pad      = [[camlink_deck_xy[0] - 1, camlink_deck_xy[0] + camlink_board[0] + 1],
               [camlink_deck_xy[1] - 1, camlink_deck_xy[1] + camlink_board[1] + 1]];   // camera-link pad XY
yk_pad_tun  = [4, 1.9];                         // zip-tie tunnel width (x), height (0.5 into the deck)
yk_gusset   = [20, 10];                         // half-width in X, leg length (45 deg)
yk_cone_r0  = 50;
yk_tie      = [[-28, -20], [-5, 5], 7];         // zip-tie anchor x range, y range, height
yk_hall_pk  = [4.8, 1.8, 4.2];                  // A3144 (TO-92S ~4.0 x 1.5 x 3.0) pocket x, depth y, z

// ---------- 2D helpers (XZ plane: 2D x = world x, 2D y = world z) ----------
// teardrop capped flat at the circle top (bridge 0.83 r): horizontal holes print unsupported
module tear2d(d) {
    r = d / 2;
    intersection() {
        hull() { circle(r = r, $fn = 64); polygon([[-0.01, r * sqrt(2)], [0.01, r * sqrt(2)], [0, 0]]); }
        square([d + 1, d], center = true);
    }
}
// swept over the motor plate travel (things that move WITH the plate)
module mslot2d() hull() for (dx = mesh_slot) translate([dx, 0]) children();
module sector2d(a0, a1, r0, r1, n = 12)
    polygon(concat([for (i = [0 : n]) let(a = a0 + (a1 - a0) * i / n) r1 * [cos(a), sin(a)]],
                   [for (i = [n : -1 : 0]) let(a = a0 + (a1 - a0) * i / n) r0 * [cos(a), sin(a)]]));
module box2d(b) translate([b[0][0], b[1][0]]) square([b[0][1] - b[0][0], b[1][1] - b[1][0]]);

// tilt motor plate outline (XZ), shared with parts/tilt_motor_plate.scad (which `use`s this file)
module tmp_core2d() translate(tilt_motor_xz)
    offset(r = 3, $fn = 24) square(2 * (tilt_mplate_half - 3), center = true);
module tmp_ear2d(sz) translate(tilt_motor_xz) hull() {   // sz = -1 lower ear, +1 upper ear
    xs = [for (e = tilt_mplate_screws) if (sign(e[1]) == sz) e[0]];
    // ear screws are fixed in the arm: relative to the plate they travel -mesh_slot -> ear covers that slot
    for (e = tilt_mplate_screws, dx = -mesh_slot) if (sign(e[1]) == sz) translate(e + [dx, 0]) circle(r = 4.6, $fn = 48);
    translate([(min(xs) + max(xs)) / 2, sz * (tilt_mplate_half - 4)]) square([max(xs) - min(xs) + 6, 4], center = true);
}
module tmp_ears2d() { tmp_ear2d(-1); tmp_ear2d(1); }

// extrude an XZ profile over world y in [y0, y1]
module y_extrude(y0, y1) translate([0, y1, 0]) rotate([90, 0, 0]) linear_extrude(height = y1 - y0) children();

// ---------- arm profiles ----------
module arm_plus2d() hull() {
    box2d(yk_foot_p);
    translate([0, tilt_z]) circle(r = yk_boss_r, $fn = 96);
    translate(yk_hall) circle(r = yk_hall_tab, $fn = 48);
    box2d(yk_mplate);
}
module arm_minus2d() hull() {
    box2d(yk_foot_m);
    translate([0, tilt_z]) circle(r = yk_boss_r, $fn = 96);
    for (a = stop_block_angs) translate([0, tilt_z])
        sector2d(a - stop_w_deg / 2, a + stop_w_deg / 2, stop_block_r[0], stop_block_r[1]);
}

// ---------- solids ----------
module yk_solid() {
    // deck (disc + arm foot pads)
    translate([0, 0, deck_z0]) linear_extrude(height = deck_t) union() {
        circle(r = yk_deck_r, $fn = 128);
        translate([yk_foot_p[0][0], arm_inner_y - yk_gusset[1]]) square([yk_foot_p[0][1] - yk_foot_p[0][0], arm_t + yk_gusset[1]]);
        translate([yk_foot_m[0][0], -arm_inner_y - arm_t]) square([yk_foot_m[0][1] - yk_foot_m[0][0], arm_t + yk_gusset[1]]);
    }
    y_extrude(arm_inner_y, arm_inner_y + arm_t) arm_plus2d();
    y_extrude(-arm_inner_y - arm_t, -arm_inner_y) arm_minus2d();
    // hard-stop blocks: 5 mm stubs on the -Y arm inner face
    for (a = stop_block_angs) y_extrude(-arm_inner_y - 0.5, stop_block_y[1]) translate([0, tilt_z])
        sector2d(a - stop_w_deg / 2, a + stop_w_deg / 2, stop_block_r[0], stop_block_r[1]);
    // 45-deg root gussets inside both arms (below the wheel: z <= 126 < 131)
    for (m = [0, 1]) mirror([0, m, 0])
        translate([-yk_gusset[0], 0, 0]) rotate([90, 0, 90]) linear_extrude(height = 2 * yk_gusset[0])
            polygon([[arm_inner_y + 0.5, deck_z0 + deck_t - 0.01], [arm_inner_y - yk_gusset[1], deck_z0 + deck_t - 0.01],
                     [arm_inner_y + 0.5, deck_z0 + deck_t + yk_gusset[1]]]);
    // zip-tie anchor
    translate([yk_tie[0][0], yk_tie[1][0], deck_z0 + deck_t - 0.01])
        cube([yk_tie[0][1] - yk_tie[0][0], yk_tie[1][1] - yk_tie[1][0], yk_tie[2] + 0.01]);
    // camera-link adapter pad
    translate([yk_pad[0][0], yk_pad[1][0], deck_z0 + deck_t - 0.01])
        cube([yk_pad[0][1] - yk_pad[0][0], yk_pad[1][1] - yk_pad[1][0], camlink_pad_h + 0.01]);
    // tilt motor plate insert bosses on the +Y arm inner face (2 mm, y 43..45), pointed underside (45 deg)
    for (e = tilt_mplate_screws) y_extrude(arm_inner_y - yk_ins_boss[1], arm_inner_y + 0.01)
        translate(tilt_motor_xz + e) hull() {
            circle(d = yk_ins_boss[0], $fn = 32);
            translate([0, -yk_ins_boss[0] / 2 * sqrt(2)]) square(0.02, center = true);
        }
}

// ---------- cuts ----------
// pocket from y0 out through the +Y outer face; the (convex) outline's top edge rises 45 deg outward
module sloped_pocket(y0) {
    y1 = tilt_motor_face_y + 1;
    hull() {
        y_extrude(y0, y0 + 0.01) children();
        y_extrude(y1 - 0.01, y1) children();
        y_extrude(y1 - 0.01, y1) translate([0, y1 - y0]) children();
    }
}
module yk_cuts() {
    // pan-stage keep-out cone (also the 45-deg print chamfer under the deck rim)
    // turned half a facet step so its meridian edges never pass through the deck-rim
    // vertices (r 51 meets the cone exactly at z 111 -> degenerate edge crossings)
    rotate([0, 0, 180 / 128]) rotate_extrude($fn = 128)
        polygon([[yk_cone_r0, deck_z0 - 1], [yk_cone_r0, deck_z0], [400, deck_z0 + 400 - yk_cone_r0], [400, deck_z0 - 1]]);
    // cable hole + chamfers
    translate([0, 0, deck_z0 - 1]) cylinder(h = deck_t + 2, d = deck_cable_hole, $fn = 96);
    translate([0, 0, deck_z0 + deck_t - 0.8]) cylinder(h = 0.81, d1 = deck_cable_hole, d2 = deck_cable_hole + 1.6 + 0.02, $fn = 96);
    // deck -> turntable screws
    for (a = [45 : 90 : 315]) rotate([0, 0, a]) translate([deck_screws_r, 0, 0]) {
        translate([0, 0, deck_z0 - 1]) cylinder(h = deck_t + 2, d = m3_clear, $fn = 24);
        translate([0, 0, deck_z0 + deck_t - yk_cb[1]]) cylinder(h = yk_cb[1] + 1, d = yk_cb[0], $fn = 32);
    }
    // 608 pockets (outside) + 14 mm lip holes, both arms
    for (s = [1, -1]) {
        y_extrude(s > 0 ? tilt_brg_y[0] : -tilt_brg_y[1] - 1, s > 0 ? tilt_brg_y[1] + 1 : -tilt_brg_y[0])
            translate([0, tilt_z]) tear2d(bearing_bore(b608));
    }
    y_extrude(arm_inner_y - 1, tilt_brg_y[0] + 0.5) translate([0, tilt_z]) tear2d(tilt_lip_hole);
    y_extrude(-tilt_brg_y[0] - 0.5, -arm_inner_y + 1) translate([0, tilt_z]) tear2d(tilt_lip_hole);
    // tilt motor plate pocket in the +Y arm outer face: core (5 deep) + ears (3 deep), swept over
    // the plate travel; open to the rear (x < -66). Ceilings rise 45 deg toward the outer face
    // (the yoke prints with the arms vertical: no flat overhang over the pocket depth).
    sloped_pocket(yk_mp_web) mslot2d() offset(delta = yk_mp_fit) tmp_core2d();
    sloped_pocket(yk_mp_web) translate([tilt_motor_xz[0] - 30, tilt_motor_xz[1] - tilt_mplate_half - yk_mp_fit])
        square([30 + mesh_slot[0] + 0.01 - tilt_mplate_half + 3, 2 * (tilt_mplate_half + yk_mp_fit)]);
    for (sz = [-1, 1]) sloped_pocket(tilt_motor_face_y - tilt_mplate_t[1]) mslot2d() offset(delta = yk_mp_fit) tmp_ear2d(sz);
    // web: pinion opening (motor + pinion come out together after -3 mm) + motor-screw head clearance
    y_extrude(arm_inner_y - 1, yk_mp_web + 0.01) {
        mslot2d() translate(tilt_motor_xz) tear2d(tilt_pinion_hole);
        for (sx = [-1, 1], sz = [-1, 1])
            mslot2d() translate(tilt_motor_xz + [sx, sz] * nema_hole_sp / 2) tear2d(m3_head_d + 1.2);
    }
    // heat-set inserts for the plate ear screws (from the ear pocket floor y 50, 6 deep)
    for (e = tilt_mplate_screws)
        translate([tilt_motor_xz[0] + e[0], tilt_motor_face_y - tilt_mplate_t[1] + 0.01, tilt_motor_xz[1] + e[1]])
            rotate([90, 0, 0]) cylinder(h = m3_insert_h + 1 + 0.01, d = m3_insert_d, $fn = 24);
    // camera-link pad: 2 zip-tie tunnels along Y
    for (x = [yk_pad[0][0] + 6, yk_pad[0][1] - 6])
        translate([x - yk_pad_tun[0] / 2, yk_pad[1][0] - 1, deck_z0 + deck_t - 0.5])
            cube([yk_pad_tun[0], yk_pad[1][1] - yk_pad[1][0] + 2, yk_pad_tun[1]]);
    // A3144 pocket on the +Y inner face + lead groove up + lead hole through to the outside
    translate([yk_hall[0] - yk_hall_pk[0] / 2, arm_inner_y - 1, yk_hall[1] - yk_hall_pk[2] / 2])
        cube([yk_hall_pk[0], yk_hall_pk[1] + 1, yk_hall_pk[2]]);
    translate([yk_hall[0] - 1.5, arm_inner_y - 1, yk_hall[1]]) cube([3, yk_hall_pk[1] + 1, 4.5]);
    translate([yk_hall[0] - 1.5, arm_inner_y - 1, yk_hall[1] + 2.5]) cube([3, arm_t + 2, 2]);
    // zip-tie tunnel (along X)
    translate([yk_tie[0][0] - 1, -2.5, deck_z0 + deck_t + 1.5]) cube([yk_tie[0][1] - yk_tie[0][0] + 2, 5, 2.5]);
}

module yoke() difference() { yk_solid(); yk_cuts(); }

module yoke_print() translate([0, 0, -deck_z0]) yoke();

yoke_print();
