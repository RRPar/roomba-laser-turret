// =====================================================================
//  robot body :: floor plate quadrant FRONT (centred on +X). Print 1.
//  The four quadrants (front / left / rear / right) share one generic module,
//  robot_floor_quad(i), defined HERE; robot_floor_left/rear/right.scad `use` this
//  file. The seam scheme is rotationally symmetric, so the quadrants are the same
//  plate rotated by 90 deg plus their own cut-outs.
//  world (robot frame): plate z 14..18, radius rb_R, sector -45..+45 deg.
//    Seams on the diagonals (rb_floor_seams), rb_seam_gap 0.3 mm everywhere.
//    Seam joint = 14 mm wide half-thickness lap. At a quadrant's CCW edge it is the
//    UPPER lap (z 16.15..18, 2x M3 clearance 3.4); at its CW edge it is the LOWER lap
//    (z 14..15.85) with a d10 boss below (z 10..14) carrying a through hole d4.2: the
//    M3 heat-set insert is pressed in from the boss tip, the M3x10 comes from ABOVE
//    through the neighbour's upper lap. Screws at r 50 and r 130 on each seam
//    (clear of the pillar flanges at r 67..103 and of every fixing hole).
//    Plain d3.4 holes at every rb_fix_* point (screws from below, inserts in the parts above).
//    Cable pass d30 at the centre; wheel wells cut per rb_well; ball hole d24 under
//    the caster (rb_caster_xy); rear tip skid dome at rb_skid_xy (lowest z = rb_skid_z).
//  Print: top face on the bed (upside down, z' = 18 - z), 4 mm plate, bosses/skid point up.
//    The 14 mm lower lap overhangs 2.15 mm above the bed: thin support under it.
//  Hardware per seam: 2x M3x10 + 2x M3 heat-set insert (4.2 hole).
// =====================================================================
include <../lib/params.scad>
include <../lib/robot_params.scad>

fl_lap     = 7;                          // lap half width
fl_z0      = rb_clear;  fl_z1 = rb_floor_top;  fl_zm = (fl_z0 + fl_z1) / 2;
fl_seam_r  = [50, 130];                  // screw radii along each seam
fl_boss    = [10, 4];                    // boss d, height below the plate
fl_cable_d = 30;
fl_ball_d  = 24;

function fl_inq(p, c) = abs(((atan2(p[1], p[0]) - c + 180) % 360 + 360) % 360 - 180) < 45;
function fl_pts(c) = [for (p = concat(rb_fix_motor, rb_fix_caster, rb_fix_batt, rb_fix_ebay,
                                       rb_fix_pillar, rb_fix_lid)) if (fl_inq(p, c)) p];

module fl_full2d(s0, s1) {
    intersection() {
        circle(r = rb_R, $fn = 240);
        rotate(s0) translate([-500, fl_lap]) square([1000, 500]);
        rotate(s1) translate([-500, -fl_lap - 500]) square([1000, 500]);
    }
}
module fl_lapB2d(s) intersection() {       // lower lap strip at this quadrant's CW seam
    circle(r = rb_R, $fn = 240);
    rotate(s) translate([0, -fl_lap + rb_seam_gap]) square([rb_R, 2 * fl_lap - rb_seam_gap + 0.5]);
}
module fl_lapA2d(s) intersection() {       // upper lap strip at the CCW seam
    circle(r = rb_R, $fn = 240);
    rotate(s) translate([0, -fl_lap - 0.5]) square([rb_R, 2 * fl_lap - rb_seam_gap + 0.5]);
}

module robot_floor_quad(i) {
    c = i * 90;  s0 = c - 45;  s1 = c + 45;
    g = rb_seam_gap;
    difference() {
        union() {
            translate([0, 0, fl_z0]) linear_extrude(fl_z1 - fl_z0) fl_full2d(s0, s1);
            translate([0, 0, fl_z0]) linear_extrude(fl_zm - g / 2 - fl_z0) fl_lapB2d(s0);
            translate([0, 0, fl_zm + g / 2]) linear_extrude(fl_z1 - fl_zm - g / 2) fl_lapA2d(s1);
            for (r = fl_seam_r) rotate(s0) translate([r, 0, fl_z0 - fl_boss[1]])
                cylinder(d = fl_boss[0], h = fl_boss[1] + 0.5, $fn = 40);
            if (i == 2)                    // rear tip skid dome, lowest point rb_skid_z
                translate([rb_skid_xy[0], rb_skid_xy[1], 0]) intersection() {
                    hull() {
                        translate([0, 0, fl_z0 - 1]) cylinder(r = 13, h = 1.5, $fn = 48);
                        translate([0, 0, rb_skid_z + 8]) sphere(r = 8, $fn = 48);
                    }
                    translate([-20, -20, 0]) cube([40, 40, fl_z1 - 1]);
                }
        }
        // seam screws
        for (r = fl_seam_r) {
            rotate(s0) translate([r, 0, fl_z0 - fl_boss[1] - 1]) cylinder(d = m3_insert_d, h = 20, $fn = 24);
            rotate(s1) translate([r, 0, fl_z0 - 1]) cylinder(d = m3_clear, h = 10, $fn = 24);
        }
        // fixing points
        for (p = fl_pts(c)) translate([p[0], p[1], fl_z0 - 1]) cylinder(d = m3_clear, h = 10, $fn = 24);
        // cable pass
        translate([0, 0, fl_z0 - 1]) cylinder(d = fl_cable_d, h = 10, $fn = 64);
        // ball under the caster
        if (fl_inq(rb_caster_xy, c)) translate([rb_caster_xy[0], rb_caster_xy[1], fl_z0 - 1])
            cylinder(d = fl_ball_d, h = 10, $fn = 64);
        // wheel wells
        for (s = [-1, 1]) translate([rb_axle_x - rb_well[0], s > 0 ? rb_well[1] : -rb_R - 10, fl_z0 - 1])
            cube([2 * rb_well[0], rb_R + 10 - rb_well[1], 10]);
    }
}

module robot_floor_front() robot_floor_quad(0);
module robot_floor_front_print() translate([0, 0, fl_z1]) rotate([180, 0, 0]) robot_floor_front();

robot_floor_front_print();
