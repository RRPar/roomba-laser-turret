// =====================================================================
//  robot base :: bumper splice plate (print 1)
//  Arc plate r 158 .. 166, 12 tall (z 46 .. 58), tangential +-26 mm, behind the 0-deg joint
//  of the two bumper halves (above the ToF window). 4 M3 heat-set inserts (2 each side, along
//  X, y +-15, z 49 / 55, hole 5.2 deep); the bumper halves are screwed on from the outside
//  (M3x8 button head). It rides with the bumper (4 mm travel).
//  Print orientation: assembled (arc plate flat on the bed, height 12), no supports.
//  robot_bumper_splice()  robot frame.
// =====================================================================
include <../lib/params.scad>
include <../lib/robot_params.scad>

module robot_bumper_splice() {
    ri = 158; ro = rb_bumper_r[0] - 0.05;   // 0.05 off the bumper band's inner face
    difference() {
        intersection() {
            translate([0, 0, 46]) difference() {
                cylinder(h = 12, r = ro, $fn = 360);
                translate([0, 0, -1]) cylinder(h = 14, r = ri, $fn = 360);
            }
            translate([100, -26, 0]) cube([100, 52, 100]);
        }
        for (s = [-1, 1], z = [49, 55])
            translate([160.0, s * 15, z]) rotate([0, 90, 0]) cylinder(h = 5.2, d = m3_insert_d, $fn = 24);
    }
}

module robot_bumper_splice_print() { translate([0, 0, -46]) robot_bumper_splice(); }

robot_bumper_splice_print();
