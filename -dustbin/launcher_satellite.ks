clearscreen.
set ipu0 to config:ipu.
set config:ipu to 300.
set terminal:reverse to true.
set terminal:width to 50.
set terminal:height to 30.
set logfile to "pid-log"+time:seconds+".txt".

parameter flightphase is 0.
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

declare turnspeed to 80.
declare turnangle to 10.
declare turnstart to 0.
declare turnend to 40000.
declare finalorbit to 80000.
declare targetorbit to finalorbit * 0.99.
declare pitch to 90.

set thrott to 0.
lock throttle to thrott.
lock alt to ship:altitude.
lock ttap to eta:apoapsis.
lock pitch to ((90 - turnangle) * (alt - turnstart) / (turnend - turnstart)).

SET apoapsis_setpoint TO 40.
//SET Kp TO 0.125.
//SET Ki TO 0.101.
//SET Kd TO 0.025.
SET Kp TO 0.156.
SET Ki TO 0.101.
SET Kd TO 0.060.
SET PID TO PIDLOOP(Kp,Ki,Kd).
SET PID:SETPOINT TO apoapsis_setpoint.

// ========================================================================

if flightphase = 0 {
	phaseshift(0).
	sas off.
	lock steering to lookdirup(heading(90,90):vector, ship:facing:topvector).

	stage.
	wait 1.
	set thrott to 1.
	wait 0.1.
	stage.
	wait until ship:airspeed > 5.
	phaseshift(1).
}

until flightphase > 6 {
	readout().
	stageMonitor().
	if flightphase = 1 {
		if ship:airspeed > turnspeed {
			lock steering to lookdirup(heading(90,90-turnangle-pitch):vector, ship:facing:topvector).
			phaseshift(2).
		}
	}
	if flightphase = 2 {
		if ttap >= 40 {
			unlock steering.
			sas on.
			wait 0.5.
			set sasmode to "prograde".
			phaseshift(3).
		}
	}
	if flightphase = 3 {
//		log "prepid	" + time:seconds + "	" + thrott to logfile.
		set thrott to thrott + pid:update(time:seconds,ttap).
//		log "postpid	" + time:seconds + "	" + thrott to logfile.
		if alt >= turnend {
			phaseshift(4).
		}
	}
	if flightphase = 4 {
		if orbit:apoapsis > targetorbit {
			set thrott to 0.
			phaseshift(5).
		}
	}
	if flightphase = 5 {
		if alt > 55000 {
			set warp to 0.
			wait 0.5.
			AG10 on.  // requires action group be defined ahead of time
			phaseshift(6).
		}
	}
	if flightphase = 6 {
		if alt > 70000 {
			phaseshift(7).
		}
	}
	if flightphase = 7 {
		until orbit:apoapsis >= targetorbit {
			set thrott to 0.1/maxTWR().
		}
		set thrott to 0.
		set ship:control:pilotmainthrottle to 0.
		unlock throttle.
		set sasmode to "stability".
		wait 5.
		sas off.
	}
}

// circularization goes here
// likely invocation: runpath("circularize.ks", finalorbit).
//		  or maybe: run "circularize.ks"(finalorbit).

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

declare function readout {
	local lineout is 1.
	local output is list().

//	output:add("STEERING @ " + round(90-turnangle-pitch,2)).
	output:add("THROTTLE = " + round(thrott,3)).
	output:add("MAXTHRST = " + round(ship:maxthrust,3)).
	output:add("  MAXTWR = " + round(maxTWR(),3)).
	output:add(" STAGEDV = " + round(stageDV(),3)).
	output:add(" STAGELF = " + stage:liquidfuel).
	output:add(" STAGESF = " + stage:solidfuel).
	
	for line in output {
		print line + "    " at (1,lineout).
		set lineout to lineout + 1.
	}
}

declare function maxTWR {
	set r to ship:altitude + ship:body:radius.
	set w to ship:mass * ship:body:mu / r / r.
	return ship:maxthrust / w.
}

declare function stageMonitor {
	// credit: https://www.reddit.com/r/Kos/comments/31x3o8/kos_launch_script_works_with_any_staging_to_any/
	if maxthrust = 0 {
		stage.
	}
	SET numOut to 0.
	LIST ENGINES IN engines. 
	FOR eng IN engines {
		IF eng:FLAMEOUT {
			SET numOut TO numOut + 1.
		}
	}
	if numOut > 0 {
		stage.
	}
}

declare FUNCTION stageDV {   
	// credit: https://www.reddit.com/r/Kos/comments/330yir/calculating_stage_deltav/cqi3jdf
	// fuel name list
	LOCAL fuels IS list().
	fuels:ADD("LiquidFuel").
	fuels:ADD("Oxidizer").
	fuels:ADD("SolidFuel").
	fuels:ADD("MonoPropellant").

	// fuel density list (order must match name list)
	LOCAL fuelsDensity IS list().
	fuelsDensity:ADD(0.005).
	fuelsDensity:ADD(0.005).
	fuelsDensity:ADD(0.0075).
	fuelsDensity:ADD(0.004).

	// initialize fuel mass sums
	LOCAL fuelMass IS 0.

	// calculate total fuel mass
	FOR r IN STAGE:RESOURCES {
		LOCAL iter is 0.
		FOR f in fuels {
			IF f = r:NAME {
				SET fuelMass TO fuelMass + fuelsDensity[iter]*r:AMOUNT.
			}.
			SET iter TO iter+1.
		}.
	}.  

	// thrust weighted average isp
	LOCAL thrustTotal IS 0.
	LOCAL mDotTotal IS 0.
	LIST ENGINES IN engList. 
	FOR eng in engList {
		IF eng:IGNITION {
			LOCAL t IS eng:maxthrust*eng:thrustlimit/100. // if multi-engine with different thrust limiters
			SET thrustTotal TO thrustTotal + t.
			IF eng:ISP = 0 SET mDotTotal TO 1. // shouldn't be possible, but ensure avoiding divide by 0
			ELSE SET mDotTotal TO mDotTotal + t / eng:ISP.
		}.
	}.
	IF mDotTotal = 0 LOCAL avgIsp IS 0.
	ELSE LOCAL avgIsp IS thrustTotal/mDotTotal.

	// deltaV calculation as Isp*g0*ln(m0/m1).
	LOCAL deltaV IS avgIsp*9.81*ln(SHIP:MASS / (SHIP:MASS-fuelMass)).

	RETURN deltaV.
}
