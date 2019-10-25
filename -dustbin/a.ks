// Auto-lander at KSC (no other runways supported at this time)
// Heavily inspired by dunbaratu

CLEARSCREEN.
CLEARVECDRAWS().
set TERMINAL:WIDTH to 50.
set TERMINAL:HEIGHT to 40.

parameter approach_direction is "land", draw_paths is true.

set ksc_runway_east to LATLNG(-0.0501377, -74.5024758448198).
set ksc_runway_center to LATLNG(-0.04937135, -74.61076263).
set ksc_runway_west to LATLNG(-0.048605, -74.7190494192674).
if approach_direction = "sea" or approach_direction = "s" {
	set approach_vector to (ksc_runway_east:position - ksc_runway_center:position):normalized.
	set farpoint to ksc_runway_west.
} else {
	set approach_vector to (ksc_runway_west:position - ksc_runway_center:position):normalized.
	set farpoint to ksc_runway_east.
}

set approach_markers to list().
set marker_names to list("Runway","Final","Inner","Outer","Initial").

set count to 0.
set dist to 0.
until count >= 5 {

	local marker_alt is 40 + dist * 160.
	local marker_pos is ksc_runway_center:altitudeposition(marker_alt) + (3000 * dist * approach_vector).
	local marker_geo is ship:body:geopositionof(marker_pos).
	approach_markers:add(list()).
	approach_markers[count]:add(marker_geo).
	approach_markers[count]:add(marker_alt).
	approach_markers[count]:add(75 + dist * 20).

	if draw_paths and count > 0 {
		local path is approach_markers[count-1][0]:altitudeposition(approach_markers[count-1][1]) - marker_geo:altitudeposition(marker_alt).
		local alt is marker_geo:altitudeposition(0) - marker_pos.
		approach_markers[count]:add(vecdraw(marker_pos,path,red,"",1,true,5)).
		approach_markers[count]:add(vecdraw(marker_pos,alt,red,"",1,true,5)).
		approach_markers[count]:add(path).
		set aim_path to vecdraw(v(0,0,0),v(1,0,0),rgb(1,0.5,0.5),"",1,true,5).
	}
	
	set count to count + 1.
	set dist to dist + count.	
}

wait 0.5.
SAS OFF.

// -------------------------------------------------------------------

// set bankPid to pidloop(4,0,0.03,-67,67).
// set rollPID to pidloop(0.001,0.0001,0.0001,-1,1).
// set pitchPID to pidloop(0.0075,0.001,0.002,-1,1).
// set throttlePID to pidloop(0.05,0.01,0.002,0,1).

set bankPid to pidloop(4,0,0.03,-50,50).
set rollPID to pidloop(0.003,0.0001,0.0002,-1,1).
set pitchPID to pidloop(0.02,0.002,0.003,-1,1).
set throttlePID to pidloop(0.05,0.01,0.025,0.0001,1).

set current to approach_markers:length - 1.
set brake_status to false.
set flare to false.
set endstate to false.

until endstate {
	local target is approach_markers[current].
	set target_geo to target[0].
	set target_alt to target[1].
	set target_spd to target[2].
	set target_pos to target_geo:altitudeposition(target_alt).
	set target_dist to target_pos:mag.
	if alt:radar < 11 {
		set flare to true.
	}

	if flare = true {
		set target_spd to 1.
	}
	set throttlePID:setpoint to target_spd.
	set ship:control:mainthrottle to throttlePID:update(time:seconds,ship:airspeed).

	if ship:airspeed / target_spd > 1.5 {
		if brake_status = false {
			BRAKES ON.
			set brake_status to true.
		}
	} else {
		if brake_status = true {
			BRAKES OFF.
			set brake_status to false.
		}
	}		
	
 	if flare = true {
		set climb_rate to -2.
	} else {
		set climb_rate to (target_alt - altitude) / (target_dist / ship:airspeed).
	}
	set pitchPID:setpoint to climb_rate.
	set ship:control:pitch to pitchPID:update(time:seconds,ship:verticalspeed).

	set angle to (shipHeading()-shipHeading(target_pos)).
	set bankPID:setpoint to 0.
	if current > 0 {
		set wantBank to bankPID:update(time:seconds, angle).
	} else {
		set wantBank to 0.
	}
	set rollPID:setpoint to wantBank.
	set ship:control:roll to rollPID:update(time:seconds,shipRoll()).
	
	if draw_paths {
		set aim_path:vec to target_pos.
		redrawMarkers().
	}
	readout().
	
	if target_dist < current^2.66666667 * 25 + 5 {
		if current > 0 {
			set current to current - 1.
		}
	}
	when current <= 1 then {
		gear on.
		print "GEAR DOWN":padleft(10) at (TERMINAL:WIDTH-10,1).
	}
	if current < 1 and status = "LANDED" {
		brakes on.
		print "BRAKES ON":padleft(10) at (TERMINAL:WIDTH-10,2).
		set throttle to 0.
		set ship:control:pilotmainthrottle to 0.
		set endstate to true.
	}
}

