"""Named pitch connection sites shared by geometry repair and recipe authoring."""
from source_identity import SourceRegistry

PAIR = ('negative', 'positive')
QUAD = ('x-positive', 'y-positive', 'x-negative', 'y-negative')
# Connection names are authoring API. Site names retain their assigned source IDs
# if a connection, emission or manifest row is moved or another site is added.
PITCH_CONNECTIONS = {
    'base-eye': ('FA-525/P_Eye_housing_1', 'Actuator eye housings', PAIR),
    'rod-eye': ('FA-525/P_Eye_housing_2', 'Actuator eye housings', PAIR),
    'rear-sensor': ('FA-528/P_End_sensor_1', 'Actuator end sensors', ('mount',)),
    'front-sensor': ('FA-528/P_End_sensor_2', 'Actuator end sensors', ('mount',)),
    'rear-cap': ('P/caps/rear', 'Actuator front and rear caps', QUAD),
    'front-cap': ('P/caps/front', 'Actuator front and rear caps', QUAD),
    'motor': ('P/Motor flanges', 'Motor flanges', QUAD),
    'gearbox': ('P/Gearbox flanges', 'Gearbox flanges', QUAD),
    'coupling': ('P/Actuator coupling clamps', 'Actuator coupling clamps', ('rear', 'front')),
    'rod': ('FA-517/P_Travelling_nut', 'Travelling nut to output rod', PAIR),
    'retainer': ('P/Actuator bearing retainer plates', 'Actuator bearing retainer plates', PAIR),
    'collar': ('P/Actuator split shaft collars', 'Actuator split shaft collars', PAIR),
    'guide': ('P/Actuator antirotation guides', 'Actuator antirotation guides', ('rear', 'front')),
    'cradle': ('FA-220/P_Clevis_1', 'Actuator clevis mounts', PAIR),
    'ring': ('FA-220/P_Clevis_2', 'Actuator clevis mounts', PAIR),
    'base-keeper': ('FA-222/P_Pin_keeper_1', 'Actuator attachment pin keepers', ('mount',)),
    'rod-keeper': ('FA-222/P_Pin_keeper_2', 'Actuator attachment pin keepers', ('mount',)),
}


def pitch_pairs(connection, sites=None):
    owner, use, known_sites = PITCH_CONNECTIONS[connection]
    sites = known_sites if sites is None else sites
    if len(set(sites)) != len(sites) or set(sites) - set(known_sites):
        raise ValueError(f'Unknown or duplicate sites for {connection}: {sites}')
    registry = SourceRegistry()
    return [(registry.resolve(f'hardware/{owner}/{use}/{site}/bolt'),
             registry.resolve(f'hardware/{owner}/{use}/{site}/washer')) for site in sites]


def pitch_instance_ids():
    registry = SourceRegistry()
    parts = {uid for role, uid in registry.identities.items()
             if role.startswith('FA-') and role.split('/')[1].startswith('P_')}
    hardware = {uid for connection in PITCH_CONNECTIONS for pair in pitch_pairs(connection) for uid in pair}
    return parts | hardware
