run once "orbital_mechanics.ks".

setNode().

declare function setNode {
	local burnTA is 180.
	local node1 is orbit:apoapsis.
	local node2 is orbit:periapsis.
	set node2 to orbit:apoapsis.
	
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
