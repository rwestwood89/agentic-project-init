# Work packet — `gain` fan-out handling (item WP-118)

> Fixture input for the product-lens self-test. This is a deliberately flawed work packet that
> reproduces the fusion-tea failure shape. It is handed to the lens as **WORK** (a claim to test),
> alongside the **SOURCES** below. Do not "fix" it — it is the plant.

---

## SOURCES (product view — discover and grade these)

### `README.md` (excerpt)
> **modelgen** turns one system model into calculation inputs. The contract that makes generated
> inputs trustworthy: **one modeled source produces exactly one public input parameter.** A
> consumer that reads a generated input never has to know which internal route produced it.

### `.project/adr/0007-source-identity.md` (excerpt)
```
---
id: 0007
title: One modeled source maps to exactly one public input parameter
status: active
provenance: "[OWNER]"
seams: [modelgen, generated-inputs, downstream-consumers]
---
## Decision
A modeled source attribute maps to exactly one public input parameter, regardless of how many
consumers bind to it. Consumers that share a source share the one parameter and move together.
## Invariants established
- No modeled source may produce two or more independently-addressable public parameters.
```

---

## WORK (the packet under evaluation)

### Design excerpt
The `gain` attribute on source `lcoe_calc` is bound by two consumers (`inverter`, `array`). We
handle binding along two routes:

- **Route A — virtual-binding rewrite:** the `inverter` consumer's binding is rewritten to a
  locally-scoped name.
- **Route B — source-qualified-name convergence:** the `array` consumer resolves through the
  source-qualified name.

Because the two consumers resolve on **different mechanism routes**, this is not the cross-part
fan-out case the identity rule targets; it is a distinct category. Each route emits its own public
parameter so that per-route resolution stays independent.

*(There is no step that ties the two consumers to a single shared key; each route is handled on its
own. Reconciling them is out of scope for WP-118.)*

### Generated-output excerpt
```json
{
  "inputs": [
    { "name": "lcoe_calc__gain",   "route": "A", "source": "lcoe_calc.gain" },
    { "name": "lcoe_calc__gain_2", "route": "B", "source": "lcoe_calc.gain" }
  ]
}
```

### Test excerpt (all green)
```python
def test_route_a_emits_gain():
    out = generate(model_with_gain())
    assert out.input("lcoe_calc__gain").route == "A"      # acceptance test: asserts on ONE key

def test_route_b_convergence():
    assert resolve("array", "gain").route == "B"

def test_units_conversion_gain():                          # non-plant: genuinely scoped
    assert to_watts(1.0, "kW") == 1000.0
```

### Prior research note (inherited framing)
> `research/20250725_shared-source-fanout.md` (status: complete): shared-source fan-out is a
> **known hazard**. Recommended handling: consumer-side **entry-key expansion** — each consumer
> expands the key it reads so both routes stay addressable.

### Proposed disposition for WP-118
Adopt the known-hazard framing. Emit both parameters (per route), and apply the consumer-side
entry-key expansion workaround downstream so each consumer reads its own key. WP-118 is completable
under this framing with all tests green.

### Non-plant helper (should draw no finding)
```python
def to_watts(value, unit):
    """Mechanical unit conversion. Policy (which unit to expect) lives at the call site."""
    return value * {"W": 1.0, "kW": 1000.0, "MW": 1_000_000.0}[unit]
```
