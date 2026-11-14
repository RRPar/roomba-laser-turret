// =====================================================================
//  laser-gimbal :: 17T herringbone pinion (print 2: pan + tilt)
//  HUBLESS: D-bore through the 10 mm face, one radial M3 set screw at
//  mid-width whose hole exits in a tooth gap, captive M3 nut in a slot
//  that opens to the z=0 face (print face).
//
//  Assembly of the set screw (no tooth flank is notched, so the screw
//  cannot pass through the gap from outside):
//    1. drop an M3 nut into the slot from the z=0 face
//    2. drop an M3x4 (or x3) cup-point set screw down the bore, tip it into
//       the radial hole socket-end first and push it out to the nut
//    3. thread it into the nut with a 1.5 mm hex key through the tooth gap
//    4. slide onto the motor shaft, flat facing the screw, tighten.
//
//  module pinion()        PAN pinion in world coordinates (meshes with turntable)
//  module pinion_local()  axis = Z, teeth z 0..gear_w, unphased (for the tilt pinion)
// =====================================================================
include <../lib/params.scad>
use <../lib/gears.scad>

// ---- local derived values ----
pin_rp   = pitch_r(pinion_z);
pin_rf   = root_r(pinion_z);
pin_rb   = pin_rp * cos(gear_pa);
// angular position of a tooth-gap centre at mid-width (z = gear_w/2):
// herringbone() rotates the profile by -twist at mid-width; gaps sit half a pitch from tooth 0
pin_gap_ang = -_twist(gear_mod, pinion_z, gear_w / 2, gear_helix) + 180 / pinion_z;
pin_flat_x  = pinion_dflat - pinion_bore / 2;     // flat distance from axis (2.025), on the screw side
pin_nut_c   = pin_flat_x + 1.675 + m3_nut_h / 2;  // nut centre: 1.675 wall to the flat
pin_nut_ac  = m3_nut_af / cos(30);                // across corners
pin_hole_end = pin_rf + 0.5;                      // stays below the base circle (no involute flank cut)

module pinion_teeth() {
    herringbone(gear_mod, pinion_z, gear_w, gear_helix, gear_pa, gear_backlash);
}

// all cutters in the frame where the set screw points along +X
module pinion_cuts() {
    // D-bore (flat at +X, perpendicular to the screw)
    translate([0, 0, -1]) linear_extrude(height = gear_w + 2)
        intersection() {
            circle(d = pinion_bore, $fn = 32);
            translate([-pinion_bore, -pinion_bore]) square([pinion_bore + pin_flat_x, 2 * pinion_bore]);
        }
    // bore entry chamfers (elephant foot / shaft lead-in)
    for (s = [0, 1]) translate([0, 0, s * gear_w]) mirror([0, 0, s])
        translate([0, 0, -0.01]) rotate([0, 0, 360 / 64])   // offset facets from the bore's (avoids coincident edges)
            cylinder(h = 0.6, d1 = pinion_bore + 1.0, d2 = pinion_bore - 0.2, $fn = 32);
    // radial screw hole: bore -> through nut -> root circle (opens in the tooth gap)
    translate([0, 0, gear_w / 2]) rotate([0, 90, 0]) cylinder(h = pin_hole_end, d = m3_clear, $fn = 24);
    // captive nut: hex with corners up/down (60 deg roof, no bridge) + slot to the z=0 face
    translate([pin_nut_c, 0, gear_w / 2]) rotate([0, 90, 0])
        cylinder(d = pin_nut_ac, h = m3_nut_h, center = true, $fn = 6);
    translate([pin_nut_c - m3_nut_h / 2, -m3_nut_af / 2, -1])
        cube([m3_nut_h, m3_nut_af, gear_w / 2 + 1]);
}

module pinion_local() {
    difference() {
        pinion_teeth();
        rotate([0, 0, pin_gap_ang]) pinion_cuts();
    }
}

// PAN pinion: axis at pan_motor_xy, teeth z 100..110, phased to mesh with the turntable at pan = 0
module pinion() {
    translate([pan_motor_xy[0], pan_motor_xy[1], turntable_z0])
        rotate([0, 0, mesh_phase(pan_gear_z, pinion_z, 180)])
            pinion_local();
}

// print: nut-slot face (z = 0) on the bed, axis vertical
module pinion_print() { pinion_local(); }

pinion_print();
