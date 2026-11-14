// =====================================================================
//  laser-gimbal :: tilt axle spacer (print 2)
//  Tube on the M8 axle between the payload side ring (|y| 31) and the 608
//  inner race (|y| 46). Passes the arm's 14 mm lip hole and, on +Y, the
//  tilt wheel's 13 mm centre hole. The M8 bolt clamps
//  inner race | spacer | payload | spacer | inner race  into one rigid stack
//  (M8x120: head and nylock bear on axle_collar rings on the 608 inner races, params tilt_axle).
//  world: tilt_spacer() is the +Y one (y 31..46); assembly mirrors it for -Y.
//  Print: standing on an end.
// =====================================================================
include <../lib/params.scad>
use <../lib/gears.scad>

ts_len = tilt_brg_y[0] - payload_wheel_standoff[1];   // 15

module tilt_spacer_local() {
    difference() {
        cylinder(h = ts_len, d = payload_pivot_boss_d, $fn = 48);
        translate([0, 0, -1]) cylinder(h = ts_len + 2, d = m8_clear, $fn = 32);
        for (z = [0, ts_len]) translate([0, 0, z]) mirror([0, 0, z > 0 ? 1 : 0])
            translate([0, 0, -0.01]) cylinder(h = 0.41, d1 = m8_clear + 0.8, d2 = m8_clear - 0.02, $fn = 32);
    }
}

module tilt_spacer() {
    translate([0, payload_wheel_standoff[1], tilt_z]) rotate([-90, 0, 0]) tilt_spacer_local();
}

module tilt_spacer_print() { tilt_spacer_local(); }

tilt_spacer_print();
