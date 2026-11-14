// =====================================================================
//  robot body :: lid quadrant FRONT-LEFT (0..90 deg). Print 1.
//  The four lid quadrants (fl 0..90, rl 90..180, rr 180..270, fr 270..360) share one generic
//  module, robot_lid_quad(a0), defined HERE; robot_lid_rl/rr/fr.scad `use` this file.
//  robot frame: top skin z 77..80, outer wall r 162..165 from z 18 up, rounded outer top edge
//  (R rb_edge_r, centre r 153 z 68), groove ring r 139..141 1 deep on top, quarter disc with
//  rb_seam_gap/2 off each seam line. Everything below belongs to whichever quadrant it lies in.
//  - Seam splice (axes seams): per seam, 2 skin tabs (r 38 and r 100) = a 12x15 block under the
//    skin on each side of the seam, M3 clearance (counterbored head) through the CW-side block
//    (the quadrant that ENDS at the seam), M3 insert hole d4.2 in the CCW-side block, plus a
//    d3 locating pin in a d3.4 hole above the screw. M3x12. On the 180 seam also one wall
//    tab (blocks inside the wall z 52..66, 45-deg gusseted), M3x12 -> 3 screws on that seam. The 0-deg seam has skin tabs only: the wall there is
//    open (|y|<=27, z 37..60, r>=151) for the bumper splice plate and the ToF window.
//    The 90 / 270 seams cross the wheel arches, so they have skin tabs only.
//  - 8 lid bosses (rb_lid_boss_angs, r 156): vertical d4.2 insert holes, bottom flush z 18.
//  - 4 gimbal mount bosses at bay_screw_xy: d18 z 70..80, d3.4 hole.
//  - grommet rb_grommet_d at rb_grommet_xy (cut in both quadrants it straddles), button hole,
//    rocker cut-out (21x15 at 195 deg) and charge-jack hole (165 deg) at z 45.
//  - wheel-well arches (round, R 37.5 around the axle, z 18..70) through the wall.
//  - bumper: 4 M3 insert bosses (radial d4.2) z 42; 2 spring pockets d6.5 x 5 deep z 42;
//    2 switch pockets 20 x 10 (tangential x tall) at +-40 deg with a back boss for 2x M2
//    (pilot d1.8, 9.5 mm apart, assumed KW10 hole spacing).
//  Print: skin down (upside down, z' = 80 - z). The rounded edge overhangs: >45 deg for its first
//    ~3.5 mm, use supports there / expect a rough edge. All radial holes are teardrops.
// =====================================================================
include <../lib/params.scad>
include <../lib/robot_params.scad>

lq_g = rb_seam_gap;
lq_tab_r = [38, 100];            // skin tab radii on a seam
lq_tab = [12, 12, 62];           // x' width, y' length, z bottom (top = rb_deck_z - rb_lid_t)
lq_z_skin = rb_deck_z - rb_lid_t;

function lq_in(a, a0, m = 0) = (((a - a0 + m) % 360 + 360) % 360) < 90 + 2 * m;

module lq_tear2d(d) {
    r = d / 2;
    hull() { circle(r = r, $fn = 32); polygon([[-0.01, -r * 1.4142], [0.01, -r * 1.4142], [0, 0]]); }
}
// hole along +x from 0 to len, apex pointing -z
module lq_tear_x(d, len) rotate([90, 0, 90]) linear_extrude(len) lq_tear2d(d);
// gusseted block in the (r,z) plane, tangential width w, centred on angle 0
module lq_gblock(r0, r1, zb, zt, w) rotate([90, 0, 0]) linear_extrude(w, center = true)
    polygon([[r0, zb], [r0, zt], [r1, zt + (r1 - r0)], [r1, zb]]);

