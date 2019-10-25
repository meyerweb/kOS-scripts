declare function readout {
	parameter output is list().
	parameter lineout is 0.
	parameter columnout is 0.
	
	for line in output {
		print line at (columnout,lineout).
		set lineout to lineout + 1.
	}
}
