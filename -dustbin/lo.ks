clearscreen.

run once "vessel_info.ks".
run once "azimuth.ks".

set flightphase to 0.

parameter finalorbit is 75000.

if (finalorbit < 50000) set finalorbit to finalorbit * 1000.

parameter inclination is 0.  // equatorial orbit

set azimuth to findAzimuth(finalorbit,inclination).
set azimuth to inst_az(inclination).


declare turnspeed to 80.
declare turnangle to 10.
declare turnstart to 0.
declare turnend to 40000.
declare pitch to 90.
declare finalpitch to 5.

set thrott to 0.
lock throttle to thrott.
lock alt to ship:altitude.
lock ttap to eta:apoapsis.
lock pitch to ((90 - turnangle) * (alt - turnstart) / (turnend - turnstart)) - finalpitch.

SET apoapsis_setpoint TO 40.
//SET Kp TO 0.125.
//SET Ki TO 0.101.
//SET Kd TO 0.025.
SET Kp TO 0.15.
SET Ki TO 0.01.
SET Kd TO 0.1.
SET throttlePID TO PIDLOOP(Kp,Ki,Kd).
SET throttlePID:minoutput to -1.
SET throttlePID:maxoutput to 1.
SET throttlePID:SETPOINT TO apoapsis_setpoint.

statusDisplay().


declare function statusDisplay {
	local output is list().

	output:add("   PITCH @ " + round(90-turnangle-pitch,2)).
// 	output:add("   PITCH = " + "???").
 	output:add("  ORBINC = " + round(orbit:inclination,3)).
	output:add("STEERING @ " + round(azimuth,3)).
// 	output:add(" HEADING = " + "???").
	output:add("THROTTLE = " + round(thrott,3)).
	output:add("MAXTHRST = " + round(ship:maxthrust,3)).
	output:add("  MAXTWR = " + round(maxTWR(),3)).
	output:add(" STAGEDV = " + round(stageDV(),3)).
	output:add(" STAGELF = " + stage:liquidfuel).
	output:add(" STAGESF = " + stage:solidfuel).
	
	readout(output,1,1).
}
