# Batch render starter — headless, optimized
# Run with hython:  hython batch_render.py scene.hip 1 240
# Works for Karma (/stage/usdrender_rop1) or any ROP (/out/...).

import sys
import hou

ROP_PATH = "/stage/usdrender_rop1"     # change to your output driver

def render(hip, start, end, rop_path=ROP_PATH):
    hou.hipFile.load(hip, ignore_load_warnings=True)

    rop = hou.node(rop_path)
    if rop is None:
        raise hou.NodeError(f"ROP not found: {rop_path}")

    # Versioned, organized output
    rop.parm("picture").set("$HIP/render/$OS.$F4.exr")
    if rop.parm("trange"):
        rop.parm("trange").set(1)          # render a frame range

    # Optimization: converge + denoise instead of brute-forcing samples
    if rop.parm("samplesperpixel"):
        rop.parm("samplesperpixel").set(256)
    if rop.parm("denoise"):
        rop.parm("denoise").set(1)

    rop.render(frame_range=(start, end, 1), verbose=True, output_progress=True)
    print(f"Done: frames {start}-{end}")

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("usage: hython batch_render.py scene.hip START END")
        sys.exit(1)
    render(sys.argv[1], int(sys.argv[2]), int(sys.argv[3]))
