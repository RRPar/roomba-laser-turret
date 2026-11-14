// =====================================================================
//  laser-gimbal :: viewer core (rig + collision checks)
//  Used by viewer/index.html. Meshes come from `make viewer`
//  (tools/export_viewer.sh): every object in WORLD coordinates at
//  pan 0 / tilt 0, so the only thing this file adds is the motion, which
//  mirrors assembly.scad:
//    static      bay, electronics, base, pan motor plate + motor
//    pan pinion  spins about its own Z axis by -pan * 85/17
//    pan         rotate([0,0,pan])
//    tilt pinion spins about its own axis (parallel to Y) by +tilt * 51/17
//    tilt        pan * rotate([0,-tilt,0]) about [0,0,tilt_z]
//  Units: mm, Z up.
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
];

const PAN_EXPLODE = { base: 60, tt: 120, yoke: 190, tilt: 290 };
const D2R = Math.PI / 180;

export class Rig {
  constructor(kin, geometries) {
    this.kin = kin;
    this.pose = { pan: 0, tilt: 0, explode: 0 };
    this.root = new THREE.Group();
    this.meshes = {};

    const g = () => new THREE.Group();
    this.staticG = g(); this.baseLift = g();
    this.panG = g(); this.ttLift = g(); this.yokeLift = g(); this.brgLift = g(); this.tiltLift = g();
    this.tiltPivot = g(); this.tiltInner = g();
    this.panPinionPivot = g(); this.tiltPinionPivot = g();

    this.root.add(this.staticG, this.panG);
    this.staticG.add(this.baseLift);
    this.panG.add(this.ttLift, this.yokeLift, this.brgLift, this.tiltLift);
    this.tiltLift.add(this.tiltPivot);
    this.tiltPivot.add(this.tiltInner);
    this.tiltPivot.position.set(0, 0, kin.tilt_z);
    this.tiltInner.position.set(0, 0, -kin.tilt_z);

    const [px, py] = kin.pan_motor_xy;
    this.baseLift.add(this.panPinionPivot);
    this.panPinionPivot.position.set(px, py, 0);
    const [tx, tz] = kin.tilt_motor_xz;
    this.yokeLift.add(this.tiltPinionPivot);
    this.tiltPinionPivot.position.set(tx, 0, tz);

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
      // pinion meshes are exported in world coordinates: undo their pivot offset
      if (p.name === 'pan_pinion') m.position.set(-px, -py, 0);
      if (p.name === 'tilt_pinion') m.position.set(-tx, 0, -tz);
      (parentOf[p.name] || this.tiltInner).add(m);
      this.meshes[p.name] = m;
    }
    this.setPose(0, 0, 0);
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

// The checks. Each yields progress so a page can stay responsive.
// result: { id, title, detail, pass, poses, failures: [{pan, tilt, hits}] }
export function* runChecks(rig, opts = {}) {
  const k = rig.kin;
  const step = opts.step ?? 5, margin = 0.5;
  const pairs = pairList(rig);
  const cache = new Map();
  const saved = { ...rig.pose };
  const results = [];
  const panLim = k.pan_stop - margin, [t0, t1] = [k.tilt_range[0] + margin, k.tilt_range[1] - margin];

  function* sweep(id, title, detail, poses, expect, onlyPairs, sense = 1) {
    const r = { id, title, detail, poses: poses.length, failures: [], expectCollision: expect };
    let n = 0, hitCount = 0;
    for (const [pan, tilt] of poses) {
      rig.setPose(pan, tilt, 0, sense);
      let hits = collisions(pairs, sense === 1 ? cache : null);
      if (onlyPairs) hits = hits.filter(([a, b]) => onlyPairs.some(([x, y]) => (a === x && b === y) || (a === y && b === x)));
      if (hits.length) hitCount++;
      if (expect ? !hits.length : hits.length) r.failures.push({ pan, tilt, hits });
      if (++n % (opts.yieldEvery ?? 25) === 0) yield { id, done: n, total: poses.length, pan, tilt };
    }
    r.pass = r.failures.length === 0;
    r.hitPoses = hitCount;
    results.push(r);
  }

  // 1. full working range
  const pans = range(-panLim, panLim, step), tilts = range(t0, t1, step);
  yield* sweep('range', 'Full range: no part hits another',
    `pan ${-panLim}..${panLim} deg x tilt ${t0}..${t1} deg, ${step} deg steps, every pair of parts on different moving bodies`,
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

  rig.setPose(saved.pan, saved.tilt, saved.explode);
  return results;
}
