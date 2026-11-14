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
// origin = optical axis at the PCB front face.
module picam3() {
    color("green") translate([-picam3_board[2], -picam3_board[0]/2, -picam3_board[1]/2 - 2.5])
        cube([picam3_board[2], picam3_board[0], picam3_board[1]]);   // lens sits 2.5 above board centre
    color("black") translate([0, -picam3_lens_block[0]/2, -picam3_lens_block[1]/2])
        cube([picam3_lens_block[2], picam3_lens_block[0], picam3_lens_block[1]]);
    color("black") translate([0, 0, 0]) rotate([0, 90, 0]) cylinder(h = picam3_lens_block[2] + 3, d = 7, $fn = 32);
}

// 12 mm laser module: axis along +X, origin = rear face centre, emitter at +laser_len.
module laser12(len = laser_len) {
    color("gold") rotate([0, 90, 0]) cylinder(h = len, d = laser_d, $fn = 48);
}

// Board placeholder: footprint [x,y] on z=0, height h.
module board(sz, h = 18, c = "seagreen") { color(c) cube([sz[0], sz[1], h]); }

module fan40() { color("#333") difference() { cube(fan40); translate([20, 20, -1]) cylinder(h = 12, d = 37); } }

// M8 axle bolt along Y, centred on origin.
module m8_axle(len = 110) { color("silver") rotate([90, 0, 0]) cylinder(h = len, d = 8, center = true, $fn = 32); }
