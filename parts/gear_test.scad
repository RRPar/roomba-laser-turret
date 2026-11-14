// =====================================================================
//  laser-gimbal :: gear mesh test coupon
//  Print this + one pinion + the tilt_gear BEFORE the big parts. Drop the
//  pinion on the D-pin and the 51T wheel on the round pin: they sit
//  exactly tilt_cd apart. Turn the wheel by hand:
//    binds              -> raise gear_backlash in lib/params.scad (0.05 steps)
//    > ~1 deg rock      -> lower it
//  The same tooth geometry is used by the pan pair, so one test tunes both.
//  Not part of the machine; no world-coordinate module.
//  Print: flat, plate down.
// =====================================================================
include <../lib/params.scad>
use <../lib/gears.scad>

gt_t      = 3;                         // plate thickness
gt_pin_h  = gear_w + 3;                // pins stand 3 mm above a seated gear
gt_dpin   = [pinion_bore - 0.25, pinion_dflat - 0.25];   // loose D-pin for the pinion: d, flat
gt_wpin_d = tilt_gear_hole - 0.2;      // 12.8 round pin for the wheel centre hole
gt_pad    = [10, 11];                  // pad radii under the pinion / wheel pins

module gear_test() {
    // plate: hull of two pads, plus a ring on each pad so the gear sits 1 mm up (no bed-rub)
    difference() {
        linear_extrude(height = gt_t) hull() {
            circle(r = gt_pad[0], $fn = 48);
            translate([tilt_cd, 0]) circle(r = gt_pad[1], $fn = 48);
        }
        // engraved centre distance on the plate top
        translate([tilt_cd / 2, 0, gt_t - 0.4]) linear_extrude(height = 1)
            text(str(tilt_cd), size = 4, halign = "center", valign = "center", font = "Liberation Sans:style=Bold");
    }
    translate([0, 0, gt_t - 0.01]) cylinder(h = 1.01, d = gt_dpin[0] + 3, $fn = 32);
    translate([tilt_cd, 0, gt_t - 0.01]) cylinder(h = 1.01, d = gt_wpin_d + 3, $fn = 48);
    // D-pin
    translate([0, 0, gt_t - 0.01]) linear_extrude(height = gt_pin_h + 0.01) intersection() {
        circle(d = gt_dpin[0], $fn = 32);
        translate([-gt_dpin[0], -gt_dpin[0]]) square([gt_dpin[0] + gt_dpin[1] - gt_dpin[0] / 2, 2 * gt_dpin[0]]);
    }
    // wheel pin with a lead-in chamfer
    translate([tilt_cd, 0, gt_t - 0.01]) {
        cylinder(h = gt_pin_h - 0.8 + 0.01, d = gt_wpin_d, $fn = 64);
        translate([0, 0, gt_pin_h - 0.8]) cylinder(h = 0.8, d1 = gt_wpin_d, d2 = gt_wpin_d - 1.6, $fn = 64);
    }
}

module gear_test_print() { gear_test(); }

gear_test_print();
