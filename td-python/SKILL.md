---
name: td-python
description: Write Python scripts for TouchDesigner — parameter expressions, DAT callbacks, Script OPs, Extensions, and module patterns. Use when creating Python expressions, DAT scripts, Execute DATs, Script CHOPs/TOPs/SOPs/DATs, component extensions, or any TouchDesigner Python automation, interaction, or data scripting.
---

# TouchDesigner Python Scripting

Write Python optimized for TouchDesigner's scripting environment.

## Quick Start

There are four main contexts where Python runs in TouchDesigner:

```python
# 1. PARAMETER EXPRESSION (one-liner, auto-updates)
absTime.frame                          # current frame number
me.par.tx                              # this operator's tx parameter
op('noise1')['chan1']                  # CHOP channel value
round(op('slider1').par.value0.eval(), 2)

# 2. TEXTPORT (live testing)
r = op('/project1/geo1')
r.par.tx = 5
print(dir(r))

# 3. DAT SCRIPT (full Python in a Text DAT)
def onCook(scriptOp):
    scriptOp.clear()
    scriptOp.appendRow(['name', 'value'])

# 4. CALLBACK (react to events)
def onValueChange(par, prev):
    debug(par, prev)
```

## Critical Rules

1. **Use `debug()` not `print()`** — `debug()` adds source location; essential for tracking down errors
2. **Use `.eval()` when passing par to functions** — `round(op('x').par.tx)` fails; `round(op('x').par.tx.eval())` works
3. **Never access TD objects at module root** — put them in functions or the module will recompile on every change
4. **`me` = the operator running this script** — works in expressions and DATs
5. **`op()` paths are relative by default** — `/` prefix makes them absolute from root

## The Core Objects (Always Available, No Import Needed)

```python
me                      # the operator this script belongs to
op('name')              # find operator by relative path
op('/project1/geo1')    # find operator by absolute path
op.MyGlobalShortcut     # find component via Global OP Shortcut
parent()                # one level up in hierarchy
parent(2)               # two levels up
parent.MyShortcut       # search upward for Parent Shortcut named "MyShortcut"
absTime.frame           # current frame
absTime.seconds         # current time in seconds
ext.MyExtension         # access extension on this or parent component
```

## Common Patterns

See [examples/PATTERNS.md](examples/PATTERNS.md) for ready-to-use templates:
- Parameter expressions
- Callback DATs (parameter, CHOP, panel, execute)
- Script OPs (Script CHOP, TOP, SOP, DAT)
- Extensions
- DATs as modules

## Response Format

When providing Python code, always include:

1. **Python code** with comments
2. **Context** — where this code goes (expression field, DAT name, callback function)
3. **TouchDesigner setup** — what operators to create, how to wire them, which parameters to configure

## Writing Process

1. Identify the context (expression / callback / script OP / extension / module)
2. Write the minimal working script
3. Add error handling and `debug()` calls
4. Note any required operator connections or parameter setup

## Additional Resources

- [examples/PATTERNS.md](examples/PATTERNS.md) — Ready-to-use templates per context
- [examples/COMPLETE.md](examples/COMPLETE.md) — Full real-world examples
- [reference/API.md](reference/API.md) — Core TD Python API reference
- [reference/TROUBLESHOOTING.md](reference/TROUBLESHOOTING.md) — Common errors and fixes
- [reference/BEST-PRACTICES.md](reference/BEST-PRACTICES.md) — Organization, performance, style
