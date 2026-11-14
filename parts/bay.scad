// =====================================================================
//  laser-gimbal :: electronics bay (tray under the base housing)
//  World frame: z 0 (desk) .. bay_h (48), square bay_w x bay_w centred on the pan axis.
//  Open top: the 190 mm base cylinder sits on the wall rims + internal 45-deg ledge and
//  is centred by a 3 mm lip that rises around the cylinder at the four corners.
//  Joint: 4x M3x50 driven UP from the counterbored floor, through the tube bosses,
//  into the heat-set inserts in the base posts (base z 48..54).
//  Print: floor on the bed, as modelled (no supports).
// =====================================================================
include <../lib/params.scad>
use <../lib/gears.scad>

// ---------- local constants ----------
bay_wall   = wall;                       // 3.0 side walls
bay_in     = bay_w / 2 - bay_wall;       // 92 inner half-width
bay_in_r   = bay_corner_r - bay_wall;    // 9 inner corner radius
chamf      = 0.5;                        // first-layer chamfer

// base seating: ledge from r = seat_r outward at z = bay_h (supported by a 45-deg cone),
// locating lip r >= lip_r, z bay_h .. bay_h + lip_h (only exists at the corners, where
// the square reaches beyond the cylinder).
seat_r     = 90;                         // base wall is r 92..95
lip_r      = base_d / 2 + fit;           // 95.2
lip_h      = 3;
lip_trim   = 116;                        // |x|+|y| >= this: drops the knife-edge lip ends (min ~2.8 mm)

// bay screw tubes
cb_d       = m3_head_d + 0.5;            // 6.5 counterbore
cb_h       = 3.5;                        // head top 0.3 below the bed face; M3x50 tip reaches z 53.5
pad_d      = 13;                         // thick foot around the counterbore
pad_h      = 7;
rib_t      = 3;                          // diagonal web tube -> corner

// board standoffs
so_h       = 6;
so_top     = bay_floor + so_h;           // 9 : board underside
zone_y     = 58.5;                       // board zone |y| <= 58.5, |x| <= 42.5
pi_org     = [-pi5_board[0] / 2, zone_y - pi5_board[1]];            // [-42.5, 2.5]
skr_org    = [-skr_pico_board[0] / 2, -zone_y];                     // [-42.5, -58.5]
pi_xy      = [for (i = [0, 1], j = [0, 1])
                 pi_org + [pi5_hole_inset + i * pi5_holes[0], pi5_hole_inset + j * pi5_holes[1]]];
// SKR Pico (BTT size drawing): 58 x 49 pattern 3.5 in from the -X short edge and the -Y long edge;
// the USB-C / power short edge faces +X (holes 23.5 from it) -> x -39 / 19, y -55 / -6
skr_xy     = [for (i = [0, 1], j = [0, 1])
                 skr_org + [skr_pico_hole_inset + i * skr_pico_holes[0], skr_pico_hole_inset + j * skr_pico_holes[1]]];
// adapter grids (front, +X free space): 30 x 30 square of M3 inserts each.
//   y < 0 : 12V->5V 5A buck converter      y > 0 : laser TTL driver
// mount the module directly if its holes match, otherwise on a small perfboard/printed plate.
aux_xy     = [for (yc = [-35, 35], i = [-1, 1], j = [-1, 1]) [67 + i * 15, yc + j * 15]];

// 40 mm intake fan on the +Y wall (inside face), blowing in over the Pi 5; exhaust on -Y.
fan_xz     = [0, bay_floor + fan40[1] / 2];   // fan sits on the floor: z 3..43
// rear (-X) panel: [y, hole, label]. Spacing for a ~30 mm e-stop mushroom next to a ~24 mm key bezel.
// Wiring of the laser enable chain: see lib/params.scad (panel section).
panel_z    = 24;
panel      = [[-32, estop_hole, "STOP"], [0, key_switch_hole, "LASER"], [30, dc_jack_hole, "12V"]];
// camera link (params): static zip-tie post under the pan axis zone + pad for the bay adapter board
anchor_sz  = [8, 8, 38];                 // post x, y, top z
anchor_tun = [4, 2.5];                   // zip-tie tunnels along Y: width (x), height (z)
anchor_tun_z = [20, 32];                 // tunnel bottoms
cl_pad     = [[camlink_bay_xy[0] - 1, camlink_bay_xy[0] + camlink_board[0] + 1],
              [camlink_bay_xy[1] - 1, camlink_bay_xy[1] + camlink_board[1] + 1]];
