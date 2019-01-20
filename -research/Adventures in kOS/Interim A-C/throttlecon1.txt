CLEARSCREEN.

LOCK THROTTLE TO 1.0.
LOCK STEERING TO HEADING (0,90).
WAIT 2.
STAGE.
PRINT "LIFTOFF!!".
PRINT " ".

LIST ENGINES IN MyLIST.

	FOR eng IN MyList 
	{
		SET tmax to eng:maxthrust.
	}

UNTIL SHIP:LIQUIDFUEL < 0.1
{
	IF SHIP:VERTICALSPEED > 50
	{
		SET g to KERBIN:MU / ((KERBIN:RADIUS + SHIP:ALTITUDE)*(KERBIN:RADIUS + SHIP:ALTITUDE)).
		SET t to 2*(SHIP:MASS*g).		//Change 2 to desired TWR
		LOCK THROTTLE TO t/tmax.
		SET twr to t/(SHIP:MASS*g).
		PRINT "maxthrust = " + round(tmax) + ", thrust = " + round(t) + ", TWR = " + round(twr,2) + ", Throttle = " + round(throttle,2).
		PRINT " ".
	}
}

WAIT 5.