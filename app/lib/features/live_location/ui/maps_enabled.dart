/// Whether this build carries a Maps key (live-location ADR-0007). Without
/// one the family map is the list, never a grey map.
const mapsEnabled = String.fromEnvironment(mapsDefineName) == 'on';

const mapsDefineName = 'NESTPREP_MAPS';
