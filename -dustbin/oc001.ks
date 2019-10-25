clearscreen.
print "Circularizing...".

parameter targetAp is -1.
parameter targetPe is -1.

if targetAp > -1  {
	run once "orbital_mechanics.ks".

	if targetPe = -1 set targetPe to TargetAp.
	if orbit:periapsis < body:atm:height and orbit:apoapsis < targetAp {
		print "First we must clear the atmosphere!".
		executeManeuver(orbit:apoapsis, orbit:periapsis, orbit:apoapsis, body:atm:height+1000, 180).
	}

	local ta0 is 180.
	if targetPe > orbit:apoapsis {
		set ta0 to 0.
	}
	local ta1 is abs(180-ta0).

	executeManeuver(orbit:apoapsis,orbit:periapsis,orbit:apoapsis,targetPe,ta0).
	executeManeuver(orbit:apoapsis,orbit:periapsis,targetAp,orbit:periapsis,ta1).




//	set finalalt to 250000.  // 250 km
//
//	set paramsAP to list(
//		list(apo0,peri0,apo0,finalalt,180),
//		list(finalalt,apo0,finalalt,finalalt,180)
//	).
//
//	set paramsPA to list(
//		list(apo0,peri0,finalalt,peri0,0),
//		list(finalalt,peri0,finalalt,finalalt,180)
//	).
//
//	set changeAP1 to findDeltaV(paramsAP[0]).
//	set changeAP2 to findDeltaV(paramsAP[1]).
//	set changeAP to abs(changeAP1) + abs(changeAP2).
//
//	set changePA1 to findDeltaV(paramsPA[0]).
//	set changePA2 to findDeltaV(paramsPA[1]).
//	set changePA to abs(changePA1) + abs(changePA2).
//
//	readout().

}

declare function executeManeuver {

	local parameter Ap is -1.
	local parameter Pe is -1.
	local parameter targetAp is -1.
	local parameter targetPe is -1.
	local parameter TA is -1.
	
	local node is abs(TA-180).
	local dV is "???".

//	set dV to getDeltaV(Ap,Pe,targetAp,targetPe,TA).
	
	// set up maneuver node, burntime
	// wait for burn
	// burn
	// remove node

	print "Burn " + dV + "m/s at " + TA + "deg.".
	print " ".

}

declare function getDeltaV {
	parameter Ap is 0.
	parameter Pe is 0.
	parameter TA is 0.
	parameter targAp is 0.
	parameter targPe is 0.
	parameter targTA is 0.
	
	local sma0 is findSMA(Ap,Pe).
	local ecc0 is findEcc(Ap,Pe).

	local sma1 is findSMA(targetAp,targetPe).
	local ecc1 is findEcc(targetAp,targetPe).

	local dv0 is findVelatTA(TA,sma0,ecc0).
	local dv1 is findVelatTA(targTA,sma1,ecc1).

	print dv0.
	print dv1.

	return dv1 - dv0.
}

declare function findDeltaV {
	parameter params is list().
	
	local sma0 is findSMA(params[0],params[1]).
	local ecc0 is findEcc(params[0],params[1]).

	local sma1 is findSMA(params[2],params[3]).
	local ecc1 is findEcc(params[2],params[3]).

	local dv0 is findVelatTA(params[4],sma0,ecc0).
	local dv1 is findVelatTA(params[4],sma1,ecc1).

	return dv1 - dv0.
}

declare function readout {
	local lineout is 5.
	local output is list().

	output:add("altF " + round(finalalt,3) + " m"). // ~119m/s
	output:add( " " ).
	output:add(" AP1 " + round(changeAP1,3) + " m/s"). // ~119m/s
	output:add(" AP2 " + round(changeAP2,3) + " m/s").
	output:add("APdv " + round(changeAP,3) + " m/s").
	output:add( " " ).
	output:add(" PA1 " + round(changePA1,3) + " m/s"). // ~46m/s
	output:add(" PA2 " + round(changePA2,3) + " m/s").
	output:add("PAdv " + round(changePA,3) + " m/s").

	for line in output {
		print line + "    " at (1,lineout).
		set lineout to lineout + 1.
	}
}


