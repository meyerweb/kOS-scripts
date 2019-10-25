CLEARSCREEN.

DECLARE PARAMETER ttaparam.

SET TERMINAL:WIDTH TO 40.
SET TERMINAL:HEIGHT TO 30.
SET TERMINAL:REVERSE TO TRUE.

LOCK SALT TO SHIP:ALTITUDE.
LOCK TTA TO ETA:APOAPSIS.

LOCK STEERING TO HEADING(90,90).
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 1.
SET PID TO 0.

DECLARE T0 TO 0.
DECLARE T1 TO 0.
DECLARE DT0 TO 0.
DECLARE DT1 TO 0.

DECLARE TURNSTART TO 0.
DECLARE TURNEND TO 40000.
DECLARE ANGLE TO 90.
DECLARE IDEALTHROTTLE TO "---".

WAIT UNTIL SALT > 100.

SET apoapsis_setpoint TO 40.

LOCK P TO apoapsis_setpoint - TTA.
SET I TO 0.
SET D TO 0.
SET P0 TO P.

LOCK in_deadband TO ABS(P) < 0.01.

SET Kp TO 0.156.
SET Ki TO 0.101.
SET Kd TO 0.060.

LOCK dthrott TO Kp * P + Ki * I + Kd * D.

SET thrott TO 1.
//LOCK THROTTLE to thrott.

UNTIL TTA > ttaparam {
	READOUT(ANGLE).
}

WHEN TTA > ttaparam THEN {
	SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.5.
	SET PID TO 1.
}

SET t0 TO TIME:SECONDS.
UNTIL SHIP:ALTITUDE > 70000 AND PID > 0 {
	SET dt TO TIME:SECONDS - t0.
	IF dt > 0 {
		IF NOT in_deadband {
			SET I TO I + P * dt.
			SET D TO (P - P0) / dt.

			// If Ki is non-zero, then limit Ki*I to [-1,1]
			IF Ki > 0 {
				SET I TO MIN(1.0/Ki, MAX(-1.0/Ki, I)).
			}

			// set throttle but keep in range [0,1]
			SET SHIP:CONTROL:PILOTMAINTHROTTLE to MIN(1, MAX(0, thrott + dthrott)).

			SET P0 TO P.
			SET t0 TO TIME:SECONDS.
		}
	}
	READOUT(ANGLE).
	PRINT "PID" AT(34,2).
	WAIT 0.05.
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
	PRINT ttaparam AT(34,1).
	PRINT "ALT: " + ROUND(SHIP:ALTITUDE,2) + "m".
	PRINT "APO: " + ROUND(SHIP:APOAPSIS,2) + "m".
	PRINT "TTA: " + ROUND(TTA,2) + "s".
	PRINT "DTH: " + DTHROTT.
	PRINT "THR: " + ROUND(SHIP:CONTROL:PILOTMAINTHROTTLE,2).
	PRINT "VEL: " + ROUND(SHIP:AIRSPEED,2) + "m/s".
//	PRINT "VEL: " + ROUND(ORBIT:VELOCITY:ORBIT:MAG,3) + "m/s".
	PRINT "AGL: " + ROUND(ANGLE,3) + "deg".
	IF TURNSTART > 0 {PRINT "SLT: " + TURNSTART + "m".}
//	PRINT " ".
//	PRINT "MASS: " + ROUND(SHIP:MASS,3) + "mT".
//	DECLARE TTH TO 0.
//	LIST ENGINES IN ENGS.
//	FOR ENG IN ENGS {
//		SET TTH TO TTH + ENG:THRUST.
//	}
//	PRINT "TTH: " + ROUND(TTH,2) + "kN".
//	PRINT "TWR: " + ROUND(TTH / (MASS * 10), 2).
}

PRINT " ".
PRINT "SHIP HAS LEFT THE ATMOSPHERE!".
PRINT "CURRENT AP: " + ROUND(SHIP:APOAPSIS).
UNLOCK STEERING.