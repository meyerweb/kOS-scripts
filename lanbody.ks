clearscreen.
parameter leadtime is 0.
parameter targeted is 0.

if targeted <> 0 set target to targeted. else {
	print "No target was supplied, so no launch can be calculated.".
	print "Press CTRL-C to abort program.".
	wait until false.
}


set incline to target:orbit:inclination.

set targetLAN to target:orbit:LAN.
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

run launch_to_azimuth(75,incline).

runpath(orbit_change,75).

wait 2.

clearscreen.

print "Program complete.  Happy spacefaring!".
