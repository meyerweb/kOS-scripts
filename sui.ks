// https://www.reddit.com/r/Kos/comments/3mslqe/suicide_burn/

function getSurfaceAltitude {
	local radarAltitude to alt:radar.
	// radar altitude readings stop working after certain altitude
	// and instead return the altitude over sea level
	if ((radarAltitude + surfaceAltitude*0.5) > ship:altitude) {
		return radarAltitude - surfaceAltitude.
	}
	return radarAltitude.
}


clearscreen.

// draw the screen
print "Estimate".
print "========".
print "ALT:            [m]   Altitude of the estimation".
print "SPD:            [m/s] Speed after the free fall".
print "BSA:            [m]   Burn start altitude".
print " BT:            [s]   Burn time".
print "UPD:                  Estimate update count".
print " ".
print "Real".
print "====".
print "SPD:            [m/s] Speed after the free fall".
print "BSA:            [m]   Burn start altitude".
print "ERR:            [m]   Altitude error".
print " ".
print "Burn".
print "====".
print "ERR:            [%]   Acceleration error".
print "THR:            [%]   Throttle level".
print "BTR:            [s]   Burn time remaining".
print " ".
print "Landing".
print "====".
print "ALT:            [m]   Altitude from the ground".
print "SPD:            [m/s] Landing speed".



// landed altitude
set landedAltitude to alt:radar.
// surface altitude
set surfaceAltitude to ship:altitude.
// gravity acceleration at surface level
set surfGravityAcc to ship:sensors:grav:mag.

// launch
lock steering to up + R(0,0,180).
lock throttle to 1.
sas on.
stage.
gear off.

// gather stats from the ship
list engines in engineList.
set engine to engineList[0].
set engineCount to engineList:length.

// ascend for a while
wait 2.5.

// stop the engine
lock throttle to 0.

// wait until the ship is falling
set lastAltitude to ship:altitude.
until (ship:altitude < lastAltitude) {
	set lastAltitude to ship:altitude.
	wait 0.1.
}
wait 2.

set e to constant():e.
set freeFallDistance to 0.
set burnDistance to 0.
set lastBurnStartAltitude to 9999999.
set lastTotalDv to 99999.
set initialMass to ship:mass.
set updateCount to 0.
set totalError to 0.

// Iterative estimation of the burn distance.
// When the ship is close to the burn altitude it calculates everything all over again
// and gets a new estimate. If this new estimate is close enough to the previous one
// it assumes that the estimate is good enough and break the loop.
// This is useful when landing in a body with an atmosphere since the drag during the
// free fall makes the ship fall slower than it would in a vacuum, meaning that the first
// estimate calculated a longer burn than necessary
until false
{
	set currentAltitude to getSurfaceAltitude().
	print round(currentAltitude, 2) + "  " at (5, 2).
	set updateCount to updateCount + 1.
	print updateCount + "  " at (5, 6).
	set speedDv to ship:velocity:surface:mag.
	set error to 1.	// to enter the loop
	set ve to engine:isp * 9.82.
	set massFlowRate to (engine:availablethrust / ve) * engineCount.
	set gravityAcc to ship:sensors:grav:mag.
	// factor by which the gravity changes over distance
	set k to (surfGravityAcc - gravityAcc) / currentAltitude.

	// find the free fall distance
	until abs(error) < 0.1
	{
		// distance traveled while on free fall
		set freeFallDistance to currentAltitude + totalError.
		// speed at the end of the free fall
		// (it's a differential equation to take into account
		// the variations in the gravity acceleration over distance)
		set freeFallDv to sqrt(speedDv^2 + freeFallDistance*(freeFallDistance*k + 2*gravityAcc)).
		
		set deltaGravDv to 1.	// to enter the loop
		set gravDv to 0.
		// find the total Δv required to slow down the ship,
		// taking into account the speed gained during the burn
		// due to gravity
		until abs(deltaGravDv) < 0.1
		{
			set totalDv to freeFallDv + gravDv.
			set finalMass to initialMass / (e^(totalDv / ve)).
			set burnTime to (initialMass - finalMass) / massFlowRate.
			set deltaGravDv to (gravityAcc * burnTime) - gravDv.
			set gravDv to gravDv + deltaGravDv.
		}
		// the engines take a little while to thrust at full force
		set burnTimeEngine to burnTime-0.1.
		// find the distance traveled while burning
		// (since the ship acceleration is NOT constant it's not possible
		// to use the standard kinematic equations)
		set burnDistance to freeFallDv*burnTime
						  + (gravityAcc*burnTime^2) / 2
						  - (burnTimeEngine*ve - burnTimeEngine*ve*(ln(initialMass/finalMass)/(initialMass/finalMass-1))).
		// altitude error
		set error to currentAltitude - (freeFallDistance + burnDistance + landedAltitude).
		set totalError to totalError + (error * 0.8).	// the 0.8 makes it converge faster by eliminating overshoots
	}
	
	// altitude at which the burn should start
	set burnStartAltitude to burnDistance + landedAltitude.
	
	print round(freeFallDv, 3) + "   " at (5, 3).
	print round(burnStartAltitude, 2) + "   " at (5, 4).
	print round(burnTime, 3) + "   " at (5, 5).
	
	// break the loop when the current estimation is close enough to the previous one
	if ((lastTotalDv - totalDv) < 1) {
		break.
	}
	else {
		set lastTotalDv to totalDv.
	}
	
	// wait until the ship is close to the calculated burn start altitude
	wait until getSurfaceAltitude() < (burnStartAltitude + 50).
}

