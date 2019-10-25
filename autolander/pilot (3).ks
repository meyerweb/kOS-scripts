// pilot control.

run lib_pid.

set yokePull to 0.
set yokeRoll to 0.
set shipRoll to 0.
set shipCompass to 0.

set east_ves to vessel("VASI east").
set west_ves to vessel("VASI west").
set runway_alt to body:altitudeof(west_ves:position).

lock runway_vect to (east_ves:position - west_ves:position):normalized.

// make a list of aiming waypoints:
set i to 0.
set arith_series to 0. // A counter that goes 1,3,6,10,15, etc.
set aim_geo_list to list().
set aim_agl_list to list().
set aim_spd_list to list().

// Seed a final waypoint which is on the runway, at ground altitude, with 80% of runway left:
local aim_pos is east_ves:geoposition:altitudeposition(0).
aim_geo_list:add(ship:body:geopositionof(aim_pos)).
aim_agl_list:add(0).
aim_spd_list:add(60).

until i >= 5 {
  local aim_agl is 45+arith_series*150.
  local aim_pos is west_ves:geoposition:altitudeposition(aim_agl) - 2500*arith_series*runway_vect.
  local aim_geo is ship:body:geopositionof(aim_pos).
  aim_geo_list:add(aim_geo).
  aim_agl_list:add(aim_agl).
  if i = 0 { 
    aim_spd_list:add(75).
  } else if i = 1{
    aim_spd_list:add(90).
  } else {
    aim_spd_list:add(120).
  }
  set i to i+1.
  set arith_series to arith_series+i.
}

function displayPitch {
  parameter col,row.

  print "Want Vspd = " + round(wantClimb,0) + "   " at (col,row).
  print "     Vspd = " + round(ship:verticalspeed,1) + " m/s   " at (col,row+1).
  print "yoke pull = " + round(yokePull,2) + "   " at (col,row+2).
}

function displayRoll {
  parameter col,row.

  print "Want Bank = " + round(wantBank,0) + "   " at (col,row).
  print "     Bank = " + round(shipRoll,1) + " m/s   " at (col,row+1).
  print "yoke Roll = " + round(yokeRoll,3) + "    " at (col,row+2).
}

function displayCompass {
  parameter col,row.

  print "Want Comp = " + round(wantCompass,0) + " deg  " at (col,row).
  print "     Comp = " + round(shipCompass,0) + " deg  " at (col,row+1).
}

function displaySpeed {
  parameter col,row.

  print "Want Spd = " + round(wantSpeed,0) + " m/s  " at (col,row).
  print "airSpeed = " + round(ship:airspeed,0) + " m/s  " at (col,row+1).
  print "curthrot = " + round(scriptThrottle,2) + "   " at (col,row+2).
}

function displayProgress {
  parameter geo, agl, col,row.

  print "Aiming at LAT=" + round(geo:lat,2) + " LNG=" + round(geo:lng,2) + ", AGL " + round(agl,0) + "m" at (col,row).
  local d is geo:altitudeposition(agl+geo:terrainheight):mag.
  print "Dist To aim point " + round(d,0) + "m" at (col,row+1).
  print "          Cur AGL " + round(alt:radar,0) + "m" at (col,row+2).
}

function roll_for {
  parameter ves.

  local raw is vang(ves:up:vector, - ves:facing:starvector).
  if vang(ves:up:vector, ves:facing:topvector) > 90 {
    if raw > 90 {
      return raw - 270.
    } else {
      return raw + 90.
    }
  } else {
    return 90 - raw.
  }
}.

function east_for {
  parameter ves.

  return vcrs(ves:up:vector, ves:north:vector).
}

function compass_for {
  parameter ves.
  parameter mode. // 0,1,2 for 0=facing, 1=orbital vel, 2 = srf vel.

  local pointing is 0.
  if mode = 0 {
    set pointing to ves:facing:forevector.
  } else if mode = 1 {
    set pointing to ves:velocity:orbit.
  } else if mode = 2 {
    set pointing to ves:velocity:surface.
  } else {
    PRINT "ARRGG.. Compass_for was called incorrectly.".
  }

  local east is east_for(ves).

  local trig_x is vdot(ves:north:vector, pointing).
  local trig_y is vdot(east, pointing).

  local result is arctan2(trig_y, trig_x).

  if result < 0 { 
    return 360 + result.
  } else {
    return result.
  }
}.

function angle_off {
  parameter a1, a2. // how far off is a2 from a1.

  local ret_val is a2 - a1.
  if ret_val < -180 {
    set ret_val to ret_val + 360.
  } else if ret_val > 180 {
    set ret_val to ret_val - 360.
  }
  return ret_val.
}

