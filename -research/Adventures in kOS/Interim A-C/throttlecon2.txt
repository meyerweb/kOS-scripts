CLEARSCREEN.

LOCK THROTTLE TO 1.0.
LOCK STEERING TO HEADING (0,90).
WAIT 2.
STAGE.
PRINT "LIFTOFF!!".
PRINT " ".

LIST ENGINES IN MyLIST.

UNTIL SHIP:LIQUIDFUEL < 0.1
{
	FOR eng IN MyList 
	{
		IF eng:flameout
		{
			PRINT "Decoupling Stage " + stage:number.
			PRINT " ".
			STAGE. 
			WAIT 1.
			STAGE.
			LIST ENGINES IN MyLIST.
			PRINT "Stage " + stage:number + " activated!".
			PRINT " ".
			WAIT 1.
		}
	}
	FOR eng IN MyLIST
	{
		SET tmax to eng:maxthrust.
		PRINT eng:name + ", " + round(eng:maxthrust).
		PRINT " ".
	}

	IF SHIP:VERTICALSPEED > 50
	{
		SET g to KERBIN:MU / ((KERBIN:RADIUS + SHIP:ALTITUDE)*(KERBIN:RADIUS + SHIP:ALTITUDE)).
		SET t to 2*(SHIP:MASS*g).		//Change 2 to desired TWR
		LOCK THROTTLE TO t/tmax.
		SET twr to t/(SHIP:MASS*g).
		PRINT "maxthrust = " + round(tmax) + ", thrust = " + round(t) + ", TWR = " + round(twr,2) + ", Throttle = " + round(throttle,2).
		PRINT " ".
		WAIT 1.
	}
}

WAIT 5.