#!/usr/bin/env bash
# =====================================================================
#  laser-gimbal :: interference check            (make interference)
#
#  1. Caches every object ONCE in world coordinates at pan = 0, tilt = 0
#     (tmp/interf/obj_<NAME>.stl, rebuilt when parts/, lib/ or assembly.scad
#     change). Placements come from assembly.scad itself (`use`), so the
#     check tests exactly what the assembly shows.
#  2. For every pair and pose it applies the stage transforms
#        static     : none
#        pan stage  : rotate([0,0,pan])
#        tilt group : rotate([0,0,pan]) * rotate([0,-tilt,0]) about [0,0,tilt_z]
#     computes both exact transformed bounding boxes (numpy) and skips pairs
#     whose boxes are apart ("clear-bbox"); the rest go to CGAL as
#     intersection(){ A; B; } ("Current top level object is empty" == clear).
#     If CGAL asserts on the imported (float-rounded) meshes, the pair is re-run
#     on the native OpenSCAD geometry; a second failure is reported as ERROR.
#     Hard-stop sanity: PAYLOAD x YOKE at tilt -21 / +91 must COLLIDE, and the
#     pan-stop dog (in TT_ENV) x BASE must be clear at +-174 and COLLIDE at +-176.
#     Pan poses stay inside the pan hard stop (+-175).
#  2c. Fastener access: a hex key (d 2.9, slotted over mesh_slot where the screw
#     travels) from each motor-plate screw head straight out must be clear of every
#     other object: pan plate screws (vertical, z 98.2 up) at pan 0, all tilts;
#     tilt plate screws (along -Y from y 56.5 outward) at every tilt.
#  3. Result classes: clear | touch (CGAL result volume < 0.01 mm3: coplanar
#     face contact, e.g. bearing on its lip, hard stop at its end angle) |
#     allowed (documented press fit under its volume limit) | COLLISION.
#  4. Gear meshes: exact involute profiles (lib/gears.scad gear2d) sliced at
#     5 heights through the herringbone half-width (the other half is the
#     mirror image) with each gear's helix twist and pose rotation applied;
#     2D intersection must be empty. Full 3D herringbones take ~3 min each in
#     CGAL, so meshing gears are NOT intersected in 3D. Includes a sanity run
#     with the pinion sense reversed, which must collide.
#
#  ENVELOPES (instead of exact geometry, where exact is slow or pointless):
#    TT_ENV          turntable without teeth/holes: tip cylinder r 54.375 z 100..110
#                    + shoulder d55 z 97..100 + spigot tube d49.95/38 (same 64-gons as the part)
#                    + the exact pan-stop dog (turntable.scad tt_dog)
#    PAN_PINION_ENV  tip cylinder r outer_r(17), z 100..110, at pan_motor_xy
#    TILT_PINION_ENV tip cylinder r outer_r(17), y 31..41, at tilt_motor_xz
#    TGEAR_ENV       51T wheel tip annulus r 6.5..33.125, y 31..41
#  (polygons circumscribe the true circles, so an envelope is never smaller)
#
#  EXCLUDED PAIRS (intended contact, not tested):
#    TILT_MOTOR  x TILT_PINION_ENV  pinion is clamped on the motor shaft
#    PAN_MOTOR   x PAN_PINION_ENV   idem (static pair anyway)
#    PAN_MOTOR   x BASE             motor face screwed under the plate, boss in its slot
#    B608        x AXLE             M8 bolt through the 608 inner races (d8 in d8)
#    TT_ENV      x PAN_PINION_ENV   gear mesh  -> 2D mesh test
#    TGEAR_ENV   x TILT_PINION_ENV  gear mesh  -> 2D mesh test
#    TGEAR_ENV   x PAYLOAD          wheel bolted to the payload ring (rigid body)
#    BAY         x BASE             base wall seated on the bay rim/ledge, bolted (static mating parts)
#  ALLOWED OVERLAP:
#    BEAM_STOP   x PAYLOAD  <= 1.0 mm3   3 crush ribs on the exit collar (push fit)
#
#  usage: tools/interference.sh [-j N]      exit 1 on any COLLISION
# =====================================================================
set -euo pipefail
cd "$(dirname "$0")/.."
JOBS=$(nproc 2>/dev/null || echo 4)
[[ "${1:-}" == "-j" ]] && JOBS="$2"
OPENSCAD=${OPENSCAD:-openscad}
W=tmp/interf
mkdir -p "$W"

