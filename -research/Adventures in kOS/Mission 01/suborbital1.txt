//Single stage - Liquid Fueled Rocket - Suborbital
//Before iniation, press X so the engine isn't running when the program ends.

CLEARSCREEN.
LOCK THROTTLE TO 0.0.

PRINT "---------------------------------".
PRINT "INITIATING SUBORBITAL TEST LAUNCH".
PRINT "---------------------------------".
PRINT " ".
PRINT " ".
WAIT 2.

//LAUNCH COUNTDOWN

PRINT "Beginning launch countdown:".
FROM {local countdown is 10.} UNTIL countdown = 5 STEP {SET countdown to countdown -1.} Do { PRINT countdown + "...".
WAIT 1.
}
LOCK THROTTLE TO 0.4.  		//This is based on the TWR of the example craft
LOCK STEERING TO HEADING(0,90).	//Should maintain launchpad orientation; UP cause it to rotate 180 degrees
PRINT "5...All systems GO!".
WAIT 1.
FROM {local countdown is 4.} UNTIL countdown = 2 STEP {SET countdown to countdown -1.} Do { PRINT countdown + "...".
WAIT 1.
}
STAGE.  			//Activate engine
PRINT "2...Main engine ignition!".
WAIT 1.
FROM {local countdown is 1.} UNTIL countdown = 0 STEP {SET countdown to countdown -1.} Do { PRINT countdown + "...".
WAIT 1.
}
STAGE.  			//Release launch clamps
PRINT "....Launch clamps disengaged.".  
PRINT " ".
PRINT " ".
PRINT "WE HAVE LIFTOFF!!!".
PRINT " ".
PRINT " ".

//Gravity turn
//5 degrees every 2 km from 2 km up to 45 degree pitch at 20 km
//10 degrees every 5 km to 5 degrees above horizon at 40 km
//Throttle constant (see above)

WHEN SHIP:ALTITUDE > 2000 THEN {
    PRINT "Commencing gravity turn.".
    PRINT "...Pitching 5 degrees East.".
    LOCK STEERING TO HEADING(90,85).
}
WHEN SHIP:ALTITUDE > 4000 THEN {
    PRINT "...Pitching 10 degrees East.".
    LOCK STEERING TO HEADING(90,80).
}
WHEN SHIP:ALTITUDE > 6000 THEN {
    PRINT "...Pitching 15 degrees East.".
    LOCK STEERING TO HEADING(90,75).
}
WHEN SHIP:ALTITUDE > 8000 THEN {
    PRINT "...Pitching 20 degrees East.".
    LOCK STEERING TO HEADING(90,70).
    }
WHEN SHIP:ALTITUDE > 10000 THEN {
    PRINT "...Pitching 22.5 degrees East.".
    LOCK STEERING TO HEADING(90,67.5).
}
WHEN SHIP:ALTITUDE > 12000 THEN {
    PRINT "...Pitching 25 degrees East.".
    LOCK STEERING TO HEADING(90,65).
}
WHEN SHIP:ALTITUDE > 14000 THEN {
    PRINT "...Pitching 30 degrees East.".
    LOCK STEERING TO HEADING(90,60).
}
WHEN SHIP:ALTITUDE > 16000 THEN {
    PRINT "...Pitching 35 degrees East.".
    LOCK STEERING TO HEADING(90,55).
}
WHEN SHIP:ALTITUDE > 18000 THEN {
    PRINT "...Pitching 40 degrees East.".
    LOCK STEERING TO HEADING(90,50).
}
WHEN SHIP:ALTITUDE > 20000 THEN {
    PRINT "...Pitching 45 degrees East.".
    LOCK STEERING TO HEADING(90,45). 
}
WHEN SHIP:ALTITUDE > 25000 THEN {
    PRINT "...Pitching 55 degrees East.".
    LOCK STEERING TO HEADING(90,35).
}
WHEN SHIP:ALTITUDE > 30000 THEN {
    PRINT "...Pitching 65 degrees East.".
    LOCK STEERING TO HEADING(90,25).
}
WHEN SHIP:ALTITUDE > 35000 THEN {
    PRINT "...Pitching 75 degrees East.".
    LOCK STEERING TO HEADING(90,15).
}
WHEN SHIP:ALTITUDE > 40000 THEN {
    PRINT "...Orienting to horizon.".
    PRINT " ".
    STAGE.  //discard fairings
    PRINT "Protective fairing jettisoned.".
    PRINT " ".
    LOCK STEERING TO HEADING(90,0).
}
WHEN APOAPSIS > 80000 THEN {
    LOCK THROTTLE TO 0.0.
    PRINT "Suborbital trajectory achieved!  APOAPSIS: " + round(SHIP:APOAPSIS).
    PRINT " ".
}

//Coast to AP

WAIT UNTIL SHIP:ALTITUDE > 70000.

PRINT "Suborbital probe has left the atmosphere!".
PRINT " ".
PRINT "ALTITUDE: " + round(SHIP:ALTITUDE).
PRINT "APOAPSIS: " + round(SHIP:APOAPSIS).
PRINT " ".

WAIT 2.
PRINT "Deploying probe.". 	//No reaction wheels so it can't hold heading
PRINT " ".
STAGE.  			//decouple probe
TOGGLE AG1.  			//extend antennas
WAIT 4.
PRINT "BEEP...BEEP...BEEP".
PRINT " ".
WAIT 1.
PRINT "Probe successfully deployed and transmitting.".
PRINT " ".

UNTIL round(ETA:APOAPSIS) < 10
{
    WAIT 10.
    PRINT "ALTITUDE: " + round(SHIP:ALTITUDE).
    PRINT "ETA to AP: " + round(ETA:APOAPSIS).
    PRINT " ".
}
WHEN SHIP:VERTICALSPEED < 0 THEN {
    PRINT "Apoapsis reached, beginning descent.".
    PRINT " ".
}

UNTIL round(SHIP:ALTITUDE) < 70000
{
    WAIT 10.
    PRINT "ALTITUDE: " + round(SHIP:ALTITUDE).
    PRINT " ".
}
WHEN SHIP:ALTITUDE < 70000 THEN {
    PRINT "Suborbital probe has reentered the atmosphere!".
    PRINT " ".
}

WAIT 10.
PRINT "----------------------".
PRINT "Mission accomplished!!".  
PRINT "----------------------".  //end program