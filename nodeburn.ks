clearscreen.

run once "orbital_mechanics.ks".
run once "vessel_info.ks".

wait 0.001.
if (hasnode) executeBurn().

declare function executeBurn {
	
	set node to nextnode.
	local currentStageDV is stageDV().
	local currentShipDV is vesselDV().
	local dv is 0.
	lock dv to node:deltav:mag.

	if currentStageDV > 0 and currentStageDV < dv {
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

	sas off.
	lock steering to node:burnvector.
	until vang(ship:facing:forevector,node:burnvector) < 0.1 {
		print "vang " + vang(ship:facing:forevector,node:burnvector) at(1,33).
	}.
	wait 1.
	print "                                               " at (1,33).	
	print "Warping to node.".
	set warp to getWarpSpeed(node:eta).
	wait until node:eta <= starttime + 360.
	set warp to 3.
	wait until node:eta <= starttime + 120.
	set warp to 1.
	wait until node:eta <= starttime + 30.
	set warp to 0.

	sas off.	

	wait until node:eta <= starttime.
	
	lock throttle to thrott.
	set thrott to thrscale.
	if thrscale < 1 lock steering to ship:facing. else lock steering to node:deltav.

	set exit to 0.
	set interval to 0.05.
	set t0 to time:seconds.
	set t1 to time:seconds.
	set oldmag to dv.
	set fulldv to dv.
	set mod to 1.
	until exit > 0 {
//		set thrott to (dv * thrscale).
		if (dv / fulldv < 0.1) set mod to (dv / fulldv) * 20.
		set thrott to thrscale * mod.
		print (dv) at(25,1).
		set t1 to time:seconds.
		set newmag to dv.
		if dv < 0.0005 set exit to 1.
		if t1 - t0 > interval {
			set t1 to t0.
			set t0 to time:seconds.
			print (newmag) at(25,2).
			if newmag >= oldmag set exit to 2.
			set oldmag to dv.
		}
		print thrott at(25,3).
	}
	print "burn complete: exit code " + exit.

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
