// made by leviathan01 (levi)
// 9/10/2016
// auto balance vtol script
// version 1.0 
// KOS version 1.0.0
// KSP version 1.1.3.1289

clearscreen.
parameter maxTick is 2000, maxIPU is 2000.

set maxcost to .05.

set oldIPU to config:ipu.
print("boosting IPU to " + maxIPU).
set config:ipu to maxIPU.

set SHIP:control:pilotmainthrottle to 0.

set VTOLs to SHIP:partsdubbed("vtol").

for vtol in vtols { vtol:activate(). }

function get_CoT {
	set CoT to V(0, 0, 0).

	for vtol in vtols {
		set pos to vtol:position.
		set relitive to pos - V(0, 0, 0).
		set CoT to CoT + relitive * (vtol:availablethrust / SHIP:availablethrust).
	}
	
	return CoT.
}

lock cost to vang(-1*vxcl(V(0, 0, 0), get_CoT()), up:forevector).
set lastCost to 1000.

set down to (UP + R(180, 0, 0)):forevector.
set down:mag to 10.

set vd0 to vecdraw().
set vd0:start to V(0, 0, 0).
set vd0:vec to down.
set vd0:color to red.
set vd0:show to true.

set vd to vecdraw().
set vd:start to get_CoT().
set vd:vec to down.
set vd:show to true.

set loop to true.
set tick to 0.

function raiseTL {
	parameter engine.
	
	set oldLimit to engine:thrustlimit.
	set lastCost to cost.
	set engine:thrustlimit to min(oldLimit + (.01), 100).
	print cost at(0, 1).
	set vd:start to get_CoT().
	if lastCost > cost {
		return true.
	} else {
		set engine:thrustlimit to oldLimit.
		return false.
	}
}

function lowerTL {
	parameter engine.
	
	set oldLimit to engine:thrustlimit.
	set lastCost to cost.
	set engine:thrustlimit to max(oldLimit - (.01), 0).
	print cost at(0, 1).
	set vd:start to get_CoT().
	if lastCost > cost {
		return true.
	} else {
		set engine:thrustlimit to oldLimit.
		return false.
	}
}

until not loop {
	
	if cost < maxcost {
		print("CoT aligned with CoM").
		clearvecdraws().
		set loop to false.
	} else if tick > maxTick {
		print("unable to align CoT with CoM after " + maxTick + " cycles").
		print("rerun the command with a higher max cylce").
		set loop to false.
	} else {
		set tick to tick + 1.
		for vtol in vtols {
			if vtol:thrustlimit < .5 {
				until not raiseTL(vtol) {}
				until not lowerTL(vtol) {}
			} else {
				until not lowerTL(vtol) {}
				until not raiseTL(vtol) {}
			}
		}
	}
}

print("reseting IPU to " + oldIPU).
set config:ipu to oldIPU.