// =====================================================================
//  robot base :: motor strap (print 4: 2 per motor; part of the motor bracket set)
//  Half-ring clamp over the JGA25 can, 12 wide, ears with 2x M3x10 down into the
//  bracket's top inserts. Tighten snug (the can is 24.4 d; strap bore 24.8).
//  Print orientation: standing on a side face (profile extruded along the print
//  height): no overhang, horizontal screw holes.
//  robot_motor_strap(side, i)  side +1/-1, i = 0 (inner) / 1 (outer), robot frame.
// =====================================================================
include <../lib/params.scad>
include <../lib/robot_params.scad>

rbms_w = 12;  rbms_ri = 12.4;  rbms_ro = 16.4;  rbms_ear = 3;  rbms_hw = 23.5;  rbms_ex = 19.5;
rbms_y = [70, 86];   // = rbmb_strap_y in robot_motor_bracket.scad

// local frame: x across, y 0 .. 12 along the motor axis, z up from the axis plane
module rbms_local() {
    difference() {
        rotate([90, 0, 0]) translate([0, 0, -rbms_w]) linear_extrude(rbms_w) rbms_profile_clean();
        for (s = [-1, 1]) translate([s * rbms_ex, rbms_w / 2, -1]) cylinder(h = rbms_ear + 2, d = m3_clear, $fn = 24);
    }
}

module rbms_profile_clean() {
    difference() {
        union() {
            intersection() {
                circle(r = rbms_ro, $fn = 72);
                translate([-rbms_ro, 0]) square([2 * rbms_ro, rbms_ro]);
            }
            translate([-rbms_hw, 0]) square([2 * rbms_hw, rbms_ear]);
        }
        circle(r = rbms_ri, $fn = 72);
    }
}

module robot_motor_strap(side = 1, i = 0) {
    translate([rb_axle_x, 0, rb_axle_z]) mirror([0, side < 0 ? 1 : 0, 0])
        translate([0, rbms_y[i] - rbms_w / 2, 0]) rbms_local();
}

module robot_motor_strap_print() { rotate([90, 0, 0]) rbms_local(); }

robot_motor_strap_print();
