CLEARSCREEN.
SET IPU0 TO CONFIG:IPU.
SET CONFIG:IPU TO 300.
SET TERMINAL:REVERSE TO TRUE.
SET TERMINAL:WIDTH TO 50.
SET TERMINAL:HEIGHT TO 15.

// ========================================================================

set stagelist to 0.
FOR p in SHIP:PARTS {
	if p:STAGE > stagelist SET stagelist TO stagelist + 1.
}

set clampstage to stagelist - 1.
SET launchClampStage to -1.
// print "stages: " + stagelist.
// print "clampstage: " + clampstage.

for c in ship:partsdubbed("launchClamp1") {
	IF launchClampStage = -1 {
		SET launchClampStage TO c:STAGE.
	} ELSE IF c:STAGE = launchClampStage {
		SET launchClampStage TO c:STAGE.
	}	
}

// print "launchclampstage: " + launchclampstage.

IF launchClampStage <> clampstage {
	PRINT "SCRIPT REQUIRES ALL LAUNCH CLAMPS IN STAGE " + clampStage.
	PRINT " ".
	PRINT "Use ctrl+c to cancel program and try again".
	PRINT " ".
	WAIT UNTIL FALSE.			
}.

DECLARE TURNSPEED TO 80.
DECLARE TURNANGLE TO 10.
DECLARE TURNSTART TO 0.
DECLARE TURNEND TO 40000.
DECLARE TARGETORBIT TO 80000.
DECLARE PITCH TO 90.

LOCK AIRSPD TO SHIP:AIRSPEED.
// LOCK ORBSPD TO SHIP:VELOCITY:ORBIT:MAG.
LOCK ALT TO SHIP:ALTITUDE.
LOCK TTA TO ETA:APOAPSIS.
LOCK PITCH TO ((90 - TURNANGLE) * (ALT - TURNSTART) / (TURNEND - TURNSTART)).

DECLARE PHASE TO 0.
// 0 - preflight
// 1 - climb
// 2 - turn
// 3 - throttle control
// 4 - level off
// 5 - in space
// 6 - final orbit

SAS OFF.
LOCK STEERING TO lookdirup(heading(90,90):vector, ship:facing:topvector).
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 1.

PHASESHIFT(0).
STAGE.
WAIT 1.
STAGE.
WAIT UNTIL AIRSPD > 3.
PHASESHIFT(1).


// ========================================================================

WHEN PHASE = 2 THEN {
//	IF PHASE = 2 {PRESERVE.}
	PRESERVE.
	LOCK STEERING TO lookdirup(heading(90,90-TURNANGLE-PITCH):vector, ship:facing:topvector).
	PRINT "STEERING @ " + ROUND(90-TURNANGLE-PITCH,2) AT(2,1).
}


SET apoapsis_setpoint TO 40.
SET Kp TO 0.156.
SET Ki TO 0.101.
SET Kd TO 0.060.
SET PID TO PIDLOOP(Kp,Ki,Kd).
SET PID:SETPOINT TO apoapsis_setpoint.

SET thrott TO 1.
LOCK THROTTLE TO thrott.

WHEN PHASE = 3 THEN {
	PRESERVE.
	SET thrott TO thrott + PID:UPDATE(TIME:SECONDS,TTA).
}

WHEN PHASE < 5 THEN {
	PRESERVE.
	PRINT "THROTTLING @ " + ROUND(thrott,2) AT(2,2).
	PRINT "MAXAVALTHR @ " + ROUND(SHIP:AVAILABLETHRUST,2) AT(2,3).
	PRINT "         Q @ " + ROUND(SHIP:Q,5) AT(2,4).
	PRINT "    MAXTWR @ " + ROUND(ShipTWR("m"),2) AT(2,5).
	PRINT "       TWR @ " + ROUND(ShipTWR("c"),2) + "  " AT(2,6).
}


WAIT UNTIL AIRSPD >= TURNSPEED.
PHASESHIFT(2).
WAIT UNTIL TTA >= 40.
PHASESHIFT(3).
SAS ON.
WAIT 3.
SET SASMODE TO "PROGRADE".
WAIT UNTIL ALT >= TURNEND.
PHASESHIFT(4).


// ========================================================================

UNLOCK STEERING.
SAS ON.
WAIT 1.
SET SASMODE TO "PROGRADE".

WAIT UNTIL ORBIT:APOAPSIS > TARGETORBIT.
UNLOCK THROTTLE.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.


WAIT UNTIL ALT >= 70000.
PHASESHIFT(5).


// ========================================================================

// SET WARP TO 0.
WAIT 5.
AG10 ON.  // blow the fairing
UNTIL ORBIT:APOAPSIS >= TARGETORBIT {
	SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.05.
}
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
set sasmode to "STABILITY".
WAIT 5.
SAS OFF.

RUN c3.ks.

PHASESHIFT(6).

WAIT 10.

// ========================================================================

PRINT "ORBIT ACHIEVED.  SAS OFF.  HAPPY SPACEFARING!" AT(2,13).
SET CONFIG:IPU TO IPU0.
WAIT 0.5.
PRINT " ".

// ========================================================================

declare FUNCTION PHASESHIFT {
	PARAMETER VAL.
	
	CLEARSCREEN.
	PRINT "FLIGHT PHASE" AT(36,0).
	PRINT "1 2 3 4 5 6" AT(36,1).
	PRINT "*":PADLEFT(VAL*2) + " " AT(35,2).
	SET PHASE TO VAL.
}

declare function ShipTWR {
	parameter type.
	set mth to SHIP:MAXTHRUST.
	if type = "c" {
		set mth to mth * thrott.
	}
    set r to SHIP:ALTITUDE+SHIP:BODY:RADIUS.
    set w to SHIP:MASS * SHIP:BODY:MU / r / r.
    return mth/w.
}
