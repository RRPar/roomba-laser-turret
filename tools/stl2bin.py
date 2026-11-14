#!/usr/bin/env python3
"""ASCII STL -> binary STL (for the browser viewer).

usage: stl2bin.py SRC_DIR DST_DIR NAME [NAME ...]
Reads SRC_DIR/NAME.stl (OpenSCAD ASCII STL), writes DST_DIR/NAME.stl (binary,
face normals recomputed from the vertex winding) and prints triangle counts.
Fails if an input is missing or empty.
"""
import struct
import sys
from pathlib import Path

import numpy as np


def read_ascii(path):
    verts = []
    with open(path) as f:
        for line in f:
            s = line.split()
            if s and s[0] == "vertex":
                verts.append((float(s[1]), float(s[2]), float(s[3])))
    if not verts or len(verts) % 3:
        raise SystemExit(f"{path}: no triangles (or a truncated file)")
    return np.asarray(verts, dtype=np.float32).reshape(-1, 3, 3)


def write_binary(path, tris):
    n = np.cross(tris[:, 1] - tris[:, 0], tris[:, 2] - tris[:, 0])
    ln = np.linalg.norm(n, axis=1, keepdims=True)
    n = np.where(ln > 0, n / np.where(ln > 0, ln, 1), 0).astype(np.float32)
    rec = np.zeros(len(tris), dtype=[("n", "<f4", 3), ("v", "<f4", (3, 3)), ("a", "<u2")])
    rec["n"], rec["v"] = n, tris
    with open(path, "wb") as f:
        f.write(b"laser-gimbal viewer mesh".ljust(80, b" "))
        f.write(struct.pack("<I", len(tris)))
        f.write(rec.tobytes())


def main():
    if len(sys.argv) < 4:
        raise SystemExit(__doc__)
    src, dst = Path(sys.argv[1]), Path(sys.argv[2])
    total = 0
    for name in sys.argv[3:]:
        tris = read_ascii(src / f"{name}.stl")
        write_binary(dst / f"{name}.stl", tris)
        total += len(tris)
        print(f"  {name:18s} {len(tris):7d} tris  {(dst / f'{name}.stl').stat().st_size / 1e6:6.2f} MB")
    print(f"  total {total} triangles")


if __name__ == "__main__":
    main()
