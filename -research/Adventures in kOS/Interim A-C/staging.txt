CLEARSCREEN.

PRINT "Current stage: Stage " + stage:number.
PRINT " ".
LOCK THROTTLE TO 1.0.
LOCK STEERING TO HEADING (0,90).
WAIT 1.
STAGE.
PRINT "Stage " + stage:number + " activated.".
PRINT " ".
STAGE.
WAIT 2.
STAGE.
PRINT "Launching!".
PRINT " ".

UNTIL STAGE:NUMBER = 0
{
	LIST ENGINES IN MyList.
	FOR eng IN MyList 
	{
		IF eng:flameout
		{
			PRINT "Decoupling Stage " + stage:number.
			PRINT " ".
			STAGE. 
			WAIT 1.
			STAGE.
			PRINT "Stage " + stage:number + " activated!".
			WAIT 1.
		}

	}
	IF SHIP:APOAPSIS > 200000
	{
	BREAK.
	}
}