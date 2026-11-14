// =====================================================================
//  rover :: viewer core (rig + collision checks + stability)
//  Used by viewer/index.html. Meshes come from `make viewer`
//  (tools/export_viewer.sh): every object (robot AND gimbal) in the ROBOT
//  frame (z 0 = floor, +X forward, origin under the pan axis) at pan 0 /
//  tilt 0, so the only thing this file adds is the motion:
//    root        the robot's pose in the room (setDrive)
//    static      robot body (floor, lid, pillars, brackets, motors, caster, trays,
//                bumper, electronics) + gimbal bay, electronics, base, pan motor + plate
//    wheel_l/r   spin about (rb_axle_x, +-rb_wheel_y, rb_axle_z) along Y
//    pan pinion  spins about its own Z axis by -pan * 85/17
//    pan         rotate([0,0,pan])
//    tilt pinion spins about its own axis (parallel to Y) by +tilt * 51/17
//    tilt        pan * rotate([0,-tilt,0]) about [0,0,deck_z + tilt_z]
//  The kinematics.json gimbal keys keep gimbal-world heights; every gimbal pivot
//  height gets deck_z added here. Units: mm, Z up.
// =====================================================================
import * as THREE from 'three';
import { MeshBVH } from 'three-mesh-bvh';

// body: which rigid body the part moves with
export const PARTS = [
  { name: 'bay',              body: 'static',      color: '#3b4252', label: 'Electronics bay' },
  { name: 'electronics',      body: 'static',      color: '#2d8a4e', label: 'Pi 5, SKR Pico, buck, laser driver, fan', vitamin: true },
  { name: 'base',             body: 'static',      color: '#4c566a', label: 'Base' },
  { name: 'pan_motor_plate',  body: 'static',      color: '#b48ead', label: 'Pan motor plate' },
  { name: 'pan_motor',        body: 'static',      color: '#33383f', label: 'Pan motor (NEMA 17)', vitamin: true },
  { name: 'pan_pinion',       body: 'pan_pinion',  color: '#a3be8c', label: 'Pan pinion 17T' },
  { name: 'turntable',        body: 'pan',         color: '#d08770', label: 'Turntable 85T' },
  { name: 'pan_collar',       body: 'pan',         color: '#ebcb8b', label: 'Pan collar' },
  { name: 'b6810',            body: 'pan',         color: '#a7b0ba', label: '6810 bearings (2)', vitamin: true },
  { name: 'yoke',             body: 'pan',         color: '#5e81ac', label: 'Yoke' },
  { name: 'tilt_motor_plate', body: 'pan',         color: '#b48ead', label: 'Tilt motor plate' },
  { name: 'tilt_motor',       body: 'pan',         color: '#33383f', label: 'Tilt motor (NEMA 17)', vitamin: true },
  { name: 'b608',             body: 'pan',         color: '#a7b0ba', label: '608 bearings (2)', vitamin: true },
  { name: 'camlink_deck',     body: 'pan',         color: '#7a3e9d', label: 'Camera-link adapter (deck)', vitamin: true },
  { name: 'tilt_pinion',      body: 'tilt_pinion', color: '#a3be8c', label: 'Tilt pinion 17T' },
  { name: 'payload',          body: 'tilt',        color: '#dfe4ec', label: 'Payload head' },
  { name: 'tilt_gear',        body: 'tilt',        color: '#bf616a', label: 'Tilt wheel 51T' },
  { name: 'spacers',          body: 'tilt',        color: '#88c0d0', label: 'Tilt spacers (2)' },
  { name: 'collars',          body: 'tilt',        color: '#88c0d0', label: 'Axle collars (2)' },
  { name: 'axle',             body: 'tilt',        color: '#a7b0ba', label: 'M8 x 120 axle', vitamin: true },
  { name: 'laser',            body: 'tilt',        color: '#c9a227', label: '12 mm laser module', vitamin: true },
  { name: 'camera',           body: 'tilt',        color: '#1f6f3f', label: 'Camera Module 3', vitamin: true },
  { name: 'beam_stop',        body: 'tilt',        color: '#2e3440', label: 'Beam-stop cap', optional: true },
  // robot base (all rigid with the gimbal's static body except the wheels)
  { name: 'rb_lid',           body: 'static',      color: '#3fa7b5', label: 'Robot lid (4 quadrants)' },
  { name: 'rb_floor',         body: 'static',      color: '#2f8794', label: 'Robot floor plate (4 quadrants)' },
  { name: 'rb_bumper',        body: 'static',      color: '#3b4048', label: 'Front bumper' },
  { name: 'rb_pillars',       body: 'static',      color: '#c3c9d0', label: 'Support pillars (4)' },
  { name: 'rb_brackets',      body: 'static',      color: '#c3c9d0', label: 'Motor brackets + straps' },
  { name: 'rb_trays',         body: 'static',      color: '#c3c9d0', label: 'Battery + electronics trays' },
  { name: 'rb_caster',        body: 'static',      color: '#aab2bb', label: 'Ball caster + mount' },
  { name: 'rb_motors',        body: 'static',      color: '#33383f', label: 'Drive motors JGA25 (2)', vitamin: true },
  { name: 'rb_electronics',   body: 'static',      color: '#2d8a4e', label: 'Battery, driver, Pico, switches, ToF', vitamin: true },
  { name: 'rb_wheel_l',       body: 'wheel_l',     color: '#222222', label: 'Left wheel + tire' },
  { name: 'rb_wheel_r',       body: 'wheel_r',     color: '#222222', label: 'Right wheel + tire' },
];

