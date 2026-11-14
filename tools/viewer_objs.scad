// =====================================================================
//  laser-gimbal :: objects for the browser viewer (tools/export_viewer.sh)
//  Every object is exported in WORLD coordinates at pan = 0, tilt = 0, with
//  the placements taken from assembly.scad itself (`use`), so the viewer
//  shows exactly what the assembly defines. The viewer applies the stage
//  transforms (same as assembly.scad):
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

obj = "";

// static
if (obj == "bay")             bay();
if (obj == "electronics")     electronics();
if (obj == "base")            base();
if (obj == "pan_motor_plate") pan_motor_plate();
if (obj == "pan_motor")       pan_motor();
if (obj == "pan_pinion")      pan_pinion();
// pan stage
if (obj == "turntable")       turntable();
if (obj == "pan_collar")      pan_collar();
if (obj == "b6810")           b6810_pair();
if (obj == "yoke")            yoke();
if (obj == "tilt_motor_plate") tilt_motor_plate();
if (obj == "tilt_motor")      tilt_motor();
if (obj == "b608")            b608_pair();
if (obj == "camlink_deck")    camlink_deck();
if (obj == "tilt_pinion")     tilt_pinion();
// tilt group (the M8 bolt clamps inner races | spacers | payload into one stack,
// so spacers, collars and axle turn with the payload)
if (obj == "payload")         payload();
if (obj == "tilt_gear")       tilt_gear();
if (obj == "spacers")         spacers();
if (obj == "collars")         collars();
if (obj == "axle")            tilt_axle();
if (obj == "laser")           laser_vit();
if (obj == "camera")          camera_vit();
if (obj == "beam_stop")       beam_stop();

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
    "}KIN"));