function lq_arc(c, r, a0, a1, n = 24) = [for (i = [0 : n]) c + r * [sin(a0 + (a1 - a0) * i / n), cos(a0 + (a1 - a0) * i / n)]];
module lq_profile() {
    c = [rb_R - rb_edge_r, rb_deck_z - rb_edge_r];
    polygon(concat(
        [[0, lq_z_skin]],
        lq_arc(c, rb_edge_r - rb_lid_t, 0, 90),                // inner arc (153,77) -> (162,68)
        [[rb_R - rb_wall_t, rb_wall_z0], [rb_R, rb_wall_z0]],
        lq_arc(c, rb_edge_r, 90, 0),                           // outer arc (165,68) -> (153,80)
        [[0, rb_deck_z]]));
}
module lq_wedge2d(a0) intersection() {
    rotate(a0) translate([-1, lq_g / 2]) square([400, 400]);
    rotate(a0 + 90) translate([-1, -400 - lq_g / 2]) square([400, 400]);
}
module lq_shell(a0) difference() {
    intersection() {
        rotate(a0) rotate_extrude(angle = 90, $fn = 240) lq_profile();
        linear_extrude(200) lq_wedge2d(a0);
    }
    // groove ring on the lid top
    translate([0, 0, rb_deck_z - rb_groove[2]]) linear_extrude(2) difference() {
        circle(r = rb_groove[1], $fn = 240); circle(r = rb_groove[0], $fn = 240);
    }
}

// ---- seam hardware (seam frame: x' radial, y' toward the CCW quadrant) ----
module lq_skin_tab_side(side, r) {          // side -1 = CW quadrant (clearance), +1 = CCW (insert)
    zt = lq_z_skin + 0.01;
    difference() {
        union() {
            if (side < 0) translate([r - lq_tab[0] / 2, -lq_tab[1], lq_tab[2]]) cube([lq_tab[0], lq_tab[1] - lq_g / 2, zt - lq_tab[2]]);
            else translate([r - lq_tab[0] / 2, lq_g / 2, lq_tab[2]]) cube([lq_tab[0], lq_tab[1] - lq_g / 2, zt - lq_tab[2]]);
            if (side < 0) translate([r, -lq_g / 2 - 0.5, lq_z_skin - 3]) rotate([0, 0, 90]) // locating pin
                translate([0, 0, 0]) rotate([0, 0, 0]) lq_tear_x(3, 4.5 + lq_g / 2);
        }
        if (side < 0) {
            translate([r, -lq_tab[1] - 1, lq_z_skin - 9]) rotate([0, 0, 90]) lq_tear_x(m3_clear, lq_tab[1] + 1 - lq_g / 2 + 0.5);
            translate([r, -lq_tab[1] - 1, lq_z_skin - 9]) rotate([0, 0, 90]) lq_tear_x(6.6, 1 + 3.5 + 1.3);
        } else {
            translate([r, lq_g / 2 - 0.1, lq_z_skin - 9]) rotate([0, 0, 90]) lq_tear_x(m3_insert_d, 7);
            translate([r, lq_g / 2 - 0.1, lq_z_skin - 3]) rotate([0, 0, 90]) lq_tear_x(3.4, 5);
        }
    }
}
module lq_wall_tab_side(side) {
    zb = 52; zt = 66; r0 = 152; r1 = rb_R - rb_wall_t + 0.01; zs = 59;
    difference() {
        if (side < 0) translate([0, -lq_g / 2, 0]) rotate([90, 0, 0]) linear_extrude(lq_tab[1] - lq_g / 2)
            polygon([[r0, zb], [r0, zt], [r1, zt + r1 - r0], [r1, zb]]);
        else translate([0, lq_tab[1], 0]) rotate([90, 0, 0]) linear_extrude(lq_tab[1] - lq_g / 2)
            polygon([[r0, zb], [r0, zt], [r1, zt + r1 - r0], [r1, zb]]);
        if (side < 0) {
            translate([157, -lq_tab[1] - 1, zs]) rotate([0, 0, 90]) lq_tear_x(m3_clear, lq_tab[1] + 1 - lq_g / 2 + 0.5);
            translate([157, -lq_tab[1] - 1, zs]) rotate([0, 0, 90]) lq_tear_x(6.6, 1 + 3.5 + 1.3);
        } else
            translate([157, lq_g / 2 - 0.1, zs]) rotate([0, 0, 90]) lq_tear_x(m3_insert_d, 7);
    }
}
module lq_seam(s, side) rotate(s) {
    for (r = lq_tab_r) lq_skin_tab_side(side, r);
    if (s == 180) lq_wall_tab_side(side);   // not at 0 deg: front opening
}

