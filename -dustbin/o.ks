clearscreen.
set ipu0 to config:ipu.
set config:ipu to 300.
set terminal:reverse to true.
set terminal:width to 50.
set terminal:height to 30.

set mu to ship:body:mu.

until false {
	local lineout is 1.
	local output is list().

	set vel to ship:velocity:orbit:mag.
	set sma to orbit:semimajoraxis.
	set ecc to orbit:eccentricity.
	set TA to orbit:trueanomaly.
	set r to ship:altitude + ship:body:radius.
	set velc to sqrt( mu * ( (2/r) - (1/sma) ) ).

	output:add(" TA  " + round(TA,3)).
	output:add(" Vo  " + round(vel,5)).
	output:add(" Vc  " + round(velc,5)).
	output:add(" Vd  " + round(vel - velc,5)).

	for line in output {
		print line + "       " at (1,lineout).
		set lineout to lineout + 1.
	}

//	output:add("ECC  " + round(orbit:eccentricity,8)).
//	output:add("SMA  " + round(orbit:semimajoraxis,3)).

}
