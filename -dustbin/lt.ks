// test data; will have to be replaced with parameter input / target:longitudeascendingnode
set targetLAN to 123.45678.

clearscreen.

set shiplon to ship:longitude.  // -74.558


until false {
	set targetLANbody to targetLAN - body:rotationangle.
	set phaseangle to targetLANbody - shiplon.
	if phaseangle < 0 set phaseangle to 360 + phaseangle.
	readout().
}

// ============================================================================================== \\

declare function readout {
	local lineout is 5.
	local output is list().

	output:add("  bodyrot " + round(body:rotationangle,3) + "    ").
	output:add( " " ).
	output:add("      shiplon " + round(shiplon,3) + "    ").
	output:add("targetLANbody " + round(targetLANbody,3) + "     ").
	output:add("      phangle " + round(phaseangle,3) + "     ").
	output:add( " " ).

	for line in output {
		print line + "    " at (1,lineout).
		set lineout to lineout + 1.
	}
}