until ship:groundspeed <= 1 {
	lock steering to farpoint.
}

print "Successful landing!" at ((terminal:width/2)-10,terminal:height-2).
CLEARVECDRAWS().
if CONFIG:STAT {
	WAIT 10.
	CLEARSCREEN.
}

// ===================================================================

function redrawMarkers {
	from {local loop is 1.} until loop >= approach_markers:length step {set loop to loop + 1.} do {
		local marker is approach_markers[loop].
		set origin to marker[0]:altitudeposition(marker[1]).
		set marker[3]:start to origin.
		set marker[4]:start to origin.
	}
}

function readout {

	local lineout is 0.
	local lpad is 16.
	local output is list().

	if target_dist > 1000 {
		set dstr to round(target_dist/1000,2) + "k".
	} else {
		set dstr to round(target_dist,0).
	}

	output:add( "Target marker: ":padleft(lpad) + current + " / " + marker_names[current]).
	output:add( "Prograde hdg.: ":padleft(lpad) + round(shipHeading(),2) ).
	output:add( "Target hdg.: ":padleft(lpad) + round(target_geo:heading,2) + " deg" ).
	output:add( "Target brg.: ":padleft(lpad) + round(target_geo:bearing,2) + " deg" ).
	output:add( "Target dist.: ":padleft(lpad) + dstr + "m" ).
	output:add( " " ).
	output:add( "Target alt.: ":padleft(lpad) + target_alt + " m AGL" ).
	output:add( "Current alt.: ":padleft(lpad) + round(ship:altitude,1) + " m AGL" ).
	output:add( "Target climb: ":padleft(lpad) + round(climb_rate,2) + " m/s" ).
	output:add( "Vertical spd.: ":padleft(lpad) + round(ship:verticalspeed,2) + " m/s" ).
	output:add( "Pitch PID: ":padleft(lpad) + round(pitchPID:setpoint,2) ).
	output:add( " " ).
	output:add( "Target speed: ":padleft(lpad) + target_spd + " m/s" ).
	output:add( "Current speed: ":padleft(lpad) + round(ship:airspeed,1) + " m/s" ).
	output:add( "Speed change: ":padleft(lpad) + round(throttlePID:changerate,2) + "m/s" ).
	output:add( "PID output: ":padleft(lpad) + round(throttlePID:output,2) ).
	output:add( "Throttle: ":padleft(lpad) + round(ship:control:mainthrottle,2) ).
	output:add( " " ).
	output:add( "Angle: ":padleft(lpad) + angle ).
	output:add( "Bank value: ":padleft(lpad) + wantBank ).

	for line in output {
		print line + "    " at (0,lineout).
		set lineout to lineout + 1.
	}

	print status:padleft(12) at (TERMINAL:WIDTH-12,0).

}

function pidMonitor {
	parameter pid.
	parameter lineout is -1.

	local output is list().
	local lpad is 15.

	output:add( "Setpoint: ":padleft(lpad) + round(pid:setpoint,5)).
	output:add( " " ).
	output:add( "Changerate: ":padleft(lpad) + round(pid:changerate,5) + " / s" ).
	output:add( "Error: ":padleft(lpad) + round(pid:error,5) ).
	output:add( "Errorsum: ":padleft(lpad) + round(pid:errorsum,5) ).
	output:add( " " ).
	output:add( "Input: ":padleft(lpad) + round(pid:input,5) ).
	output:add( "Minoutput: ":padleft(lpad) + pid:minoutput ).
	output:add( "Output: ":padleft(lpad) + round(pid:output,5) ).
	output:add( "Maxoutput: ":padleft(lpad) + pid:maxoutput ).

	if lineout < 0 {
		set lineout to TERMINAL:HEIGHT - output:length.
	}
	for line in output {
		print line + "     " at (0,lineout).
		set lineout to lineout + 1.
	}

}

function shipHeading {
	parameter pointing is ship:facing:forevector.

	local trig_x is vdot(ship:north:vector, pointing).
	local trig_y is vdot(vcrs(ship:up:vector, ship:north:vector), pointing).
	local result is arctan2(trig_y, trig_x).
	if result < 0 { 
		return 360 + result.
	} else {
		return result.
	}
}

function shipRoll {
	local raw is vang(ship:up:vector,-ship:facing:starvector).
	if vang(ship:up:vector, ship:facing:topvector) > 90 {
		if raw > 90 {
			return raw - 270.
		} else {
			return raw + 90.
		}
	} else {
		return 90 - raw.
	}
}