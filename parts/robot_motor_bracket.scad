// =====================================================================
//  robot base :: motor bracket (print 2: one per side, mirror pair)
//  Saddle block on the floor plate cradling the JGA25 gearbox and can (lower
//  half up to the axis plane z 32.5; motor underside z 20). The upper half is
//  closed by 2 separate straps (parts/robot_motor_strap.scad, print 4 total)
//  screwed down into M3 heat-set inserts in the two ear pairs.
//  Fixing: 4x M3 from below into inserts in the bottom at rb_fix_motor.
//  Hardware per bracket: 4x M3x10 (floor), 4x M3 inserts bottom + 4 top ears.
//  Print orientation: assembled (floor face down), saddle open upward, no supports.
//  The bracket stays at |y| 47 .. 111 (hub starts at 115, gearbox face at 113).
//  robot_motor_bracket(side)  side = +1 (left) / -1 (right), robot frame.
// =====================================================================
include <../lib/params.scad>
include <../lib/robot_params.scad>

rbmb_y   = [47, 111];
rbmb_hw  = 23.5;                       // half width (x)
rbmb_ear_x = 19.5;                     // strap screw x offset from the axle
rbmb_strap_y = [70, 86];               // strap centres (over the can, y 64 .. 92); first one moved off the pillar flange
function rbmb_ear_pts() = [for (x = [-1, 1], y = rbmb_strap_y) [rb_axle_x + x * rbmb_ear_x, y]];

module rbmb_left() {
    z0 = rb_floor_top;
    difference() {
        translate([rb_axle_x - rbmb_hw, rbmb_y[0], z0]) cube([2 * rbmb_hw, rbmb_y[1] - rbmb_y[0], rb_axle_z - z0]);
        // gearbox (y > 90) and can/encoder bores, axis along Y at the top plane
        translate([rb_axle_x, 90, rb_axle_z]) rotate([-90, 0, 0]) cylinder(h = 30, d = jga25_gear[0] + 0.3, $fn = 64);
        translate([rb_axle_x, 40, rb_axle_z]) rotate([-90, 0, 0]) cylinder(h = 51, d = jga25_motor[0] + 0.5, $fn = 64);
        // relief around the pillar flange (d 38 at (-60, 60), 0.5 clearance)
        translate([bay_screw_xy[1][0], bay_screw_xy[1][1], z0 - 1]) cylinder(h = 14, d = 39, $fn = 72);
        // bottom inserts (floor fixings)
        for (p = rb_fix_motor) if (p[1] > 0)
            translate([p[0], p[1], z0 - 0.01]) cylinder(h = m3_insert_h + 1, d = m3_insert_d, $fn = 24);
        // strap screw inserts from the top
        for (p = rbmb_ear_pts())
            translate([p[0], p[1], rb_axle_z - m3_insert_h - 1]) cylinder(h = m3_insert_h + 1.01, d = m3_insert_d, $fn = 24);
    }
}

module robot_motor_bracket(side = 1) { mirror([0, side < 0 ? 1 : 0, 0]) rbmb_left(); }

module robot_motor_bracket_print() { translate([0, 0, -rb_floor_top]) robot_motor_bracket(1); }

robot_motor_bracket_print();
