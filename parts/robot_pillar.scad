// =====================================================================
//  robot body :: support pillar. Print 4.
//  robot frame: tube OD/ID rb_pillar (18/10), z 18 .. 70 at each bay_screw_xy; the top
//  bears on the underside of the lid mount boss (z 70). Bottom flange d38, z 18..24, with
//  4x M3 heat-set insert holes (d4.2, 5.2 deep, from below) at 14 mm / 0,90,180,270 deg
//  = rb_fix_pillar, screws from below through the floor. The bore is open through the
//  flange (M3x60 head + hex key). 45-deg cone from flange to tube.
//  robot_pillar(i) places pillar i at bay_screw_xy[i]; robot_pillar_print() = one pillar.
//  Print: flange down, no supports.
// =====================================================================
include <../lib/params.scad>
include <../lib/robot_params.scad>

rp_fl_d = 38;  rp_fl_t = 6;  rp_z1 = 70;

module robot_pillar_at0() {
    difference() {
        union() {
            translate([0, 0, rb_floor_top]) cylinder(d = rp_fl_d, h = rp_fl_t, $fn = 72);
            translate([0, 0, rb_floor_top + rp_fl_t - 0.01])
                cylinder(d1 = rp_fl_d, d2 = rb_pillar[0], h = (rp_fl_d - rb_pillar[0]) / 2, $fn = 72);
            translate([0, 0, rb_floor_top]) cylinder(d = rb_pillar[0], h = rp_z1 - rb_floor_top, $fn = 72);
        }
        translate([0, 0, rb_floor_top - 1]) cylinder(d = rb_pillar[1], h = 60, $fn = 48);
        for (a = [0, 90, 180, 270]) translate([14 * cos(a), 14 * sin(a), rb_floor_top - 1])
            cylinder(d = m3_insert_d, h = 6.2, $fn = 24);
    }
}
module robot_pillar(i = 0) translate([bay_screw_xy[i][0], bay_screw_xy[i][1], 0]) robot_pillar_at0();
module robot_pillar_print() translate([0, 0, -rb_floor_top]) robot_pillar_at0();

robot_pillar_print();
