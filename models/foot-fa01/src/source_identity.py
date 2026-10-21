"""Stable source identities. New roles require a deliberate registry entry.

Roles describe a part or named connection site, never an emission counter. Keep
existing entries when retiring parts so a source ID cannot accidentally be reused.
"""
import json
import re
from pathlib import Path

REGISTRY_PATH = Path(__file__).with_name('source-identities.json')


class SourceRegistry:
    def __init__(self, identities=None):
        self.identities = dict(identities if identities is not None else
                               json.loads(REGISTRY_PATH.read_text())['identities'])
        self.claimed = set()
        ids = list(self.identities.values())
        if len(ids) != len(set(ids)):
            raise ValueError('Duplicate source IDs in source identity registry')
        for role, uid in self.identities.items():
            if not role or not re.fullmatch(r'(?:FA|H|W)-\d+(?:-[A-Z]+)?__\d{3,}', uid):
                raise ValueError(f'Invalid source identity: {role!r}: {uid!r}')

    def resolve(self, role, family=None):
        if role not in self.identities:
            raise ValueError(f'Unknown source role {role!r}; add an explicit unused ID to {REGISTRY_PATH.name}')
        uid = self.identities[role]
        if family is not None and uid.split('__')[0] != family:
            raise ValueError(f'Source role {role!r} belongs to {uid}, not {family}')
        return uid

    def claim(self, role, family):
        uid = self.resolve(role, family)
        if role in self.claimed:
            raise ValueError(f'Duplicate source role emitted: {role}')
        self.claimed.add(role)
        return uid
