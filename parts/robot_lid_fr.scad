// =====================================================================
//  robot body :: lid quadrant FR (270..360 deg). Print 1.
//  Same generic module robot_lid_quad(a0) as robot_lid_fl.scad (see its header for the seam
//  splice, bosses, panel holes, arches, bumper hardware and print orientation).
//  Print: skin down (upside down), supports on the rounded edge's first ~3.5 mm.
// =====================================================================
include <../lib/params.scad>
include <../lib/robot_params.scad>
use <robot_lid_fl.scad>

module robot_lid_fr() robot_lid_quad(270);
module robot_lid_fr_print() translate([0, 0, rb_deck_z]) rotate([180, 0, 0]) robot_lid_fr();

robot_lid_fr_print();
