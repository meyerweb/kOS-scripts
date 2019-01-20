clearscreen.

DECLARE PARAMETER tgt_alt_KM.
local statusMsg to "".

SET tgt_alt TO tgt_alt_KM * 1000.

lock throttle to 1.0.

WHEN MAXTHRUST = 0 THEN {
  STAGE.
  IF STAGE:NUMBER > 0
    PRESERVE.
}

function panel_off_trigger {
  WHEN ship:altitude < body:atm:height THEN {
    PANELS OFF.
    panel_on_trigger().
  }
}

function panel_on_trigger {
  WHEN ship:altitude > body:atm:height THEN {
    PANELS ON.
    panel_off_trigger().
  }
}

panel_on_trigger().

function current_thrust {
  SET t TO 0.
  LIST ENGINES IN l.
  FOR e IN l
    IF e:IGNITION SET t TO t+e:THRUST.
  RETURN t.
}

LOCAL lastTime TO TIME.
//LOCAL airDragLoss = 0.
LOCAL gDragLoss TO 0.
LOCAL vDragLoss TO 0.
LOCAL dvBurn TO 0.

SET CONFIG:IPU TO 2000.

SET max_Q TO SHIP:Q.

LOCAL dt TO 0.

WHEN lastTime <> TIME THEN {
  SET dt TO (TIME - lastTime):seconds.
  SET lastTime to TIME.
  IF SHIP:PARTSNAMED("sensorGravimeter"):LENGTH > 0 {
    SET gDrag TO VDOT(SHIP:SENSORS:GRAV, -VELOCITY:ORBIT:NORMALIZED).
    SET gDragLoss TO gDragLoss + gDrag * dt.
  } ELSE {
    SET gDrag TO "requires gravioli detector".
    SET gDragLoss TO "requires gravioli detector".
  }
  // FIXME: assuming thrust is backwards, no gimballing
  SET vDrag TO current_thrust * (1 + VDOT(-FACING:VECTOR:NORMALIZED, VELOCITY:ORBIT:NORMALIZED) ) / MASS.
  SET vDragLoss TO vDragLoss + vDrag * dt.
  SET max_Q TO MAX(max_Q, SHIP:Q).
  SET dvBurn TO dvBurn + current_thrust/MASS * dt.
  PRESERVE.
}

LOCAL lastDisplay TO TIME:SECONDS.

SET massStart TO MASS.

WHEN TIME:SECONDS - lastDisplay > 0.1 THEN {
  // easier to calculate this backwards
  LOCAL airDragLoss TO dvBurn - vDragLoss - gDragLoss - VELOCITY:ORBIT:MAG.
  LOCAL massFrac TO MASS / massStart * 100.
  PRINT "STATUS: " + statusMsg AT(0,0).
  PRINT "dT:                " + dt AT(0,1).
  PRINT "Q:                 " + SHIP:Q AT (0,2).
  PRINT "Max Q:             " + Max_Q AT (0,3).
  PRINT "Gravity Drag:      " + gDrag AT (0,4).
  PRINT "Vector Drag:       " + vDrag AT (0,5).
  PRINT "Gravity Drag Loss: " + gDragLoss AT (0,6).
  PRINT "Vector Drag Loss:  " + vDragLoss AT (0,7).
  PRINT "Air Drag Loss:     " + airDragLoss at (0,8).
  PRINT "DELTA-V Burned:    " + dvBurn AT(0,9).
  PRINT "Payload Fraction:  " + massFrac AT (0,10).
  SET lastDisplay TO TIME:SECONDS.
  PRESERVE.
}

set statusMsg to "Takeoff burn.".

SET TWR TO 2.8.

//SET startSpeed TO MIN(100, MAX(10, 100 - ( TWR - 1.2 ) * 30 )).
//SET startTurn TO MIN(80, MAX(10, 10 + ( TWR - 1.2 ) * 1 )).

SET startSpeed TO 50.
SET startTurn TO 17.

UNTIL VELOCITY:SURFACE:MAG > StartSpeed
  LOCK STEERING TO HEADING(90,90).

set statusMsg to "Initiating Gravity Turn.".

LOCK STEERING TO HEADING(90,90-startTurn).

WAIT UNTIL VANG(FACING:VECTOR,VELOCITY:SURFACE) > 2.

WAIT UNTIL VANG(FACING:VECTOR,VELOCITY:SURFACE) < 1.

set statusMsg to "Following Gravity Turn, APTime = 40s".

LOCK STEERING TO VELOCITY:SURFACE.

//SET end_surface to FALSE.

