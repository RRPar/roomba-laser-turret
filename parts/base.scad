// =====================================================================
//  laser-gimbal :: base housing
//  Cylinder shell + top plate carrying the pan hub (2x 6810), the pan
//  motor plate (pan_motor_plate.scad, clamped under the top plate by 4x M3
//  from the top through X-slots: backlash set with the turntable fitted),
//  the pinion window, the pan hard-stop groove (+-175 deg, post at 90 deg),
//  the pan hall sensor and 4 heat-set-insert posts for the bay screws.
//
//  base()        world coordinates, pan = 0
//  base_print()  upside down: top plate (z 98) on the bed
// =====================================================================
include <../lib/params.scad>
use <../lib/gears.scad>

// ---------- local constants ----------
base_r     = base_d / 2;                 // 95
base_in_r  = base_r - wall;              // 92
plate_z0   = base_top - base_top_t;      // 92  (underside of top plate = pan motor face)
hub_r      = pan_hub_od / 2;             // 36
pocket_d   = bearing_bore(b6810);        // 65.05
big_fn     = 128;
hole_fn    = 32;
// polygon circumscribing a true circle of radius r (so the pocket is never undersize)
function circ(r, n = big_fn) = r / cos(180 / n);

// ribs: hub -> outer wall, under the top plate. 180 deg is skipped (pan motor),
// 0 deg is skipped (hall sensor lead slot). Nearest rib to the motor body
// (135/225 deg) clears its corner by ~15 mm.
rib_t      = 4;
rib_angs   = [45, 90, 135, 225, 270, 315];
rib_z_hub  = pan_hub_bottom_z;           // rib lower edge at the hub (70)
rib_z_wall = 54;                         // rib lower edge at the wall

// bay screw posts (full height, tied to the wall by a web)
post_d       = 10;
insert_depth = m3_insert_h + 1;          // 6

// pan motor plate interface (the screws move WITH the plate: slots span mesh_slot)
mot_cb_d   = m3_head_d + 0.6;            // 6.6 counterbore for SHCS head
mot_cb_h   = m3_head_h + 0.2;            // 3.4: head sits 0.2 below the top surface
                                         // -> 2.6 mm clamped plate; M3x8 SHCS into the plate inserts

// hall sensor A3144 (TO-92 UA: ~4.5 x 3.5 x 1.6), lying face up, leads toward -X
hall_pocket = [4.0, 5.0, 2.0];           // X x Y x depth  (top of sensor ~0.4 below z 98)
hall_lead   = [2.0, 5.0];                // lead slot X x Y, through the plate

chamfer = 0.5;                           // first-layer chamfer (top face is the bed face)
shoulder_relief = 1.5;                   // 45 deg relief, shoulder bore d 58 -> 61 at z 90

// ---------- geometry ----------
module _rib(a) {
    rotate([0, 0, a]) rotate([90, 0, 0])
        linear_extrude(height = rib_t, center = true)
            polygon([[hub_r - 1, rib_z_hub], [hub_r - 1, plate_z0 + 0.5],
                     [base_in_r + 0.5, plate_z0 + 0.5], [base_in_r + 0.5, rib_z_wall]]);
}

module _post(p) {
    a  = atan2(p[1], p[0]);
    rp = norm(p);
    h  = plate_z0 - base_z0 + 0.5;
    rotate([0, 0, a]) translate([rp, 0, base_z0]) hull() {
        cylinder(h = h, d = post_d, $fn = 48);
        translate([0, -post_d / 2 + 1, 0]) cube([base_in_r + 0.5 - rp, post_d - 2, h]);
    }
}

module _solid() {
    // outer shell
    translate([0, 0, base_z0]) difference() {
        cylinder(h = plate_z0 - base_z0 + 0.5, r = base_r, $fn = big_fn);
        translate([0, 0, -1]) cylinder(h = plate_z0 - base_z0 + 2, r = base_in_r, $fn = big_fn);
    }
    // top plate
    translate([0, 0, plate_z0]) cylinder(h = base_top_t, r = base_r, $fn = big_fn);
    // pan hub
    translate([0, 0, pan_hub_bottom_z]) cylinder(h = base_top - pan_hub_bottom_z, r = hub_r, $fn = big_fn);
    // ribs
    for (a = rib_angs) _rib(a);
    // bay screw posts
    for (p = bay_screw_xy) _post(p);
}

// vertical hole slotted along X over the motor plate travel
module _slot(d, h, fn = hole_fn) {
    hull() for (dx = mesh_slot) translate([dx, 0, 0]) cylinder(h = h, d = d, $fn = fn);
}