# ---------------- object definitions (world, pan = 0, tilt = 0) ----------------
cat > "$W/objs.scad.new" <<'EOF'
include <../../lib/params.scad>
use <../../lib/gears.scad>
use <../../lib/vitamins.scad>
use <../../assembly.scad>
use <../../parts/bay.scad>
use <../../parts/base.scad>
use <../../parts/pan_collar.scad>
use <../../parts/yoke.scad>
use <../../parts/tilt_spacer.scad>
use <../../parts/payload.scad>
use <../../parts/beam_stop.scad>
use <../../parts/turntable.scad>
use <../../parts/pan_motor_plate.scad>
use <../../parts/tilt_motor_plate.scad>
use <../../parts/axle_collar.scad>
function circ(r, n) = r / cos(180 / n);
// hex key (d 2.9): vertical from z0 up, slotted in X over dxs
module key_z(p, z0, dxs) hull() for (dx = dxs) translate([p[0] + dx, p[1], z0]) cylinder(h = 120, d = 2.9, $fn = 16);
obj = "";
O(obj);
module O(obj) {
// static
if (obj == "BAY")             bay();
if (obj == "BASE")            base();
if (obj == "ELECTRONICS")     electronics();
if (obj == "PAN_MOTOR")       pan_motor();
if (obj == "PAN_MPLATE")      pan_motor_plate();
if (obj == "KEY_PAN")         for (p = pan_mplate_screws) key_z(p, base_top + 0.2, mesh_slot);
if (obj == "PAN_PINION_ENV")  translate([pan_motor_xy[0], pan_motor_xy[1], turntable_z0])
                                  cylinder(h = gear_w, r = circ(outer_r(pinion_z), 48), $fn = 48);
// pan stage
if (obj == "TT_ENV")          {   // spigot + shoulder exactly as turntable.scad ($fn 64), tip cylinder circumscribed
                                  translate([0, 0, 72.2]) difference() {
                                      cylinder(h = turntable_z0 - 72.2 + 0.5, d = spigot_od, $fn = 64);
                                      translate([0, 0, -1]) cylinder(h = 40, d = spigot_id, $fn = 64);
                                  }
                                  translate([0, 0, 97]) difference() {
                                      cylinder(h = 3.5, d = spigot_shoulder_od, $fn = 64);
                                      translate([0, 0, -1]) cylinder(h = 6, d = spigot_id, $fn = 64);
                                  }
                                  translate([0, 0, turntable_z0]) difference() {
                                      cylinder(h = gear_w, r = circ(outer_r(pan_gear_z), 128), $fn = 128);
                                      translate([0, 0, -1]) cylinder(h = gear_w + 2, d = spigot_id, $fn = 64);
                                  }
                                  tt_dog();
                              }
if (obj == "COLLAR")          pan_collar();
if (obj == "B6810")           b6810_pair();
if (obj == "YOKE")            yoke();
if (obj == "TILT_MOTOR")      tilt_motor();
if (obj == "TILT_MPLATE")     tilt_motor_plate();
if (obj == "COLLARS")         collars();
if (obj == "CAMLINK_DECK")    camlink_deck();
if (obj == "KEY_TILT")        for (e = tilt_mplate_screws)   // along +Y from just outside the head
                                  translate([tilt_motor_xz[0] + e[0], tilt_motor_face_y + 3.5, tilt_motor_xz[1] + e[1]])
                                      rotate([-90, 0, 0]) cylinder(h = 80, d = 2.9, $fn = 16);
if (obj == "TILT_PINION_ENV") translate([tilt_motor_xz[0], tilt_gear_y[0], tilt_motor_xz[1]]) rotate([-90, 0, 0])
                                  cylinder(h = gear_w, r = circ(outer_r(pinion_z), 48), $fn = 48);
if (obj == "B608")            b608_pair();
if (obj == "AXLE")            tilt_axle();
if (obj == "SPACERS")         spacers();
// tilt group
if (obj == "PAYLOAD")         payload();
if (obj == "TGEAR_ENV")       translate([0, tilt_gear_y[0], tilt_z]) rotate([-90, 0, 0]) difference() {
                                  cylinder(h = gear_w, r = circ(outer_r(tilt_gear_z), 128), $fn = 128);
                                  translate([0, 0, -1]) cylinder(h = gear_w + 2, d = tilt_gear_hole, $fn = 64);
                              }
if (obj == "LASER")           laser_vit();
if (obj == "CAMERA")          camera_vit();
if (obj == "BEAM_STOP")       beam_stop();
}
EOF
# only replace objs.scad when its text changes (its mtime invalidates the object cache)
if cmp -s "$W/objs.scad.new" "$W/objs.scad"; then rm "$W/objs.scad.new"; else mv "$W/objs.scad.new" "$W/objs.scad"; fi

