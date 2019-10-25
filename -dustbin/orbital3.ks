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

WHEN SHIP:APOAPSIS > 81000 THEN {
    LOCK THROTTLE TO 0.0.
    PRINT "Suborbital trajectory achieved!  APOAPSIS: " + round(SHIP:APOAPSIS).
    PRINT "Awaiting circularization burn.".
    PRINT " ".
}

WAIT UNTIL SHIP:ALTITUDE > 70000.

PRINT "Orbital probe has left the atmosphere!".
TOGGLE AG1.  //discard fairings
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