"""Bounded catalogue of demonstrated shared FA-01 hardware, dimensions in mm.

Consult this catalogue before adding standard hardware. A component prefix or
baked source orientation is not a fit distinction. New equivalences require
geometry/interface evidence; unclassified catalogue families are left alone.
"""
from copy import deepcopy
import json

# Source authority: geometry.hardware / pitch_interfaces.fasteners in FA-01.
CATALOGUE = {
    "washer": dict(family="W-24", title="M24 washer", specification=dict(
        form="flat_washer", bore=26, outside=44, thickness=4, material="steel")),
    "w-12": dict(family="W-12", title="M12 washer", specification=dict(
        form="flat_washer", bore=13, outside=24, thickness=2.5, material="steel")),
    "h-12050": dict(family="H-12050", title="M12 × 50 cap screw", specification=dict(
        form="socket_cap_screw", thread="M12", pitch=1.75, length=50,
        head_diameter=18, head_height=12, material="steel")),
}


def canonical_part(key):
    record = CATALOGUE[key]
    return dict(family=record["family"], variant="standard",
                title=f'{record["family"]} · {record["title"]}',
                short_title=record["title"], carry_class="pocket",
                standard_hardware=deepcopy(record["specification"]))


def signature(specification):
    def numeric(value):
        if isinstance(value, dict):
            return {key: numeric(item) for key, item in value.items()}
        if isinstance(value, list):
            return [numeric(item) for item in value]
        return int(value) if isinstance(value, float) and value.is_integer() else value
    return json.dumps(numeric(specification), sort_keys=True, separators=(",", ":"))


def audit_standard_hardware(definitions):
    """Reject demonstrated duplicate specs, including under a new family name.

    Registration supplies explicit specifications; names alone never establish
    equivalence. Seed with the existing catalogue so a prefixed copy is rejected
    even if its author omitted the canonical kind from the current overlay.
    """
    registered = {signature(value["specification"]): key for key, value in CATALOGUE.items()}
    for key, definition in definitions.items():
        if key in CATALOGUE:
            assert definition["family"] == CATALOGUE[key]["family"], f"Changed canonical family: {key}"
            assert definition.get("standard_hardware") == CATALOGUE[key]["specification"], f"Changed canonical specification: {key}"
        specification = definition.get("standard_hardware")
        if specification is None:
            continue
        fit = signature(specification)
        assert fit not in registered or registered[fit] == key, (
            f"Duplicate standard hardware {key}: reuse {registered.get(fit)}")
        registered[fit] = key
