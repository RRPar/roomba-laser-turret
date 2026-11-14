// =====================================================================
//  robot base :: front caster mount (print 1)
//  5 mm block on the floor at rb_caster_xy: top face z 23 = caster mounting face
//  (rb_caster_h). d 21.5 hole lets the caster housing (d 20) and ball pass down
//  through the block and the floor's d 24 hole. 2x M3 tapped holes (d 2.6, 5 deep)
//  at rb_caster_holes along Y: use M3x6-8 (plate + 5). The 3 floor fixings
//  (rb_fix_caster) sit in 7 mm towers (a 5 mm block cannot hold a 6 mm insert);
//  towers stay outside the caster plate footprint (plate placeholder x +-8, y +-16).
//  Hardware: 3x M3 inserts, 3x M3x10 from below, 2x M3 caster screws.
//  Print orientation: assembled (floor face down).
//  robot_caster_mount()  robot frame.
// =====================================================================
include <../lib/params.scad>
include <../lib/robot_params.scad>

rbcm_t = rb_caster_h - rb_floor_top;   // 5
rbcm_tw = 7;                           // tower height

module robot_caster_mount() {
    cx = rb_caster_xy[0]; cy = rb_caster_xy[1]; z0 = rb_floor_top;
    difference() {
        union() {
            translate([cx, cy, z0]) linear_extrude(rbcm_t) {
                offset(r = 3) square([22 - 6, 38 - 6], center = true);
            }
            for (p = rb_fix_caster) {
                translate([0, 0, z0]) linear_extrude(rbcm_t)
                    hull() { translate(p) circle(r = 3.5, $fn = 24);
                             translate([clamp(p[0], cx - 8, cx + 8), clamp(p[1], -12, 12)]) circle(r = 3.5, $fn = 24); }
                translate([p[0], p[1], z0]) cylinder(h = rbcm_tw, r = 3.5, $fn = 32);
            }
        }
        translate([cx, cy, z0 - 1]) cylinder(h = 20, d = 21.5, $fn = 64);
        for (p = rb_fix_caster) translate([p[0], p[1], z0 - 0.01]) cylinder(h = m3_insert_h + 1, d = m3_insert_d, $fn = 24);
        for (s = [-1, 1]) translate([cx, cy + s * rb_caster_holes[0] / 2, z0 - 1]) cylinder(h = rbcm_t + 2, d = m3_tap, $fn = 20);
    }
}
function clamp(v, a, b) = min(max(v, a), b);

module robot_caster_mount_print() { translate([0, 0, -rb_floor_top]) robot_caster_mount(); }

robot_caster_mount_print();