// Intended contact between different bodies: not tested (same list as
// tools/interference.sh, plus the bearing races that ride on both bodies).
export const EXCLUDE = [
  ['pan_pinion', 'pan_motor',  'pinion is clamped on the motor shaft'],
  ['tilt_pinion', 'tilt_motor', 'pinion is clamped on the motor shaft'],
  ['b608', 'axle',    'M8 bolt runs through the 608 inner races'],
  ['b608', 'spacers', 'spacers clamp the 608 inner races'],
  ['b608', 'collars', 'collars clamp the 608 inner races'],
  ['b6810', 'base',   'bearing outer races sit in the base'],
  ['b6810', 'bay',    'bearing outer races sit in the base / bay hub'],
  ['rb_wheel_l', 'rb_motors', 'hub clamps on the 4 mm D-shaft (7 mm of shaft inside the hub)'],
  ['rb_wheel_r', 'rb_motors', 'hub clamps on the 4 mm D-shaft (7 mm of shaft inside the hub)'],
];

// ---------------------------------------------------------------- masses (kg)
// Printed parts: enclosed mesh volume (signed tetrahedra) x 1.24 g/cm3 (PETG) x 0.45
// effective fill (walls + sparse infill). Wheels include the TPU tire (same density rule).
// Vitamins: nominal masses; lib/robot_params.scad rb_mass_vit lists nema17 0.28, jga25 0.095,
// battery 0.30, caster 0.03, b6810 0.026 (each), b608 0.012 (each), laser 0.02, camera 0.005,
// axle 0.045; the rest are estimates (datasheet class) for meshes that bundle several parts.
export const PRINT_DENSITY = 1.24, PRINT_FILL = 0.45;      // g/cm3, -
export const MASS_VIT = {
  pan_motor: 0.28,                       // NEMA 17 (rb_mass_vit nema17)
  tilt_motor: 0.28,                      // NEMA 17
  electronics: 0.15,                     // bay boards: Pi 5 0.05 + SKR Pico 0.04 + buck, laser driver, fan ~0.06
  b6810: 0.052,                          // pair: 2 x rb_mass_vit b6810 0.026
  b608: 0.024,                           // pair: 2 x rb_mass_vit b608 0.012
  camlink_deck: 0.01,                    // camera adapter board + short FFC
  axle: 0.045,                           // M8 x 120 bolt (rb_mass_vit axle)
  laser: 0.02,                           // 12 mm module (rb_mass_vit laser)
  camera: 0.005,                         // Camera Module 3 board (rb_mass_vit camera)
  rb_motors: 2 * 0.095,                  // 2 x JGA25-370 (rb_mass_vit jga25)
  // rb_electronics bundles: battery (region x 50..125) 0.30 + MDD3A 0.02 + Pico ~0.01 + fuse
  // holder, rocker, jack, button, 2 KW10, ToF, wires ~0.03 = 0.06 (see split below)
  rb_electronics: 0.36,
  rb_caster: 0.03,                       // steel ball + hardware (rb_mass_vit caster); mount is printed (extra)
};
const BATT_KG = 0.30, BALL_VOL = 4 / 3 * Math.PI * Math.pow(9.525, 3);   // 3/4" ball, mm3

// volume (mm3, abs) and volume centroid of a triangle soup (signed tetrahedra to the origin),
// optionally only the triangles whose centroid satisfies keep(x, y, z)
export function volumeMoments(geo, keep = null) {
  const pos = geo.attributes.position, idx = geo.index;
  const n = idx ? idx.count : pos.count;
  let vol = 0, cx = 0, cy = 0, cz = 0;
  for (let i = 0; i < n; i += 3) {
    const ia = idx ? idx.getX(i) : i, ib = idx ? idx.getX(i + 1) : i + 1, ic = idx ? idx.getX(i + 2) : i + 2;
    const ax = pos.getX(ia), ay = pos.getY(ia), az = pos.getZ(ia);
    const bx = pos.getX(ib), by = pos.getY(ib), bz = pos.getZ(ib);
    const qx = pos.getX(ic), qy = pos.getY(ic), qz = pos.getZ(ic);
    if (keep && !keep((ax + bx + qx) / 3, (ay + by + qy) / 3, (az + bz + qz) / 3)) continue;
    const v = (ax * (by * qz - bz * qy) - ay * (bx * qz - bz * qx) + az * (bx * qy - by * qx)) / 6;
    vol += v; cx += v * (ax + bx + qx) / 4; cy += v * (ay + by + qy) / 4; cz += v * (az + bz + qz) / 4;
  }
  if (Math.abs(vol) < 1e-9) return { vol: 0, c: new THREE.Vector3() };
  return { vol: Math.abs(vol), c: new THREE.Vector3(cx / vol, cy / vol, cz / vol) };
}

