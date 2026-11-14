// =====================================================================
//  roomba-laser-turret :: full robot (driving base + pan/tilt gimbal)
//
//    openscad -D pan=30 -D tilt=45 robot.scad
//    -D explode=1          separate vertically: floor 0, drive/trays +40, lid +120,
//                          gimbal +220 on top of its own explode
//    -D show_vitamins=false
//    -D show_lid=false     take the lid (and the gimbal on it) off to see inside
//    -D show_beam_stop=true
//
//  ROBOT FRAME (lib/robot_params.scad): origin on the floor under the pan axis, +X
//  forward, z up. Robot parts are authored in it; the gimbal (assembly.scad, world
//  frame, bay bottom at z 0) is placed with translate([0, 0, rb_deck_z]). assembly.scad is
//  `include`d (not `use`d) so that pan / tilt / show_* reach the gimbal; its explode is added
//  to the robot's: the gimbal's own explode_* offsets use the `explode` variable below.
//  With show_lid=false the gimbal is hidden too (it stands on the lid).
// =====================================================================
include <lib/params.scad>
include <lib/robot_params.scad>
use <lib/robot_vitamins.scad>
include <assembly.scad>      // modules + pan/tilt/explode/show_* variables (overridden below)
use <parts/robot_floor_front.scad>
use <parts/robot_lid_fl.scad>
use <parts/robot_pillar.scad>
use <parts/robot_motor_bracket.scad>
use <parts/robot_motor_strap.scad>
use <parts/robot_wheel_hub.scad>
use <parts/robot_tire.scad>
use <parts/robot_caster_mount.scad>
use <parts/robot_batt_tray.scad>
use <parts/robot_ebay_tray.scad>
use <parts/robot_bumper_left.scad>
use <parts/robot_bumper_right.scad>
use <parts/robot_bumper_splice.scad>

asm_embedded   = true;
pan            = 0;
tilt           = 0;
explode        = 0;
show_vitamins  = true;
show_lid       = true;
show_beam_stop = false;

// explode offsets (z)
ex_drive = 40 * explode;
ex_lid   = 120 * explode;
ex_gimb  = 220 * explode;

c_lid    = "#3fa7b5";
c_floor  = "#2f8794";
c_bump   = "#3b4252";
c_tire   = "#222222";
c_hw     = "#b8bec6";      // pillars, brackets, wheel hubs
c_tray   = "#5e6a7d";


module floor_stage() color(c_floor) for (i = [0:3]) robot_floor_quad(i);

module drive_stage() lift(ex_drive) {
    color(c_hw) {
        for (i = [0:3]) robot_pillar(i);
        for (s = [-1, 1]) {
            robot_motor_bracket(s);
            for (i = [0, 1]) robot_motor_strap(s, i);
            robot_wheel_hub(s);
        }
    }
    for (s = [-1, 1]) color(c_tire) robot_tire(s);
    color(c_tray) { robot_caster_mount(); robot_batt_tray(); robot_ebay_tray(); }
    color(c_bump) { robot_bumper_left(); robot_bumper_right(); robot_bumper_splice(); }
    if (show_vitamins) robot_vitamins();
}

module lid_stage() lift(ex_lid) color(c_lid) for (a = [0, 90, 180, 270]) robot_lid_quad(a);

module gimbal_stage() lift(ex_gimb) translate([0, 0, rb_deck_z]) {
    static_stage();
    pan_stage();
}

floor_stage();
drive_stage();
if (show_lid) { lid_stage(); gimbal_stage(); }
