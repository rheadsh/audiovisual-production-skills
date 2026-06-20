# Animation starter — keyframes + expressions via HOM
# Run from a shelf tool or the Python Source Editor.
# Demonstrates ease in/out and volume-preserving squash & stretch.

import hou

NODE_PATH = "/obj/ball/ctrl"     # an Xform (or Transform SOP) to animate

def key(parm, frame, value, ease=True):
    k = hou.Keyframe()
    k.setFrame(frame)
    k.setValue(value)
    if ease:
        k.setInExpression("bezier()")
        k.setOutExpression("bezier()")
    parm.setKeyframe(k)

def main():
    node = hou.node(NODE_PATH)
    if node is None:
        raise hou.NodeError(f"node not found: {NODE_PATH}")

    ty = node.parm("ty")
    ty.deleteAllKeyframes()

    # Slow in / slow out between two poses (principle: ease in/out)
    key(ty, 1, 0.0)
    key(ty, 24, 5.0)
    key(ty, 48, 0.0)

    # Volume-preserving squash & stretch driven from sy (expression)
    for axis in ("sx", "sz"):
        node.parm(axis).setExpression(
            '1.0 / sqrt(max(hou.ch("./sy"), 0.001))',
            language=hou.exprLanguage.Python)

    hou.playbar.setFrameRange(1, 48)
    hou.playbar.setPlaybackRange(1, 48)

if __name__ == "__main__":
    main()