function compass_between_latlngs {
  parameter p1, p2. // latlngs for current and desired position.

  return
    arctan2( sin( p2:lng - p1:lng ) * cos( p2:lat ),
             cos( p1:lat )*sin( p2:lat ) - sin( p1:lat )*cos( p2:lat )*cos( p2:lng - p1:lng ) ).
}

function circle_distance {
 parameter
  p1,     //...this point, as a latlng...
  p2,     //...to this point, as a latlng...
  radius. //...around a body of this radius plus altitude.

 local A is sin((p1:lat-p2:lat)/2)^2 + cos(p1:lat)*cos(p2:lat)*sin((p1:lng-p2:lng)/2)^2.
 
 return radius*constant():PI*arctan2(sqrt(A),sqrt(1-A))/90.
}.

function get_want_climb {
  parameter ves, // vessel that's doing the climb
            ap. // aim pos.

  local alt_diff is ves:body:altitudeof(ap) - ves:altitude.
  local dist is circle_distance( ves:geoposition, ves:body:geopositionof(ap), ves:body:radius+ves:altitude).
  local time_to_dest is dist / ves:surfacespeed.

  return alt_diff / time_to_dest.
}

// Pitch control mode.
set pitchPid to PID_init(0.005, 0.001, 0.0001, -1, 1).

// Roll control mode.
set rollPid to PID_init(0.001, 0.0001, 0.0001, -1, 1).

// compass causing bank.
set bankPid to PID_init(5, 0.00, 0.05, -65, 65).

// speed causing throttle.
set throtPid to PID_init(0.002, 0.001, 0.00, 0, 1).

set wantClimb to 0.
set wantBank to 0.
set wantSpeed to 0.

on ag1 { set wantClimb to wantClimb + 2. preserve. }.
on ag2 { set wantClimb to wantClimb - 2. preserve. }.
on ag3 { 
  set wantCompass to mod(wantCompass - 2,360).
  if wantCompass < 0 {
    set wantCompass to wantCompass + 360.
  }
  preserve.
}.
on ag4 {
  set wantCompass to mod(wantCompass + 2,360). 
  preserve.
}.


clearscreen.

sas off.
set cur_aim_i to aim_geo_list:length-1.
set vd_aimpos to vecdraw(v(0,0,0),v(1,0,0),RGBA(1,0,0,2),"aim point",1,true).

set user_quit to false.
on abort set user_quit to true.

when alt:radar < 100 then {
  gear on.
  print "***GEAR ON***".
}

until user_quit or status="LANDED" or cur_aim_i < 0 {
  wait 0.001.
  local cur_aim_geo is aim_geo_list[cur_aim_i].
  local cur_aim_agl is aim_agl_list[cur_aim_i].
  local cur_spd_want is  aim_spd_list[cur_aim_i].
  local cur_aim_pos is cur_aim_geo:altitudeposition(cur_aim_agl + cur_aim_geo:terrainheight).
  set wantCompass to compass_between_latlngs(ship:geoposition, cur_aim_geo).
  set vd_aimpos:start to ship:position.
  set vd_aimpos:vec to cur_aim_pos.
  set wantSpeed to cur_spd_want.

  if cur_aim_i > 0 {
    set wantClimb to get_want_climb(ship, cur_aim_pos).
  } else {
    set wantClimb to -1.5.
  }

  if (cur_aim_pos - ship:position):mag < 100 {
    set cur_aim_i to cur_aim_i - 1.
    if cur_aim_i < 0 {
       
    }
  }

  set shipSpd to ship:airspeed.
  set scriptThrottle to PID_seek( throtPID, wantSpeed, shipSpd).
  lock throttle to scriptThrottle.

  set shipRoll to roll_for(ship).
  set shipCompass to compass_for(ship,2). // srf vel mode

  set yokePull to PID_seek( pitchPid, wantClimb, ship:verticalspeed ).
  set ship:control:pitch to yokePull.

  set wantBank to PID_seek( bankPid, 0, angle_off(wantCompass, shipCompass) ).
  
  set yokeRoll to PID_seek( rollPid, wantBank, shipRoll ).
  set ship:control:roll to yokeRoll.

  displayCompass(5,5).
  displayRoll(5,10).
  displayPitch(5,15).
  displaySpeed(5,20).
  displayProgress(cur_aim_geo, cur_aim_agl, 3,25).
}

if not user_quit {
  brakes on.
  print "QUITTING.. BRAKES ON.".
  lock throttle to 0.
  wait until status="LANDED".
}
sas on.
set vd_aimpos to 0.
set ship:control:pilotmainthrottle to 0.
set ship:control:neutralize to true.
