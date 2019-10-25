CLEARSCREEN.
CLEARVECDRAWS().

parameter approach_direction is "land", draw_paths is true.

set points to list(
	LATLNG(-0.0501377, -74.5024758448198),
	LATLNG(-0.04937135, -74.61076263),
	LATLNG(-0.048605, -74.7190494192674)
).

set markers to list().

set count to 0.
until count > 2 {
	markers:add(list()).
	local marker_pos is points[count]:altitudeposition(100).
	local marker_alt is marker_pos - points[count]:position.
	local marker_geo is ship:body:geopositionof(marker_pos).
	markers[count]:add(vecdraw(marker_pos,-marker_alt,rgba(0,255,0,2),"",1,true,2)).	
	markers[count]:add(marker_geo).
	set count to count + 1.
}

set endstate to false.
until endstate {
	redrawMarkers().
}


// ===================================================================

function redrawMarkers {
	from {local loop is 0.} until loop >= markers:length step {set loop to loop + 1.} do {
		local marker is markers[loop].
		set marker[0]:start to marker[1]:altitudeposition(100).
	}
}
