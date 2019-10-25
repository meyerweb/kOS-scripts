// assume apoapsis for both altitude and TA if not supplied
parameter altitude is orbit:apoapsis.
parameter maneuverTA is 180.

run "orbital_mechanics.ks".




set thrott to 0.
lock throttle to thrott.	

set circvel to findVelAtTA(maneuverTA).
set apovel to findVelAtTA(maneuverTA, altitude + body:radius, 0).
set circdv to apovel-circvel.
set acceleration to (availablethrust / mass).
set burntime to (circdv / acceleration).
set starttime to (burntime / 2).
SET apoNode to NODE(TIME:SECONDS + ETA:APOAPSIS,0,0,circdv).
//WAIT UNTIL apoNode:ETA <= STARTTIME + 30.
ADD apoNode.

CLEARSCREEN.
PRINT " APO: " + ROUND(ORBIT:APOAPSIS,3) + "m" AT(2,1).
PRINT "PERI: " + ROUND(ORBIT:PERIAPSIS,3) + "m" AT(2,2).
PRINT "pAPO: " + ROUND(apoNode:ORBIT:APOAPSIS,3) + "m" AT(2,4).
PRINT "pPER: " + ROUND(apoNode:ORBIT:PERIAPSIS,3) + "m" AT(2,5).
PRINT "pAPD: " + ROUND(ABS(apoNode:ORBIT:PERIAPSIS - apoNode:ORBIT:APOAPSIS),3) + "m" AT(2,6).
PRINT "tBRN: " + ROUND(BURNTIME,3) + "s" AT(2,7).
PRINT " nDV: " + ROUND(apoNode:DELTAV:MAG,3) + "m/s" AT(2,8).
//PRINT "TSCL: " + ROUND(THRSCALE,3) + "m/s" AT(2,9).

SAS ON.
WAIT 0.5.
SET SASMODE TO "MANEUVER".

WAIT UNTIL apoNode:ETA <= STARTTIME.

SET burnstart to TIME:SECONDS.
set thrott to 1.

wait until TIME:SECONDS - burnstart >= burntime.

set thrott to 0.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
unlock throttle.

PRINT "fAPO: " + ROUND(ORBIT:APOAPSIS,3) + "m" AT(25,4).
PRINT "fPER: " + ROUND(ORBIT:PERIAPSIS,3) + "m" AT(25,5).
PRINT "fAPD: " + ROUND(ABS(ORBIT:PERIAPSIS - ORBIT:APOAPSIS),3) + "m" AT(25,6).
WAIT 30.

REMOVE apoNode.
SAS OFF.
