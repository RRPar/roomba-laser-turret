#!/usr/bin/env bash
# =====================================================================
#  laser-gimbal :: export meshes for the browser viewer   (make viewer)
#  For every object in tools/viewer_objs.scad: OpenSCAD -> ASCII STL in
#  world coordinates (pan 0, tilt 0) -> binary STL in viewer/meshes/.
#  Gimbal + robot objects, all in the ROBOT frame (gimbal shifted by rb_deck_z; see
#  tools/viewer_objs.scad). Also writes viewer/meshes/kinematics.json.
#  usage: tools/export_viewer.sh [-j N]
# =====================================================================
set -euo pipefail
cd "$(dirname "$0")/.."
JOBS=$(nproc 2>/dev/null || echo 4)
[[ "${1:-}" == "-j" ]] && JOBS="$2"
OPENSCAD=${OPENSCAD:-openscad}
W=tmp/viewer
OUT=viewer/meshes
mkdir -p "$W" "$OUT"

OBJS="bay electronics base pan_motor_plate pan_motor pan_pinion
      turntable pan_collar b6810 yoke tilt_motor_plate tilt_motor b608 camlink_deck tilt_pinion
      payload tilt_gear spacers collars axle laser camera beam_stop
      rb_floor rb_lid rb_pillars rb_brackets rb_wheel_l rb_wheel_r rb_motors rb_caster rb_trays rb_bumper rb_electronics"

# kinematics (echo only, no geometry)
"$OPENSCAD" -o "$W/kin.echo" -D 'obj="kinematics"' tools/viewer_objs.scad 2>/dev/null
sed -n 's/.*KIN\(.*\)KIN.*/\1/p' "$W/kin.echo" > "$OUT/kinematics.json"
python3 -I -c 'import json,sys; json.load(open(sys.argv[1]))' "$OUT/kinematics.json"
echo "kinematics.json: $(cat "$OUT/kinematics.json")"

export OPENSCAD W
# shellcheck disable=SC2086
printf '%s\n' $OBJS | xargs -P "$JOBS" -I{} sh -c \
    '"$OPENSCAD" -q -o "$W/{}.stl" -D "obj=\"{}\"" tools/viewer_objs.scad && echo "  built {}"'

# shellcheck disable=SC2086
python3 -I tools/stl2bin.py "$W" "$OUT" $OBJS
