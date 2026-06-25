# Redshift batch render starter (headless)
# Run with hython:  hython batch_render.py scene.hip 1 240

import sys
import hou

ROP_PATH = "/out/Redshift_ROP"

def render(hip, start, end, rop_path=ROP_PATH):
    hou.hipFile.load(hip, ignore_load_warnings=True)
    rop = hou.node(rop_path)
    if rop is None:
        raise hou.NodeError(f"ROP not found: {rop_path}")

    out = rop.parm("RS_outputFileNamePrefix") or rop.parm("RS_outputFilePath")
    if out:
        out.set("$HIP/render/$OS.$F4.exr")
    if rop.parm("trange"):
        rop.parm("trange").set(1)        # render frame range

    rop.render(frame_range=(start, end, 1), verbose=True, output_progress=True)
    print(f"Done: frames {start}-{end}")

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("usage: hython batch_render.py scene.hip START END")
        sys.exit(1)
    render(sys.argv[1], int(sys.argv[2]), int(sys.argv[3]))
