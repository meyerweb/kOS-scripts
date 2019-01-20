clearscreen.
parameter leadtime is 0.
parameter targetLAN is 0.
parameter incline is 0.
parameter altitude is 75.

lock shipLAN to LANcalc().

function LANcalc {
	set temp to ship:longitude + ship:body:rotationangle.
	if temp < 0 and targetLAN > 10 set temp to temp + 360.
	return temp.
}

hudtext(incline,10,2,16,yellow,false).

set warp to 5.
until (abs(shipLAN-targetLAN) < (leadtime + 10)) {
	print targetLAN at (1,1).
	print shipLAN at (1,2).
}
set warp to 3.
until (abs(shipLAN-targetLAN) < (leadtime + 3)) {
	print targetLAN at (1,1).
	print shipLAN at (1,2).
}
set warp to 2.
until (abs(shipLAN-targetLAN) < (leadtime + 1)) {
	print targetLAN at (1,1).
	print shipLAN at (1,2).
}
set warp to 1.
until (abs(shipLAN-targetLAN) < (leadtime + 0.05)) {
	print targetLAN at (1,1).
	print shipLAN at (1,2).
}

set warp to 0.
print "Launch at " + incline + " degrees!".
wait 2.
set warp to 0.
wait 1.

run launch_to_azimuth(altitude,incline).

runpath(orbit_change,altitude).

wait 2.

clearscreen.

print "Program complete.  Happy spacefaring!".
