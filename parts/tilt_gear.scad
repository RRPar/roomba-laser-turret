// =====================================================================
//  laser-gimbal :: tilt wheel, 51T herringbone (-gear_helix)
//  world (tilt = 0): axis = tilt axis (parallel to Y through [0,0,tilt_z]),
//  teeth y 31..41. Bolted to the payload's +Y face with 3x M3x12 SHCS into
//  heat-set inserts (heads counterbored in the +Y face). Its 13 mm centre hole
//  clears the +Y axle spacer (d 11.5).
//  6x3 magnet in the +Y face at r 26, straight up at tilt 0 -> trips the A3144
//  on the +Y arm (tilt home = 0 deg).
//
//  LOCAL frame: gear axis Z, teeth z 0..gear_w, tooth 0 on +X (lib gears).
//  local -> world: rotate([-90,0,0]) maps (x,y,z) -> (x, z, -y), so a local polar
//  angle a is the world XZ angle -a. Local z = gear_w is the +Y face (y 41).
//  The tilt pinion sits at local/world angle 180 -> phase it with
//  mesh_phase(tilt_gear_z, pinion_z, 180) in the same local frame (assembly does).
//  Print: local frame as is: -Y face on the bed, counterbores + magnet pocket up.
// =====================================================================
include <../lib/params.scad>
use <../lib/gears.scad>

tg_bolt_angs = [30, 150, 270];                 // WORLD XZ angles (params)
tg_mag_ang   = 90;                             // WORLD XZ angle
tg_ra        = outer_r(tilt_gear_z);           // 33.125
tg_cb        = [m3_head_d + 0.6, m3_head_h + 0.2];   // counterbore d, depth (6.6, 3.4)
tg_mag       = [pan_magnet[0] + 0.2, pan_magnet[1] + 0.2];
tg_chamfer   = 0.5;

function tg_local(a, r) = [r * cos(-a), r * sin(-a)];   // world XZ angle -> local xy

module tilt_gear_local() {
    difference() {
        herringbone(gear_mod, tilt_gear_z, gear_w, -gear_helix, gear_pa, gear_backlash);
        translate([0, 0, -1]) cylinder(h = gear_w + 2, d = tilt_gear_hole, $fn = 64);
        for (a = tg_bolt_angs) translate(tg_local(a, tilt_gear_bolt_r)) {
            translate([0, 0, -1]) cylinder(h = gear_w + 2, d = m3_clear, $fn = 24);
            translate([0, 0, gear_w - tg_cb[1]]) cylinder(h = tg_cb[1] + 1, d = tg_cb[0], $fn = 32);
        }
        translate(concat(tg_local(tg_mag_ang, tilt_hall_r), [gear_w - tg_mag[1]]))
            cylinder(h = tg_mag[1] + 1, d = tg_mag[0], $fn = 32);
        // tooth-tip chamfers on both faces + centre-hole chamfers
        for (zf = [[0, 1], [gear_w, -1]]) translate([0, 0, zf[0]]) scale([1, 1, zf[1]]) {
            rotate_extrude($fn = 128)
                polygon([[tg_ra - tg_chamfer, -0.01], [tg_ra + 1, -0.01], [tg_ra + 1, tg_chamfer + 1.01]]);
            // cone ends inside the hole, facets offset half a step (coincident rings -> non-manifold)
            translate([0, 0, -0.01]) rotate([0, 0, 360 / 128])
                cylinder(h = tg_chamfer + 0.21, d1 = tilt_gear_hole + 2 * tg_chamfer + 0.02, d2 = tilt_gear_hole - 0.4, $fn = 64);
        }
    }
}

module tilt_gear() {
    translate([0, tilt_gear_y[0], tilt_z]) rotate([-90, 0, 0]) tilt_gear_local();
}

module tilt_gear_print() { tilt_gear_local(); }

tilt_gear_print();
