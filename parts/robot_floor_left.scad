// =====================================================================
//  robot body :: floor plate quadrant LEFT (centred on angle 90 deg). Print 1.
//  Same plate as robot_floor_front.scad (generic module robot_floor_quad(i), see its header
//  for the seam scheme, hardware and print orientation) with this quadrant's own cut-outs.
//  Print: top face on the bed (upside down), thin support under the lower lap.
// =====================================================================
include <../lib/params.scad>
include <../lib/robot_params.scad>
use <robot_floor_front.scad>

module robot_floor_left() robot_floor_quad(1);
module robot_floor_left_print() translate([0, 0, rb_floor_top]) rotate([180, 0, 0]) robot_floor_left();

robot_floor_left_print();
