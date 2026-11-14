// =====================================================================
//  robot base :: rear electronics tray (print 1)
//  Plate x -125 .. -50, |y| <= 45, 3 mm thick on the floor plate, with
//    - 4 M3 standoffs (5 high, M3 tap hole) for the Cytron MDD3A:
//      PLACEHOLDER pattern 44 x 36 -- CONFIRM against the real board before printing
//    - 4 M2 standoffs (4 high, d 1.8 tap) for the Pico: real pattern 47 x 11.4
//    - fuse-holder cradle (35 x 15 x 12 blade-fuse holder): 2 side walls + end stops
//    - cable-tie slots (4.2 x 2) at y 2.5 and 4 more near the plate edges
//  Fixing: 4x M3 from below into inserts in 8 mm towers at rb_fix_ebay.
//  Layout (centres): MDD3A (-92,-20), Pico (-87,14), fuse (-87,35) -- matches robot_vitamins.
//  Print orientation: assembled (plate on the bed), no supports.
//  robot_ebay_tray()  robot frame.
// =====================================================================
include <../lib/params.scad>
include <../lib/robot_params.scad>

rbe_t = 3;
rbe_mdd_c = [-92, -20];  rbe_pico_c = [-87, 14];  rbe_fuse_c = [-87, 35];
rbe_mdd_holes  = [44, 36];
rbe_pico_holes = [47, 11.4];

module robot_ebay_tray() {
    z0 = rb_floor_top;
    difference() {
        union() {
            translate([rb_ebay_x[0], -45, z0]) cube([rb_ebay_x[1] - rb_ebay_x[0], 90, rbe_t]);
            for (p = rb_fix_ebay) translate([p[0], p[1], z0]) cylinder(h = 8, r = 4.0, $fn = 32);
            // MDD3A standoffs
            for (x = [-1, 1], y = [-1, 1])
                translate([rbe_mdd_c[0] + x * rbe_mdd_holes[0] / 2, rbe_mdd_c[1] + y * rbe_mdd_holes[1] / 2, z0 + rbe_t - 0.01])
                    cylinder(h = 5.01, d = 7, $fn = 32);
            // Pico standoffs
            for (x = [-1, 1], y = [-1, 1])
                translate([rbe_pico_c[0] + x * rbe_pico_holes[0] / 2, rbe_pico_c[1] + y * rbe_pico_holes[1] / 2, z0 + rbe_t - 0.01])
                    cylinder(h = 4.01, d = 5, $fn = 32);
            // fuse cradle
            translate([rbe_fuse_c[0], rbe_fuse_c[1], z0 + rbe_t - 0.01]) {
                for (s = [-1, 1]) translate([-19.5, s * 8.7 - 1, 0]) cube([39, 2, 8.01]);
                for (s = [-1, 1]) translate([s * 18.5 - 1, -7.7, 0]) cube([2, 15.4, 8.01]);
            }
        }
        // relief around the two pillar flanges (d 38 at (-60, +-60), 0.5 clearance)
        for (p = [bay_screw_xy[1], bay_screw_xy[2]]) translate([p[0], p[1], z0 - 1]) cylinder(h = 12, d = 39, $fn = 72);
        // standoff tap holes
        for (x = [-1, 1], y = [-1, 1]) {
            translate([rbe_mdd_c[0] + x * rbe_mdd_holes[0] / 2, rbe_mdd_c[1] + y * rbe_mdd_holes[1] / 2, z0 + rbe_t - 0.5])
                cylinder(h = 6, d = m3_tap, $fn = 20);
            translate([rbe_pico_c[0] + x * rbe_pico_holes[0] / 2, rbe_pico_c[1] + y * rbe_pico_holes[1] / 2, z0 + rbe_t - 0.5])
                cylinder(h = 5, d = 1.8, $fn = 16);
        }
        // fuse wire notches in the end stops
        for (s = [-1, 1]) translate([rbe_fuse_c[0] + s * 18.5 - 2, rbe_fuse_c[1] - 3, z0 + rbe_t + 2]) cube([4, 6, 8]);
        // cable-tie slots
        for (p = [[-105, 2.5], [-70, 2.5], [-118, 20], [-56, 20], [-118, -20], [-56, -20], [-118, 38], [-56, 38]])
            translate([p[0] - 2.1, p[1] - 1, z0 - 1]) cube([4.2, 2, rbe_t + 2]);
        for (p = rb_fix_ebay) translate([p[0], p[1], z0 - 0.01]) cylinder(h = m3_insert_h + 1, d = m3_insert_d, $fn = 24);
    }
}

module robot_ebay_tray_print() { translate([0, 0, -rb_floor_top]) robot_ebay_tray(); }

robot_ebay_tray_print();