cl_tun     = [4, 2];                     // pad tunnels along Y: width, height (from z bay_floor + 0.5)
label_z    = 7.5;
label_d    = 0.6;

foot_xy    = 80;
foot_d     = 10;
foot_h     = 1;

// ---------- 2D helpers ----------
module rsq(half, r) offset(r = r, $fn = 48) square(2 * (half - r), center = true);

// teardrop capped at the circle's top tangent (bridge 0.83 r) -- for horizontal holes > 6 mm.
// The 64-gon circumscribes the nominal circle (its flats sit ON d, not inside it).
module tear2d(d) {
    r = d / 2 / cos(180 / 64);
    intersection() {
        hull() {
            circle(r = r, $fn = 64);
            polygon([[-0.01, r * sqrt(2)], [0.01, r * sqrt(2)], [0, 0]]);
        }
        square([d + 1, d], center = true);
    }
}

// vertical vent slot with a 45-deg roof
module slot2d(w, z0, z1) polygon([[-w / 2, z0], [w / 2, z0], [w / 2, z1 - w / 2], [0, z1], [-w / 2, z1 - w / 2]]);

module grille2d() intersection() {
    circle(d = 37, $fn = 64);
    for (x = [-15 : 5 : 15]) translate([x - 1.5, -20]) square([3, 40]);
}

// ---------- solids ----------
module shell_outer() hull() {
    linear_extrude(height = 0.01) rsq(bay_w / 2 - chamf, bay_corner_r - chamf);
    translate([0, 0, chamf]) linear_extrude(height = bay_h - chamf) rsq(bay_w / 2, bay_corner_r);
}

module tray() difference() {
    shell_outer();
    translate([0, 0, bay_floor]) linear_extrude(height = bay_h) rsq(bay_in, bay_in_r);
}

// 45-deg ledge under the base wall seat (grows toward the corners)
module ledge() difference() {
    translate([0, 0, bay_floor]) linear_extrude(height = bay_h - bay_floor) rsq(bay_in + 0.5, bay_in_r + 0.5);
    translate([0, 0, -eps]) cylinder(h = bay_h + 2 * eps, r1 = seat_r + bay_h, r2 = seat_r, $fn = 128);
}

module lip() difference() {
    translate([0, 0, bay_h - eps]) linear_extrude(height = lip_h + eps) difference() {
        rsq(bay_w / 2, bay_corner_r);
        circle(r = lip_r, $fn = 256);
        rotate(45) square(lip_trim * sqrt(2), center = true);
    }
    // lead-in chamfer on the inner top edge
    translate([0, 0, bay_h + lip_h - 0.8]) cylinder(h = 0.8 + eps, r1 = lip_r, r2 = lip_r + 0.8 + eps, $fn = 256);
}

module tube_solid(p) translate([p[0], p[1], 0]) {
    cylinder(h = pad_h, d = pad_d, $fn = 48);
    translate([0, 0, pad_h - eps]) cylinder(h = (pad_d - bay_tube_od) / 2 + eps, d1 = pad_d, d2 = bay_tube_od, $fn = 48);
    cylinder(h = bay_h, d = bay_tube_od, $fn = 48);
}

module tube_cut(p) translate([p[0], p[1], 0]) {
    translate([0, 0, -1]) cylinder(h = bay_h + 2, d = m3_clear, $fn = 24);
    translate([0, 0, -1]) cylinder(h = cb_h + 1, d = cb_d, $fn = 32);
}

module ribs() intersection() {
    translate([0, 0, bay_floor - eps]) linear_extrude(height = bay_h - bay_floor + eps) rsq(bay_in + 0.5, bay_in_r + 0.5);
    for (p = bay_screw_xy) translate([p[0], p[1], 0]) rotate(atan2(p[1], p[0]))
        translate([0, -rib_t / 2, 0]) cube([60, rib_t, bay_h]);
}

module standoff(p, d) translate([p[0], p[1], bay_floor - eps]) {
    cylinder(h = so_h + eps, d = d, $fn = 32);
    cylinder(h = 1.5, d1 = d + 3, d2 = d, $fn = 32);
}

