// =====================================================================
//  robot base :: wheel hub (print 2, PETG)
//  OD 59 body + 2 flanges (OD 62, 1.5 thick) holding the 23 wide TPU tire
//  (parts/robot_tire.scad). Open cup (open to the OUTBOARD face, |y| 141) with a
//  5 mm web at the inboard face (|y| 115) and a d 18 boss: blind D-bore 4.1
//  (flat 0.5 deep, +X side) 9 deep from the web face, radial M3 set screw at
//  z 3.5 into an M3 heat-set insert in the boss (set screw points +X; reach it
//  with an L hex key through the open cup).
//  Hardware per hub: 1x M3 insert, 1x M3x5 cup-point set screw.
//  Print orientation: web face (inboard) on the bed, cup opening up. No supports.
//  robot_wheel_hub(side)  side +1 (left) / -1 (right), robot frame.
// =====================================================================
include <../lib/params.scad>
include <../lib/robot_params.scad>

rbwh_od   = rb_wheel_d - 2 * rb_tire_t;   // 59
rbwh_fl_od = 62;  rbwh_fl_t = 1.5;
rbwh_web  = 5;    rbwh_wall = 3;  rbwh_boss_d = 18;  rbwh_boss_h = 14;
rbwh_screw_z = 3.5;
rbwh_flat_x = jga25_shaft[0] / 2 - jga25_shaft[2] + 0.05;   // 1.55

module robot_wheel_hub_local() {   // axis = Z, z 0 = inboard face, z rb_wheel_w = outboard face
    w = rb_wheel_w;
    difference() {
        union() {
            // rim + flanges + web
            difference() {
                union() {
                    cylinder(h = w, d = rbwh_od, $fn = 120);
                    cylinder(h = rbwh_fl_t, d = rbwh_fl_od, $fn = 120);
                    translate([0, 0, w - rbwh_fl_t]) cylinder(h = rbwh_fl_t, d = rbwh_fl_od, $fn = 120);
                }
                translate([0, 0, rbwh_web]) cylinder(h = w, d = rbwh_od - 2 * rbwh_wall, $fn = 120);
            }
            cylinder(h = rbwh_boss_h, d = rbwh_boss_d, $fn = 48);
            // 4 spokes boss -> rim
            for (a = [45, 135, 225, 315]) rotate([0, 0, a])
                translate([0, -1.5, 0]) cube([rbwh_od / 2 - 1, 3, 10]);
        }
        // D-bore (flat on +X)
        translate([0, 0, -1]) linear_extrude(height = 10)
            intersection() {
                circle(d = jga25_shaft[0] + 0.1, $fn = 36);
                translate([-5, -5]) square([5 + rbwh_flat_x, 10]);
            }
        // entry chamfer
        translate([0, 0, -0.01]) rotate([0, 0, 5]) cylinder(h = 0.6, d1 = 5.2, d2 = 4.0, $fn = 36);
        // set screw: insert pocket from the boss surface, clear hole to the bore
        translate([0, 0, rbwh_screw_z]) rotate([0, 90, 0]) {
            translate([0, 0, rbwh_boss_d / 2 - m3_insert_h - 1]) cylinder(h = m3_insert_h + 1.5, d = m3_insert_d, $fn = 24);
            cylinder(h = rbwh_boss_d / 2, d = m3_clear, $fn = 24);
        }
    }
}

// inboard face at |y| 115, local +Z toward outboard (+/- y)
module robot_wheel_hub(side = 1) {
    translate([rb_axle_x, side * (rb_wheel_y - rb_wheel_w / 2), rb_axle_z])
        rotate([side > 0 ? -90 : 90, 0, 0]) robot_wheel_hub_local();
}

module robot_wheel_hub_print() { robot_wheel_hub_local(); }

robot_wheel_hub_print();
