CLEARSCREEN.
SET CONFIG:IPU TO 400.
SET TERMINAL:REVERSE TO TRUE.
// SET TERMINAL:WIDTH TO 40.
// SET TERMINAL:HEIGHT TO 20.

// ========================================================================

DECLARE TURNSPEED TO 80.
DECLARE TURNANGLE TO 10.
DECLARE TURNSTART TO 0.
DECLARE TURNEND TO 40000.
DECLARE TARGETAPO TO 80000.
DECLARE PITCH TO 90.

LOCK AIRSPD TO SHIP:AIRSPEED.
LOCK ORBSPD TO SHIP:VELOCITY:ORBIT:MAG.
LOCK ALT TO SHIP:ALTITUDE.
LOCK TTA TO ETA:APOAPSIS.

DECLARE PHASE TO 0.
// 0 - preflight
// 1 - climb
// 2 - turn
// 3 - throttle control
// 4 - level off
// 5 - in space
// 6 - final orbit

SAS ON.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 1.

PHASESHIFT(0).
WAIT UNTIL AIRSPD > 1.

// ========================================================================

WHEN AIRSPD > 3 		THEN {PHASESHIFT(1).}
WHEN AIRSPD >= TURNSPEED THEN {PHASESHIFT(2).}
WHEN TTA >= 40 		THEN {PHASESHIFT(3).}
WHEN ALT >= TURNEND 	THEN {PHASESHIFT(4).}
WHEN ALT >= 70000 		THEN {PHASESHIFT(5).}


// ========================================================================

SET apoapsis_setpoint TO 40.

LOCK P TO apoapsis_setpoint - TTA.
SET P0 TO P.
SET I TO 0.
SET D TO 0.
SET Kp TO 0.156.
SET Ki TO 0.101.
SET Kd TO 0.060.
LOCK in_deadband TO ABS(P) < 0.01.
LOCK dthrott TO Kp * P + Ki * I + Kd * D.
SET THROTT TO 0.

SET t0 TO TIME:SECONDS.

WHEN PHASE > 0 AND PHASE < 4 THEN {
	IF PHASE < 4 {PRESERVE.}
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
	PRINT "THROTTLING @ " + ROUND(T0,2) AT(2,2).
}

UNTIL PHASE = 4 {}.


// ========================================================================

WHEN PHASE = 4 THEN {
	// THROTTLE CONTROL TO KEEP APOAPSIS UP	
	IF PHASE = 4 {PRESERVE.}
}

WAIT 10.
SAS ON.
WAIT 0.5.
SET SASMODE TO "PROGRADE".

WHEN ORBIT:APOAPSIS > TARGETAPO THEN {
	SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
}

// ========================================================================

// phase 5 stuff here (orbit circularization)

UNTIL PHASE = 6 {}.


// ========================================================================

CLEARSCREEN.
PRINT "ORBIT ACHIEVED.  HAPPY SPACEFARING!" AT(3,3).


// ========================================================================

FUNCTION PHASESHIFT {
	PARAMETER VAL.
	
	CLEARSCREEN.
	PRINT "FLIGHT PHASE" AT(32,1).
	PRINT "*" AT(30+(VAL*2),2).
	PRINT "1 2 3 4 5 6" AT(32,3).
	SET PHASE TO VAL.
}