# ---------------- 2D gear-mesh slice test ----------------
cat > "$W/mesh2d.scad" <<'EOF'
include <../../lib/params.scad>
use <../../lib/gears.scad>
axis = "pan"; ang = 0; s = 1;
zw = axis == "pan" ? pan_gear_z : tilt_gear_z;
cd = axis == "pan" ? pan_cd : tilt_cd;
// pan : wheel turns +pan about Z, pinion (polar 180) = phase - pan*85/17      (assembly.scad)
// tilt: in tilt_gear's local frame the wheel turns -tilt, pinion = phase + tilt*51/17
wspin = axis == "pan" ? ang : -ang;
pspin = mesh_phase(zw, pinion_z, 180) + s * (axis == "pan" ? -1 : 1) * ang * zw / pinion_z;
// linear_extrude(twist = t) turns the profile by -t over its height
module g2(z, helix, spin, h) rotate(spin) rotate(-_twist(gear_mod, z, gear_w / 2, helix) * h / (gear_w / 2))
    gear2d(gear_mod, z, gear_pa, gear_backlash);
for (h = [0, 1.25, 2.5, 3.75, 5]) linear_extrude(height = 1) intersection() {
    g2(zw, -gear_helix, wspin, h);
    translate([-cd, 0]) g2(pinion_z, gear_helix, pspin, h);
}
EOF

export OPENSCAD JOBS
python3 -I - "$W" <<'PY'
import concurrent.futures as cf, itertools, os, re, subprocess, sys, time
import numpy as np

W = sys.argv[1]
OPENSCAD = os.environ.get("OPENSCAD", "openscad")
JOBS = int(os.environ.get("JOBS", "4"))
TILT_Z = 165.0
PAN_STOP = 175.0                          # lib/params.scad pan_stop: poses stay inside it
PANS  = [0, 90, 170, -170]
TILTS = [-20, 0, 45, 90]
TILTS_FINE = list(range(-20, 91, 10))     # extra sweep for the head vs yoke / tilt drive
PANS_FINE  = sorted(set(range(-165, 166, 15)) | {-174, 174})   # extra sweep: yoke / tilt motor vs pan pinion + shaft

STATIC = ["BAY", "BASE", "ELECTRONICS", "PAN_MOTOR", "PAN_PINION_ENV", "PAN_MPLATE"]
PANSTG = ["TT_ENV", "COLLAR", "B6810", "YOKE", "TILT_MOTOR", "TILT_PINION_ENV", "B608", "AXLE", "SPACERS",
          "TILT_MPLATE", "COLLARS", "CAMLINK_DECK"]