LOCK end_surface TO ((SHIP:Q * CONSTANT:AtmToKpa) < 2.5) AND (SHIP:Q < (max_Q / 2)).

WHEN end_surface THEN {
  LOCK STEERING TO PROGRADE.
}

LOCK THROTTLE TO th.

SET Kp TO 0.1.
SET Ki TO 0.01.
SET Kd TO 0.05.

SET th TO 1.
SET t0 TO TIME:SECONDS.
LOCK P TO 40 - ETA:APOAPSIS.
SET I TO 0.
SET P0 TO P.
LOCK dth TO Kp * P + Ki * I + Kd * D.

UNTIL SHIP:APOAPSIS > tgt_alt {
  LOCAL dt TO TIME:SECONDS - t0.
  IF dt > 0 {
    IF ETA:APOAPSIS > ETA:PERIAPSIS
      SET P TO 40.
    ELSE
      SET P TO 40 - ETA:APOAPSIS.
    IF ABS(P) < 2
      SET I TO I + P * dt.
    ELSE
      SET I TO 0.
    SET D TO (P - P0) / dt.
    SET th TO MIN(1, MAX(0.2, th + dth)).
    PRINT "P: " + P AT (0,12).
    PRINT "I: " + I AT (0,13).
    PRINT "D: " + D AT (0,14).
    SET t0 TO TIME:SECONDS.
    SET P0 TO P.
  }
  WAIT 0.001.
}

// set statusMsg to "Burning AP to target altitude".

// GT seems to leave the throttle where it last was?
// WAIT UNTIL SHIP:APOAPSIS > tgt_alt.

set statusMsg to "Coasting to edge of atmosphere.".

function check_apoapsis {
  IF SHIP:APOAPSIS < tgt_alt {
    SET WARP TO 0.
    WAIT 1.
    UNTIL SHIP:APOAPSIS > tgt_alt
      LOCK THROTTLE TO 0.05.
  }
  LOCK THROTTLE TO 0.
}

function coast_to_atmosphere {
  LOCK THROTTLE TO 0.

  LOCK STEERING TO PROGRADE.
  WAIT UNTIL VANG(FACING:VECTOR,PROGRADE:FOREVECTOR) < 1.

  SET WARPMODE TO "physics".

  UNTIL SHIP:ALTITUDE > BODY:ATM:HEIGHT {
    check_apoapsis().
    SET WARP TO 3.
    WAIT 1.
  }

  SET WARP TO 0.
  WAIT 3.

  check_apoapsis().
}

coast_to_atmosphere().

set statusMsg to "Coasting to circularization burn.".

set Vtgt to sqrt(body:mu/(body:radius + tgt_alt)).
set Vapo to velocityat(ship, time+eta:apoapsis).
set circ to node(time:seconds+eta:apoapsis,0,0,Vtgt-Vapo:ORBIT:MAG).

add circ.

lock steering to circ:DELTAV.

wait until vang(facing:vector,circ:DELTAV) < 1.

// return ISP + thrust of active engines
function engSum {
  LOCAL m IS 0.
  LOCAL t IS 0.
  LIST ENGINES IN l.
  FOR e IN l
    IF e:IGNITION {
      LOCAL th IS e:MAXTHRUST*e:THRUSTLIMIT/100.
      SET t to t + th.
      IF e:VISP = 0
        SET m TO 1.
      ELSE
        SET m to m+th/e:VISP.
    }
  IF m = 0
    RETURN list(0, 0).
  ELSE
    RETURN list(t/m, t).
}

function burntime {
  SET res TO engSum().
  SET ve TO res[0] * 9.8.
  SET maxthr TO res[1].
  RETURN ((MASS*ve)/maxthr)*(1-CONSTANT:E^(-(NEXTNODE:DELTAV:MAG/ve))).
}

SET bt TO burntime().

set warpmode to "rails".
SET WARP TO 2.

wait until eta:apoapsis < bt / 2 + 10.

set warp to 0.

set statusMsg to "Waiting for circularization burn.".

wait until eta:apoapsis < bt / 2.

set statusMsg to "Executing circularization burn.".

lock throttle to 1.

until circ:DELTAV:MAG < 0.01 {
  if vang(ship:facing:vector,circ:DELTAV) > 1 {
    lock throttle to 0.
  } else {
    // FIXME: should scale throttle by TWR
    lock throttle to max(0,min(1,circ:DELTAV:MAG/50)).
  }
}

remove circ.

set ship:control:pilotmainthrottle to 0.
unlock steering.
unlock throttle.
sas on.