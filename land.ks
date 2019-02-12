// https://www.reddit.com/r/Kos/comments/3478p2/the_math_and_physics_of_suicide_burns/

wait until ship:unpacked.
run once "common_lib.ks".
clearvecdraws().
clearscreen.

lock g to body:mu / (ship:altitude + body:radius)^2.
lock TWR to ship:availablethrust / ( ship:mass * g ).
lock shipVelocity to ship:velocity:surface:mag.

lock maxAcceleration to TWR * g.

lock burnLength to maneuver_time(shipVelocity).
lock burnDistance to burn_distance(burnLength,shipvelocity).

set tempVariable to 1.
until ((alt:radar - burnDistance) < 10) {
    statusDisplay().
    wait 0.05.
}

unlock burnLength.
unlock burnDistance.

set burnLength to maneuver_time(shipVelocity).
set burnDistance to burn_distance(burnLength,shipvelocity).

set startTime to time:seconds.
set startAlt to alt:radar.

gear on.
set throttle to 1.
statusDisplay().

wait until ABS(shipVelocity) < 1 or ship:verticalspeed > 0.

set throttle to 0.
statusDisplay(ceiling(terminal:height/2)).
print "Actual burn: " + round(time:seconds-startTime,3) + " s" at (1,terminal:height-2).
print "Actual burn: " + round(startAlt - alt:radar,3) + " m" at (1,terminal:height-1).

unlock steering.
unlock throttle.
set throttle to 0.


// ================================================================================

FUNCTION BURN_DISTANCE {
    parameter burn_time is -1.
    parameter speed is 0.
    if (burn_time < 0) return false.
    return ( speed * burn_time ) + ( 0.5 * maxacceleration * burn_time^2).
}

FUNCTION MANEUVER_TIME {
    // https://www.reddit.com/r/Kos/comments/3ftcwk/compute_burn_time_with_calculus/
    PARAMETER dV.

    LIST ENGINES IN en.

    LOCAL f IS en[0]:availablethrust * 1000.  // Engine Thrust (kg * m/s²)
    LOCAL m IS SHIP:MASS * 1000.        // Starting mass (kg)
    LOCAL e IS CONSTANT():E.            // Base of natural log
    LOCAL p IS en[0]:ISP.               // Engine ISP (s)
    LOCAL g IS CONSTANT:g0.             // Gravitational acceleration constant (m/s²)

    RETURN g * m * p * ( 1 - e^( -dV / ( g * p ) ) ) / f.
}

function statusDisplay {
    parameter row is 1.

    set output to list().

    output:add("  g " + round(g,3)).
    output:add("TWR " + round(TWR,3)).
    output:add("=============").
    output:add("ship velocity " + round(shipVelocity,3) + " m/s").
    output:add("ship vert spd " + round(ship:verticalspeed,3) + " m/s").
    output:add("=============").
    output:add(" ship mass " + round(ship:mass*1000,3) + " kg").
    output:add("maxacceler " + round(maxAcceleration,3) + " m/s^2").
    output:add("maneuver t " + round(maneuver_time(shipvelocity),3) + " s").
    output:add("burnlength " + round(burnLength,3) + " s").
    output:add("burnDistnc " + round(burnDistance,3) + " m").
    output:add("=============").
    output:add("radar alt " + round(alt:radar,3) + " m").
    output:add("meand alt " + round(ship:altitude,3) + " m").
    output:add("temp vari " + round(tempVariable,3)).
    readout(output,row,1).
}
