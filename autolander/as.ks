// Auto-lander at KSC (no other runways supported at this time)
// KSC midpoint: -0.0496207077006795, -74.60286189
// Heavily inspired by ????
CLEARSCREEN.
CLEARVECDRAWS().

set approach_markers_dist to list().
set approach_markers_alt to list().
set approach_markers_geo to list().
set pathdraw to list().
set pathalts to list().
set ksc_runway_center to LATLNG(-0.0486, -74.60286189).
set ksc_runway_east to LATLNG(-0.0486, -74.4926454940342):position.
set ksc_runway_west to LATLNG(-0.0486, -74.7244679538648):position.

set ksc_land_vector to (ksc_runway_east - ksc_runway_west):normalized.

set count to 0.
set dist to 0.

SET v to vecdraw(
	ship:position,
	10*ksc_land_vector,
	red
).
set v:show to true.
set i to 0.
until i > 10 {
	wait 0.25.
	set v:start to v:start + v(0,i/10,0).
	vecdraw(ship:position,v(-i,0,0),rgb(i/10,1-i/10,0),"",1,true).
	set i to i + 1.
}

PRINT " ".
PRINT "-=-=-=-=-=-=-=-=-=-=-".
PRINT " ".