// mass items of one part: [{ kg, c (local to the mesh geometry), what }]
export function massItems(part, geo, kin) {
  const printedKg = v => v / 1000 * PRINT_DENSITY * PRINT_FILL / 1000;
  const n = part.name, all = volumeMoments(geo);
  if (n === 'rb_electronics') {
    const [bx, by] = kin.rb_batt_xy;
    const inBatt = (x, y) => Math.abs(x - bx) < 40 && Math.abs(y - by) < 45;
    const b = volumeMoments(geo, inBatt), o = volumeMoments(geo, (x, y, z) => !inBatt(x, y, z));
    return [{ kg: BATT_KG, c: b.c, what: 'battery' }, { kg: MASS_VIT.rb_electronics - BATT_KG, c: o.c, what: 'driver, Pico, switches' }];
  }
  if (n === 'rb_caster') {
    const ball = new THREE.Vector3(kin.rb_caster_xy[0], kin.rb_caster_xy[1], 9.525);
    return [{ kg: MASS_VIT.rb_caster, c: ball, what: 'ball + hardware' },
            { kg: printedKg(Math.max(0, all.vol - BALL_VOL)), c: all.c, what: 'printed mount' }];
  }
  if (part.optional) return [];                       // beam-stop cap: only when fitted
  if (n in MASS_VIT) return [{ kg: MASS_VIT[n], c: all.c, what: 'nominal' }];
  return [{ kg: printedKg(all.vol), c: all.c, what: 'printed' }];
}

const PAN_EXPLODE = { base: 60, tt: 120, yoke: 190, tilt: 290 };
const D2R = Math.PI / 180;

export class Rig {
  constructor(kin, geometries) {
    this.kin = kin;
    this.pose = { pan: 0, tilt: 0, explode: 0 };
    this.drive = { x: 0, y: 0, yaw: 0 };
    this.wheel = { l: 0, r: 0 };
    this.root = new THREE.Group();          // robot pose in the room
    this.meshes = {};
    this.massList = [];                      // { part, kg, c }

    const g = () => new THREE.Group();
    const dz = kin.deck_z ?? 0;
    this.staticG = g(); this.baseLift = g();
    this.panG = g(); this.ttLift = g(); this.yokeLift = g(); this.brgLift = g(); this.tiltLift = g();
    this.tiltPivot = g(); this.tiltInner = g();
    this.panPinionPivot = g(); this.tiltPinionPivot = g();
    this.wheelG = { l: g(), r: g() };

    this.root.add(this.staticG, this.panG, this.wheelG.l, this.wheelG.r);
    this.staticG.add(this.baseLift);
    this.panG.add(this.ttLift, this.yokeLift, this.brgLift, this.tiltLift);
    this.tiltLift.add(this.tiltPivot);
    this.tiltPivot.add(this.tiltInner);
    this.tiltPivot.position.set(0, 0, dz + kin.tilt_z);
    this.tiltInner.position.set(0, 0, -(dz + kin.tilt_z));

    const [px, py] = kin.pan_motor_xy;
    this.baseLift.add(this.panPinionPivot);
    this.panPinionPivot.position.set(px, py, 0);
    const [tx, tz] = kin.tilt_motor_xz;
    this.yokeLift.add(this.tiltPinionPivot);
    this.tiltPinionPivot.position.set(tx, 0, tz + dz);
    this.wheelG.l.position.set(kin.rb_axle_x, kin.rb_wheel_y, kin.rb_axle_z);
    this.wheelG.r.position.set(kin.rb_axle_x, -kin.rb_wheel_y, kin.rb_axle_z);

    const parentOf = {
      bay: this.staticG, electronics: this.staticG,
      base: this.baseLift, pan_motor_plate: this.baseLift, pan_motor: this.baseLift,
      pan_pinion: this.panPinionPivot,
      turntable: this.ttLift, pan_collar: this.panG, b6810: this.brgLift,
      yoke: this.yokeLift, tilt_motor_plate: this.yokeLift, tilt_motor: this.yokeLift,
      b608: this.yokeLift, camlink_deck: this.yokeLift,
      tilt_pinion: this.tiltPinionPivot,
    };
    for (const p of PARTS) {
      const geo = geometries[p.name];
      if (!geo) continue;
      const mat = new THREE.MeshStandardMaterial({ color: p.color, roughness: 0.62, metalness: p.vitamin ? 0.35 : 0.05 });
      const m = new THREE.Mesh(geo, mat);
      m.name = p.name;
      m.userData.part = p;
      m.userData.baseColor = new THREE.Color(p.color);
      // pinion and wheel meshes are exported in robot coordinates: undo their pivot offset
      if (p.name === 'pan_pinion') m.position.set(-px, -py, 0);
      if (p.name === 'tilt_pinion') m.position.set(-tx, 0, -(tz + dz));
      let parent = parentOf[p.name] || (p.body === 'static' ? this.staticG : this.tiltInner);
      if (p.body === 'wheel_l' || p.body === 'wheel_r') {
        const w = this.wheelG[p.body === 'wheel_l' ? 'l' : 'r'];
        m.position.copy(w.position).negate(); parent = w;
      }
      parent.add(m);
      this.meshes[p.name] = m;
      for (const it of massItems(p, geo, kin)) this.massList.push({ part: p.name, ...it });
    }
    this.massTotal = this.massList.reduce((s, i) => s + i.kg, 0);
    this.setDrive(0, 0, 0);
    this.setPose(0, 0, 0);
  }

