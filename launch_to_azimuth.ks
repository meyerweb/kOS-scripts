clearscreen.
set debug to false.
set ipu0 to config:ipu.
set config:ipu to 300.
// set terminal:reverse to true.
// set terminal:width to 50.
// set terminal:height to 30.
set logfile to "pid-log"+time:seconds+".txt".

run once "vessel_info.ks".
// run once "azimuth.ks".

set flightphase to 0.
// 0 - preflight
// 1 - initial ascent
// 2 - initial gravity turn
// 3 - 40s TtAp throttle control
// 4 - level burn to Ap > target Ap
// 5 - coast to fairing ejection (55km)
// 6 - coast to space (70km)
// 7 - spaaaaaaace

//log "==================================================" to logfile.
//log "N FLIGHT " + time:seconds to logfile.
//log "==================================================" to logfile.

parameter finalorbit is 72000.
if (finalorbit < 50000) set finalorbit to finalorbit * 1000.
parameter inclination is 0.  // equatorial orbit
// if (inclination < 0) set inclination_mod to -1. else set inclination_mod to 1.
// set azimuth to inst_az(inclination).
set azimuth to findAzimuth(finalorbit,inclination).

declare turnspeed to 80.
declare turnangle to 10.
declare turnstart to 0.
declare turnend to 45000.
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

// ========================================================================

if flightphase = 0 {
	phaseshift(0).
	sas off.
	lock steering to lookdirup(heading(azimuth,90):vector, ship:facing:topvector).

	set warp to 0.
	wait 1.
	stage.
	set thrott to 1.
	wait 1.
	stage.
	wait until ship:airspeed > 5.
	phaseshift(1).
}

until flightphase > 6 {
	statusDisplay().
//	pidDisplay().
	steer().
	stageMonitor().
	if mod(time:seconds,2) > 1 {
		print "*" at (terminal:width,0).
	} else {
		print "-" at (terminal:width,0).
	}
	if flightphase = 1 {
		// inital pad clearance
		if ship:airspeed > turnspeed {
			lock steering to lookdirup(heading(azimuth,90-turnangle-pitch):vector, ship:facing:topvector).
			phaseshift(2).
		}
	}
	if flightphase = 2 {
		// initial gravity turn
		if ttap >= apoapsis_setpoint - 1 {
			phaseshift(3).
		}
	}
	if flightphase = 3 {
		// throttle control to keep TtAp at setpoint (40s)
		set thrott to thrott + throttlePID:update(time:seconds,ttap).
		if (thrott < 0) set thrott to 0.
		if (thrott > 1) set thrott to 1.
//		log time:seconds + " | " + ttap + " | " + thrott + " | " + throttlePID to logfile.
		if alt >= turnend {
			phaseshift(4).
		}
	}
	if flightphase = 4 {
		// keep pitch above horizon at end of gravity turn
		lock steering to lookdirup(heading(azimuth,finalpitch):vector, ship:facing:topvector).
		if orbit:apoapsis > finalorbit * 0.99 {
			set thrott to 0.
			phaseshift(5).
		}
	}
	if flightphase = 5 {
		// unpowered cruise
		if alt > 65000 {
			// blow fairing
			set warp to 0.
			wait 5.
			AG10 on.  // requires action group be defined ahead of time
			phaseshift(6).
		}
	}
	if flightphase = 6 {
		// pulse to spaaaaace
		if orbit:apoapsis < finalorbit * 0.975 {
			set thrott to 0.1/maxTWR().
		} else {
			set thrott to 0.
		}
		if alt > 70000 {
			phaseshift(7).
		}
	}
}

if flightphase = 7 {
	// spaaaaace
	until orbit:apoapsis >= finalorbit {
		set thrott to 0.1/maxTWR().
	}
	set thrott to 0.
	set ship:control:pilotmainthrottle to 0.
	unlock throttle.
	set sasmode to "stability".
	wait 5.
	sas off.
} else {
	errorreport("Abnormal exit of heartbeat loop").
}



// ========================================================================


declare function phaseshift {
	parameter newphase.
	clearscreen.
	from {local i is 0.} until i > 7 step {set i to i + 1.} do {
		print i at((terminal:width-3), i * 2).
	}
	print "[-" at((terminal:width-5), newphase*2).
	print "-]" at((terminal:width-2), newphase*2).
	set flightphase to newphase.
}


declare function steer {
	local dampener is 10.
	local inc is orbit:inclination.
	local trg is 90 - inclination.
	local hdg is 90 - inc.
	local hdgdiff is abs(hdg - trg).
	local azscale is (hdg - azimuth)/dampener.
	local test is azscale - hdgdiff.
	if hdgdiff < test {
		set azimuth to trg - ((hdg - trg)*dampener).
	}

//	local output is list().
//	output:add(" inclin " + inc).
//	output:add(" target " + trg).
//	output:add("heading " + hdg).
//	output:add("azscale " + azscale).
//	output:add("hdgdiff " + hdgdiff).
//	output:add("   test " + test).
//	output:add("azimuth " + azimuth).
//	readout(output,1,1).

}


declare function pidDisplay {
	local output is list().

	output:add("  setpoint " + round(throttlePID:setpoint,3)).
	output:add("     input " + round(throttlePID:input,3)).
	output:add("    output " + round(throttlePID:output,3)).
	output:add("     error " + round(throttlePID:error,3)).
	output:add("  errorsum " + round(throttlePID:errorsum,3)).
	output:add("changerate " + round(throttlePID:changerate,3)).
	output:add("     pterm " + round(throttlePID:pterm,3)).
	output:add("     iterm " + round(throttlePID:iterm,3)).
	output:add("     dterm " + round(throttlePID:dterm,3)).
	output:add("    thrott " + round(thrott,3)).

	readout(output,15,1).
}

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

declare function findAzimuth {
	local parameter altitude is 0.
	local parameter inclination is 0.
	local parameter latitude is ship:body:latitude.
	
	local Binertial is arcsin( cos(inclination) / cos(latitude) ).
	if (inclination < 0) set Binertial to 180 - Binertial.
	local Vorbit is ( ship:body:mu / (altitude + body:radius) )^0.5.
	local Vsurface is ship:velocity:orbit:mag.
	local term1 is ( Vorbit * sin(Binertial) ) - ( Vsurface * cos(latitude) ).
	local term2 is ( Vorbit * cos(Binertial) ).
	local Brotational is arctan2(term1,term2).

	if debug {
		local output is list().
		output:add(" alt " + altitude).
		output:add(" inc " + inclination).
		output:add(" lat " + latitude).
		output:add("Vorb " + Vorbit).
		output:add("Vsrf " + Vsurface).
		output:add("Binr " + Binertial).
		output:add("trm1 " + term1).
		output:add("trm2 " + term2).
		output:add("Brot " + Brotational).
		readout(output,15,1).
	}

	return Brotational.

}
