//@lazyglobal off.

set mu to ship:body:mu.

declare function findSMA {
	local parameter ap is 0.
	local parameter pe is 0.
	local parameter r is ship:body:radius.

	if ap and pe {
		return (ap + r + pe + r) / 2.
	} else return -1.
}

declare function findEcc {
	local parameter ap is 0.
	local parameter pe is 0.
	local parameter r is ship:body:radius.

	if ap and pe {
		return 1 - (2 / (((ap + r) / (pe + r)) + 1 )).
	} else return -1.
}

declare function findVelAtTA {
	local parameter ta is orbit:trueanomaly.
	local parameter sma is orbit:semimajoraxis.
	local parameter ecc is orbit:eccentricity.
	
	local r is (sma * ( 1 - ecc^2 )) / ( 1 + ( ecc * cos(ta))).
	return sqrt(mu * (( 2 / r ) - ( 1 / sma ))).
}

declare function findTimeBetweenTAs {
	local parameter finalta is -1.
	local parameter startta is orbit:trueanomaly.
	local parameter sma is orbit:semimajoraxis.
	local parameter ecc is orbit:eccentricity.

	if finalta = 0 set finalta to 360.
	if finalta > -1 {

		set radconv to constant:pi/180.
		set n to sqrt(mu / sma^3).
		set halves to list(0,0).

		if startta <= 180 and finalta > 180 {
			set e0 to arccos((ecc + cos(startta)) / (1 + ecc * cos(startta))) * radconv.
			set e1 to arccos((ecc + cos(180)) / (1 + ecc * cos(180))) * radconv.
			set m0 to e0 - (ecc * sin(e0 / radconv)).
			set m1 to e1 - (ecc * sin(e1 / radconv)).
			set halves[0] to abs(m1 - m0) / n.
			set e0 to arccos((ecc + cos(180)) / (1 + ecc * cos(180))) * radconv.
			set e1 to arccos((ecc + cos(finalta)) / (1 + ecc * cos(finalta))) * radconv.
			set m0 to e0 - (ecc * sin(e0 / radconv)).
			set m1 to e1 - (ecc * sin(e1 / radconv)).
			set halves[1] to abs(m1 - m0) / n.
//			print "01".
			return halves[0] + halves[1].
		}
		if startta > 180 and finalta <= 180 {
			set e0 to arccos((ecc + cos(startta)) / (1 + ecc * cos(startta))) * radconv.
			set e1 to arccos((ecc + cos(0)) / (1 + ecc * cos(0))) * radconv.
			set m0 to e0 - (ecc * sin(e0 / radconv)).
			set m1 to e1 - (ecc * sin(e1 / radconv)).
			set halves[0] to abs(m1 - m0) / n.
			set e0 to arccos((ecc + cos(0)) / (1 + ecc * cos(0))) * radconv.
			set e1 to arccos((ecc + cos(finalta)) / (1 + ecc * cos(finalta))) * radconv.
			set m0 to e0 - (ecc * sin(e0 / radconv)).
			set m1 to e1 - (ecc * sin(e1 / radconv)).
			set halves[1] to abs(m1 - m0) / n.
//			print "02".
			return halves[0] + halves[1].
		}

		set e0 to arccos((ecc + cos(startta)) / (1 + ecc * cos(startta))) * radconv.
		set e1 to arccos((ecc + cos(finalta)) / (1 + ecc * cos(finalta))) * radconv.
		set m0 to e0 - (ecc * sin(e0 / radconv)).
		set m1 to e1 - (ecc * sin(e1 / radconv)).
		set halves[0] to abs(m1 - m0) / n.
//		print "03".
		return halves[0] + halves[1].

	} else return -1.
}



testing().

declare function testing {
	set t0 to time:seconds.
	clearscreen.
	print " ".
	print "Current TA (KSP, KER)".
	print orbit:trueanomaly.
	print orbit:trueanomaly * constant:degtorad.
	print " ".
	print "Current SMA (calc,KSP)".
	print findSMA(orbit:apoapsis,orbit:periapsis).
	print orbit:semimajoraxis.
	print " ".
	print "Current ECC (calc,KSP)".
	print findEcc(orbit:apoapsis,orbit:periapsis).
	print orbit:eccentricity.
	print " ".
	print "Circularize at Ap".
	set apVel to findVelAtTA(180).
	set peVel to findVelAtTA(0).
	set apCirc to findVelAtTA(180,orbit:apoapsis+body:radius,0).
	set peCirc to findVelAtTA(180,orbit:periapsis+body:radius,0).
	print apVel.
	print apCirc.
	print apCirc-apVel.
	print " ".
	print "Circularize at Pe".
	print peVel.
	print peCirc.
	print peCirc-peVel.
	print " ".
	print round(findTimeBetweenTAs(90,30,675000,0.1),4) + "s (should be 277.7919)".
	print round(findTimeBetweenTAs(180,90,675000,0.1),4) + "s (should be 522.4643)".
	print " ".
	print round(eta:apoapsis,4)/60 + "m (TTA)".
	print round(findTimeBetweenTAs(180),4)/60 + "m (should be TTA)".
	print " ".
	print round(eta:periapsis,4)/60 + "m (TTP)".
	print round(findTimeBetweenTAs(0),4)/60 + "m (should be TTP)".
	print " ".
	print round(findTimeBetweenTAs(0,0),4)/60 + "m (should be orbital period)".
	print " ".
//	print "Runtime: " + (time:seconds - t0) + "s ".
//	print " ".
}

//-for calculating current state of orbit, not projected information-\\
// set vel to ship:velocity:orbit:mag.
// set r to ship:altitude + ship:body:radius.
// set velc to sqrt( mu * ( (2/r) - (1/sma) ) ).
