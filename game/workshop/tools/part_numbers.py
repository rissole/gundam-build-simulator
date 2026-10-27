"""Engineering part numbers for authored robot part types.

Authoring modules name some part types with working names; this catalogue
assigns their part numbers. Instance and source IDs keep the working names:
they are internal and never shown. A part number has no full words: a prefix,
a number or hardware code, and an optional variant suffix (-A, -B, ... in
order; -L/-R are reserved for left and right hand).
"""
import re

PART_NUMBERS = {
    "SH-RING-FRONT": "SH-100-A",
    "SH-RING-REAR": "SH-100-B",
    "SH-BRACE-LEFT": "SH-110-L",
    "SH-BRACE-RIGHT": "SH-110-R",
    "SH-DRIVE": "SH-120",
    "SH-SERVICE": "SH-130",
    "SH-BOLT": "SH-H24240",
    "SH-WASHER": "SH-W24",
    "SH-PIN": "SH-P40",
    "SH-KEEPER": "SH-K40",
    "PD-FRONT": "PD-100-A",
    "PD-REAR": "PD-100-B",
    "PD-M20-LONG": "PD-H20120-A",
    "PD-M20-SHORT": "PD-H20120-B",
    "HD-FACE": "HD-100",
    "HD-MASK": "HD-110",
    "HD-SENSORS": "HD-120",
    "HD-LOOM": "HD-130",
    "HD-SERVICE": "HD-140",
    "CH-SERVICE": "CH-100",
    "BP-SERVICE": "BP-100",
}
FORMAT = re.compile(r"[A-Z]+(-[A-Z])?-[A-Z]?\d+(-[A-Z])?")
TEXT_FIELDS = {"title", "short_title", "label", "goal", "body", "text"}
_NAMES = re.compile(r"(?<![\w-])(" + "|".join(sorted(map(re.escape, PART_NUMBERS), key=len, reverse=True)) + r")(?![\w-])")


def _text(value):
    return _NAMES.sub(lambda match: PART_NUMBERS[match.group(1)], value)


def _rewrite(node):
    if isinstance(node, dict):
        for key, value in node.items():
            if key in TEXT_FIELDS and isinstance(value, str):node[key] = _text(value)
            else:_rewrite(value)
    elif isinstance(node, list):
        for value in node:_rewrite(value)


def apply(parts, inventory, assemblies):
    """Renumber part types, their stock records and every player-facing text."""
    for definition in parts.values():
        definition["family"] = PART_NUMBERS.get(definition["family"], definition["family"])
    for record in inventory:
        if "part_id" in record:record["part_id"] = PART_NUMBERS.get(record["part_id"], record["part_id"])
    _rewrite(parts)
    _rewrite(assemblies)
    unnumbered = sorted({p["family"] for p in parts.values() if not FORMAT.fullmatch(p["family"])})
    assert not unnumbered, "Part numbers must not contain words: " + ", ".join(unnumbered)
