run once "common_lib.ks".

set mu to ship:body:mu.
set debug to false.

if debug {
	set t0 to time:seconds.
	until false {
		if time:seconds > t0 + 1 {
			testing().
			set t0 to time:seconds.
		}
	}
}


// ==========================================================================


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
		return abs( 1 - (2 / (((ap + r) / (pe + r)) + 1 ))).
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

		set halves to list(0,0).

		if startta <= 180 and finalta > 180 {
			set halves[0] to TAtime(startta,180,sma,ecc).
			set halves[1] to TAtime(180,finalta,sma,ecc).
			return halves[0] + halves[1].
		}
		if startta > 180 and finalta <= 180 {
			set halves[0] to TAtime(startta,360,sma,ecc).
			set halves[1] to TAtime(0,finalta,sma,ecc).
			return halves[0] + halves[1].
		}
		set halves[0] to TAtime(startta,finalta,sma,ecc).
		return halves[0] + halves[1].

	} else return -1.
}

declare function TAtime {
	local parameter start is 0.
	local parameter end is 0.
	local parameter sma is 0.
	local parameter ecc is 0.

	if sma > 0 {
		local radconv is constant:degtorad.
		local n is sqrt(mu / sma^3).

		local e0 is arccos((ecc + cos(start)) / (1 + ecc * cos(start))) * radconv.
		local e1 is arccos((ecc + cos(end)) / (1 + ecc * cos(end))) * radconv.
		local m0 is e0 - (ecc * sin(e0 / radconv)).
		local m1 is e1 - (ecc * sin(e1 / radconv)).
		return abs(m1 - m0) / n.	
	}
}

//   https://www.reddit.com/r/Kos/comments/3r5pbj/set_inclination_from_orbit_script/

function eta_true_anom {
    declare local parameter tgt_lng.
    // convert the positon from reference to deg from PE (which is the true anomaly)
    local ship_ref to mod(obt:lan+obt:argumentofperiapsis+obt:trueanomaly,360).
    // s_ref = lan + arg + referenc

    local node_true_anom to (mod (720+ tgt_lng - (obt:lan + obt:argumentofperiapsis),360)).

    print "Node anomaly   : " + round(node_true_anom,2).    
    local node_eta to 0.
    local ecc to OBT:ECCENTRICITY.
    if ecc < 0.001 {
        set node_eta to SHIP:OBT:PERIOD * ((mod(tgt_lng - ship_ref + 360,360))) / 360.

    } else {
        local eccentric_anomaly to  arccos((ecc + cos(node_true_anom)) / (1 + ecc * cos(node_true_anom))).
        local mean_anom to (eccentric_anomaly - ((180 / (constant():pi)) * (ecc * sin(eccentric_anomaly)))).

        // time from periapsis to point
        local time_2_anom to  SHIP:OBT:PERIOD * mean_anom /360.

        local my_time_in_orbit to ((OBT:MEANANOMALYATEPOCH)*OBT:PERIOD /360).
        set node_eta to mod(OBT:PERIOD + time_2_anom - my_time_in_orbit,OBT:PERIOD) .

    }

    return node_eta.
}

function set_inc_lan {
    DECLARE PARAMETER incl_t.
    DECLARE PARAMETER lan_t.
    local incl_i to SHIP:OBT:INCLINATION.
    local lan_i to SHIP:OBT:LAN.

// setup the vectors to highest latitude; Transform spherical to cubic coordinates.
    local Va to V(sin(incl_i)*cos(lan_i+90),sin(incl_i)*sin(lan_i+90),cos(incl_i)).
    local Vb to V(sin(incl_t)*cos(lan_t+90),sin(incl_t)*sin(lan_t+90),cos(incl_t)).
// important to use the reverse order
    local Vc to VCRS(Vb,Va).

    local dv_factor to 1.
    //compute burn_point and set to the range of [0,360]
    local node_lng to mod(arctan2(Vc:Y,Vc:X)+360,360).
    local ship_ref to mod(obt:lan+obt:argumentofperiapsis+obt:trueanomaly,360).

    local ship_2_node to mod((720 + node_lng - ship_ref),360).
    if ship_2_node > 180 {
        print "Switching to DN".
        set dv_factor to -1.
        set node_lng to mod(node_lng + 180,360).
    }       

    local node_true_anom to 360- mod(720 + (obt:lan + obt:argumentofperiapsis) - node_lng , 360 ).
    local ecc to OBT:ECCENTRICITY.
    local my_radius to OBT:SEMIMAJORAXIS * (( 1 - ecc^2)/ (1 + ecc*cos(node_true_anom)) ).
    local my_speed1 to sqrt(SHIP:BODY:MU * ((2/my_radius) - (1/OBT:SEMIMAJORAXIS)) ).   
    local node_eta to eta_true_anom(node_lng).
    local my_speed to VELOCITYAT(SHIP, time+node_eta):ORBIT:MAG.
    local d_inc to arccos (vdot(Vb,Va) ).
    local dvtgt to dv_factor* (2 * (my_speed) * SIN(d_inc/2)).

    // Create a blank node
    local inc_node to NODE(node_eta, 0, 0, 0).
 // we need to split our dV to normal and prograde
    set inc_node:NORMAL to dvtgt * cos(d_inc/2).
    // always burn retrograde
    set inc_node:PROGRADE to 0 - abs(dvtgt * sin(d_inc/2)).
    set inc_node:ETA to node_eta.

    ADD inc_node.
}



// ==========================================================================


declare function testing {
//	set t0 to time:seconds.
	clearscreen.
	print " ".
	print round(findTimeBetweenTAs(90,30,675000,0.1),4) + "s (should be 277.7919s)".
	print round(findTimeBetweenTAs(180,90,675000,0.1),4) + "s (should be 522.4643s)".
	print " ".
	print sec2min(eta:apoapsis) + " (TTA)".
	print sec2min(findTimeBetweenTAs(180)) + " (should be TTA)".
	print " ".
	print sec2min(eta:periapsis) + " (TTP)".
	print sec2min(findTimeBetweenTAs(0)) + " (should be TTP)".
	print " ".
	print sec2min(findTimeBetweenTAs(0,0),3) + " (should be orbital period)".
	print " ".
//	print "Current TA (KSP, KER)".
//	print orbit:trueanomaly.
//	print orbit:trueanomaly * constant:degtorad.
//	print " ".
//	print "Current SMA (calc,KSP)".
//	print findSMA(orbit:apoapsis,orbit:periapsis).
//	print orbit:semimajoraxis.
//	print " ".
//	print "Current ECC (calc,KSP)".
//	print findEcc(orbit:apoapsis,orbit:periapsis).
//	print orbit:eccentricity.
//	print " ".
//	print "Circularize at Ap".
//	set apVel to findVelAtTA(180).
//	set apCirc to findVelAtTA(180,orbit:apoapsis+body:radius,0).
//	print apVel.
//	print apCirc.
//	print apCirc-apVel.
//	print " ".
//	print "Circularize at Pe".
//	set peVel to findVelAtTA(0).
//	set peCirc to findVelAtTA(180,orbit:periapsis+body:radius,0).
//	print peVel.
//	print peCirc.
//	print peCirc-peVel.
//	print " ".
//	print "Runtime: " + (time:seconds - t0) + "s ".
//	print " ".
}
