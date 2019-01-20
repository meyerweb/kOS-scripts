
local parameter targetAp is -1.
local parameter targetPe is -1.
if targetPe = -1 set targetPe to targetAp.
local parameter burnTA is -1.

wait 1.
clearscreen.

run once "vessel_info.ks".
run once "nodeburn.ks".

if targetAp = -1 set targetAp to orbit:apoapsis.
if targetAp > -1 {
	if (targetAp < 10000) set targetAp to targetAp * 1000.
	if (targetPe < 10000) set targetPe to targetPe * 1000.

	run once "orbital_mechanics.ks".

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

	if burnTA = -1 {
		set burns to list(180,0).
		if targetPe > orbit:apoapsis set burns to list(0,180).
	}
	if burnTA > -1 set burns to list(burnTA,abs(0-burnTA)).
	

	until burncount >= 2 {
		if burns[burncount] = 0 set targetAlt to targetAp. else set targetAlt to targetPe.
		print "burn " + burncount.
		print " targetAp " + targetAp.
		print " targetPe " + targetPe.
		print "targetAlt " + targetAlt.
		setNode(burns[burncount],targetAlt).
		executeburn().
		set burncount to burncount + 1.
	}

//	showInfo().

} else {
	print "Invalid orbital parameters supplied; aborting.".
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
		local deltaV is getDeltaV(
			orbit:apoapsis, orbit:periapsis, burnTA,
			node1, node2, burnTA).
		print "burnTA " + burnTA.
		print "orb:ap " + orbit:apoapsis.
		print "orb:pe " + orbit:periapsis.
		print "node1  " + node1.
		print "node2  " + node2.
		print "dV     " + deltaV.
		SET node to NODE(TIME:SECONDS + findTimeBetweenTAs(burnTA),0,0,deltaV).
		ADD node.
		print "----------/setNode".
	}
}


// declare function executeBurn {
// 
// 	local currentStageDV is stageDV().
// 	local currentShipDV is vesselDV().
// 	local dv is 0.
// 	lock dv to node:deltav:mag.
// 
// 	if currentStageDV > 0 and currentStageDV < dv {
// 		stage.
// 	}
// 	wait 0.2.
// 	until maxthrust > 0 {
// 		stage.
// 		wait 0.2.
// 		print maxthrust.
// 	}
// 	
// 	set currentShipDV to vesselDV().
// 	set currentStageDV to stageDV().
// 
// 	if currentShipDV < dv {
// 		errorreport("Insufficient dV to complete maneuver.").
// 	}
// 
// 	print "---------- executeBurn".
// 	local thrscale is 1.
// 	local acceleration is (availablethrust / mass).
// 	local burntime is (dv / acceleration).
// 	print "burntime " + burntime.
// 	if (burntime < 2) {
// 		set thrscale to burntime / 2.
// 		set acceleration to ((availablethrust*thrscale)/mass).
// 		set burntime to (dv/acceleration).	
// 		print "burntime " + burntime + " (modified)".
// 	}
// 	print "thrscale " + thrscale.
// 	local starttime is (burntime / 2).
// 
// 	wait until node:eta <= starttime + 120.
// 	set warp to 1.
// 	wait until node:eta <= starttime + 40.
// 	set warp to 0.
// 	sas off.
// 
// 	lock steering to node:burnvector.
// 	wait until node:eta <= starttime + 5.
// 	set warp to 0.
// 	
// 
// 	wait until node:eta <= starttime.
// 	
// 	lock throttle to thrott.
// 	set thrott to thrscale.
// 	if thrscale < 1 lock steering to ship:facing. else lock steering to node:deltav.
// 
// 	set exit to 0.
// 	set interval to 0.05.
// 	set t0 to time:seconds.
// 	set t1 to time:seconds.
// 	set oldmag to dv.
// 	set fulldv to dv.
// 	set mod to 1.
// 	until exit > 0 {
// //		set thrott to (dv * thrscale).
// 		if (dv / fulldv < 0.1) set mod to (dv / fulldv) * 20.
// 		set thrott to thrscale * mod.
// 		print (dv) at(25,1).
// 		set t1 to time:seconds.
// 		set newmag to dv.
// 		if dv < 0.0005 set exit to 1.
// 		if t1 - t0 > interval {
// 			set t1 to t0.
// 			set t0 to time:seconds.
// 			print (newmag) at(25,2).
// 			if newmag >= oldmag set exit to 2.
// 			set oldmag to dv.
// 		}
// 		print thrott at(25,3).
// 	}
// 	print "burn complete: exit code " + exit.
// 
// 	set thrott to 0.
// 	set ship:control:pilotmainthrottle to 0.
// 	sas on.
// 	set sasmode to "STABILITYASSIST".
// 	unlock steering.
// 	wait 2.
// 	remove node.
// 	wait 1.
// 	sas off.
// 	print "----------/executeBurn".
// }


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
