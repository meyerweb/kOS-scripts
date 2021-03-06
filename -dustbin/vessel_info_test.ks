declare function stageMonitor {
	// credit: https://www.reddit.com/r/Kos/comments/31x3o8/kos_launch_script_works_with_any_staging_to_any/
	if maxthrust = 0 {
		stage.
	}
	SET numOut to 0.
	LIST ENGINES IN engines. 
	FOR eng IN engines {
		IF eng:FLAMEOUT {
			SET numOut TO numOut + 1.
		}
	}
	if numOut > 0 {
		stage.
	}
}


declare function maxTWR {
	set r to ship:altitude + ship:body:radius.
	set w to ship:mass * ship:body:mu / r / r.
	return ship:maxthrust / w.
}


declare function stageDV {   
	// credit: https://www.reddit.com/r/Kos/comments/330yir/calculating_stage_deltav/cqi3jdf
	// fuel name list
	LOCAL fuels IS list().
	fuels:ADD("LiquidFuel").
	fuels:ADD("Oxidizer").
	fuels:ADD("SolidFuel").
	fuels:ADD("MonoPropellant").

	// fuel density list (order must match name list)
	LOCAL fuelsDensity IS list().
	fuelsDensity:ADD(0.005).
	fuelsDensity:ADD(0.005).
	fuelsDensity:ADD(0.0075).
	fuelsDensity:ADD(0.004).

	// initialize fuel mass sums
	LOCAL fuelMass IS 0.

	// calculate total fuel mass
//	print "resources = " + resources.
	print stage:number.
	list parts in partlist.
	for prt in partlist {
		print prt:stage + " - " + prt:title.
	}.
	FOR r IN STAGE:RESOURCES {
		LOCAL iter is 0.
		FOR f in fuels {
			IF f = r:NAME {
				SET fuelMass TO fuelMass + fuelsDensity[iter]*r:AMOUNT.
//				print "-+-".
//				print "r:n " + r:name.
//				print "r:a " + r:amount.
//				print "r:c " + r:capacity.
//				print "r:p " + r:parts.
//				print "fdi " + fuelsDensity[iter].
//				print "-/-".
			}.
			SET iter TO iter+1.
		}.
	}.  
	print fuelMass.
	// thrust weighted average isp
	LOCAL thrustTotal IS 0.
	LOCAL mDotTotal IS 0.
	LIST ENGINES IN engList.
	FOR eng in engList {
		IF eng:IGNITION {
			LOCAL t IS eng:maxthrust*eng:thrustlimit/100. // if multi-engine with different thrust limiters
			SET thrustTotal TO thrustTotal + t.
			IF eng:ISP = 0 SET mDotTotal TO 1. // shouldn't be possible, but ensure avoiding divide by 0
			ELSE SET mDotTotal TO mDotTotal + t / eng:ISP.
		}.
	}.
	IF mDotTotal = 0 LOCAL avgIsp IS 0.
	ELSE LOCAL avgIsp IS thrustTotal/mDotTotal.

	if (SHIP:MASS-fuelMass) <= 0 {
		errorreport("NaN condition: SM " + SHIP:MASS + "   FM " + fuelMass).
		return 0.
	}

	// deltaV calculation as Isp*g0*ln(m0/m1).
	LOCAL deltaV IS avgIsp*9.81*ln(SHIP:MASS / (SHIP:MASS-fuelMass)).

	RETURN deltaV.
}


declare function vesselDV {
	// NOT SURE THIS WORKS TBH
	// fuel name list
	LOCAL fuels IS list().
	fuels:ADD("LiquidFuel").
	fuels:ADD("Oxidizer").
	fuels:ADD("SolidFuel").
	fuels:ADD("MonoPropellant").

	// fuel density list (order must match name list)
	LOCAL fuelsDensity IS list().
	fuelsDensity:ADD(0.005).
	fuelsDensity:ADD(0.005).
	fuelsDensity:ADD(0.0075).
	fuelsDensity:ADD(0.004).

	// initialize fuel mass sums
	LOCAL fuelMass IS 0.

	// calculate total fuel mass
	FOR r IN SHIP:RESOURCES {
		LOCAL iter is 0.
		FOR f in fuels {
			IF f = r:NAME {
				SET fuelMass TO fuelMass + fuelsDensity[iter]*r:AMOUNT.
			}.
			SET iter TO iter+1.
		}.
	}.  

	// thrust weighted average isp
	LOCAL thrustTotal IS 0.
	LOCAL mDotTotal IS 0.
	LIST ENGINES IN engList. 
	FOR eng in engList {
		IF eng:IGNITION {
			LOCAL t IS eng:maxthrust*eng:thrustlimit/100. // if multi-engine with different thrust limiters
			SET thrustTotal TO thrustTotal + t.
			IF eng:ISP = 0 SET mDotTotal TO 1. // shouldn't be possible, but ensure avoiding divide by 0
			ELSE SET mDotTotal TO mDotTotal + t / eng:ISP.
		}.
	}.
	IF mDotTotal = 0 LOCAL avgIsp IS 0.
	ELSE LOCAL avgIsp IS thrustTotal/mDotTotal.

	if (SHIP:MASS-fuelMass) <= 0 {
		errorreport("NaN condition: SM " + SHIP:MASS + "   FM " + fuelMass).
		return 0.
	}

	// deltaV calculation as Isp*g0*ln(m0/m1).
	LOCAL deltaV IS avgIsp*9.81*ln(SHIP:MASS / (SHIP:MASS-fuelMass)).

	RETURN deltaV.
}





// ---------------------------------------------------------------------------------------------------------


declare function readout {
	parameter output is list().
	parameter row is 0.
	parameter col is 0.

	for line in output {
		print line + "    " at (col,row).
		set row to row + 1.
	}
}


declare function errorreport {
	parameter message is "Unknown error".
	local output is list().
	local lineout is 1.
	print " ".
	print " ".
	print " ".
	print " ".
	print " ".

	output:add("==================================").
	output:add("PRESS CTRL-C TO ABORT PROGRAM").
	output:add(message).
	output:add("SCRIPT TERMINATING ERROR").
	output:add("==================================").

	for line in output {
		print "   " + line + "   " at ((terminal:width - line:length)/2 - 3,terminal:height - lineout).
		set lineout to lineout + 1.
	}
	wait until false.
}
