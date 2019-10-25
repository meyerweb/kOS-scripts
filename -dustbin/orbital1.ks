//Two stage - LF - orbital

CLEARSCREEN.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.  
//Thanks to Steven Mading on the KSP forum for this override of the default 50% throttle on launch

PRINT "------------------------------".
PRINT "INITIATING ORBITAL TEST LAUNCH".
PRINT "------------------------------".
PRINT " ".
WAIT 2.

//LAUNCH COUNTDOWN

PRINT "Beginning launch countdown:".
FROM {local countdown is 10.} UNTIL countdown = 5 STEP {SET countdown to countdown -1.} Do { PRINT countdown + "...".
WAIT 1.
}
LOCK THROTTLE TO 0.5.		//This is based on the TWR of the example craft
LOCK STEERING TO HEADING(0,90).
PRINT "5...All systems GO!".
WAIT 1.
FROM {local countdown is 4.} UNTIL countdown = 2 STEP {SET countdown to countdown -1.} Do { PRINT countdown + "...".
WAIT 1.
}
STAGE.  //Activate engine
PRINT "2...Main engine ignition!".
WAIT 1.
FROM {local countdown is 1.} UNTIL countdown = 0 STEP {SET countdown to countdown -1.} Do { PRINT countdown + "...".
WAIT 1.
}
STAGE.  //Release launch clamps
PRINT "Launch clamps disengaged.  We have liftoff!!!".
PRINT " ".
WAIT 5.
LOCK STEERING TO HEADING(90,90).

//Gravity turn
//5 degrees every 2 km from 2 km up to 45 degree pitch at 20 km
//10 degrees every 5 km to 5 degrees above horizon at 40 km
//Throttle constant (see above)

WHEN SHIP:ALTITUDE > 2000 THEN {
    PRINT "Commencing gravity turn.".
    PRINT "...Pitching 5 degrees East".
    LOCK STEERING TO HEADING(90,85).
}
WHEN SHIP:ALTITUDE > 4000 THEN {
    PRINT "...Pitching 10 degrees East".
    LOCK STEERING TO HEADING(90,80).
}
WHEN SHIP:ALTITUDE > 6000 THEN {
    PRINT "...Pitching 15 degrees East".
    LOCK STEERING TO HEADING(90,75).
}
WHEN SHIP:ALTITUDE > 8000 THEN {
    PRINT "...Pitching 20 degrees East".
    LOCK STEERING TO HEADING(90,70).
    }
WHEN SHIP:ALTITUDE > 10000 THEN {
    PRINT "...Pitching 22.5 degrees East".
    LOCK STEERING TO HEADING(90,67.5).
}
WHEN SHIP:ALTITUDE > 12000 THEN {
    PRINT "...Pitching 25 degrees East".
    LOCK STEERING TO HEADING(90,65).
}
WHEN SHIP:ALTITUDE > 14000 THEN {
    PRINT "...Pitching 30 degrees East".
    LOCK STEERING TO HEADING(90,60).
}
WHEN SHIP:ALTITUDE > 16000 THEN {
    PRINT "...Pitching 35 degrees East".
    LOCK STEERING TO HEADING(90,55).
}
WHEN SHIP:ALTITUDE > 18000 THEN {
    PRINT "...Pitching 40 degrees East".
    LOCK STEERING TO HEADING(90,50).
}
WHEN SHIP:ALTITUDE > 20000 THEN {
    PRINT "...Pitching 45 degrees East".
    LOCK STEERING TO HEADING(90,45). 
}
WHEN SHIP:ALTITUDE > 25000 THEN {
    PRINT "...Pitching 55 degrees East".
    LOCK STEERING TO HEADING(90,35).
}
WHEN SHIP:ALTITUDE > 30000 THEN {
    PRINT "...Pitching 65 degrees East".
    LOCK STEERING TO HEADING(90,25).
}
WHEN SHIP:ALTITUDE > 35000 THEN {
    PRINT "...Pitching 75 degrees East".
    LOCK STEERING TO HEADING(90,15).
}
WHEN SHIP:ALTITUDE > 45000 THEN {
    PRINT "...Orienting to horizon".
    PRINT " ".
    LOCK STEERING TO HEADING(90,0).
}
WHEN SHIP:APOAPSIS > 81000 THEN {
    LOCK THROTTLE TO 0.0.
    PRINT "Suborbital trajectory achieved!  APOAPSIS: " + round(SHIP:APOAPSIS).
    PRINT "Awaiting circularization burn.".
    PRINT " ".
}

//Staging

WAIT UNTIL SHIP:LIQUIDFUEL < 90.1.

    PRINT " ".
    PRINT "...Stage 1 exhausted, activating Stage 2.".
    LOCK THROTTLE TO 0.0.
    WAIT 0.5.
    STAGE.
    PRINT "...Stage 1 separation complete.".
    WAIT 0.5.
    LOCK THROTTLE TO 0.6.
    WAIT 0.5.
    STAGE.
    PRINT "...2nd stage ignition successful!". 
    PRINT " ".


//Coast to AP

WAIT UNTIL SHIP:ALTITUDE > 70000.

PRINT "Orbital probe has left the atmosphere!".
TOGGLE AG9.  //discard fairings
PRINT "Protective fairing jettisoned.".
PRINT " ".
PRINT "Current AP: " + round(SHIP:APOAPSIS).
PRINT " ".

UNTIL round(ETA:APOAPSIS) < 15
{
    WAIT 10.
    PRINT "ALTITUDE: " + round(SHIP:ALTITUDE).
    PRINT "ETA to AP: " + round(ETA:APOAPSIS).
    PRINT " ".
}

//Orbital insertion

WAIT UNTIL SHIP:ALTITUDE > 70000 AND round(ETA:APOAPSIS)  < 8.		
//Burning prograde gives highly elliptic orbit if timing is off, used trial and error for the ETA
//Want to improve this method

LOCK STEERING TO HEADING(90,0).		
LOCK THROTTLE TO 1.0.
PRINT "Commencing orbital insertion burn.".

WAIT UNTIL SHIP:PERIAPSIS > 80000.
   
LOCK THROTTLE TO 0.0.
PRINT "Orbital insertion complete, orbit achieved!".
PRINT " ".
WAIT 5.
PRINT "Deploying probe.".
TOGGLE AG1. //Detach probe, extend antenna
WAIT 4.
PRINT "Probe successfully deployed in stable orbit.".
PRINT " ".
PRINT "Final Apoapsis: " + round(SHIP:APOAPSIS).
PRINT "ETA to AP: " + round(ETA:APOAPSIS).
PRINT " ".
PRINT "Final Periapsis: " + round(SHIP:PERIAPSIS).
PRINT "ETA to PE: " + round(ETA:PERIAPSIS).
PRINT " ".
WAIT 1.
UNLOCK STEERING.

WAIT 2.
UNTIL SHIP:ELECTRICCHARGE < 10
{
    SET WARP to 3.
}

SET WARP to 0.

PRINT "Probe batteries at critical level - entering hibernation.".
PRINT " ".
Wait 1.
PRINT "Transmission ended.".
PRINT " ".

SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0. 

WAIT 2.

PRINT "----------------------".
PRINT "Mission accomplished!!".  
PRINT "----------------------".  //end program