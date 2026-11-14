// Robot vacuum with a cartoon gun turret on top.
// Decorative, single-piece, print-in-place model (no moving or functional parts).
// Units: mm. Front of the vacuum (and the barrel) points along +X.
//
// Render:  openscad -o roomba_turret.stl roomba_turret.scad

/* ---------- Tunables ---------- */
scale_factor = 1.0;     // uniform scale for the whole model

body_d      = 120;      // vacuum diameter
body_h      = 22;       // vacuum height
edge_r      = 5;        // rounding of the top outer edge
bumper_out  = 1.6;      // how far the front bumper sticks out
bumper_z    = [4, 15];  // bumper band bottom/top heights

ring_d_bot  = 52;       // turret ring
ring_d_top  = 46;
ring_h      = 8;

gun_w       = 12;       // receiver width
gun_h       = 16;       // receiver height
barrel_d    = 8;
muzzle_d    = 11;
fin_t       = 2.4;      // barrel support fin thickness (keeps the print support-free)

$fn = 96;

/* ---------- Derived ---------- */
R      = body_d / 2;
top_z  = body_h;                    // top of vacuum
ring_z = top_z + ring_h;            // top of turret ring
gun_z0 = ring_z;                    // receiver bottom
axis_z = gun_z0 + gun_h / 2;        // barrel axis height

/* ---------- Helpers ---------- */
module rounded_box(size, r = 1.5) {
    hull()
        for (x = [r, size[0] - r], y = [r, size[1] - r], z = [r, size[2] - r])
            translate([x, y, z]) sphere(r = r, $fn = 24);
}

// Cylinder lying along +X, starting at x0.
module xcyl(x0, len, d, z = axis_z, d2 = undef) {
    translate([x0, 0, z]) rotate([0, 90, 0])
        cylinder(h = len, d1 = d, d2 = (d2 == undef ? d : d2));
}

/* ---------- Vacuum body ---------- */
module body_shell() {
    rotate_extrude()
        hull() {
            square([R - edge_r, body_h]);
            square([R, body_h - edge_r]);
            translate([R - edge_r, body_h - edge_r]) circle(r = edge_r);
        }
}

module bumper() {
    // Front half-ring band, -90..+90 degrees, i.e. centred on +X.
    rotate([0, 0, -90])
        rotate_extrude(angle = 180)
            translate([R - 2, bumper_z[0]])
                square([2 + bumper_out, bumper_z[1] - bumper_z[0]]);
}

module top_details_cut() {
    // Decorative groove ring on the lid
    translate([0, 0, top_z - 0.8])
        difference() {
            cylinder(h = 2, r = 48.6);
            translate([0, 0, -1]) cylinder(h = 4, r = 47.4);
        }
    // Recessed ring around the "clean" button (rear of the lid)
    translate([-40, 0, top_z - 0.8])
        difference() {
            cylinder(h = 2, d = 16.4, $fn = 48);
            translate([0, 0, -1]) cylinder(h = 4, d = 14, $fn = 48);
        }
    // Small sensor window on the bumper face
    translate([R + bumper_out - 0.6, 0, (bumper_z[0] + bumper_z[1]) / 2])
        cube([2, 18, 4], center = true);
}

module vacuum() {
    difference() {
        union() {
            body_shell();
            bumper();
        }
        top_details_cut();
    }
}

/* ---------- Turret ---------- */
module turret_ring() {
    translate([0, 0, top_z - 0.5])
        cylinder(h = ring_h + 0.5, d1 = ring_d_bot, d2 = ring_d_top);
    // Bolt heads around the ring
    for (a = [0 : 45 : 359])
        rotate([0, 0, a + 22.5])
            translate([ring_d_bot / 2 - 2.2, 0, top_z + ring_h * 0.45])
                rotate([0, 90, 0]) cylinder(h = 2.5, d = 3, $fn = 20);
}

module receiver() {
    translate([-20, -gun_w / 2, gun_z0 - 0.5])
        rounded_box([46, gun_w, gun_h + 0.5], r = 1.5);
}

module stock() {
    // Rear stock with a 45-degree underside so it prints without supports.
    rotate([90, 0, 0])
        linear_extrude(height = 10, center = true)
            polygon([[-18, gun_z0 - 2], [-32, gun_z0 + 13],
                     [-32, gun_z0 + gun_h], [-18, gun_z0 + gun_h]]);
}

module scope() {
    // Rail
    translate([-10, -2, gun_z0 + gun_h - 0.5]) cube([22, 4, 3.5]);
    // Tube + end bells
    sz = gun_z0 + gun_h + 6;
    xcyl(-12, 26, 8, z = sz);
    xcyl(-14, 3, 10, z = sz);
    xcyl(13,  3, 10, z = sz);
}

module magazine() {
    // Sits on the vacuum lid in front of the turret ring.
    translate([15, -4, top_z - 0.5]) cube([8, 8, gun_z0 - top_z + 1]);
}

module barrel() {
    xcyl(24, 27, barrel_d);                                  // barrel
    for (x = [30, 36, 42]) xcyl(x, 1.6, barrel_d + 1.6);     // cooling rings
    xcyl(50, 8, muzzle_d);                                   // muzzle brake
}

module muzzle_cut() {
    // Shallow decorative recess in the muzzle face (solid barrel, not a bore).
    xcyl(58 - 3, 4, 5);
    // Side vents on the muzzle brake
    for (s = [-1, 1])
        translate([54, s * muzzle_d / 2, axis_z]) cube([4, 3, 3], center = true);
}

module barrel_fin() {
    // Vertical cradle under the barrel, rooted in the lid: makes the barrel printable.
    translate([24, -fin_t / 2, top_z - 3])
        cube([57 - 24, fin_t, axis_z - (top_z - 3)]);
}

module gun() {
    difference() {
        union() {
            receiver();
            stock();
            scope();
            magazine();
            barrel();
            barrel_fin();
        }
        muzzle_cut();
    }
}

/* ---------- Assembly ---------- */
scale(scale_factor)
    union() {
        vacuum();
        turret_ring();
        gun();
    }