TILTG  = ["PAYLOAD", "TGEAR_ENV", "LASER", "CAMERA", "BEAM_STOP"]
KEYS   = {"KEY_PAN": "s", "KEY_TILT": "p"}   # access probes: only used in section 2c
GROUP = {**{n: "s" for n in STATIC}, **{n: "p" for n in PANSTG}, **{n: "t" for n in TILTG}, **KEYS}
EXCLUDE = {frozenset(p) for p in [
    ("TILT_MOTOR", "TILT_PINION_ENV"), ("PAN_MOTOR", "PAN_PINION_ENV"), ("PAN_MOTOR", "BASE"),
    ("B608", "AXLE"), ("TT_ENV", "PAN_PINION_ENV"), ("TGEAR_ENV", "TILT_PINION_ENV"),
    ("TGEAR_ENV", "PAYLOAD"), ("BAY", "BASE")]}
ALLOW = {frozenset(("BEAM_STOP", "PAYLOAD")): (1.0, "crush ribs on the exit collar")}
TOUCH = 0.01   # mm3

def run(args, timeout=900):
    p = subprocess.run([OPENSCAD] + args, capture_output=True, text=True, timeout=timeout)
    return p.returncode, p.stdout + p.stderr

def load(path):
    v = []
    with open(path) as fh:
        for line in fh:
            if line.lstrip().startswith("vertex"):
                v.append([float(x) for x in line.split()[1:4]])
    return np.array(v).reshape(-1, 3, 3) if v else np.zeros((0, 3, 3))

def volume(tris):
    if len(tris) == 0:
        return 0.0
    a, b, c = tris[:, 0], tris[:, 1], tris[:, 2]
    return float(np.einsum("ij,ij->i", a, np.cross(b, c)).sum() / 6)

# ---- 1. cache world objects ----
deps = [os.path.join(d, f) for d in ("parts", "lib") for f in os.listdir(d) if f.endswith(".scad")]
deps += ["assembly.scad", os.path.join(W, "objs.scad")]
newest = max(os.path.getmtime(p) for p in deps)
def build(name):
    out = os.path.join(W, f"obj_{name}.stl")
    if os.path.exists(out) and os.path.getmtime(out) > newest:
        return name, "cached", 0.0
    t = time.time()
    rc, log = run(["-q", "-o", out, "-D", f'obj="{name}"', os.path.join(W, "objs.scad")])
    if rc or not os.path.exists(out):
        sys.exit(f"cache build failed for {name}:\n{log}")
    return name, "built", time.time() - t
print(f"== caching {len(GROUP)} objects (world, pan 0, tilt 0), {JOBS} jobs")
with cf.ThreadPoolExecutor(JOBS) as ex:
    for name, st, dt in ex.map(build, GROUP):
        if st == "built":
            print(f"   built {name:16s} {dt:6.1f} s")
MESH = {n: load(os.path.join(W, f"obj_{n}.stl")).reshape(-1, 3) for n in GROUP}

# ---- transforms ----
def Rz(a):
    c, s = np.cos(np.radians(a)), np.sin(np.radians(a))
    return np.array([[c, -s, 0], [s, c, 0], [0, 0, 1]])
def Ry(a):
    c, s = np.cos(np.radians(a)), np.sin(np.radians(a))
    return np.array([[c, 0, s], [0, 1, 0], [-s, 0, c]])
def place(name, pan, tilt):
    v = MESH[name]
    g = GROUP[name]
    if g == "t":
        v = (v - [0, 0, TILT_Z]) @ Ry(-tilt).T + [0, 0, TILT_Z]
    if g in "pt":
        v = v @ Rz(pan).T
    return v.min(0), v.max(0)
def scad_tf(name, pan, tilt, native=False):
    g = GROUP[name]
    s = ""
    if g in "pt":
        s += f"rotate([0, 0, {pan}]) "
    if g == "t":
        s += f"translate([0, 0, {TILT_Z}]) rotate([0, {-tilt}, 0]) translate([0, 0, {-TILT_Z}]) "
    return s + (f'O("{name}");' if native else f'import("obj_{name}.stl", convexity = 10);')

# ---- 2. test list ----
tests = []   # (section, a, b, pan, tilt)
def add(sec, a, b, pan, tilt):
    if frozenset((a, b)) not in EXCLUDE and a != b:
        tests.append((sec, a, b, pan, tilt))
