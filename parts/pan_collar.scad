// =====================================================================
//  laser-gimbal :: pan collar
//  Ring under the lower 6810: 3x M3x10 SHCS go UP through it into the
//  self-tap holes in the turntable spigot end, pulling the lower inner
//  race up against the integral shoulder -> the two 6810s are clamped
//  back-to-back between the turntable shoulder (top) and this collar.
//  world: z collar_z (68..72), OD collar_od (touches the inner race only),
//  ID spigot_id (cable bore stays clear).
//  Screw heads stay proud below the ring (inside the open base cavity):
//  a 4 mm ring is too thin to counterbore.
//  Print: flat, top face (z 72) on the bed.
// =====================================================================
include <../lib/params.scad>
use <../lib/gears.scad>

collar_screw_angs = [90, 210, 330];      // must match turntable.scad
pc_chamfer = 0.5;

module pan_collar() {
    h = collar_z[1] - collar_z[0];
    translate([0, 0, collar_z[0]]) difference() {
        cylinder(h = h, d = collar_od, $fn = 96);
        translate([0, 0, -1]) cylinder(h = h + 2, d = spigot_id, $fn = 96);
        for (a = collar_screw_angs) rotate([0, 0, a]) translate([collar_screws_r, 0, -1])
            cylinder(h = h + 2, d = m3_clear, $fn = 24);
        // bed-side (top face) edge chamfers, outer + inner
        translate([0, 0, h - pc_chamfer]) difference() {
            cylinder(h = pc_chamfer + 1, d = collar_od + 2, $fn = 96);
            translate([0, 0, -0.01]) cylinder(h = pc_chamfer + 0.02, d1 = collar_od, d2 = collar_od - 2 * pc_chamfer, $fn = 96);
        }
        translate([0, 0, h - pc_chamfer]) cylinder(h = pc_chamfer + 0.01, d1 = spigot_id, d2 = spigot_id + 2 * pc_chamfer + 0.02, $fn = 96);
    }
}

// top face (z 72) on the bed
module pan_collar_print() { translate([0, 0, collar_z[1]]) rotate([180, 0, 0]) pan_collar(); }

pan_collar_print();
