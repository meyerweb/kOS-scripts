set debug to false.
parameter al is 0.
parameter in is 0.
parameter la is ship:body:latitude.

if al > 0 {
	set debug to true.
	run once "debugger.ks".
	clearscreen.
	findAzimuth(al,in,la).
}

declare function findAzimuth {
	local parameter altitude is 0.
	local parameter inclination is 0.
	local parameter latitude is ship:body:latitude.
	
	local Binertial is arcsin( cos(inclination) / cos(latitude) ).
	if (inclination < 0) set Binertial to 180 - Binertial.
	local Vorbit is ( ship:body:mu / (altitude + body:radius) )^0.5.
	local Vsurface is ship:velocity:orbit:mag.
	local term1 is ( Vorbit * sin(Binertial) ) - ( Vsurface * cos(latitude) ).
	local term2 is ( Vorbit * cos(Binertial) ).
	local Brotational is arctan2(term1,term2).

	if debug {
		local output is list().
		output:add(" alt " + altitude).
		output:add(" inc " + inclination).
		output:add(" lat " + latitude).
		output:add("Vorb " + Vorbit).
		output:add("Vsrf " + Vsurface).
		output:add("Binr " + Binertial).
		output:add("trm1 " + term1).
		output:add("trm2 " + term2).
		output:add("Brot " + Brotational).
		readout(output,15,1).
	}

	return Brotational.

}


// function inst_az {
// // This function calculates the direction a ship must travel to achieve the target inclination given the current ship's latitude and orbital velocity.
// // https://www.reddit.com/r/Kos/comments/3a5hjq/instantaneous_azimuth_function/
// 
// 	parameter
// 		inc. // target inclination
// 	
// 	// find orbital velocity for a circular orbit at the current altitude.
// 	local V_orb is sqrt( body:mu / ( ship:altitude + body:radius)).
// 	
// 	// project desired orbit onto surface heading
// 	local az_orb is arcsin ( cos(inc) / cos(ship:body:latitude)).
// 	if (inc < 0) {
// 		set az_orb to 180 - az_orb.
// 	}
// 	
// 	// create desired orbit velocity vector
// 	local V_star is heading(az_orb, 0)*v(0, 0, V_orb).
// 
// 	// find horizontal component of current orbital velocity vector
// 	local V_ship_h is ship:velocity:orbit - vdot(ship:velocity:orbit, up:vector)*up:vector.
// 	
// 	// calculate difference between desired orbital vector and current (this is the direction we go)
// 	local V_corr is V_star - V_ship_h.
// 	
// 	// project the velocity correction vector onto north and east directions
// 	local vel_n is vdot(V_corr, ship:north:vector).
// 	local vel_e is vdot(V_corr, heading(90,0):vector).
// 	
// 	// calculate compass heading
// 	local az_corr is arctan2(vel_e, vel_n).
// 	return az_corr.
// }