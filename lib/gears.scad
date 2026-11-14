// =====================================================================
//  laser-gimbal :: involute spur / herringbone gears (no external libs)
//  use <../lib/gears.scad>
//
//  gear2d(m, z)                         2D involute profile, centred, tooth 0 on +X
//  herringbone(m, z, w, helix)          3D gear z = 0..w. Mating gears use OPPOSITE helix sign.
//  mesh_phase(z_wheel, z_pinion, ang)   rotation (deg) to apply to a pinion placed at polar angle
//                                       `ang` around a wheel (wheel at rotation 0) so teeth interleave.
// =====================================================================

// involute function, a in degrees -> radians
function _inv(a) = tan(a) - a * PI / 180;

// half tooth angle (degrees) at radius r
function _half_ang(r, rb, halfp_rad, pa) =
    (halfp_rad + _inv(pa) - (r <= rb ? 0 : _inv(acos(rb / r)))) * 180 / PI;

module gear2d(m, z, pa = 20, backlash = 0.15, steps = 10) {
    rp = m * z / 2;
    rb = rp * cos(pa);
    ra = rp + m;
    rf = rp - 1.25 * m;
    halfp = (PI * m / 2 - backlash / 2) / (2 * rp);      // half tooth thickness angle at pitch (rad)
    r0 = max(rb, rf);
    rs = [for (i = [0 : steps]) r0 + (ra - r0) * i / steps];
    a0 = _half_ang(r0, rb, halfp, pa);
    root_pts = rf < rb ? [[rf * cos(-a0), rf * sin(-a0)]] : [];
    root_pts2 = rf < rb ? [[rf * cos(a0), rf * sin(a0)]] : [];
    tooth = concat(
        [[(rf - 0.5) * cos(-a0), (rf - 0.5) * sin(-a0)]],
        root_pts,
        [for (r = rs) let(a = _half_ang(r, rb, halfp, pa)) [r * cos(-a), r * sin(-a)]],
        [for (j = [steps : -1 : 0]) let(r = rs[j], a = _half_ang(r, rb, halfp, pa)) [r * cos(a), r * sin(a)]],
        root_pts2,
        [[(rf - 0.5) * cos(a0), (rf - 0.5) * sin(a0)]]
    );
    union() {
        circle(r = rf, $fn = max(z * 4, 64));
        for (i = [0 : z - 1]) rotate(i * 360 / z) polygon(tooth);
    }
}

// twist (deg) over height h for helix angle at pitch radius
function _twist(m, z, h, helix) = h * tan(helix) / (m * z / 2) * 180 / PI;

module herringbone(m, z, w, helix = 20, pa = 20, backlash = 0.15) {
    tw = _twist(m, z, w / 2, helix);
    slices = max(4, ceil(w / 0.8));
    // upper half = exact mirror of the lower half, so the two share the mid-plane face
    // vertex-for-vertex (an overlap left sliver faces at the tooth tips -> non-manifold STL)
    module half() linear_extrude(height = w / 2, twist = tw, slices = slices, convexity = 10)
        gear2d(m, z, pa, backlash);
    half();
    translate([0, 0, w]) mirror([0, 0, 1]) half();
}

// Pinion phase so its teeth interleave with a wheel whose tooth 0 is on +X.
// Pinion centre sits at polar angle `ang` from the wheel centre.
function mesh_phase(z_wheel, z_pinion, ang) =
    // a wheel gap faces the pinion if the wheel is at 0 and ang is a tooth-centre angle;
    // rotate the pinion so a pinion tooth points back at the wheel centre (into that gap)
    // Nearest wheel tooth sits delta behind the line of centres == wheel rotated by -delta from the
    // aligned case; meshing turns the pinion the opposite way by delta * z_wheel / z_pinion.
    let(
        delta = ang - round(ang / (360 / z_wheel)) * (360 / z_wheel),
        aligned = 180 + ang - 180 / z_pinion   // pinion GAP points back at a wheel tooth on the centre line
    )
    aligned + delta * z_wheel / z_pinion;