  // robot pose in the room: origin (under the pan axis) at x, y (mm), heading yaw (rad)
  setDrive(x, y, yaw) {
    this.drive = { x, y, yaw };
    this.root.position.set(x, y, 0);
    this.root.rotation.set(0, 0, yaw);
    this.root.updateMatrixWorld(true);
  }
  // wheel angles (rad about +Y; positive = rolling forward)
  setWheels(l, r) {
    this.wheel = { l, r };
    this.wheelG.l.rotation.set(0, l, 0);
    this.wheelG.r.rotation.set(0, r, 0);
    this.root.updateMatrixWorld(true);
  }

  // pinionSense = -1 reverses both pinions (sanity test: must make the gears clash)
  setPose(pan, tilt, explode = this.pose.explode, pinionSense = 1) {
    const k = this.kin;
    this.pose = { pan, tilt, explode };
    this.panG.rotation.set(0, 0, pan * D2R);
    this.tiltPivot.rotation.set(0, -tilt * D2R, 0);
    this.panPinionPivot.rotation.set(0, 0, -pinionSense * pan * k.pan_gear_z / k.pinion_z * D2R);
    this.tiltPinionPivot.rotation.set(0, pinionSense * tilt * k.tilt_gear_z / k.pinion_z * D2R, 0);
    this.baseLift.position.z = PAN_EXPLODE.base * explode;
    this.brgLift.position.z = PAN_EXPLODE.base * explode;
    this.ttLift.position.z = PAN_EXPLODE.tt * explode;
    this.yokeLift.position.z = PAN_EXPLODE.yoke * explode;
    this.tiltLift.position.z = PAN_EXPLODE.tilt * explode;
    this.root.updateMatrixWorld(true);
  }

  // motor shaft angles for the current pose (degrees)
  motorAngles() {
    const k = this.kin, { pan, tilt } = this.pose;
    return { pan: -pan * k.pan_gear_z / k.pinion_z, tilt: tilt * k.tilt_gear_z / k.pinion_z };
  }

  // robot-frame matrix of a mesh (independent of the drive pose)
  robotMatrix(m, out = new THREE.Matrix4()) {
    return out.copy(this.root.matrixWorld).invert().multiply(m.matrixWorld);
  }

  // centre of gravity in the ROBOT frame at the current pose: { mass, x, y, z }
  cog(includeCap = false) {
    const inv = _inv.copy(this.root.matrixWorld).invert();
    let M = 0, x = 0, y = 0, z = 0;
    for (const it of this.massList) {
      const m = this.meshes[it.part];
      if (m.userData.part.optional && !includeCap) continue;
      _v.copy(it.c).applyMatrix4(_mm.multiplyMatrices(inv, m.matrixWorld));
      M += it.kg; x += it.kg * _v.x; y += it.kg * _v.y; z += it.kg * _v.z;
    }
    return { mass: M, x: x / M, y: y / M, z: z / M };
  }
}
const _inv = new THREE.Matrix4(), _mm = new THREE.Matrix4(), _v = new THREE.Vector3();

