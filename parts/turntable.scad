// =====================================================================
//  laser-gimbal :: turntable = 85T herringbone pan gear + bearing spigot
//
//  world (pan = 0):
//    gear        z 100..110, 85T, helix -gear_helix (pinion is +)
//    shoulder    z  97..100, d 55, bears DOWN on the upper 6810 inner race
//    spigot      z ~72..100, d 49.95 / 38, slips through both 6810 inner races
//    3x M3 insert in the spigot end face (pan_collar pulls the lower inner race up)
//    4x M3 insert in the gear top at deck_screws_r (45/135/225/315 deg) for the deck
//    6x3 magnet pocket in the gear underside at r pan_hall_xy[0], angle 0 (hall sensor on the base)
//    pan-stop dog under the gear at gear angle 270 (r 47.25..50.75, z 94.75..100) running in the
//    base groove; it stalls on the base post at pan +-175 (params: pan_stop)
//    underside lightening pockets between 8 radial ribs; 5.5 mm top web stays solid
//  Cable bore d 38 runs clear end to end.
//  Print: gear top face on the bed, spigot up. No supports.
// =====================================================================
include <../lib/params.scad>
use <../lib/gears.scad>

// ---- local constants (not in the contract) ----
collar_screw_angs   = [90, 210, 330];   // spigot-end screws (pan_collar.scad uses the same)
collar_use_inserts  = false;            // self-tap 2.6 mm holes: inserts would leave 0.89 mm walls (see check below)
spigot_preload_gap  = 0.2;              // spigot end sits 0.2 above the lower bearing face so the collar
                                        // clamps the inner race (real preload) instead of bottoming on the spigot
tt_spigot_z0 = spigot_bottom_z + spigot_preload_gap;
tt_ra   = outer_r(pan_gear_z);          // 54.375
tt_rf   = root_r(pan_gear_z);           // 51.5625
tt_pocket_r  = [29.5, 47.5];            // lightening pocket annulus (rim 4 mm under the root circle)
tt_pocket_d  = 4.5;                     // pocket depth from the gear underside (web = 5.5)
tt_rib_w     = 9;                       // 8 radial ribs, every 45 deg (inserts at 45.., magnet at 0)
tt_magnet_pocket = [pan_magnet[0] + 0.2, pan_magnet[1] + 0.2];
tt_chamfer   = 0.6;

// wall check for the spigot-end inserts (hole d 4.2 at collar_screws_r in a 5.975 mm wall)
tt_wall_in  = collar_screws_r - m3_insert_d / 2 - spigot_id / 2;   // 0.89
tt_wall_out = spigot_od / 2 - collar_screws_r - m3_insert_d / 2;   // 0.89
assert(!collar_use_inserts || min(tt_wall_in, tt_wall_out) >= 0.8, "spigot insert walls < 0.8 mm");

module tt_body() {
    // gear
    translate([0, 0, turntable_z0])
        herringbone(gear_mod, pan_gear_z, gear_w, -gear_helix, gear_pa, gear_backlash);
    // shoulder ring + spigot (overlap into the gear by 0.5 for a clean union)
    translate([0, 0, 97]) cylinder(h = turntable_z0 - 97 + 0.5, d = spigot_shoulder_od);
    translate([0, 0, tt_spigot_z0]) cylinder(h = turntable_z0 - tt_spigot_z0 + 0.5, d = spigot_od);
    tt_dog();
}

// pan-stop dog: exact radial contact faces, overlaps 0.5 into the gear web (on the 270-deg rib,
// inside the root circle, so it never fills a tooth gap)
module tt_dog() {
    a0 = pan_dog_ang - pan_dog_w / 2;
    a1 = pan_dog_ang + pan_dog_w / 2;
    n = 6;
    translate([0, 0, pan_dog_z0]) linear_extrude(height = turntable_z0 - pan_dog_z0 + 0.5)
        polygon(concat([for (i = [0 : n]) let(a = a0 + (a1 - a0) * i / n) pan_dog_r[1] * [cos(a), sin(a)]],
                       [for (i = [n : -1 : 0]) let(a = a0 + (a1 - a0) * i / n) pan_dog_r[0] * [cos(a), sin(a)]]));
}

module tt_pockets_2d() {
    offset(r = 2) offset(delta = -2)
        difference() {
            circle(r = tt_pocket_r[1]);
            circle(r = tt_pocket_r[0]);
            for (a = [0 : 45 : 315]) rotate(a) translate([0, -tt_rib_w / 2]) square([tt_pocket_r[1] + 1, tt_rib_w]);
        }
}

module tt_cuts() {
    // cable bore, end to end
    translate([0, 0, tt_spigot_z0 - 1]) cylinder(h = 50, d = spigot_id);
    // bore chamfers at both ends
    translate([0, 0, turntable_gear_top - tt_chamfer]) cylinder(h = tt_chamfer + 0.01, d1 = spigot_id - 0.2, d2 = spigot_id + 2 * tt_chamfer + 0.02, $fn = 72);
    translate([0, 0, tt_spigot_z0 - 0.01]) cylinder(h = tt_chamfer + 0.01, d1 = spigot_id + 2 * tt_chamfer + 0.02, d2 = spigot_id - 0.2, $fn = 72);
    // spigot-end outer lead-in chamfer (slides into the bearings)
    translate([0, 0, tt_spigot_z0]) rotate_extrude($fn = 72)
        polygon([[spigot_od / 2 - tt_chamfer, -0.01], [spigot_od / 2 + 1, -0.01], [spigot_od / 2 + 1, tt_chamfer + 1.01]]);
    // tooth-tip chamfers on both gear faces (bed-side elephant foot + mesh entry)
    for (zf = [[turntable_z0, 1], [turntable_gear_top, -1]])
        translate([0, 0, zf[0]]) scale([1, 1, zf[1]]) rotate_extrude($fn = 128)
            polygon([[tt_ra - tt_chamfer, -0.01], [tt_ra + 1, -0.01], [tt_ra + 1, tt_chamfer + 1.01]]);
    // spigot-end fasteners for pan_collar
    for (a = collar_screw_angs) rotate([0, 0, a]) translate([collar_screws_r, 0, tt_spigot_z0 - 0.01])
        if (collar_use_inserts) cylinder(h = m3_insert_h + 1 + 0.01, d = m3_insert_d, $fn = 24);
        else cylinder(h = 9, d = m3_tap, $fn = 24);
    // deck inserts in the gear top
    for (a = [45 : 90 : 315]) rotate([0, 0, a]) translate([deck_screws_r, 0, turntable_gear_top - (m3_insert_h + 1)])
        cylinder(h = m3_insert_h + 1 + 0.01, d = m3_insert_d, $fn = 24);
    // hall magnet pocket, underside, r 45, angle 0
    translate([pan_hall_xy[0], 0, turntable_z0 - 0.01]) cylinder(h = tt_magnet_pocket[1] + 0.01, d = tt_magnet_pocket[0], $fn = 32);
    // lightening pockets, open to the underside
    translate([0, 0, turntable_z0 - 0.01]) linear_extrude(height = tt_pocket_d + 0.01) tt_pockets_2d();
}

module turntable() {
    difference() {
        tt_body();
        tt_cuts();
    }
}

// print: gear top (z = 110) on the bed, spigot up
module turntable_print() {
    translate([0, 0, turntable_gear_top]) rotate([180, 0, 0]) turntable();
}

turntable_print();
