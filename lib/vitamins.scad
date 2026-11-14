// =====================================================================
//  laser-gimbal :: purchased-part placeholders ("vitamins") for the
//  assembly and interference checks. NOT printed.
//  use <../lib/vitamins.scad>   (after include <../lib/params.scad>)
//  All modules are in a LOCAL frame documented per module.
// =====================================================================
include <params.scad>

// NEMA17: mounting face on z=0, body extends to -Z, shaft along +Z. Axis = Z.
module nema17(len = nema_len) {
    color("dimgray") translate([-nema_w/2, -nema_w/2, -len]) cube([nema_w, nema_w, len]);
    color("silver") cylinder(h = nema_boss_h, d = nema_boss_d);
    color("silver") cylinder(h = nema_shaft_l, d = nema_shaft_d, $fn = 24);
}

// Ball bearing: axis = Z, bottom face z=0.
module bearing(b) {
    color("lightsteelblue") difference() {
        cylinder(h = b[2], d = b[1]);
        translate([0, 0, -1]) cylinder(h = b[2] + 2, d = b[0]);
    }
}

// Raspberry Pi Camera Module 3: PCB in the YZ plane, lens pointing +X,
// origin = optical axis at the PCB front face. Drawn as MOUNTED on the payload:
// connector edge DOWN (-Z), FPC connector on the back at that edge.
module picam3() {
    zb = -picam3_lens_from_conn;   // board bottom (connector) edge
    color("green") translate([-picam3_board[2], -picam3_board[0]/2, zb])
        cube([picam3_board[2], picam3_board[0], picam3_board[1]]);
    color("#222") translate([0, -picam3_lens_block[0]/2, -picam3_lens_block[1]/2])
        cube([picam3_lens_block[2], picam3_lens_block[0], picam3_lens_block[1]]);
    color("#111") rotate([0, 90, 0]) cylinder(h = 6.98, d = 5.75, $fn = 32);   // lens tip 6.98 proud
    color("ivory") translate([-picam3_board[2] - picam3_conn[2], -picam3_conn[0]/2, zb])
        cube([picam3_conn[2], picam3_conn[0], picam3_conn[1]]);
}

// 12 mm laser module: axis along +X, origin = rear face centre, emitter at +laser_len.
module laser12(len = laser_len) {
    color("gold") rotate([0, 90, 0]) cylinder(h = len, d = laser_d, $fn = 48);
}

// Board placeholder: footprint [x,y] on z=0, height h.
module board(sz, h = 18, c = "seagreen") { color(c) cube([sz[0], sz[1], h]); }

module fan40() { color("#333") difference() { cube(fan40); translate([20, 20, -1]) cylinder(h = 12, d = 37); } }

// M8 tilt axle along Y, origin = tilt axis at y 0 (params: tilt_axle). Hex head on -Y bearing on
// the -Y axle_collar (y -55), nylock on +Y on the +Y collar (y 55..63), shank to y -55 + len.
// Head / nut drawn as round envelopes (d = across corners): they turn with tilt.
module m8_axle(len = tilt_axle_len) {
    yc = tilt_brg_y[1] + axle_collar[1];          // 55: collar outer faces
    color("silver") {
        translate([0, -yc, 0]) rotate([-90, 0, 0]) cylinder(h = len, d = 8, $fn = 32);
        translate([0, -yc, 0]) rotate([90, 0, 0]) cylinder(h = m8_head[1], d = m8_head[0] / cos(30), $fn = 32);
        translate([0, yc, 0]) rotate([-90, 0, 0]) cylinder(h = m8_nylock[1], d = m8_nylock[0] / cos(30), $fn = 32);
    }
}
