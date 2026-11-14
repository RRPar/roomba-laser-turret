// =====================================================================
//  robot base :: front bumper, LEFT half 0 .. +80 deg (print 1; right half = mirror)
//  Band r 166 .. 169, z 22 .. 62 (the legacy model's front half-ring band).
//    - 2 slots (3.4 x 10.4, long along X) at 25 / 65 deg, z 42 for radial M3 shoulder screws
//    - spring seat d 6.5 x 2 deep (radial) on the inner face at 15 deg, z 42
//    - switch strike pad on the inner face at 40 deg (12 tangential x 8 tall, 0.5 proud: 0.1 off the switch lever tip at rest)
//    - ToF window 18 x 6 at 0 deg split across both halves (9 per half), z 42
//    - splice plate screws: 2x M3 (z 49 / 55) at y +15, counterbored 6.2 x 2 on the outer face,
//      M3 along X into robot_bumper_splice (M3x8).
//  Print orientation: standing on its bottom edge (band vertical), no supports.
//  robot_bumper_left()  robot frame.   NOTE: the lid wall needs a ToF window and a relief for
//  the splice plate at 0 deg (see report).
// =====================================================================
include <../lib/params.scad>
include <../lib/robot_params.scad>

rbb_ri = rb_bumper_r[0];  rbb_ro = rb_bumper_r[1];
rbb_z0 = rb_bumper_z[0];  rbb_z1 = rb_bumper_z[1];
rbb_mid = rb_bumper_mid_z;
rbb_slot_len = rb_bumper_travel + 6.4;
rbb_splice_y = 15;  rbb_splice_z = [49, 55];

module rbb_left_body() {
    difference() {
        rotate_extrude(angle = rb_bumper_ang, $fn = 360)
            translate([rbb_ri, rbb_z0]) square([rbb_ro - rbb_ri, rbb_z1 - rbb_z0]);
        // M3 shoulder-screw slots (hull of 2 radial cylinders, ends along X)
        for (a = [25, 65]) {
            pt = rbb_ro * [cos(a), sin(a)];
            hull() for (s = [-1, 1])
                translate([pt[0] + s * (rbb_slot_len - 3.4) / 2, pt[1], rbb_mid])
                    rotate([0, 90, a]) translate([0, 0, -8]) cylinder(h = 16, d = 3.4, $fn = 24);
        }
        // spring seat (radial pocket on the inner face)
        rotate([0, 0, 15]) translate([rbb_ri - 1, 0, rbb_mid]) rotate([0, 90, 0]) cylinder(h = 3, d = 6.5, $fn = 32);
        // ToF window half
        translate([rbb_ri - 1, -0.01, rbb_mid - 3]) cube([rbb_ro - rbb_ri + 2, 9.01, 6]);
        // splice screws (counterbored from outside)
        for (z = rbb_splice_z) translate([0, rbb_splice_y, z]) rotate([0, 90, 0]) {
            translate([0, 0, rbb_ri - 2]) cylinder(h = 6, d = m3_clear, $fn = 24);
            translate([0, 0, 166.6]) cylinder(h = 6, d = 6.2, $fn = 24);
        }
    }
    // strike pad
    intersection() {
        rotate([0, 0, 40]) translate([rbb_ri - 0.5, -6, rbb_mid - 4]) cube([1.5, 12, 8]);
        cylinder(h = 100, r = 200);
    }
}

module robot_bumper_left() { rbb_left_body(); }
module robot_bumper_left_print() { translate([0, 0, -rbb_z0]) robot_bumper_left(); }

robot_bumper_left_print();