// ---------- cuts ----------
module fan_cut() {
    translate([fan_xz[0], bay_w / 2 + 1, fan_xz[1]]) rotate([90, 0, 0])
        linear_extrude(height = bay_wall + 2) grille2d();
    for (i = [-1, 1], j = [-1, 1])
        translate([fan_xz[0] + i * fan40_hole_sp / 2, bay_w / 2 + 1, fan_xz[1] + j * fan40_hole_sp / 2])
            rotate([90, 0, 0]) cylinder(h = bay_wall + 2, d = m3_clear, $fn = 24);
}

module vent_cut() for (x = [-38.5 : 7 : 38.5])
    translate([x, -bay_in + 3, 0]) rotate([90, 0, 0]) linear_extrude(height = bay_wall + 4) slot2d(3, 10, 36);

module panel_cut() for (p = panel) {
    translate([-bay_w / 2 - 1, p[0], panel_z]) rotate([90, 0, 90]) linear_extrude(height = bay_wall + 2) tear2d(p[1]);
    translate([-bay_w / 2 + label_d, p[0], label_z]) rotate([90, 0, -90]) linear_extrude(height = label_d + 1)
        text(p[2], size = 4.5, font = "Liberation Sans:style=Bold", halign = "center", valign = "center");
}

module feet_cut() for (sx = [-1, 1], sy = [-1, 1])
    translate([sx * foot_xy, sy * foot_xy, -1]) cylinder(h = foot_h + 1, d = foot_d, $fn = 48);

module insert_hole(p) translate([p[0], p[1], so_top - (m3_insert_h + 1)])
    cylinder(h = m3_insert_h + 2, d = m3_insert_d, $fn = 24);

// ---------- part ----------
module bay() difference() {
    union() {
        tray();
        ledge();
        lip();
        ribs();
        for (p = bay_screw_xy) tube_solid(p);
        for (p = pi_xy)  standoff(p, 6);          // M2.5 self-tap
        for (p = skr_xy) standoff(p, 8);          // M3 heat-set
        for (p = aux_xy) standoff(p, 8);          // M3 heat-set
        // camera-link anchor post + adapter pad
        translate([cable_anchor_xy[0] - anchor_sz[0] / 2, cable_anchor_xy[1] - anchor_sz[1] / 2, bay_floor - eps])
            cube([anchor_sz[0], anchor_sz[1], anchor_sz[2] - bay_floor + eps]);
        translate([cl_pad[0][0], cl_pad[1][0], bay_floor - eps])
            cube([cl_pad[0][1] - cl_pad[0][0], cl_pad[1][1] - cl_pad[1][0], so_top - bay_floor + eps]);
    }
    for (z = anchor_tun_z) translate([cable_anchor_xy[0] - anchor_tun[0] / 2, cable_anchor_xy[1] - anchor_sz[1] / 2 - 1, z])
        cube([anchor_tun[0], anchor_sz[1] + 2, anchor_tun[1]]);
    for (x = [cl_pad[0][0] + 6, cl_pad[0][1] - 6]) translate([x - cl_tun[0] / 2, cl_pad[1][0] - 1, bay_floor + 0.5])
        cube([cl_tun[0], cl_pad[1][1] - cl_pad[1][0] + 2, cl_tun[1]]);
    for (p = bay_screw_xy) tube_cut(p);
    for (p = pi_xy) translate([p[0], p[1], so_top - 7]) cylinder(h = 8, d = m25_tap, $fn = 24);
    for (p = concat(skr_xy, aux_xy)) insert_hole(p);
    translate([bay_grommet_xy[0], bay_grommet_xy[1], -1]) cylinder(h = bay_floor + 2, d = bay_grommet_d, $fn = 48);
    fan_cut();
    vent_cut();
    panel_cut();
    feet_cut();
}

// ---------- accessors for assembly.scad (a `use`d file exports functions, not variables) ----------
// [origin xy (board corner), footprint, component height, label]
function bay_board_top() = so_top;
function bay_boards() = [
    [pi_org,  pi5_board,      20, "Pi 5"],
    [skr_org, skr_pico_board, 16, "SKR Pico"],
    [[67 - 18, -35 - 18], [36, 36], 14, "buck 12V->5V"],
    [[67 - 18,  35 - 18], [36, 36], 12, "laser driver"],
    [camlink_bay_xy, [camlink_board[0], camlink_board[1]], camlink_board[2], "camlink"]];
function bay_anchor() = [cable_anchor_xy, anchor_sz];
function bay_fan_xz() = fan_xz;
function bay_inner_half() = bay_in;

// floor already rests on z = 0 in world coordinates
module bay_print() bay();

bay_print();
