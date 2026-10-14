"""Per-texel 3D position map for the character texture (rasterises triangles in UV space).
Saves pos.npy (H,W,3) with NaN where no triangle covers the texel."""
import json, sys
import numpy as np
from PIL import Image
C = sys.argv[1]; W = H = int(sys.argv[2])
tris = json.load(open(C + '/tris.json'))
pos = np.full((H, W, 3), np.nan, dtype=np.float32)
for tri in tris:
    uv = np.array([[p[0] * W - 0.5, p[1] * H - 0.5] for p in tri])
    P = np.array([p[2:5] for p in tri])
    x0, y0 = np.floor(uv.min(0)).astype(int) - 1; x1, y1 = np.ceil(uv.max(0)).astype(int) + 1
    x0, y0 = max(x0, 0), max(y0, 0); x1, y1 = min(x1, W - 1), min(y1, H - 1)
    if x1 < x0 or y1 < y0: continue
    xs, ys = np.meshgrid(np.arange(x0, x1 + 1), np.arange(y0, y1 + 1))
    a, b, c = uv
    den = (b[1] - c[1]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[1] - c[1])
    if abs(den) < 1e-9: continue
    l1 = ((b[1] - c[1]) * (xs - c[0]) + (c[0] - b[0]) * (ys - c[1])) / den
    l2 = ((c[1] - a[1]) * (xs - c[0]) + (a[0] - c[0]) * (ys - c[1])) / den
    l3 = 1 - l1 - l2
    eps = -0.08  # small dilation so seams are covered
    inside = (l1 >= eps) & (l2 >= eps) & (l3 >= eps)
    p = l1[..., None] * P[0] + l2[..., None] * P[1] + l3[..., None] * P[2]
    sel = inside & np.isnan(pos[ys, xs, 0])
    pos[ys[sel], xs[sel]] = p[sel]
np.save(C + '/pos.npy', pos)
print('covered', np.isfinite(pos[..., 0]).mean())
