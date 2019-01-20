SET TERMINAL:WIDTH TO 40.
SET TERMINAL:HEIGHT TO 30.
SET TERMINAL:REVERSE TO TRUE.

LOCK SALT TO SHIP:ALTITUDE.
LOCK TTA TO ETA:APOAPSIS.

LOCK STEERING TO HEADING(90,90).
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 1.

DECLARE T0 TO 0.
DECLARE T1 TO 0.
DECLARE DT0 TO 0.
DECLARE DT1 TO 0.

DECLARE TURNSTART TO 0.
DECLARE TURNEND TO 40000.
DECLARE ANGLE TO 90.
DECLARE IDEALTHROTTLE TO "---".

UNTIL SHIP:AIRSPEED > 80 {
	THROTTLER().
	READOUT(ANGLE).
	WAIT 0.2.
}

SET TURNSTART TO ROUND(SALT,4).

UNTIL SALT > TURNEND {
	SET ANGLE TO 80 * (SALT - TURNSTART) / (TURNEND - TURNSTART).
	LOCK STEERING TO HEADING(90, 80-ANGLE).
	THROTTLER().
	READOUT(ANGLE).
	WAIT 0.2.
}

SAS ON.
WAIT 0.5.
UNLOCK STEERING.
WAIT 0.5.
SET SASMODE TO "PROGRADE".

CLEARSCREEN.
PRINT "LEVELED OUT".
WAIT 2.

UNTIL SALT > 70000 {
	READOUT(ANGLE).
	WAIT 0.2.
}

// =============================================================================

DECLARE FUNCTION THROTTLER {
//	SET DT0 TO ROUND((40 - ETA:APOAPSIS) * 10, 4).
//	SET DT1 TO ROUND((ETA:APOAPSIS - OLDTTA) * 100, 4).

	SET CHANGETHROTTLE TO 0.05 * (40 - TTA).
	SET NEWTHROTTLE TO SHIP:CONTROL:PILOTMAINTHROTTLE + CHANGETHROTTLE.
	SET IDEALTHROTTLE TO CHANGETHROTTLE.
	SET SHIP:CONTROL:PILOTMAINTHROTTLE TO NEWTHROTTLE.

//	SET OLDTTA TO ETA:APOAPSIS.
//	SET IDEALTHROTTLE TO NEWTHROTTLE.
//	SET SHIP:CONTROL:PILOTMAINTHROTTLE TO NEWTHROTTLE.

}

DECLARE FUNCTION READOUT {
	PARAMETER ANGLE.

	CLEARSCREEN.
	PRINT "--------------------".
	PRINT SHIP:NAME + " - " + SHIP:STATUS.
	PRINT "FLIGHT PARAMETERS".
	PRINT "--------------------".
//	PRINT T1 AT(34,0).
	PRINT "ALT: " + ROUND(SHIP:ALTITUDE,2) + "m".
	PRINT "APO: " + ROUND(SHIP:APOAPSIS,2) + "m".
	PRINT "TTA: " + ROUND(TTA,2) + "s".
	PRINT "ITH: " + IDEALTHROTTLE.
	PRINT "THR: " + ROUND(SHIP:CONTROL:PILOTMAINTHROTTLE,2).
	PRINT "VEL: " + ROUND(SHIP:AIRSPEED,2) + "m/s".
//	PRINT "VEL: " + ROUND(ORBIT:VELOCITY:ORBIT:MAG,3) + "m/s".
	PRINT "AGL: " + ROUND(ANGLE,3) + "deg".
	IF TURNSTART > 0 {PRINT "SLT: " + TURNSTART + "m".}
	PRINT " ".
	PRINT "MASS: " + ROUND(SHIP:MASS,3) + "mT".
	DECLARE TTH TO 0.
	LIST ENGINES IN ENGS.
	FOR ENG IN ENGS {
		SET TTH TO TTH + ENG:THRUST.
	}
	PRINT "TTH: " + ROUND(TTH,2) + "kN".
	PRINT "TWR: " + ROUND(TTH / (MASS * 10), 2).
}

PRINT " ".
PRINT "SHIP HAS LEFT THE ATMOSPHERE!".
PRINT "CURRENT AP: " + ROUND(SHIP:APOAPSIS).
UNLOCK STEERING.