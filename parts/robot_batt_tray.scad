// =====================================================================
//  robot base :: battery tray (print 1)
//  Low-walled frame (no floor: the pack sits on the floor plate, rb_batt_z0)
//  around the 58 x 72 x 40 pack (+1 mm clearance per side), walls 2 mm x 14 high.
//  2 strap slots (27 x 3.2) in the +-Y walls at x = pack centre -/+ 15 for a 25 mm
//  hook-and-loop strap over the pack; U-notch in the rear (-X) wall for the BMS wires.
//  Fixing: 4 ears, M3 inserts in the bottom at rb_fix_batt (M3x10 from below).
//  Print orientation: assembled (frame on the bed), no supports (slots bridge 27 mm).
//  robot_batt_tray()  robot frame.
// =====================================================================
include <../lib/params.scad>
include <../lib/robot_params.scad>

rbbt_wall = 2;  rbbt_h = 14;  rbbt_ear_h = 8;
module robot_batt_tray() {
    cx = rb_batt_xy[0]; cy = rb_batt_xy[1]; z0 = rb_batt_z0;
    iw = [rb_batt[0] + 2, rb_batt[1] + 2];
    difference() {
        union() {
            translate([cx, cy, z0]) linear_extrude(rbbt_h) difference() {
                square([iw[0] + 2 * rbbt_wall, iw[1] + 2 * rbbt_wall], center = true);
                square(iw, center = true);
            }
            for (p = rb_fix_batt) {
                translate([0, 0, z0]) linear_extrude(rbbt_ear_h)
                    hull() { translate(p) circle(r = 5, $fn = 32);
                             translate([p[0], cy + (p[1] > cy ? 1 : -1) * (iw[1] / 2 + rbbt_wall / 2)]) circle(r = 1, $fn = 16); }   // ear -> side wall at the same x
            }
        }
        for (s = [-1, 1], dx = [-15, 15])
            translate([cx + dx - 13.5, cy + s * (iw[1] / 2 + rbbt_wall / 2) - 3, z0 + 8]) cube([27, 6, 3.2]);
        translate([cx - iw[0] / 2 - rbbt_wall - 1, cy - 7, z0 + 5]) cube([rbbt_wall + 2, 14, 20]);
        for (p = rb_fix_batt) translate([p[0], p[1], z0 - 0.01]) cylinder(h = m3_insert_h + 1, d = m3_insert_d, $fn = 24);
    }
}

module robot_batt_tray_print() { translate([0, 0, -rb_batt_z0]) robot_batt_tray(); }

robot_batt_tray_print();
