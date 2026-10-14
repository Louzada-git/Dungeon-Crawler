"""Repaints Character_16's texture as a medieval adventurer, by body region.
python3 -I repaint.py <work dir> <src png> <out png>"""
import sys, colorsys
import numpy as np
from PIL import Image
C, src, out = sys.argv[1:4]
pos = np.load(C + '/pos.npy')
img = np.asarray(Image.open(src).convert('RGB')).astype(np.float32) / 255.0
H, W, _ = img.shape
x, y, z = pos[..., 0], pos[..., 1], pos[..., 2]
covered = np.isfinite(y)
lum = img.mean(2)
# Skin: orange hue, mid saturation, bright enough (hands, face, neck).
hsv = np.array([colorsys.rgb_to_hsv(*p) for p in img.reshape(-1, 3)]).reshape(H, W, 3)
skin = (hsv[..., 0] > 0.0) & (hsv[..., 0] < 0.11) & (hsv[..., 1] > 0.18) & (hsv[..., 1] < 0.75) & (hsv[..., 2] > 0.33)
head = covered & (y > 1.47)
keep = head | (covered & skin)
arm = covered & (np.abs(x + 0.025) > 0.175)          # body centre is x = -0.025
leg = covered & (y < 0.97) & ~arm
torso = covered & (y >= 0.97) & ~arm & ~head
rng = np.random.default_rng(16)
noise = rng.normal(0, 1, (H, W)).astype(np.float32)

def shade(mask, base, contrast=0.8, grain=0.035):
    """Base colour modulated by the original folds (luminance relative to the region mean)."""
    if not mask.any():
        return
    ref = lum[mask].mean() + 1e-3
    detail = np.clip(1.0 + contrast * (lum / ref - 1.0), 0.55, 1.45)
    col = np.array(base, np.float32) / 255.0
    res = col[None, None, :] * detail[..., None] * (1.0 + grain * noise[..., None])
    img[mask] = np.clip(res[mask], 0, 1)

def m(*conds):
    r = covered & ~keep
    for c in conds:
        r = r & c
    return r

tunic = (82, 92, 58)        # dull green wool
linen = (196, 178, 140)
trousers = (92, 66, 44)
leather = (78, 50, 30)
boot = (58, 38, 24)
brass = (176, 140, 62)
shade(m(torso), tunic)
shade(m(arm, y >= 1.16), tunic)                       # upper sleeve
shade(m(arm, y < 1.16), linen, 0.6)                   # forearm sleeve
shade(m(arm, y < 1.03, y > 0.94), leather, 0.5)       # bracers at the wrist
shade(m(leg), trousers)
shade(m(leg, y < 0.46), boot, 0.5)                    # boots up to below the knee
shade(m(leg, y < 0.49, y >= 0.44), leather, 0.4)      # boot cuff
shade(m(leg, y < 0.03), (34, 24, 16), 0.3)            # soles
# Tunic hem a little over the hips, then the belt.
shade(m(leg, y >= 0.86, ~arm), tunic)
shade(m(~arm, y > 0.93, y < 1.0), leather, 0.4)
shade(m(~arm, y > 0.935, y < 0.995, np.abs(x + 0.025) < 0.035, z > 0.04), brass, 0.3, 0.02)
# Bag strap: left shoulder to right hip, front and back.
p0 = np.array([0.12, 1.41]); p1 = np.array([-0.17, 0.98])
d = p1 - p0; t = np.clip(((x - p0[0]) * d[0] + (y - p0[1]) * d[1]) / (d @ d), 0, 1)
dist = np.hypot(x - (p0[0] + t * d[0]), y - (p0[1] + t * d[1]))
shade(m(~arm, torso, dist < 0.022), leather, 0.4)
# Collar of the tunic, a darker band at the neck.
shade(m(torso, y > 1.435), (70, 78, 50), 0.5)
outimg = Image.fromarray((img * 255).astype(np.uint8))
outimg.save(out)
print('repainted', m(torso).sum() + m(leg).sum() + m(arm).sum(), 'texels; kept', keep.sum())
