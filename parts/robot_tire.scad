// =====================================================================
//  robot base :: tire (print 2, TPU 95A)
//  Ring ID 58.4 (stretches onto the 59 hub body and over the 62 flanges), OD 65,
//  23 wide = hub groove between the flanges, 24 light transverse tread grooves
//  (0.8 deep). The bottom of the tire (z 0) is a tread land.
//  Print orientation: flat on the bed (ring), no supports; slow, no retraction-heavy.
//  robot_tire(side)  side +1 / -1, robot frame.
// =====================================================================
include <../lib/params.scad>
include <../lib/robot_params.scad>

rbt_id = 58.4;  rbt_w = rb_wheel_w - 3;  rbt_groove = [1.6, 0.8];  rbt_n = 24;

module robot_tire_local() {   // axis = Z, z 0 .. rbt_w
    difference() {
        cylinder(h = rbt_w, d = rb_wheel_d, $fn = 96);
        translate([0, 0, -1]) cylinder(h = rbt_w + 2, d = rbt_id, $fn = 96);
        // tread: groove centres a half pitch off the 270 deg land (the ground contact)
        for (k = [0 : rbt_n - 1]) rotate([0, 0, 270 + 360 / rbt_n * (k + 0.5)])
            translate([rb_wheel_d / 2 - rbt_groove[1], -rbt_groove[0] / 2, -1])
                cube([rbt_groove[1] + 1, rbt_groove[0], rbt_w + 2]);
    }
}

module robot_tire(side = 1) {
    translate([rb_axle_x, side * rb_wheel_y, rb_axle_z]) rotate([90, 0, 0])
        translate([0, 0, -rbt_w / 2]) robot_tire_local();
}

module robot_tire_print() { robot_tire_local(); }

robot_tire_print();