module robot_lid_quad(a0) {
    z = rb_bumper_mid_z;
    difference() {
        union() {
            lq_shell(a0);
            lq_seam(a0, 1);                 // this quadrant is the CCW side of its start seam
            lq_seam(a0 + 90, -1);           // and the CW side of its end seam
            for (p = bay_screw_xy) if (lq_in(atan2(p[1], p[0]), a0))
                translate([p[0], p[1], rb_deck_z - rb_mount_boss_t]) cylinder(d = rb_mount_boss_d, h = rb_mount_boss_t - 2, $fn = 64);
            for (a = rb_lid_boss_angs) if (lq_in(a, a0)) rotate(a) translate([0, 0, rb_wall_z0])
                { translate([0, 0, 0]) lq_gblock(150, rb_R - rb_wall_t + 0.01, 0, 12, 11); }
            for (a = rb_bumper_screw_angs) if (lq_in(a, a0)) rotate(a) lq_gblock(150, rb_R - rb_wall_t + 0.01, z - 5, z + 5, 10);
            for (a = rb_bumper_spring_angs) if (lq_in(a, a0)) rotate(a) lq_gblock(152, rb_R - rb_wall_t + 0.01, z - 6, z + 6, 12);
            for (a = rb_bumper_sw_angs) if (lq_in(a, a0)) rotate(a) lq_gblock(146, rb_R - rb_wall_t + 0.01, z - 10, z + 10, 30);
        }
        // mount screw holes, grommet, button
        for (p = bay_screw_xy) if (lq_in(atan2(p[1], p[0]), a0))
            translate([p[0], p[1], rb_deck_z - rb_mount_boss_t - 1]) cylinder(d = m3_clear, h = rb_mount_boss_t + 2, $fn = 24);
        if (lq_in(atan2(rb_grommet_xy[1], rb_grommet_xy[0]), a0, 8))
            translate([rb_grommet_xy[0], rb_grommet_xy[1], lq_z_skin - 1]) cylinder(d = rb_grommet_d, h = 5, $fn = 48);
        if (lq_in(atan2(rb_button_xy[1], rb_button_xy[0]), a0))
            translate([rb_button_xy[0], rb_button_xy[1], lq_z_skin - 1]) cylinder(d = rb_button_hole, h = 5, $fn = 48);
        // lid bosses: insert holes
        for (a = rb_lid_boss_angs) if (lq_in(a, a0))
            translate([rb_lid_boss_r * cos(a), rb_lid_boss_r * sin(a), rb_wall_z0 - 1]) cylinder(d = m3_insert_d, h = 7, $fn = 24);
        // panel holes
        if (lq_in(rb_rocker_ang, a0)) rotate(rb_rocker_ang) translate([rb_R - 8, -rb_rocker_cut[0] / 2 - 0.3, rb_panel_z - rb_rocker_cut[1] / 2 - 0.3])
            cube([15, rb_rocker_cut[0] + 0.6, rb_rocker_cut[1] + 0.6]);
        if (lq_in(rb_jack_ang, a0)) rotate(rb_jack_ang) translate([rb_R - 8, 0, rb_panel_z]) lq_tear_x(rb_jack_hole, 15);
        // wheel-well arches
        for (s = [-1, 1]) if (lq_in(s > 0 ? 45 : -45, a0, 45))
            translate([rb_axle_x, 0, rb_axle_z]) {
                translate([0, s > 0 ? rb_well[1] : -rb_R - 10, 0]) rotate([-90, 0, 0]) cylinder(r = rb_well[0], h = rb_R + 10 - rb_well[1], $fn = 96);
                translate([-rb_well[0], s > 0 ? rb_well[1] : -rb_R - 10, -rb_axle_z - 1]) cube([2 * rb_well[0], rb_R + 10 - rb_well[1], rb_axle_z + 1]);
            }
        // combined front opening (bumper splice plate + ToF window), split over fl / fr at the 0 deg seam
        if (lq_in(0, a0, 8)) translate([151, -27, 37]) cube([20, 54, 23]);
        // bumper hardware
        for (a = rb_bumper_screw_angs) if (lq_in(a, a0)) rotate(a) translate([151, 0, z]) lq_tear_x(m3_insert_d, 16);
        for (a = rb_bumper_spring_angs) if (lq_in(a, a0)) rotate(a) translate([rb_R - 5, 0, z]) lq_tear_x(6.5, 7);
        for (a = rb_bumper_sw_angs) if (lq_in(a, a0)) rotate(a) {
            translate([156, -10.3, z - 5.3]) cube([15, 20.6, 10.6]);
            for (t = [-4.75, 4.75]) translate([147, t, z]) lq_tear_x(1.8, 9.1);
        }
    }
}

module robot_lid_fl() robot_lid_quad(0);
module robot_lid_fl_print() translate([0, 0, rb_deck_z]) rotate([180, 0, 0]) robot_lid_fl();

robot_lid_fl_print();