// ---------------------------------------------------------------- stability
// Support triangle: the two tire contact points and the caster contact. Returns the
// distance from the CoG's ground projection to the nearest edge (mm, negative = outside)
// and the along-X distances to the edges (for the acceleration limit).
export function stability(rig, c = rig.cog()) {
  const k = rig.kin, ax = k.rb_axle_x, wy = k.rb_wheel_y, [cx, cy] = k.rb_caster_xy;
  const P = [[ax, wy], [ax, -wy], [cx, cy]];
  let margin = Infinity;
  for (let i = 0; i < 3; i++) {
    const [x0, y0] = P[i], [x1, y1] = P[(i + 1) % 3];
    const ex = x1 - x0, ey = y1 - y0, L = Math.hypot(ex, ey);
    // triangle P0 -> P1 -> P2 runs counter-clockwise seen from above: inside is to the left of each edge
    margin = Math.min(margin, (ex * (c.y - y0) - ey * (c.x - x0)) / L);
  }
  const g = 9810;                                    // mm/s2
  const rear = c.x - ax;                             // along -X to the axle line
  // along +X to the nearest front edge (tire -> caster) at the CoG's y
  const front = (ax + (cx - ax) * (1 - Math.abs(c.y) / wy)) - c.x;
  return { margin, rear, front, aFwd: g * rear / c.z / 1000, aBrake: g * front / c.z / 1000 };
}

// ---------------------------------------------------------------- collisions
export function buildBVHs(geometries) {
  for (const geo of Object.values(geometries)) {
    geo.computeBoundingBox();
    geo.boundsTree = new MeshBVH(geo);
  }
}

export function pairList(rig, { includeBeamStop = false } = {}) {
  const ex = new Set(EXCLUDE.flatMap(([a, b]) => [`${a}|${b}`, `${b}|${a}`]));
  const ms = Object.values(rig.meshes).filter(m => includeBeamStop || !m.userData.part.optional);
  const pairs = [];
  for (let i = 0; i < ms.length; i++)
    for (let j = i + 1; j < ms.length; j++) {
      const a = ms[i], b = ms[j];
      if (a.userData.part.body === b.userData.part.body) continue;
      if (ex.has(`${a.name}|${b.name}`)) continue;
      pairs.push([a, b]);
    }
  return pairs;
}

const _ba = new THREE.Box3(), _bb = new THREE.Box3(), _m = new THREE.Matrix4();

// Do two triangles PENETRATE each other? (Moller interval test.)
// Touching (a vertex, edge or face lying on the other triangle within EPS) is
// contact, not penetration, so coplanar faces (bolted parts, both gear end faces
// on y = 41, a hard stop at its end angle) never count. Any real overlap of two
// solids always has some triangle pair that crosses properly.
// (three-mesh-bvh's own ExtendedTriangle.intersectsTriangle is not used: when a
// vertex lies exactly on the other triangle's plane it can return a crossing
// segment outside the triangle, e.g. the pinion tip chamfer vertex on the tilt
// wheel's end face at y = 41, and flag gears that have 0.066 mm clearance.)
const EPS = 1e-4;          // mm: 0.1 um, far below float32 vertex noise at 200 mm
const _e1 = new THREE.Vector3(), _e2 = new THREE.Vector3(), _n1 = new THREE.Vector3(), _n2 = new THREE.Vector3(), _D = new THREE.Vector3();
const _d1 = [0, 0, 0], _d2 = [0, 0, 0], _iv = [0, 0, 0, 0], _P = [null, null, null];
// signed distances of tri's vertices to the plane (n, p0) into out; true if they straddle it
function straddle(n, p0, tri, out) {
  const k = n.dot(p0);
  out[0] = n.dot(tri.a) - k; out[1] = n.dot(tri.b) - k; out[2] = n.dot(tri.c) - k;
  let pos = false, neg = false;
  for (let i = 0; i < 3; i++) { if (out[i] > EPS) pos = true; else if (out[i] < -EPS) neg = true; }
  return pos && neg;
}
// interval of tri on the line direction D (where it crosses the other plane) into _iv[o], _iv[o+1]
function interval(tri, d, D, o) {
  _P[0] = tri.a; _P[1] = tri.b; _P[2] = tri.c;
  let lo = Infinity, hi = -Infinity;
  for (let i = 0; i < 3; i++) {
    const j = (i + 1) % 3, di = d[i], dj = d[j];
    const si = di > EPS ? 1 : di < -EPS ? -1 : 0, sj = dj > EPS ? 1 : dj < -EPS ? -1 : 0;
    const pi = D.dot(_P[i]);
    if (si === 0) { if (pi < lo) lo = pi; if (pi > hi) hi = pi; }
    if (si * sj < 0) {
      const t = pi + (D.dot(_P[j]) - pi) * di / (di - dj);
      if (t < lo) lo = t; if (t > hi) hi = t;
    }
  }
  _iv[o] = lo; _iv[o + 1] = hi;
}
export function trianglesPenetrate(t1, t2) {
  _n1.crossVectors(_e1.subVectors(t1.b, t1.a), _e2.subVectors(t1.c, t1.a));
  const l1 = _n1.length();
  if (l1 < 1e-12) return false;                       // degenerate sliver
  _n1.divideScalar(l1);
  if (!straddle(_n1, t1.a, t2, _d2)) return false;
  _n2.crossVectors(_e1.subVectors(t2.b, t2.a), _e2.subVectors(t2.c, t2.a));
  const l2 = _n2.length();
  if (l2 < 1e-12) return false;
  _n2.divideScalar(l2);
  if (!straddle(_n2, t2.a, t1, _d1)) return false;
  _D.crossVectors(_n1, _n2);
  if (_D.lengthSq() < 1e-18) return false;            // parallel planes
  interval(t1, _d1, _D, 0); interval(t2, _d2, _D, 2);
  return Math.max(_iv[0], _iv[2]) < Math.min(_iv[1], _iv[3]) - 1e-9;
}

