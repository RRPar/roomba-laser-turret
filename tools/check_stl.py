#!/usr/bin/env python3
"""Validate OpenSCAD ASCII STL exports: watertight (every edge shared by exactly
two triangles), single body, positive volume, sits on z=0, fits the print bed.

usage: check_stl.py [--bed 250] file.stl [file.stl ...]
exit 1 if any file fails.
"""
import collections
import sys


def load(path):
    tris, cur = [], []
    with open(path) as fh:
        for line in fh:
            p = line.split()
            if p and p[0] == "vertex":
                cur.append(tuple(round(float(v), 5) for v in p[1:4]))
                if len(cur) == 3:
                    tris.append(cur)
                    cur = []
    return tris


def bodies(tris):
    parent = {}

    def find(a):
        while parent.setdefault(a, a) != a:
            parent[a] = parent[parent[a]]
            a = parent[a]
        return a

    for t in tris:
        r = find(t[0])
        for v in t[1:]:
            parent[find(v)] = r
    return len({find(v) for t in tris for v in t})


def check(path, bed):
    tris = load(path)
    if not tris:
        return False, "no triangles (binary STL or empty export)"
    edges = collections.Counter()
    for t in tris:
        for i in range(3):
            edges[frozenset((t[i], t[(i + 1) % 3]))] += 1
    bad = sum(1 for c in edges.values() if c != 2)
    pts = [v for t in tris for v in t]
    mn = [min(p[i] for p in pts) for i in range(3)]
    mx = [max(p[i] for p in pts) for i in range(3)]
    size = [mx[i] - mn[i] for i in range(3)]
    vol = sum(
        (a[0] * (b[1] * c[2] - b[2] * c[1]) - a[1] * (b[0] * c[2] - b[2] * c[0])
         + a[2] * (b[0] * c[1] - b[1] * c[0])) / 6 for a, b, c in tris)
    n_bodies = bodies(tris)
    problems = []
    if bad:
        problems.append(f"{bad} non-manifold edges")
    if vol <= 0:
        problems.append(f"non-positive volume {vol:.1f}")
    if abs(mn[2]) > 0.05:
        problems.append(f"min z = {mn[2]:.2f} (not on bed)")
    if max(size[0], size[1]) > bed:
        problems.append(f"footprint {size[0]:.0f}x{size[1]:.0f} exceeds bed {bed}")
    if n_bodies != 1:
        problems.append(f"{n_bodies} separate bodies")
    info = (f"{len(tris)} tris, size {size[0]:.1f}x{size[1]:.1f}x{size[2]:.1f} mm, "
            f"vol {vol / 1000:.1f} cm3, ~{vol / 1000 * 1.24 * 0.45:.0f} g PLA @~30% effective")
    return not problems, info + ("" if not problems else " | FAIL: " + "; ".join(problems))


def main(argv):
    bed = 250.0
    if len(argv) > 1 and argv[0] == "--bed":
        bed = float(argv[1])
        argv = argv[2:]
    ok_all = True
    for path in argv:
        ok, msg = check(path, bed)
        ok_all &= ok
        print(f"{'PASS' if ok else 'FAIL'}  {path}: {msg}")
    return 0 if ok_all else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
