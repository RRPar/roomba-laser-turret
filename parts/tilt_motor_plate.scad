// =====================================================================
//  laser-gimbal :: tilt motor plate
//  The tilt NEMA17 is screwed to this plate ON THE BENCH (4x M3x8, heads on
//  the plate inner face in 1 mm counterbores, boss centred in d 22.4). The
//  plate sits in a pocket in the +Y yoke arm's OUTER face, motor face flush
//  with the arm (y 53, shaft end y 29), and is clamped by 4x M3x8 driven
//  from OUTSIDE (+Y) through X-slots in its ears into heat-set inserts in the
//  arm. Those heads sit 4 mm above / below the motor body, at r >= 42 from
//  the tilt axis: backlash (mesh_slot -3 .. +1.5 mm) is set, and the motor
//  removed (-3 mm disengages the herringbone; the pinion passes the arm's
//  d 24.75 opening), with the payload and the 51T wheel installed.
//  Outline (XZ) shared with yoke.scad (tmp_core2d / tmp_ear2d).
//
//  world (pan = 0): core y 48..53, ears y 50..53.
//  Print: outer face (y 53) on the bed. No supports.
// =====================================================================
include <../lib/params.scad>
use <../lib/gears.scad>
use <yoke.scad>          // tmp_core2d(), tmp_ears2d(), y_extrude()

tmpl_y1   = tilt_motor_face_y;                  // 53 outer face (motor face)
tmpl_y0   = tmpl_y1 - tilt_mplate_t[0];         // 48 core inner face
tmpl_ye   = tmpl_y1 - tilt_mplate_t[1];         // 50 ear inner face
tmpl_boss = nema_boss_d + 0.4;                  // 22.4
tmpl_cb   = [m3_head_d + 0.6, 1];               // head seat: 4 mm clamped, M3x8 -> 4 mm in the motor

module tilt_motor_plate() {
    difference() {
        union() {
            y_extrude(tmpl_y0, tmpl_y1) tmp_core2d();
            y_extrude(tmpl_ye, tmpl_y1) tmp_ears2d();
        }
        // boss centring hole (vertical when printed)
        y_extrude(tmpl_y0 - 1, tmpl_y1 + 1) translate(tilt_motor_xz) circle(d = tmpl_boss, $fn = 64);
        // motor screws + 1 mm head seats on the inner face
        for (sx = [-1, 1], sz = [-1, 1]) translate(tilt_motor_xz + [sx, sz] * nema_hole_sp / 2) {
            y_extrude(tmpl_y0 - 1, tmpl_y1 + 1) circle(d = m3_clear, $fn = 24);
            y_extrude(tmpl_y0 - 1, tmpl_y0 + tmpl_cb[1]) circle(d = tmpl_cb[0], $fn = 32);
        }
        // ear X-slots (the screws stay put in the arm inserts while the plate travels mesh_slot)
        for (e = tilt_mplate_screws) y_extrude(tmpl_ye - 1, tmpl_y1 + 1)
            hull() for (dx = -mesh_slot) translate(tilt_motor_xz + e + [dx, 0]) circle(d = m3_clear, $fn = 24);
    }
}

// outer face (y 53) on the bed: (x, y, z) -> (x, z, -y), shifted to the motor axis
module tilt_motor_plate_print()
    translate([-tilt_motor_xz[0], -tilt_motor_xz[1], tmpl_y1]) rotate([-90, 0, 0]) tilt_motor_plate();

tilt_motor_plate_print();