const _cast = { intersectsTriangles: (t1, t2) => trianglesPenetrate(t1, t2) };
function meshesIntersect(a, b) {
  _m.copy(a.matrixWorld).invert().multiply(b.matrixWorld);
  return a.geometry.boundsTree.bvhcast(b.geometry.boundsTree, _m, _cast);
}
// returns [[nameA, nameB], ...] of mesh pairs whose surfaces intersect at the current pose.
// cache (optional Map): results keyed by the pair's relative transform. Most pairs
// depend on one angle only (static vs pan: pan; pan vs tilt: tilt), so a sweep
// tests each relative position once.
export function collisions(pairs, cache = null) {
  const hits = [];
  for (const [a, b] of pairs) {
    _ba.copy(a.geometry.boundingBox).applyMatrix4(a.matrixWorld);
    _bb.copy(b.geometry.boundingBox).applyMatrix4(b.matrixWorld);
    if (!_ba.intersectsBox(_bb)) continue;
    let hit;
    if (cache) {
      _m.copy(a.matrixWorld).invert().multiply(b.matrixWorld);
      const key = a.name + '|' + b.name + '|' + _m.elements.map(v => Math.round(v * 1e6)).join(',');
      hit = cache.get(key);
      if (hit === undefined) { hit = meshesIntersect(a, b); cache.set(key, hit); }
    } else hit = meshesIntersect(a, b);
    if (hit) hits.push([a.name, b.name]);
  }
  return hits;
}

const range = (a, b, step) => {
  const out = [];
  for (let v = a; v <= b + 1e-9; v += step) out.push(+v.toFixed(4));
  if (Math.abs(out[out.length - 1] - b) > 1e-6) out.push(b);
  return out;
};



// Lowest world-ish z (robot frame) of a mesh: exact vertex minimum, optionally for the
// vertices inside a region only (keep(x, y) in the robot frame)
function minZ(rig, m, keep = null) {
  rig.robotMatrix(m, _m);
  const e = _m.elements, pos = m.geometry.attributes.position;
  let lo = Infinity;
  for (let i = 0; i < pos.count; i++) {
    const x = pos.getX(i), y = pos.getY(i), z = pos.getZ(i);
    if (keep && !keep(e[0] * x + e[4] * y + e[8] * z + e[12], e[1] * x + e[5] * y + e[9] * z + e[13])) continue;
    const w = e[2] * x + e[6] * y + e[10] * z + e[14];
    if (w < lo) lo = w;
  }
  return lo;
}

