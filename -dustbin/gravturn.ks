CLEARSCREEN.

//Setup

SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.  			//Thanks to Steven Mading on the KSP forum for this override of the default 50% throttle on launch
SET twr to 1.6.							//Change as needed depending on vessel design
LIST ENGINES IN MyList.

PRINT "All systems go for launch!".
PRINT " ".
WAIT 2.

SET runmode to 1.

//Flight Control

UNTIL runmode = 0						//Runmode format based on code found at https://gist.github.com/KK4TEE/c41b4fb789a01cef6122
{
	FOR eng IN MyList 
	{
		IF eng:flameout
		{
			LOCK THROTTLE TO 0.
			LOCK STEERING TO SHIP:FACING.				//May not be needed depending on craft design
			PRINT "Decoupling Stage " + stage:number.
			PRINT " ".
			STAGE. 
			WAIT 1.

			STAGE.
			LIST ENGINES in MyList.
			PRINT "Stage " + stage:number + " activated!".
			PRINT " ".
			
			UNLOCK STEERING.	
		}
	}

	IF runmode = 1			//Launch Sequence
	{
		STAGE.
		FOR eng IN MyList 
		{
			SET tmax to eng:maxthrust.
		}
		SET g to KERBIN:MU / ((KERBIN:RADIUS + SHIP:ALTITUDE)*(KERBIN:RADIUS + SHIP:ALTITUDE)).
		SET t to twr*(SHIP:MASS*g).
		LOCK THROTTLE TO t/tmax.
		LOCK STEERING TO HEADING(0, 90).
		PRINT "Main engine ignition!".
		PRINT " ".
		WAIT 2.

		STAGE.
		PRINT "Launch clamps disengaged!".
		PRINT "WE HAVE LIFTOFF!!!".
		PRINT " ".
		WAIT 2.
		LOCK STEERING TO HEADING(90, 90).		//Potentially add a wait here for large vessels with less control authority (SAS/RCS)

		SET runmode to 2.
	}	

	ELSE IF runmode = 2		//Gravity turn
	{
		IF SHIP:VERTICALSPEED > 50			//Change as needed depending on vessel design
		{
			LOCK STEERING TO HEADING(90, 85).
			PRINT "Commencing gravity turn.".
			PRINT " ".			
			WAIT 3.

			UNLOCK STEERING.
		
			SET runmode to 3.
		}	
	}
	
	ELSE IF runmode = 3		//Throttle control
	{
		FOR eng IN MyList 
		{
			IF eng:ignition AND NOT eng:flameout	//Need this because stowed/flameout give maxthrust = 0
			{
				SET tmax to eng:maxthrust.
			}
		}		
		SET g to KERBIN:MU / ((KERBIN:RADIUS + SHIP:ALTITUDE)*(KERBIN:RADIUS + SHIP:ALTITUDE)).
		SET p to VECTORANGLE(ship:facing:vector, ship:up:vector).		//90-p = angle above horizon, p = angle from straight up; Formula from https://github.com/KSP-KOS/KOS/issues/664
		SET teff to twr*(SHIP:MASS*g).						
		SET t to teff / COS(p).
		LOCK THROTTLE TO t/tmax.		
											//Change as needed depending on vessel design (or omit??)
		WHEN SHIP:ALTITUDE > 12000 THEN						//11.5 km -> 0.1 atm
		{									
			SET twr to 1.3.
		}
		WHEN SHIP:ALTITUDE > 24000 THEN						//23 km -> 0.01 atm
		{
			SET twr to 1.0.
		}

		IF SHIP:APOAPSIS > 100000						
		{
			LOCK THROTTLE TO 0.
			LOCK STEERING TO PROGRADE.
			PRINT "Suborbital trajectory achieved.".
			PRINT "Current AP: " + round(SHIP:APOAPSIS).
			PRINT " ".

			SET runmode to 0.
		}
	}
}

SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
WAIT UNTIL SHIP:ALTITUDE > 70000.