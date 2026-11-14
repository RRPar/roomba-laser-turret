// =====================================================================
//  roomba-laser-turret :: purchased-part placeholders for the ROBOT BASE
//  (assembly / collision checks, NOT printed). Robot frame (see robot_params.scad).
//      include <../lib/params.scad>
//      include <../lib/robot_params.scad>
//      use <../lib/robot_vitamins.scad>        (or include it)
//  Boards are drawn at their tray positions (parts/robot_ebay_tray.scad layout).
// =====================================================================
include <params.scad>
include <robot_params.scad>

// e-bay layout shared with parts/robot_ebay_tray.scad (kept in sync by hand)
rbv_mdd_c  = [-92, -20];     // MDD3A centre
rbv_pico_c = [-87, 14];    // Pico centre
rbv_fuse_c = [-87, 35];    // fuse holder centre
rbv_ebay_top = rb_floor_top + 3;   // tray plate top (z 21)

// JGA25-370 gear motor, side = +1 (left, +y) / -1 (right). Axis along Y at x = rb_axle_x,
// z = rb_axle_z, gearbox face at |y| = rb_motor_face_y, body toward y = 0, shaft outward.
// The D-shaft flat faces +X.
module jga25(side = 1) {
    translate([rb_axle_x, side * rb_motor_face_y, rb_axle_z])
        rotate([side > 0 ? 90 : -90, 0, 0]) {       // local +Z = toward the body
            color("goldenrod") cylinder(h = jga25_gear[1], d = jga25_gear[0], $fn = 64);
            color("silver") translate([0, 0, -1.5]) cylinder(h = 1.5, d = 12, $fn = 40);
            color("dimgray") translate([0, 0, jga25_gear[1]]) cylinder(h = jga25_motor[1], d = jga25_motor[0], $fn = 64);
            color("#223") translate([0, 0, jga25_gear[1] + jga25_motor[1]])
                cylinder(h = jga25_enc[1], d = jga25_enc[0], $fn = 64);
            color("silver") translate([0, 0, -jga25_shaft[1]]) difference() {
                cylinder(h = jga25_shaft[1] + 0.01, d = jga25_shaft[0], $fn = 32);
                translate([jga25_shaft[0] / 2 - jga25_shaft[2], -3, -1]) cube([3, 6, jga25_shaft[1] + 2]);
            }
        }
}

// 3/4" ball caster: ball touches z = 0, housing + 17 x 32 plate whose underside is the mounting
// face at z rb_caster_h, 2x M3 along Y at rb_caster_holes[0] (placeholder size: confirm vs part).
rbv_caster_plate = [16, 32, 2];
module ball_caster() {
    translate([rb_caster_xy[0], rb_caster_xy[1], 0]) {
        color("silver") translate([0, 0, 9.5]) hull() { sphere(d = 19, $fn = 48); translate([0, 0, -9.5]) cylinder(h = 0.01, d = 0.5, $fn = 8); }
        color("dimgray") translate([0, 0, 12]) cylinder(h = rb_caster_h - 12, d = 20, $fn = 48);
        color("dimgray") translate([-rbv_caster_plate[0] / 2, -rbv_caster_plate[1] / 2, rb_caster_h])
            difference() {
                cube(rbv_caster_plate);
                for (s = [-1, 1]) translate([rbv_caster_plate[0] / 2, rbv_caster_plate[1] / 2 + s * rb_caster_holes[0] / 2, -1])
                    cylinder(h = 4, d = 3.4, $fn = 16);
            }
    }
}

module battery_pack() {
    color("royalblue") translate([rb_batt_xy[0] - rb_batt[0] / 2, rb_batt_xy[1] - rb_batt[1] / 2, rb_batt_z0])
        cube(rb_batt);
}

module mdd3a() {   // placeholder 52 x 44 x 13 at the e-bay layout, on 5 mm standoffs
    color("crimson") translate([rbv_mdd_c[0] - rb_mdd3a[0] / 2, rbv_mdd_c[1] - rb_mdd3a[1] / 2, rbv_ebay_top + 5])
        cube(rb_mdd3a);
}

module pico() {
    translate([rbv_pico_c[0] - rb_pico[0] / 2, rbv_pico_c[1] - rb_pico[1] / 2, rbv_ebay_top + 4]) {
        color("seagreen") cube([rb_pico[0], rb_pico[1], 1.6]);
        color("silver") translate([-1.5, rb_pico[1] / 2 - 4, 1.6]) cube([5.5, 8, 2.4]);   // micro-USB
    }
}

module fuse_holder() {   // 35 x 15 x 12 blade-fuse holder
    color("darkorange") translate([rbv_fuse_c[0] - 17.5, rbv_fuse_c[1] - 7.5, rbv_ebay_top]) cube([35, 15, 12]);
}

// radial helper: local +X = outward at wall angle a
module rbv_at_wall(a, z) { rotate([0, 0, a]) translate([0, 0, z]) children(); }

module rocker_switch() {   // KCD1, cutout 21 x 15, body behind the wall, flange outside (r 165)
    rbv_at_wall(rb_rocker_ang, rb_panel_z) {
        color("black") translate([150, -rb_rocker_cut[0] / 2, -rb_rocker_cut[1] / 2])
            cube([15.0, rb_rocker_cut[0], rb_rocker_cut[1]]);
        color("#c00") translate([165.05, -11, -8]) cube([1.5, 22, 16]);
        color("#c00") translate([166.55, -10, -6]) rotate([0, 0, 0]) cube([2, 20, 12]);
    }
}

module charge_jack() {   // 5.5 x 2.1 panel jack, M8 thread, hole 8.4
    rbv_at_wall(rb_jack_ang, rb_panel_z) {
        color("black") translate([150, 0, 0]) rotate([0, 90, 0]) cylinder(h = 15, d = 8, $fn = 24);
        color("silver") translate([165, 0, 0]) rotate([0, 90, 0]) cylinder(h = 3, d = 12, $fn = 6);
    }
}

module lid_button() {   // 16 mm momentary illuminated button through the lid (top z rb_deck_z)
    translate([rb_button_xy[0], rb_button_xy[1], 0]) {
        color("silver") translate([0, 0, rb_deck_z - 14]) cylinder(h = 14, d = 16, $fn = 40);
        color("limegreen") translate([0, 0, rb_deck_z]) cylinder(h = 3, d = 17.5, $fn = 40);
    }
}

// KW10-class microswitch behind the lid wall pocket at rb_bumper_sw_angs[i], z 42:
// body 20 tangential x 10 tall x 6 radial (r 157 .. 163), lever out to r 165.4.
module kw10_switch(i = 0) {
    rbv_at_wall(rb_bumper_sw_angs[i], rb_bumper_mid_z) {
        color("#888") translate([157, -10, -5]) cube([6, 20, 10]);
        color("silver") translate([162, -8, 3.5]) cube([3.4, 16, 0.6]);
    }
}

module tof_sensor() {   // VL53L1X board behind the window at 0 deg, lens toward +X
    rbv_at_wall(0, rb_bumper_mid_z) {
        color("purple") translate([156, -6.5, -5]) cube([1.6, 13, 10]);
        color("#111") translate([157.6, -2.5, -2.5]) cube([4, 5, 5]);
    }
}

module robot_vitamins() {
    for (s = [-1, 1]) jga25(s);
    ball_caster();
    battery_pack();
    mdd3a(); pico(); fuse_holder();
    rocker_switch(); charge_jack(); lid_button();
    for (i = [0, 1]) kw10_switch(i);
    tof_sensor();
}