// The checks. Each yields progress so a page can stay responsive.
// result: { id, title, detail, pass, poses, failures: [{pan, tilt, hits}], ... }
export function* runChecks(rig, opts = {}) {
  const k = rig.kin;
  const step = opts.step ?? 5, margin = 0.5;
  const pairs = pairList(rig);
  const cache = new Map();
  const saved = { ...rig.pose }, savedWheel = { ...rig.wheel }, savedDrive = { ...rig.drive };
  rig.setDrive(0, 0, 0); rig.setWheels(0, 0);
  const results = [];
  const panLim = k.pan_stop - margin, [t0, t1] = [k.tilt_range[0] + margin, k.tilt_range[1] - margin];
  const total = checkPoseCount(k, step);
  let cum = 0;
  const yieldEvery = opts.yieldEvery ?? 25;

  function* sweep(id, title, detail, poses, expect, onlyPairs, sense = 1) {
    const r = { id, title, detail, poses: poses.length, failures: [], expectCollision: expect };
    let n = 0, hitCount = 0;
    for (const [pan, tilt] of poses) {
      rig.setPose(pan, tilt, 0, sense);
      let hits = collisions(pairs, sense === 1 ? cache : null);
      if (onlyPairs) hits = hits.filter(([a, b]) => onlyPairs.some(([x, y]) => (a === x && b === y) || (a === y && b === x)));
      if (hits.length) hitCount++;
      if (expect ? !hits.length : hits.length) r.failures.push({ pan, tilt, hits });
      cum++;
      if (++n % yieldEvery === 0) yield { id, done: n, total: poses.length, pan, tilt, cum, all: total };
    }
    r.pass = r.failures.length === 0;
    r.hitPoses = hitCount;
    results.push(r);
  }

  // 1. full working range (every robot part is now one of the bodies, too)
  const pans = range(-panLim, panLim, step), tilts = range(t0, t1, step);
  yield* sweep('range', 'Full range: no part hits another',
    `pan ${-panLim}..${panLim} deg x tilt ${t0}..${t1} deg, ${step} deg steps, every pair of parts on different moving bodies (gimbal and robot)`,
    pans.flatMap(p => tilts.map(t => [p, t])), false);

  // 2-3. gear meshes over several tooth pitches (exact tooth geometry)
  const panPitch = 360 / k.pan_gear_z, tiltPitch = 360 / k.tilt_gear_z;
  yield* sweep('pan_gear', `Pan gears ${k.pan_gear_z}:${k.pinion_z} mesh without clashing`,
    `turntable vs pan pinion through 3 tooth pitches at 1/24-pitch steps, at 4 places around the wheel`,
    [0, 90, -90, 170].flatMap(p0 => range(0, 3 * panPitch, panPitch / 24).map(d => [p0 + d > panLim ? p0 - d : p0 + d, 0])), false,
    [['turntable', 'pan_pinion']]);
  yield* sweep('tilt_gear', `Tilt gears ${k.tilt_gear_z}:${k.pinion_z} mesh without clashing`,
    `tilt wheel vs tilt pinion through 3 tooth pitches at 1/24-pitch steps, at 3 tilt positions`,
    [t0, 35, t1 - 3 * tiltPitch].flatMap(t => range(0, 3 * tiltPitch, tiltPitch / 24).map(d => [0, t + d])), false,
    [['tilt_gear', 'tilt_pinion']]);

  // 4. hard stops engage 1 deg past each limit
  yield* sweep('tilt_stops', 'Tilt hard stops engage',
    `payload stop lug must hit the yoke at ${k.tilt_range[0] - 1} and ${k.tilt_range[1] + 1} deg`,
    [[0, k.tilt_range[0] - 1], [0, k.tilt_range[1] + 1]], true, [['payload', 'yoke']]);
  yield* sweep('pan_stops', 'Pan hard stop engages',
    `turntable stop dog must hit the base at +-${k.pan_stop + 1} deg`,
    [[k.pan_stop + 1, 0], [-(k.pan_stop + 1), 0]], true, [['turntable', 'base']]);

  // 5. sanity: the gear test can see a clash (pinions turned the wrong way)
  yield* sweep('sanity', 'Sanity: a wrong gear direction is caught',
    `same gear sweep with both pinions reversed: the teeth must clash`,
    range(panPitch / 4, panPitch, panPitch / 8).map(d => [d, 10 + d]), true,
    [['turntable', 'pan_pinion'], ['tilt_gear', 'tilt_pinion']], -1);

  // 6. wheels spin clear: each wheel through 360 deg vs every other part
  rig.setPose(0, 0, 0);
  {
    const r = { id: 'wheels', title: 'Wheels spin clear', poses: 0, failures: [] };
    r.detail = `each wheel through 360 deg in 10 deg steps vs every other part (wheel x motor shaft skipped: the hub clamps it)`;
    for (const w of ['l', 'r']) {
      const name = 'rb_wheel_' + w, wp = pairs.filter(([a, b]) => a.name === name || b.name === name);
      for (let a = 0; a < 360; a += 10) {
        rig.setWheels(w === 'l' ? a * D2R : 0, w === 'r' ? a * D2R : 0);
        const hits = collisions(wp, cache);
        r.poses++; cum++;
        if (hits.length) r.failures.push({ pan: a, tilt: 0, wheel: w, hits });
      }
      yield { id: 'wheels', done: r.poses, total: 72, pan: 0, tilt: 0, cum, all: total };
    }
    rig.setWheels(0, 0);
    r.pass = r.failures.length === 0;
    results.push(r);
  }

  // 7. stands on its wheels: tires + caster ball on the floor, the skid and every other part clear
  {
    cum++;
    const r = { id: 'stand', title: 'Stands on its wheels', poses: 1, failures: [] };
    const low = {}, bad = [];
    const [sx, sy] = k.rb_skid_xy;
    const nearSkid = (x, y) => Math.hypot(x - sx, y - sy) < 25;
    for (const m of Object.values(rig.meshes)) {
      const n = m.name;
      if (m.userData.part.optional) continue;
      if (n === 'rb_floor') {
        const skid = minZ(rig, m, nearSkid), rest = minZ(rig, m, (x, y) => !nearSkid(x, y));
        low['rb_floor skid'] = skid; low.rb_floor = rest;
        if (skid < 2) bad.push(`skid ${skid.toFixed(2)} mm < 2`);
        if (rest < 1) bad.push(`rb_floor ${rest.toFixed(2)} mm < 1`);
        continue;
      }
      const z = minZ(rig, m); low[n] = z;
      if (n.startsWith('rb_wheel') || n === 'rb_caster') { if (Math.abs(z) > 0.3) bad.push(`${n} lowest point ${z.toFixed(2)} mm, not on the floor`); }
      else if (z < 1) bad.push(`${n} ${z.toFixed(2)} mm < 1`);
    }
    const others = Object.entries(low).filter(([n]) => !/^rb_(wheel|caster)|skid/.test(n)).reduce((a, b) => (b[1] < a[1] ? b : a));
    r.detail = `tires ${low.rb_wheel_l.toFixed(2)} / ${low.rb_wheel_r.toFixed(2)} mm, caster ball ${low.rb_caster.toFixed(2)} mm (must be 0 +-0.3); ` +
      `rear skid ${low['rb_floor skid'].toFixed(2)} mm (>= 2); lowest other part ${others[0]} ${others[1].toFixed(2)} mm (>= 1)`;
    for (const b of bad) r.failures.push({ pan: 0, tilt: 0, hits: [], note: b });
    r.pass = !bad.length; r.low = low;
    results.push(r);
    yield { id: 'stand', done: 1, total: 1, pan: 0, tilt: 0, cum, all: total };
  }

  // 8. does not tip over: CoG over the whole pan/tilt range vs the support triangle
  {
    const r = { id: 'tip', title: 'Does not tip over', failures: [], poses: 0 };
    let worst = null, minRear = Infinity, minFront = Infinity, aF = Infinity, aB = Infinity, hMin = Infinity, hMax = 0, mass = rig.massTotal;
    for (const pan of range(-panLim, panLim, 15)) for (const tilt of range(t0, t1, 15)) {
      rig.setPose(pan, tilt, 0);
      const c = rig.cog(), s = stability(rig, c);
      r.poses++; cum++;
      mass = c.mass; hMin = Math.min(hMin, c.z); hMax = Math.max(hMax, c.z);
      if (!worst || s.margin < worst.margin) worst = { ...s, pan, tilt, cog: c };
      aF = Math.min(aF, s.aFwd); aB = Math.min(aB, s.aBrake);
      if (s.margin < 10) r.failures.push({ pan, tilt, hits: [], note: `margin ${s.margin.toFixed(1)} mm` });
    }
    rig.setPose(0, 0, 0);
    const c0 = rig.cog(), s0 = stability(rig, c0);
    r.stats = { mass, cogZ: c0.z, cogZRange: [hMin, hMax], cog0: c0, margin0: s0.margin, worst, aFwd: aF, aBrake: aB };
    r.pass = r.failures.length === 0;
    r.detail = `CoG over pan ${-panLim}..${panLim} x tilt ${t0}..${t1} deg (15 deg steps) vs the triangle tires (${k.rb_axle_x}, +-${k.rb_wheel_y}) / caster (${k.rb_caster_xy}). ` +
      `Total ${mass.toFixed(2)} kg, CoG height ${hMin.toFixed(0)}..${hMax.toFixed(0)} mm (home ${c0.z.toFixed(0)}). ` +
      `Minimum margin ${worst.margin.toFixed(1)} mm at pan ${worst.pan} / tilt ${worst.tilt} (need >= 10). ` +
      `Max acceleration before tipping: ${aF.toFixed(2)} m/s2 forward (tips back over the axle), ${aB.toFixed(2)} m/s2 braking (tips forward over the caster edge)`;
    results.push(r);
    yield { id: 'tip', done: r.poses, total: r.poses, pan: 0, tilt: 0, cum, all: total };
  }

  rig.setWheels(savedWheel.l, savedWheel.r);
  rig.setDrive(savedDrive.x, savedDrive.y, savedDrive.yaw);
  rig.setPose(saved.pan, saved.tilt, saved.explode);
  return results;
}

// number of poses runChecks steps through (progress bar)
export function checkPoseCount(k, step = 5) {
  const margin = 0.5, panLim = k.pan_stop - margin;
  const n = (a, b, s) => range(a, b, s).length;
  const panPitch = 360 / k.pan_gear_z;
  return n(-panLim, panLim, step) * n(k.tilt_range[0] + margin, k.tilt_range[1] - margin, step)
    + 4 * n(0, 3 * panPitch, panPitch / 24) + 3 * n(0, 3 * (360 / k.tilt_gear_z), 360 / k.tilt_gear_z / 24)
    + 2 + 2 + n(panPitch / 4, panPitch, panPitch / 8) + 72 + 1
    + n(-panLim, panLim, 15) * n(k.tilt_range[0] + margin, k.tilt_range[1] - margin, 15);
}
