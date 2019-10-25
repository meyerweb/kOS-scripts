// Auto-lander at KSC (no other runways supported at this time)
// KSC midpoint: -0.0496207077006795, -74.60286189
// Heavily inspired by ????
CLEARSCREEN.
CLEARVECDRAWS().

set approach_markers_geo to list().
set approach_markers_alt to list().
set pathdraw to list().
set pathalts to list().
set ksc_runway_center to LATLNG(-0.049425, -74.6085).
set ksc_runway_east to LATLNG(-0.05025, -74.4885).
set ksc_runway_west to LATLNG(-0.0486, -74.7285).
set ksc_land_vector to (ksc_runway_east:position - ksc_runway_west:position):normalized.
set ksc_sea_vector to -ksc_land_vector.

set count to 0.
set dist to 0.
until count >= 5 {

	local marker_alt is dist * 150.
	local marker_pos is ksc_runway_center:altitudeposition(marker_alt) - (2000 * dist * ksc_land_vector).
	local marker_geo is ship:body:geopositionof(marker_pos).

	approach_markers_alt:ADD(marker_alt).
	approach_markers_geo:ADD(marker_geo).
	local path is v(0,0,0).
	local alt is v(0,0,0).
	if count > 0 {
		set path to approach_markers_geo[count-1]:altitudeposition(approach_markers_alt[count-1]) - approach_markers_geo[count]:altitudeposition(marker_alt).
		set alt to marker_geo:altitudeposition(0) - marker_pos.
	}

	pathdraw:add(vecdraw(marker_pos,path,red,"",1.0,true,5)).
	pathalts:add(vecdraw(marker_pos,alt,red,"",1.0,true,5)).
	
	set count to count + 1.
	set dist to dist + count.	
}

wait 0.5.

set pg_abort to false.
UNTIL AG5 OR PG_ABORT {
	set loop to 0.
	until loop >= 5 {
		local marker_geo is approach_markers_geo[loop].
		local marker_alt is approach_markers_alt[loop].
		set pathdraw[loop]:start to marker_geo:altitudeposition(marker_alt).
		set loop to loop + 1.
	}
	WAIT 0.01.
}