for a, b in itertools.combinations(STATIC, 2):                 # static vs static (once)
    add("static/static", a, b, 0, 0)
for pan in sorted(set(PANS) | set(PANS_FINE)):                 # pan stage vs static
    for a in PANSTG:
        for b in STATIC:
            if pan in PANS or (a in ("YOKE", "TILT_MOTOR", "TILT_MPLATE", "TT_ENV") and b in ("PAN_PINION_ENV", "PAN_MOTOR", "BASE")):
                add("pan/static", a, b, pan, 0)
for a, b in itertools.combinations(PANSTG, 2):                 # pan stage internal (pose-independent)
    add("pan/pan", a, b, 0, 0)
for pan, tilt in itertools.product(PANS, TILTS):               # tilt group vs static
    for a in TILTG:
        for b in STATIC:
            add("tilt/static", a, b, pan, tilt)
for tilt in sorted(set(TILTS) | set(TILTS_FINE)):              # tilt group vs pan stage
    for a in TILTG:
        for b in PANSTG:
            if tilt in TILTS or b in ("YOKE", "TILT_PINION_ENV", "TILT_MOTOR"):
                add("tilt/pan", a, b, 0, tilt)
for a, b in itertools.combinations(TILTG, 2):                  # tilt group internal
    add("tilt/tilt", a, b, 0, 0)

def check(t):
    sec, a, b, pan, tilt = t
    (amin, amax), (bmin, bmax) = place(a, pan, tilt), place(b, pan, tilt)
    if np.any(amax < bmin - 0.01) or np.any(bmax < amin - 0.01):
        return t, "clear-bbox", 0.0
    tag = f"{a}__{b}__p{pan}_t{tilt}".replace("-", "m")
    scad = os.path.join(W, f"t_{tag}.scad")
    out = os.path.join(W, f"t_{tag}.stl")
    for native in (False, True):
        with open(scad, "w") as fh:
            if native:
                fh.write('include <objs.scad>\n')
            fh.write(f"intersection() {{\n  {scad_tf(a, pan, tilt, native)}\n  {scad_tf(b, pan, tilt, native)}\n}}\n")
        if os.path.exists(out):
            os.remove(out)
        rc, log = run(["-o", out, scad])
        if "ERROR" not in log:
            break
    if "ERROR" in log:
        return t, "ERROR (CGAL): " + log.strip().splitlines()[0], float("nan")
    if "top level object is empty" in log:
        return t, "clear", 0.0
    if rc or not os.path.exists(out):
        return t, "ERROR", float("nan")
    tris = load(out)
    vol = abs(volume(tris))
    lo = tris.reshape(-1, 3).min(0); hi = tris.reshape(-1, 3).max(0)
    where = "x %.1f..%.1f y %.1f..%.1f z %.1f..%.1f" % (lo[0], hi[0], lo[1], hi[1], lo[2], hi[2])
    if vol < TOUCH:
        return t, "touch", vol
    lim = ALLOW.get(frozenset((a, b)))
    if lim and vol <= lim[0]:
        return t, f"allowed ({lim[1]}) " + where, vol
    return t, "COLLISION " + where, vol

print(f"== {len(tests)} pair/pose tests")
t0 = time.time()
results = []
with cf.ThreadPoolExecutor(JOBS) as ex:
    for r in ex.map(check, tests):
        results.append(r)
counts = {}
for (sec, a, b, pan, tilt), st, vol in results:
    k = st.split()[0]
    counts[k] = counts.get(k, 0) + 1
    if k != "clear-bbox":
        print(f"   {sec:13s} pan {pan:5d} tilt {tilt:4d}  {a:15s} x {b:15s}  {st}" + (f"  {vol:.3f} mm3" if k not in ("clear",) else ""))
print("   summary:", ", ".join(f"{k} {v}" for k, v in sorted(counts.items())), f"({time.time() - t0:.0f} s)")

