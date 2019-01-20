declare parameter targetAp is -1.
declare parameter targetPe is -1.

clearscreen.

if targetAp = -1 set targetAp to orbit:apoapsis.

if targetAp > -1 {
	run once "orbital_mechanics.ks".

	if targetPe = -1 set targetPe to TargetAp.
	if orbit:periapsis < body:atm:height and orbit:apoapsis < targetAp {
		print "First we must clear the atmosphere!".
		setApoNode(body:atm:height+1000).
	}

	setApoNode(targetPe).
	executeBurn().
	setPeriNode(targetAp).
	executeBurn().

//	readout().

} else {
	print "Invalid orbital parameter supplied; aborting.".
}

// =================================================================== \\


declare function setApoNode {
	local parameter targPeAlt is -1.
	local endTA is 180.
	print targPeAlt.
	
	if targPeAlt > orbit:apoapsis {
		set endTA to 0.
		print "Apoapsis node flip.".
	}
	local dV is getDeltaV(
		orbit:apoapsis, orbit:periapsis, 180,
		orbit:apoapsis, targPeAlt,       endTA).
	print dV.
	SET apoNode to NODE(TIME:SECONDS + ETA:APOAPSIS,0,0,dV).
	ADD apoNode.
}

declare function setPeriNode {
	local parameter targApAlt is -1.
	local endTA is 0.
	print targApAlt.

	if targApAlt < orbit:periapsis {
		set endTA to 180.
		print "Periapsis node flip.".
	}
	local dV is getDeltaV(
		orbit:apoapsis, orbit:periapsis, 0,
		targApAlt,      orbit:periapsis, endTA).
	print dV.
	SET periNode to NODE(TIME:SECONDS + ETA:PERIAPSIS,0,0,dV).
	ADD periNode.
}

declare function getDeltaV {
	local parameter Ap is 0.
	local parameter Pe is 0.
	local parameter TA is 0.
	local parameter targAp is 0.
	local parameter targPe is 0.
	local parameter targTA is 0.
	
	if Ap = 0 set Ap to orbit:apoapsis.
	if Pe = 0 set Pe to orbit:periapsis.
	
	local sma0 is findSMA(Ap,Pe).
	local ecc0 is findEcc(Ap,Pe).

	local sma1 is findSMA(targAp,targPe).
	local ecc1 is findEcc(targAp,targPe).

	local dv0 is findVelatTA(TA,sma0,ecc0).
	local dv1 is findVelatTA(targTA,sma1,ecc1).

	return dv1 - dv0.
}

declare function executeBurn {
	local node is nextnode.
	local dv is node:deltav:mag.

	local thrscale is 1.
	local acceleration is (availablethrust / mass).
	local burntime is (dv / acceleration).
	print burntime.
	if (burntime < 2) {
		set thrscale to burntime / 2.
		set acceleration to ((availablethrust*thrscale)/mass).
		set burntime to (dv/acceleration).	
	}
	print burntime.
	print thrscale.
	local starttime is (burntime / 2).

	wait until node:eta <= starttime + 40.
	set warp to 0.
	wait 3.
	sas on.
	wait 5.
	set sasmode to "MANEUVER".

	wait until node:eta <= starttime.
	local burnstart is TIME:SECONDS.
	set ship:control:pilotmainthrottle to thrscale.

	// need a better routine, one that checks both time and altitude difference (or eccentricity?)

	wait until time:seconds - burnstart >= burntime.
	set ship:control:pilotmainthrottle to 0.

	wait 2.
	set sasmode to "STABILITYASSIST".
	remove node.
	wait 1.
	sas off.
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