// Compensate for the fact that the game is a discrete time simulation.
// This ensures that the burn will always start as close as possible to the target,
// but without overshooting it.
// The simulation runs at approximately 25 ticks per second so the simulation step
// should be around 1/25 of the falling speed.
set simulationStep to 0.
set lastAltitude to ship:altitude.

until (getSurfaceAltitude() <= (burnStartAltitude + simulationStep*1.25))
{
	set simulationStep to lastAltitude - ship:altitude.
	set lastAltitude to ship:altitude.
	wait 0.01.
}

// Deploy the landing gear and other burn variables initialization
gear on.
set burnStartTime to time:seconds.
set correctionAcc to 0.

// Since the burn started a little too early to compensate for the simulation step
// the ship is a little higher than it should be, meaning that at the end of the
// burn it'll be higher than ground level.
set altitudeError to getSurfaceAltitude() - burnStartAltitude.
if (altitudeError > 0) {
	// prorrate the altitude error over the entire burn
	// as a little increase of the target acceleration
	// (it's an increase since the burn acceleration is negative)
	set altitudeErrorAcc to (2 * altitudeError) / burnTime^2.
	set correctionAcc to correctionAcc + altitudeErrorAcc.
}
// time of the burn
lock t to time:seconds - burnStartTime.
// During the burn a PI controller will try to keep the real acceleration
// as close to this target acceleration, that includes (in order):
// - Gravity acceleration
// - Engine acceleration (variable through time as the ship losses mass)
// - Correction acceleration (to correct the altitude error)
lock targetAcc to ship:sensors:grav:mag
			    - ((ve * massFlowRate) / (initialMass - massFlowRate*t))
				+ correctionAcc.

print round(ship:velocity:surface:mag, 3) + "   " at (5, 10).
print round(getSurfaceAltitude(), 2) + "   " at (5, 11).
print round(altitudeError, 2) + "   " at (5, 12).

// Start the burn, trying to keep the real acceleration close to the calculated one
// (this compensates for drag and other forces during the burn)
set newThrottle to 1.
lock throttle to newThrottle.

set kp to 1.
set ki to 0.1.
set errorAcu to 0.

until (time:seconds >= (burnStartTime + burnTime))
{
	// acceleration error, as a percentage
	set error to (abs(targetAcc) / ship:sensors:acc:mag) - 1.
	set newThrottle to 1 + kp*error + ki*errorAcu.
	// acumulate the error only if the throttle is within bounds
	if (newThrottle > 0 and newThrottle < 1) {
		set errorAcu to errorAcu + error.
	}
	else {
		// clamp the throttle to sane values
		if (newThrottle < 0) { set newThrottle to 0. }
		else if (newThrottle > 1) { set newThrottle to 1. }
	}
	// print some stats
	print round((error * 100), 2) + "   " at (5, 16).
	print round((newThrottle * 100), 2) + "   " at (5, 17).
	print round((burnTime-t), 3) + "     " at (5, 18).
	// wait until the next update
	wait 0.01.
}
// stop the burn
lock throttle to 0.

// speed and ground altitude after the burn
print round(alt:radar - landedAltitude, 2) + "   " at (5, 22).
print round(ship:velocity:surface:mag, 3) + "   " at (5, 23).

// if the ship is still to high then reduce the throttle to achieve a TWR of 0.98
// so it hits the ground a little less hard
if ((alt:radar - landedAltitude) > 5) {
	// wait a bit to gain some speed
	wait 0.25.
	set gravityAcc to ship:sensors:grav:mag.
	lock throttle to ((ship:mass * gravityAcc) / (engine:availablethrust * engineCount))*0.98.
	wait until (alt:radar - landedAltitude) < 1.
	// stop the burn
	lock throttle to 0.
}

// final speed and ground altitude
wait 0.01.
print round(alt:radar - landedAltitude, 2) + "   " at (5, 22).
print round(ship:velocity:surface:mag, 3) + "   " at (5, 23).

// allow the ship to land without SAS interfering
// (this is important when landing on a slight slope)
unlock steering.
wait until ship:status = "LANDED".
wait 1.
sas off.
wait 3.
sas on.