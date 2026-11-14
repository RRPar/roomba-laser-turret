// =====================================================================
//  robot base :: front bumper, RIGHT half -80 .. 0 deg (print 1)
//  Exact mirror (Y) of parts/robot_bumper_left.scad: see that file.
//  Print orientation: standing on its bottom edge, no supports.
//  robot_bumper_right()  robot frame.
// =====================================================================
include <../lib/params.scad>
include <../lib/robot_params.scad>
use <robot_bumper_left.scad>

module robot_bumper_right() { mirror([0, 1, 0]) robot_bumper_left(); }
module robot_bumper_right_print() { translate([0, 0, -rb_bumper_z[0]]) robot_bumper_right(); }

robot_bumper_right_print();
