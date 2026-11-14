// =====================================================================
//  laser-gimbal + robot :: objects for the browser viewer (tools/export_viewer.sh)
//  FRAME CONVENTION: every mesh (robot AND gimbal) is exported in the ROBOT frame
//  (lib/robot_params.scad: origin on the floor under the pan axis, +X forward) at
//  pan = 0, tilt = 0. The gimbal objects are the assembly.scad world-frame objects
//  translated by [0, 0, rb_deck_z]. The kinematics keys keep their GIMBAL-world
//  values (tilt_z, tilt_motor_xz, pan_gear_z ... are NOT shifted); the viewer adds
//  "deck_z" (= rb_deck_z) to every gimbal pivot height (tilt pivot z = deck_z + tilt_z,
//  pan-pinion / tilt-pinion pivots likewise). Robot objects have no pivots except the
//  wheels, which spin about the axis (rb_axle_x, +-rb_wheel_y, rb_axle_z) along Y.
//  Placements are taken from assembly.scad and the parts/robot_*.scad modules (`use`),
//  so the viewer shows exactly what the assemblies define. The viewer applies the
//  gimbal stage transforms (same as assembly.scad, about the shifted pivots):
//    static : none            (pan pinion spins about its own axis)
//    pan    : rotate([0,0,pan])  (tilt pinion spins about its own axis)
//    tilt   : pan * rotate([0,-tilt,0]) about [0,0,tilt_z]
//  obj = "kinematics" echoes the numbers the viewer needs as JSON.
// =====================================================================
include <../lib/params.scad>
use <../lib/gears.scad>
use <../lib/vitamins.scad>
use <../assembly.scad>
use <../parts/bay.scad>
use <../parts/base.scad>
use <../parts/pan_motor_plate.scad>
use <../parts/tilt_motor_plate.scad>
use <../parts/axle_collar.scad>
use <../parts/pinion.scad>
use <../parts/turntable.scad>
use <../parts/pan_collar.scad>
use <../parts/yoke.scad>
use <../parts/tilt_gear.scad>
use <../parts/tilt_spacer.scad>
use <../parts/payload.scad>
use <../parts/beam_stop.scad>
include <../lib/robot_params.scad>
use <../lib/robot_vitamins.scad>
use <../parts/robot_floor_front.scad>
use <../parts/robot_lid_fl.scad>
use <../parts/robot_pillar.scad>
use <../parts/robot_motor_bracket.scad>
use <../parts/robot_motor_strap.scad>
use <../parts/robot_wheel_hub.scad>
use <../parts/robot_tire.scad>
use <../parts/robot_caster_mount.scad>
use <../parts/robot_batt_tray.scad>
use <../parts/robot_ebay_tray.scad>
use <../parts/robot_bumper_left.scad>
use <../parts/robot_bumper_right.scad>
use <../parts/robot_bumper_splice.scad>

obj = "";

module deck() translate([0, 0, rb_deck_z]) children();   // gimbal world -> robot frame

// static
if (obj == "bay") deck()             bay();
if (obj == "electronics") deck()     electronics();
if (obj == "base") deck()            base();
if (obj == "pan_motor_plate") deck() pan_motor_plate();
if (obj == "pan_motor") deck()       pan_motor();
if (obj == "pan_pinion") deck()      pan_pinion();
// pan stage
if (obj == "turntable") deck()       turntable();
if (obj == "pan_collar") deck()      pan_collar();
if (obj == "b6810") deck()           b6810_pair();
if (obj == "yoke") deck()            yoke();
if (obj == "tilt_motor_plate") deck() tilt_motor_plate();
if (obj == "tilt_motor") deck()      tilt_motor();
if (obj == "b608") deck()            b608_pair();
if (obj == "camlink_deck") deck()    camlink_deck();
if (obj == "tilt_pinion") deck()     tilt_pinion();
// tilt group (the M8 bolt clamps inner races | spacers | payload into one stack,
// so spacers, collars and axle turn with the payload)
if (obj == "payload") deck()         payload();
if (obj == "tilt_gear") deck()       tilt_gear();
if (obj == "spacers") deck()         spacers();
if (obj == "collars") deck()         collars();
if (obj == "axle") deck()            tilt_axle();
if (obj == "laser") deck()           laser_vit();
if (obj == "camera") deck()          camera_vit();
if (obj == "beam_stop") deck()       beam_stop();


