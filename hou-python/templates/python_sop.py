# Python SOP starter — generate / modify geometry
# Paste into a Python SOP node (Type: Python). `hou.pwd()` is this SOP.
# Bulk attribute access is used so this scales to large point counts.

import hou

node = hou.pwd()
geo = node.geometry()

# --- Optional: read parameters created via Edit Parameter Interface ---
amount = node.evalParm("amount") if node.parm("amount") else 1.0

# --- Example A: build points from scratch (bulk) ---
# import math
# n = 10000
# pos = []
# for i in range(n):
#     a = i * 0.01
#     pos += [math.cos(a) * a, 0.0, math.sin(a) * a]
# geo.createPoints([(0, 0, 0)] * n)
# geo.setPointFloatAttribValues("P", pos)

# --- Example B: modify incoming geometry (bulk) ---
# Requires the SOP to pass input through (it does by default if wired).
if geo.points():
    P = geo.pointFloatAttribValues("P")
    P = [v * amount for v in P]          # scale all positions
    geo.setPointFloatAttribValues("P", P)

# --- Add a color attribute if missing ---
if geo.findPointAttrib("Cd") is None:
    geo.addAttrib(hou.attribType.Point, "Cd", (1.0, 1.0, 1.0))
