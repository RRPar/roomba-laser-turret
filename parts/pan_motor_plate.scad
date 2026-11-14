// =====================================================================
//  laser-gimbal :: pan motor plate
//  The pan NEMA17 is screwed to this plate ON THE BENCH (4x M3x8 from the
//  plate top, heads counterbored, boss centred in a d 22.4 hole). The plate
//  then goes up under the base top plate from below (pinion already on the
//  shaft: it passes the base window) and is clamped by 4x M3x8 driven from
//  the BASE TOP through X-slots into heat-set inserts in the plate ears.
//  Those 4 heads sit at r >= 64.8 from the pan axis, outside the 85T gear
//  and the yoke deck: at pan = 0 a hex key reaches every one of them, so the
//  backlash (mesh_slot -3 .. +1.5 mm in X) is set with the turntable,
//  yoke and payload installed. -3 mm disengages the herringbone teeth.
//
//  world (static): top face z 92 against the base top-plate underside,
//                  motor face z 86, ears z 84..92.
//  Print: top face (z 92) on the bed. No supports.
// =====================================================================
include <../lib/params.scad>
use <../lib/gears.scad>

pmp_z1     = base_top - base_top_t;               // 92 top face
pmp_z0     = pmp_z1 - pan_mplate_t;               // 86 = pan_motor_face_z
pmp_ear_z0 = pmp_z1 - pan_mplate_ear_t;           // 84
pmp_scr_r  = 5.5;                                 // pad around a motor screw (cb 6.6 -> 2.2 wall)
pmp_ear_r  = 5;                                   // ear around an insert (4.2 -> 2.9 wall)
pmp_boss_d = nema_boss_d + 0.4;                   // 22.4 centring hole
pmp_cb     = [m3_head_d + 0.6, m3_head_h + 0.2];  // 6.6 x 3.4 -> 2.6 mm clamped, M3x8
pmp_ins    = m3_insert_h + 1;                     // 6

assert(pmp_z0 == pan_motor_face_z, "pan motor plate / motor face mismatch");

// ear screw positions relative to the motor axis
function pmp_ears() = [for (p = pan_mplate_screws) p - pan_motor_xy];
function pmp_mscr() = [for (sx = [-1, 1], sy = [-1, 1]) [sx, sy] * nema_hole_sp / 2];

module pmp_outline2d() hull() {
    for (p = pmp_mscr()) translate(p) circle(r = pmp_scr_r, $fn = 48);
    for (p = pmp_ears()) translate(p) circle(r = pmp_ear_r, $fn = 48);
}

module pan_motor_plate_local() {   // motor axis at the origin, z = world z
    difference() {
        union() {
            translate([0, 0, pmp_z0]) linear_extrude(height = pan_mplate_t) pmp_outline2d();
            // ears thickened downward beside the motor body (>= 1.35 mm clear of it)
            for (p = pmp_ears()) translate([p[0], p[1], pmp_ear_z0])
                cylinder(h = pmp_z0 - pmp_ear_z0 + 0.01, r = pmp_ear_r, $fn = 48);
        }
        // boss centring hole (shaft passes)
        translate([0, 0, pmp_z0 - 1]) cylinder(h = pan_mplate_t + 2, d = pmp_boss_d, $fn = 64);
        // motor screws: clearance + counterbore from the top
        for (p = pmp_mscr()) translate([p[0], p[1], 0]) {
            translate([0, 0, pmp_z0 - 1]) cylinder(h = pan_mplate_t + 2, d = m3_clear, $fn = 24);
            translate([0, 0, pmp_z1 - pmp_cb[1]]) cylinder(h = pmp_cb[1] + 1, d = pmp_cb[0], $fn = 32);
        }
        // heat-set inserts in the ears, from the top face
        for (p = pmp_ears()) translate([p[0], p[1], pmp_z1 - pmp_ins])
            cylinder(h = pmp_ins + 1, d = m3_insert_d, $fn = 24);
    }
}

module pan_motor_plate() translate([pan_motor_xy[0], pan_motor_xy[1], 0]) pan_motor_plate_local();

// top face (z 92) on the bed
module pan_motor_plate_print() translate([0, 0, pmp_z1]) rotate([180, 0, 0]) pan_motor_plate_local();

pan_motor_plate_print();
