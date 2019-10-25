CLEARSCREEN.

SET IPU0 TO CONFIG:IPU.
SET CONFIG:IPU TO 300.
SET TERMINAL:REVERSE TO TRUE.
SET TERMINAL:WIDTH TO 50.
SET TERMINAL:HEIGHT TO 15.

SET THRSCALE TO 1.

SET GK TO 3.5316000*10^12.
SET RADIUS TO 600000 + ORBIT:APOAPSIS.
SET SMA TO 600000 + ((ORBIT:PERIAPSIS + ORBIT:APOAPSIS) / 2).
SET V1 TO (GK/RADIUS)^.5.
SET V2 TO (GK*((2/RADIUS)-(1/SMA)))^.5.
SET DV TO ABS(V1-V2).
SET ACCELERATION TO ((AVAILABLETHRUST*THRSCALE)/MASS).
SET BURNTIME TO (DV/ACCELERATION).
IF (BURNTIME < 3) AND (DV > 1) {
	SET THRSCALE TO BURNTIME / 3.
	SET ACCELERATION TO ((AVAILABLETHRUST*THRSCALE)/MASS).
	SET BURNTIME TO (DV/ACCELERATION).
}
SET STARTTIME TO (BURNTIME/2).
PRINT " APO: " + ROUND(ORBIT:APOAPSIS,3) + "m" AT(2,1).
PRINT "PERI: " + ROUND(ORBIT:PERIAPSIS,3) + "m" AT(2,2).
PRINT "BRNt: " + ROUND(BURNTIME,3) + "s" AT(2,7).
PRINT "  DV: " + ROUND(DV,3) + "m/s" AT(2,8).
PRINT "TSCL: " + ROUND(THRSCALE,3) AT(2,9).

//---

SET apoNode to NODE(TIME:SECONDS + ETA:APOAPSIS,0,0,DV).

// ---


WAIT UNTIL apoNode:ETA <= STARTTIME + 30.
CLEARSCREEN.

ADD apoNode.

PRINT " APO: " + ROUND(ORBIT:APOAPSIS,3) + "m" AT(2,1).
PRINT "PERI: " + ROUND(ORBIT:PERIAPSIS,3) + "m" AT(2,2).
PRINT "pAPO: " + ROUND(apoNode:ORBIT:APOAPSIS,3) + "m" AT(2,4).
PRINT "pPER: " + ROUND(apoNode:ORBIT:PERIAPSIS,3) + "m" AT(2,5).
PRINT "pAPD: " + ROUND(ABS(apoNode:ORBIT:PERIAPSIS - apoNode:ORBIT:APOAPSIS),3) + "m" AT(2,6).
PRINT "tBRN: " + ROUND(BURNTIME,3) + "s" AT(2,7).
PRINT " nDV: " + ROUND(apoNode:DELTAV:MAG,3) + "m/s" AT(2,8).
PRINT "TSCL: " + ROUND(THRSCALE,3) + "m/s" AT(2,9).

SAS ON.
WAIT 0.5.
SET SASMODE TO "MANEUVER".

WAIT UNTIL apoNode:ETA <= STARTTIME.

SET burnstart to TIME:SECONDS.

LOCK APDIFF TO ORBIT:APOAPSIS - ORBIT:PERIAPSIS.
LOCK ECC TO ORBIT:ECCENTRICITY.
SET OLDECC TO ECC.
LOCK ECCTHR TO (THRSCALE - (ECC * 300)).
SET INITAP TO ORBIT:APOAPSIS.

SET INTERVAL TO 0.1.
SET TLAPSE TO 0.
LOCK T to TIME:SECONDS.
SET OLDT TO T.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO THRSCALE.

SET CUTOFF TO 0.
UNTIL CUTOFF > 0 {
	IF ECCTHR > 0 {
		SET SHIP:CONTROL:PILOTMAINTHROTTLE TO (THRSCALE - ECCTHR).
	}
	IF (TLAPSE > INTERVAL) {
		IF OLDECC - ECC < 0 {
			SET CUTOFF TO 1.
		}
		IF (T - burnstart) > (BURNTIME * 2) {
			SET CUTOFF TO 2.
		}
		IF (ORBIT:APOAPSIS - INITAP) > (INITAP / 1000) {
			SET CUTOFF TO 3.
		}
// 		IF ORBIT:PERIAPSIS > 70000 {
// 			SET CUTOFF TO 0.
// 		}
		IF (T - burnstart) < (BURNTIME / 5) {
			SET CUTOFF TO 0.
		}
		SET OLDECC TO ECC.
		SET OLDT to T.
	}
	SET TLAPSE TO T - OLDT.
	PRINT " APD: " + ROUND(APDIFF,3) + "m   " AT(2,11).
	PRINT " ECC: " + ECC + "     " AT(2,12).
	PRINT "sECC: " + ECCTHR + "     " AT(2,13).
	PRINT "dECC: " + (OLDECC - ECC) + "     " AT(2,14).
}

SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.

PRINT "fAPO: " + ROUND(ORBIT:APOAPSIS,3) + "m" AT(25,4).
PRINT "fPER: " + ROUND(ORBIT:PERIAPSIS,3) + "m" AT(25,5).
PRINT "fAPD: " + ROUND(ABS(ORBIT:PERIAPSIS - ORBIT:APOAPSIS),3) + "m" AT(25,6).

PRINT " CTF: " + CUTOFF AT(25,8).

WAIT 30.

REMOVE apoNode.
SAS OFF.