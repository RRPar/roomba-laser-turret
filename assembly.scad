// =====================================================================
//  laser-gimbal :: full assembly (preview / renders / interference)
//
//    openscad -D pan=30 -D tilt=45 assembly.scad
//    -D explode=1          separate the stages vertically
//    -D show_vitamins=false
//    -D show_beam_stop=true
//
//  Every part module is in WORLD coordinates at pan = 0, tilt = 0
//  (lib/params.scad). Here:
//    static     bay, base, pan_motor_plate + pan motor, pan pinion (spins on its own axis)
//    pan stage  rotate([0,0,pan])           turntable (+ pan-stop dog), pan_collar, 2x 6810,
//               yoke, tilt_motor_plate + tilt motor + pinion, 2x 608, M8 axle + 2x axle_collar,
//               2x tilt_spacer, deck camera-link adapter
//  Pan range is limited by the hard stop to +-pan_stop (175 deg).
//    tilt group + rotate([0,-tilt,0]) about [0,0,tilt_z]
//               payload, tilt_gear, laser, camera, beam_stop
//  Gear senses (verified by tools/interference.sh, 2D slice test):
//    pan pinion  = mesh_phase(85,17,180) - pan * 85/17   (about its own Z axis)
//    tilt pinion = mesh_phase(51,17,180) + tilt * 51/17  (in tilt_gear's LOCAL frame,
//                  where the wheel turns by -tilt; local -> world = rotate([-90,0,0]))
// =====================================================================
include <lib/params.scad>
use <lib/gears.scad>
use <lib/vitamins.scad>
use <parts/bay.scad>
use <parts/base.scad>
use <parts/pan_motor_plate.scad>
use <parts/tilt_motor_plate.scad>
use <parts/axle_collar.scad>
use <parts/pinion.scad>
use <parts/turntable.scad>
use <parts/pan_collar.scad>
use <parts/yoke.scad>
use <parts/tilt_gear.scad>
use <parts/tilt_spacer.scad>
use <parts/payload.scad>
use <parts/beam_stop.scad>

pan            = 0;
tilt           = 0;
explode        = 0;
show_vitamins  = true;
show_beam_stop = false;

// laser seated against the payload's 45-deg front seat (payload.scad: seat at x 43.9),
// i.e. 2.9 mm ahead of the contract laser_x[0] = 6 (wire bend room behind it)
asm_laser_x = 43.9 - laser_len;

// explode offsets (z) per stage
ex_base   = 60 * explode;
ex_collar = 0;                 // stays under the hub, visible in the gap between bay and lifted base
ex_tt     = 120 * explode;
ex_yoke   = 190 * explode;
ex_tilt   = 290 * explode;

// ---------- colours ----------
c_bay     = "#3b4252";
c_base    = "#4c566a";
c_tt      = "#d08770";
c_collar  = "#ebcb8b";
c_yoke    = "#5e81ac";
c_spacer  = "#88c0d0";
c_payload = "#e5e9f0";
c_tgear   = "#bf616a";
c_pinion  = "#a3be8c";
c_bstop   = "#2e3440";
c_mplate  = "#b48ead";

// ---------- transforms ----------
module at_pan()  rotate([0, 0, pan]) children();
module at_tilt() translate([0, 0, tilt_z]) rotate([0, -tilt, 0]) translate([0, 0, -tilt_z]) children();
module lift(z)   translate([0, 0, z]) children();

// ---------- sub-assemblies ----------
module pan_motor() translate([pan_motor_xy[0], pan_motor_xy[1], pan_motor_face_z]) nema17();

module pan_pinion() {
    p = [pan_motor_xy[0], pan_motor_xy[1], 0];
    translate(p) rotate([0, 0, -pan * pan_gear_z / pinion_z]) translate(-p) pinion();
}

// tilt motor: face on the +Y arm outside (y 53), body toward +Y, shaft toward -Y
module tilt_motor() translate([tilt_motor_xz[0], tilt_motor_face_y, tilt_motor_xz[1]]) rotate([90, 0, 0]) nema17();

// tilt pinion in the tilt_gear LOCAL frame (axis Z, z 0..gear_w == world y 31..41)
module tilt_pinion() translate([0, tilt_gear_y[0], tilt_z]) rotate([-90, 0, 0])
    translate([-tilt_cd, 0, 0]) rotate([0, 0, mesh_phase(tilt_gear_z, pinion_z, 180) + tilt * tilt_gear_z / pinion_z])
        pinion_local();

module b6810_pair() for (z = [pan_brg_lower_z, pan_brg_upper_z]) translate([0, 0, z]) bearing(b6810);
module b608_pair() for (y0 = [tilt_brg_y[0], -tilt_brg_y[1]]) translate([0, y0, tilt_z]) rotate([-90, 0, 0]) bearing(b608);
module spacers() { tilt_spacer(); mirror([0, 1, 0]) tilt_spacer(); }
module collars() { axle_collar(); mirror([0, 1, 0]) axle_collar(); }
module tilt_axle() translate([0, 0, tilt_z]) m8_axle();
// camera-link adapter board on the deck pad (CSI -> HDMI, envelope)
module camlink_deck() translate([camlink_deck_xy[0], camlink_deck_xy[1], deck_z0 + deck_t + camlink_pad_h])
    board([camlink_board[0], camlink_board[1]], camlink_board[2], "#7a3e9d");

module electronics() {
    t = bay_board_top();
    for (b = bay_boards()) translate([b[0][0], b[0][1], t])
        board(b[1], b[2], b[3] == "Pi 5" ? "#2d8a4e" : b[3] == "SKR Pico" ? "#1f4e8c" : b[3] == "buck 12V->5V" ? "#7a3e9d"
                        : b[3] == "camlink" ? "#7a3e9d" : "#b03a2e");
    fx = bay_fan_xz();
    // 40 mm fan on the +Y wall inside face, axis along Y
    translate([fx[0] - fan40[0] / 2, bay_inner_half(), fx[1] - fan40[1] / 2]) rotate([90, 0, 0]) fan40();
}

module static_stage() {
    color(c_bay) bay();
    if (show_vitamins) electronics();
    lift(ex_base) {
        color(c_base) base();
        color(c_mplate) pan_motor_plate();
        if (show_vitamins) pan_motor();
        color(c_pinion) pan_pinion();
    }
}

module laser_vit()  translate([asm_laser_x, laser_axis[1], laser_axis[2]]) laser12();
module camera_vit() translate([payload_x[1], cam_axis[1], cam_axis[2]]) picam3();

module tilt_group() {
    color(c_payload) payload();
    color(c_tgear) tilt_gear();
    if (show_vitamins) { laser_vit(); camera_vit(); }
    if (show_beam_stop) color(c_bstop) beam_stop();
}

module pan_stage() at_pan() {
    lift(ex_tt) color(c_tt) turntable();
    lift(ex_collar) color(c_collar) pan_collar();
    if (show_vitamins) lift(ex_base) b6810_pair();
    lift(ex_yoke) {
        color(c_yoke) yoke();
        color(c_pinion) tilt_pinion();
        color(c_spacer) spacers();
        color(c_mplate) tilt_motor_plate();
        color(c_spacer) collars();
        if (show_vitamins) { tilt_motor(); b608_pair(); tilt_axle(); camlink_deck(); }
    }
    lift(ex_tilt) at_tilt() tilt_group();
}

// robot.scad `include`s this file (a `use`d file would keep its own pan/tilt/explode) and sets
// asm_embedded = true so the two calls below do not draw a second gimbal at the origin.
asm_embedded = false;
if (!asm_embedded) {
    static_stage();
    pan_stage();
}