# ---- 2b. hard-stop sanity: 1 deg past each end stop the payload lug MUST hit a yoke block ----
print("== tilt hard stops (payload lug vs yoke blocks, 1 deg beyond the range must collide)")
stop_bad = 0
for tilt in (-21, 91):
    _, st, vol = check(("stop-sanity", "PAYLOAD", "YOKE", 0, tilt))
    hit = st.startswith("COLLISION")
    stop_bad += not hit
    print(f"   tilt {tilt:4d}: {'blocked (stop engages)' if hit else 'NOT blocked: ' + st}" + (f"  {vol:.1f} mm3" if hit else ""))

# ---- 2b'. pan hard stop: dog (TT_ENV) x BASE clear at +-174, MUST collide at +-176 ----
print("== pan hard stop (turntable dog vs base post)")
for pan, must in ((174, False), (-174, False), (176, True), (-176, True)):
    _, st, vol = check(("pan-stop", "TT_ENV", "BASE", pan, 0))
    hit = st.startswith("COLLISION")
    ok = hit == must
    stop_bad += not ok
    print(f"   pan {pan:5d}: {'blocked' if hit else 'free   '} ({'ok' if ok else 'WRONG'})" + (f"  {vol:.1f} mm3" if hit else ""))

# ---- 2c. fastener access (hex keys from the motor-plate screws) ----
print("== fastener access (hex key d 2.9 from each motor-plate screw head)")
acc_bad = 0
acc = [("KEY_PAN", b, 0, 0) for b in PANSTG + STATIC if b not in ("BASE", "PAN_MPLATE")] + \
      [("KEY_PAN", b, 0, t) for b in TILTG for t in TILTS] + \
      [("KEY_TILT", b, 0, 0) for b in PANSTG if b != "TILT_MPLATE"] + \
      [("KEY_TILT", b, 0, t) for b in TILTG for t in TILTS_FINE]
with cf.ThreadPoolExecutor(JOBS) as ex:
    acc_res = list(ex.map(lambda q: check(("access",) + q), acc))
for (sec, a, b, pan, tilt), st, vol in acc_res:
    k = st.split()[0]
    if k not in ("clear", "clear-bbox", "touch"):
        acc_bad += 1
        print(f"   BLOCKED {a} x {b} pan {pan} tilt {tilt}: {st}")
print(f"   {len(acc_res) - acc_bad}/{len(acc_res)} key paths clear")
stop_bad += acc_bad

# ---- 3. gear meshes ----
print("== gear meshes (2D involute slices, 5 heights per half-width)")
mesh_bad = 0
def mesh(args):
    axis, ang, s = args
    out = os.path.join(W, f"m_{axis}_{ang}_{s}.stl".replace("-", "m"))
    rc, log = run(["-o", out, "-D", f'axis="{axis}"', "-D", f"ang={ang}", "-D", f"s={s}", os.path.join(W, "mesh2d.scad")])
    return args, "top level object is empty" in log
jobs = [("pan", a, 1) for a in PANS + [2.1]] + [("tilt", a, 1) for a in TILTS + [3.3]] + \
       [("pan", a, -1) for a in PANS] + [("tilt", a, -1) for a in TILTS]
with cf.ThreadPoolExecutor(JOBS) as ex:
    res = list(ex.map(mesh, jobs))
for (axis, ang, s), empty in res:
    if s == 1:
        print(f"   {axis:4s} {ang:6} deg  pinion/wheel {'interleaved (clear)' if empty else 'COLLISION'}")
        mesh_bad += not empty
rev = {axis: any(not e for (ax, a, s), e in res if s == -1 and ax == axis) for axis in ("pan", "tilt")}
for axis, hit in rev.items():
    print(f"   {axis:4s} sanity: reversed pinion sense {'collides as expected' if hit else 'NEVER collides (test is blind!)'}")
    mesh_bad += not hit

bad = sum(1 for _, st, _ in results if st.startswith(("COLLISION", "ERROR")))
print(f"== RESULT: {bad} collision(s)/error(s), {mesh_bad} gear-mesh problem(s), {stop_bad} hard-stop/access problem(s)")
sys.exit(1 if bad or mesh_bad or stop_bad else 0)
PY
