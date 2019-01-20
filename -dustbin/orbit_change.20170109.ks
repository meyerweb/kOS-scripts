
local parameter targetAp is -1.
local parameter targetPe is -1.

wait 1.
clearscreen.

run once "vessel_info.ks".


if targetAp = -1 set targetAp to orbit:apoapsis.

if targetAp > -1 {

	run once "orbital_mechanics.ks".

	if (targetAp < 100000) set targetAp to targetAp * 1000.
	if targetPe = -1 set targetPe to targetAp.
	if (targetPe < 100000) set targetPe to targetPe * 1000.

	print "orb:pe " + orbit:periapsis.
	print "b:a:h  " + body:atm:height.
	print "orb:ap " + orbit:apoapsis.
	print "trgAp  " + targetAp.
	
	if orbit:periapsis < body:atm:height and orbit:apoapsis < targetAp {
		print "First we must clear the atmosphere!".
		setNode(180,body:atm:height+1000).
		executeburn().
		print "Clear of the atmosphere.".
	}

	print "Starting node burns.".
	set burncount to 0.

	set burns to list(180,0).
	if targetPe > orbit:apoapsis set burns to list(0,180).

	until burncount >= 2 {
		if burns[burncount] = 0 set targetAlt to targetAp. else set targetAlt to targetPe.
		print "burn " + burncount.
		print " targetAp " + targetAp.
		print " targetPe " + targetPe.
		print "targetAlt " + targetAlt.
		setNode(burns[burncount],targetAlt).
		executeburn(targetAlt,burns[burncount]).
		set burncount to burncount + 1.
	}

//	showInfo().

} else {
	print "Invalid orbital parameter supplied; aborting.".
}




// =================================================================== \\


declare function setNode {
	local parameter burnTA is -1.
	local parameter targAlt is -1.

	local node1 is orbit:apoapsis.
	local node2 is orbit:periapsis.
	if burnTA = 0 set node1 to targAlt. else set node2 to targAlt.
	
	if burnTA > -1 {
		print "---------- setNode".
		local dV is getDeltaV(
			orbit:apoapsis, orbit:periapsis, burnTA,
			node1, node2, burnTA).
		print "burnTA " + burnTA.
		print "orb:ap " + orbit:apoapsis.
		print "orb:pe " + orbit:periapsis.
		print "node1  " + node1.
		print "node2  " + node2.
		print "dV     " + dV.
		SET node to NODE(TIME:SECONDS + findTimeBetweenTAs(burnTA),0,0,dV).
		ADD node.
		print "----------/setNode".
	}
}


declare function executeBurn {
	local parameter targetAlt is -1.
	local parameter orbitNode is -1.

	local dv is node:deltav:mag.
	local currentStageDV is stageDV().
	local currentShipDV is vesselDV().

	if currentStageDV < dv {
		stage.
	}
	wait 0.2.
	until maxthrust > 0 {
		stage.
		wait 0.2.
		print maxthrust.
	}
	
	set currentShipDV to vesselDV().
	set currentStageDV to stageDV().

	if currentShipDV < dv {
		errorreport("Insufficient dV to complete maneuver.").
	}

	print "---------- executeBurn".
	local thrscale is 1.
	local acceleration is (availablethrust / mass).
	local burntime is (dv / acceleration).
	print "burntime " + burntime.
	if (burntime < 2) {
		set thrscale to burntime / 2.
		set acceleration to ((availablethrust*thrscale)/mass).
		set burntime to (dv/acceleration).	
		print "burntime " + burntime + " (modified)".
	}
	print "thrscale " + thrscale.
	local starttime is (burntime / 2).

	wait until node:eta <= starttime + 40.
	set warp to 0.
	lock steering to node:burnvector.
	wait until node:eta <= starttime + 5.
	set warp to 0.
	
	lock throttle to thrott.
	set thrott to thrscale.

	wait until node:eta <= starttime.

	if targetAlt > -1 {
		set exit to false.
		if orbitNode = 0 lock currentAlt to orbit:apoapsis. else lock currentAlt to orbit:periapsis.
		set diffInit to abs(currentAlt - targetAlt).
		lock diffCurrent to abs(currentAlt - targetAlt).
		lock diffRatio to (diffCurrent / diffInit).
		set oldDiff to diffCurrent.
//		set logfile to "diff-log"+time:seconds+".txt".
		until exit = true {
			set thrott to diffRatio * 10.
//			log targetAlt + " | " + currentAlt + " | " + diffRatio + " | " + thrott to logfile.
			if abs(diffCurrent) > oldDiff set exit to true.
			set oldDiff to abs(diffCurrent).
		}
	} else {
		local burnstart is TIME:SECONDS.
		until time:seconds - burnstart >= burntime {
			set throttle to 1.
		}
	}

	set thrott to 0.
	set ship:control:pilotmainthrottle to 0.
	sas on.
	set sasmode to "STABILITYASSIST".
	unlock steering.
	wait 2.
	remove node.
	wait 1.
	sas off.
	print "----------/executeBurn".
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


declare function showInfo {
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

	readout(list,1,5).

}
