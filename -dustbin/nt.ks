CLEARSCREEN.

SET IPU0 TO CONFIG:IPU.
SET CONFIG:IPU TO 300.
SET TERMINAL:REVERSE TO TRUE.
SET TERMINAL:WIDTH TO 50.
SET TERMINAL:HEIGHT TO 15.

SET DV to 0.1.
SET apoNode to NODE(TIME:SECONDS + ETA:APOAPSIS,0,0,DV).

UNTIL DV <= 0 {
	REMOVE apoNode.
	SET DV TO (DV - 0.00001).
	SET apoNode to NODE(TIME:SECONDS + ETA:APOAPSIS,0,0,DV).
	ADD apoNode.
	PRINT apoNode:DELTAV:MAG.
}