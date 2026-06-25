# Redshift ROP configuration starter
# Run from a shelf tool / Python Source Editor / hython.
# Parm names vary by Redshift version — this template sets defensively and
# prints any name it couldn't find so you can confirm and substitute.

import hou

ROP_PATH = "/out/Redshift_ROP"

# Pick a look: "hyperreal" or "stylized"
LOOK = "hyperreal"

PRESETS = {
    "hyperreal": {
        "RS_unifiedMinSamples": 16,
        "RS_unifiedMaxSamples": 512,
        "RS_unifiedAdaptiveErrorThreshold": 0.003,
        "RS_GIEnabled": 1,
        "RS_GIPrimaryEngine": 0,      # Brute Force (confirm enum)
        "RS_GISecondaryEngine": 0,    # Brute Force
        "RS_reflectionMaxTraceDepth": 6,
        "RS_refractionMaxTraceDepth": 8,
    },
    "stylized": {
        "RS_unifiedMinSamples": 8,
        "RS_unifiedMaxSamples": 128,
        "RS_unifiedAdaptiveErrorThreshold": 0.015,
        "RS_GIEnabled": 0,
        "RS_reflectionMaxTraceDepth": 2,
        "RS_refractionMaxTraceDepth": 2,
    },
}

def configure(rop_path=ROP_PATH, look=LOOK):
    rop = hou.node(rop_path)
    if rop is None:
        raise hou.NodeError(f"ROP not found: {rop_path}")

    for name, value in PRESETS[look].items():
        p = rop.parm(name)
        if p:
            p.set(value)
        else:
            print(f"[confirm parm name] {name}")

    # Output path (confirm the correct parm in your version)
    out = rop.parm("RS_outputFileNamePrefix") or rop.parm("RS_outputFilePath")
    if out:
        out.set("$HIP/render/$OS.$F4.exr")

    print(f"Configured {rop_path} for '{look}' look.")

if __name__ == "__main__":
    configure()