// pan-stop groove plan: annulus minus the post sector (exact radial faces through the axis)
module _stop_groove2d() difference() {
    difference() {
        circle(r = circ(pan_stop_r[1]), $fn = big_fn);
        circle(r = pan_stop_r[0], $fn = big_fn);
    }
    a0 = pan_post_ang - pan_post_w / 2;
    a1 = pan_post_ang + pan_post_w / 2;
    polygon([[0, 0], 80 * [cos(a0), sin(a0)], 80 * [cos(a1), sin(a1)]]);
}

module _cuts() {
    // ---- pan hub bore ----
    // upper pocket (bearing z 90..97), opens to the top
    translate([0, 0, pan_brg_upper_z]) cylinder(h = base_top - pan_brg_upper_z + 1, r = circ(pocket_d / 2), $fn = big_fn);
    // lead-in chamfer on the upper pocket mouth (also kills elephant foot)
    translate([0, 0, base_top - chamfer])
        cylinder(h = chamfer + 0.01, r1 = circ(pocket_d / 2), r2 = circ(pocket_d / 2) + chamfer + 0.01, $fn = big_fn);
    // shoulder bore between the bearings (z 79..90)
    translate([0, 0, pan_hub_bottom_z - 1]) cylinder(h = base_top - pan_hub_bottom_z + 2, d = pan_brg_shoulder_id, $fn = big_fn);
    // 45 deg relief on the top edge of the shoulder bore: in print orientation (upside down) the
    // shoulder face under the upper bearing is a ceiling; this cuts its free overhang from 3.5 mm
    // to 2 mm while still seating the 6810 outer race (outer-race land d ~61.3 > 61)
    translate([0, 0, pan_brg_upper_z - shoulder_relief])
        cylinder(h = shoulder_relief + 0.01, d1 = pan_brg_shoulder_id, d2 = pan_brg_shoulder_id + 2 * shoulder_relief + 0.02, $fn = big_fn);
    // lower pocket (bearing z 72..79), opens to the bottom
    translate([0, 0, pan_hub_bottom_z - 1])
        cylinder(h = pan_brg_lower_z + b6810[2] - pan_hub_bottom_z + 1, r = circ(pocket_d / 2), $fn = big_fn);
    translate([0, 0, pan_hub_bottom_z - 0.01])
        cylinder(h = chamfer + 0.01, r1 = circ(pocket_d / 2) + chamfer, r2 = circ(pocket_d / 2), $fn = big_fn);

    // ---- pan motor plate interface ----
    // shaft / pinion window (the pinion passes through it with the motor; slotted with the plate)
    translate([pan_motor_xy[0], pan_motor_xy[1], plate_z0 - 1]) _slot(pan_window_d, base_t_cut(), 64);
    // 4 plate screws from the top: X-slots + counterbores, all at r >= 64.8 (outside gear and deck)
    for (p = pan_mplate_screws) translate([p[0], p[1], 0]) {
        translate([0, 0, plate_z0 - 1]) _slot(m3_clear, base_t_cut());
        translate([0, 0, base_top - mot_cb_h]) _slot(mot_cb_d, mot_cb_h + 1);
    }

    // ---- pan hard stop: groove for the turntable dog, interrupted at the post ----
    translate([0, 0, pan_stop_z]) linear_extrude(height = base_top - pan_stop_z + 1) _stop_groove2d();

    // ---- hall sensor pocket (face up, flush-ish below z 98) ----
    translate([pan_hall_xy[0], pan_hall_xy[1], 0]) {
        translate([-hall_pocket[0] / 2, -hall_pocket[1] / 2, base_top - hall_pocket[2]])
            cube([hall_pocket[0], hall_pocket[1], hall_pocket[2] + 1]);
        // lead slot down into the cavity, on the -X (hub) side of the pocket
        translate([-hall_pocket[0] / 2 - hall_lead[0] + 0.2, -hall_lead[1] / 2, plate_z0 - 1])
            cube([hall_lead[0], hall_lead[1], base_top_t + 2]);
    }

    // ---- M3 heat-set inserts in the post bottoms (bay screws come up from below) ----
    for (p = bay_screw_xy) translate([p[0], p[1], base_z0 - 1]) {
        cylinder(h = insert_depth + 1, d = m3_insert_d, $fn = hole_fn);
        cylinder(h = 1 + chamfer, d1 = m3_insert_d + 2 * (1 + chamfer), d2 = m3_insert_d, $fn = hole_fn);
    }

    // ---- first-layer chamfer on the top outer edge (bed face) ----
    rotate_extrude($fn = big_fn)
        polygon([[base_r - chamfer - 1, base_top + 1], [base_r + 1, base_top + 1], [base_r + 1, base_top - chamfer - 1]]);
}

function base_t_cut() = base_top_t + 2;

module base() {
    difference() { _solid(); _cuts(); }
}

// upside down: world z = base_top lands on the bed -> z' = base_top - z, min z' = 0
module base_print() {
    translate([0, 0, base_top]) rotate([180, 0, 0]) base();
}

base_print();