// ---------- robot (robot frame, no offset) ----------
if (obj == "rb_floor")   for (i = [0:3]) robot_floor_quad(i);
if (obj == "rb_lid")     for (a = [0, 90, 180, 270]) robot_lid_quad(a);
if (obj == "rb_pillars") for (i = [0:3]) robot_pillar(i);
if (obj == "rb_brackets") for (s = [-1, 1]) { robot_motor_bracket(s); for (i = [0, 1]) robot_motor_strap(s, i); }
if (obj == "rb_wheel_l") { robot_wheel_hub(1);  robot_tire(1); }
if (obj == "rb_wheel_r") { robot_wheel_hub(-1); robot_tire(-1); }
if (obj == "rb_motors")  for (s = [-1, 1]) jga25(s);
if (obj == "rb_caster")  { robot_caster_mount(); ball_caster(); }
if (obj == "rb_trays")   { robot_batt_tray(); robot_ebay_tray(); }
if (obj == "rb_bumper")  { robot_bumper_left(); robot_bumper_right(); robot_bumper_splice(); }
if (obj == "rb_electronics") {
    battery_pack(); mdd3a(); pico(); fuse_holder();
    rocker_switch(); charge_jack(); lid_button();
    for (i = [0, 1]) kw10_switch(i);
    tof_sensor();
}

// ---------- single robot parts (x_*): NOT exported for the viewer; for the per-part
// interference check (groups above are implicit unions and would hide overlaps inside a group)
if (obj == "x_floor0") robot_floor_quad(0);
if (obj == "x_lid0") robot_lid_quad(0);
if (obj == "x_pillar0") robot_pillar(0);
if (obj == "x_floor1") robot_floor_quad(1);
if (obj == "x_lid1") robot_lid_quad(90);
if (obj == "x_pillar1") robot_pillar(1);
if (obj == "x_floor2") robot_floor_quad(2);
if (obj == "x_lid2") robot_lid_quad(180);
if (obj == "x_pillar2") robot_pillar(2);
if (obj == "x_floor3") robot_floor_quad(3);
if (obj == "x_lid3") robot_lid_quad(270);
if (obj == "x_pillar3") robot_pillar(3);
if (obj == "x_bracketL") robot_motor_bracket(1);
if (obj == "x_strapL0") robot_motor_strap(1,0);
if (obj == "x_strapL1") robot_motor_strap(1,1);
if (obj == "x_hubL") robot_wheel_hub(1);
if (obj == "x_tireL") robot_tire(1);
if (obj == "x_motorL") jga25(1);
if (obj == "x_bracketR") robot_motor_bracket(-1);
if (obj == "x_strapR0") robot_motor_strap(-1,0);
if (obj == "x_strapR1") robot_motor_strap(-1,1);
if (obj == "x_hubR") robot_wheel_hub(-1);
if (obj == "x_tireR") robot_tire(-1);
if (obj == "x_motorR") jga25(-1);
if (obj == "x_caster_mount") robot_caster_mount();
if (obj == "x_ball") ball_caster();
if (obj == "x_batt_tray") robot_batt_tray();
if (obj == "x_ebay_tray") robot_ebay_tray();
if (obj == "x_bumperL") robot_bumper_left();
if (obj == "x_bumperR") robot_bumper_right();
if (obj == "x_bumper_splice") robot_bumper_splice();
if (obj == "x_battery") battery_pack();
if (obj == "x_mdd3a") mdd3a();
if (obj == "x_pico") pico();
if (obj == "x_fuse") fuse_holder();
if (obj == "x_rocker") rocker_switch();
if (obj == "x_jack") charge_jack();
if (obj == "x_button") lid_button();
if (obj == "x_kw0") kw10_switch(0);
if (obj == "x_kw1") kw10_switch(1);
if (obj == "x_tof") tof_sensor();

if (obj == "kinematics") echo(str("KIN{",
    "\"tilt_z\":", tilt_z,
    ",\"pan_motor_xy\":", pan_motor_xy,
    ",\"tilt_motor_xz\":", tilt_motor_xz,
    ",\"pan_gear_z\":", pan_gear_z,
    ",\"tilt_gear_z\":", tilt_gear_z,
    ",\"pinion_z\":", pinion_z,
    ",\"gear_mod\":", gear_mod,
    ",\"pan_stop\":", pan_stop,
    ",\"tilt_range\":", tilt_range,
    ",\"laser_axis\":", laser_axis,
    ",\"laser_exit_x\":", payload_x[1] + laser_collar[1],
    ",\"cam_axis\":", cam_axis,
    ",\"cam_front_x\":", payload_x[1] + picam3_lens_block[2],
    ",\"deck_z\":", rb_deck_z,
    ",\"rb_deck_z\":", rb_deck_z,
    ",\"rb_axle_x\":", rb_axle_x,
    ",\"rb_axle_z\":", rb_axle_z,
    ",\"rb_wheel_d\":", rb_wheel_d,
    ",\"rb_wheel_y\":", rb_wheel_y,
    ",\"rb_R\":", rb_R,
    ",\"rb_caster_xy\":", rb_caster_xy,
    ",\"rb_bumper_ang\":", rb_bumper_ang,
    "}KIN"));
