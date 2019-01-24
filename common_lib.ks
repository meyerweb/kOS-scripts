declare function getWarpSpeed {
	local parameter tr is -1.
	print tr.
	if tr < 0 {return 0.}
	else if tr > 500000 {return 7.}   // x 100,000
	else if tr > 50000 {return 6.}   // x 10,000
	else if tr > 5000 {return 5.}   // x 1,000
	else if tr > 600 {return 4.}   // x 100
	else if tr > 360 {return 3.}  // x 50
	else if tr > 150 {return 2.} // x 10
	else if tr > 60 {return 1.} // x 5
	return 0.
}

declare function sec2min {
	local parameter s is -1.
	local parameter places is 4.
	local parameter padding is false.
	
	if s > -1 {
		local minutes is floor(s/60).
		local seconds is mod(s,60).
		local output is "".
		if minutes > 0 {
			set output to output + minutes:tostring + "m ".
//			if minutes < 10 and padding {
//				set output to " " + output.
//			}
//		}
//		if seconds < 10 and padding {
//			set output to output + " ".
		}
		set output to output + round(seconds,places):tostring + "s".
		return output:tostring.
	}
}

declare function readout {
	parameter output is list().
	parameter row is 0.
	parameter col is 0.

	for line in output {
		print line + "     " at (col,row).
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
