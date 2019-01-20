CLEARSCREEN.
CLEARVECDRAWS().

set ksc_runway_east to LATLNG(-0.05025, -74.4885).
set ksc_runway_west to LATLNG(-0.0486, -74.7285).

SET v to vecdraw(
	ksc_runway_west:altitudeposition(70),
	ksc_runway_west:altitudeposition(100) - ksc_runway_west:altitudeposition(70),
	rgb(1,0,0)
).
set v:show to true.

UNTIL AG5 {
	set v:start to ksc_runway_west:altitudeposition(70).
	wait 0.01.
}

PRINT " ".
PRINT "-=-=-=-=-=-=-=-=-=-=-".
PRINT " ".
