// =====================================================================
//  laser-gimbal :: tilt axle collar (print 2)
//  Thin ring under the M8 bolt head (-Y) and under the nylock (+Y): it clamps
//  ONLY the 608 inner race (OD 11.5 < inner-race land ~12), so the 13 AF
//  head / nut cannot rub the bearing shields. Steel 8 x 11.5 x 2 shims work too.
//  Stack: head | collar | 608 | tilt_spacer | payload | tilt_spacer | 608 | collar | nylock
//  (M8x120: 2 mm of thread past the nylock).
//  world: axle_collar() is the +Y one (y 53..55); assembly mirrors it for -Y.
//  Print: flat (print 2), 100 % infill.
// =====================================================================
include <../lib/params.scad>
use <../lib/gears.scad>

module axle_collar_local() {
    difference() {
        cylinder(h = axle_collar[1], d = axle_collar[0], $fn = 48);
        translate([0, 0, -1]) cylinder(h = axle_collar[1] + 2, d = m8_clear, $fn = 32);
    }
}

module axle_collar() translate([0, tilt_brg_y[1], tilt_z]) rotate([-90, 0, 0]) axle_collar_local();

module axle_collar_print() axle_collar_local();

axle_collar_print();
