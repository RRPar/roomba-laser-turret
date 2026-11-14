// =====================================================================
//  laser-gimbal :: beam-stop cap
//  Push-fit cap over the laser exit collar (OD 18, x 42..46 on laser_axis).
//  Solid 3 mm end blocks the beam completely: fit it whenever the gimbal is
//  being assembled, tested or tuned. Print in BLACK / opaque filament,
//  100% infill for the end disc. Tether loop: tie it to the yoke with a
//  short cord so it is always at hand.
//  world: tilt = 0, on the collar.
//  Print: end face on the bed (as local).
// =====================================================================
include <../lib/params.scad>
use <../lib/gears.scad>

bs_bore  = laser_collar[0] + 0.4;   // 18.4 + 3 crush ribs -> light interference
bs_rib   = 0.35;
bs_depth = laser_collar[1];         // covers the whole collar
bs_end   = 3;
bs_wall  = 2;
bs_od    = bs_bore + 2 * bs_wall;
bs_len   = bs_end + bs_depth;

module beam_stop_local() {
    difference() {
        union() {
            cylinder(h = bs_len, d = bs_od, $fn = 64);
            // tether tab with a 4 mm hole, lying on the bed
            hull() {
                cylinder(h = 2.4, d = 8, $fn = 32);
                translate([bs_od / 2 + 4, 0, 0]) cylinder(h = 2.4, d = 8, $fn = 32);
            }
        }
        translate([bs_od / 2 + 4, 0, -1]) cylinder(h = 5, d = 4, $fn = 24);
        translate([0, 0, bs_end]) difference() {
            cylinder(h = bs_depth + 1, d = bs_bore, $fn = 64);
            for (a = [0, 120, 240]) rotate([0, 0, a + 60]) translate([bs_bore / 2, 0, 0])
                cylinder(h = bs_depth + 1, d = 2 * bs_rib, $fn = 12);
        }
        // mouth chamfer
        translate([0, 0, bs_len - 0.6]) cylinder(h = 0.61, d1 = bs_bore, d2 = bs_bore + 1.2, $fn = 64);
    }
}

// local z = 0 (end face) sits in front of the collar at x = 49, mouth faces -X
module beam_stop() {
    translate([42 + bs_len, laser_axis[1], laser_axis[2]]) rotate([0, -90, 0]) beam_stop_local();   // tether tab points up (+Z)
}

module beam_stop_print() { beam_stop_local(); }

beam_stop_print();
