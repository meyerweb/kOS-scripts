wait until ship:unpacked.
run once "common_lib.ks".
clearvecdraws().
clearscreen.
//sas off.
rcs off.

lock g to body:mu / (ship:altitude + body:radius)^2.
lock TWR to ship:availablethrust / ( ship:mass * g ).
lock shipVelocity to ship:velocity:surface:mag.

lock maxAcceleration to TWR * g.

// lock burnLength to maneuver_time(shipVelocity).
lock burnLength to shipVelocity / maxacceleration.

lock tempVariable to alt:radar - ( ( shipVelocity * burnLength ) + ( 0.5 * maxAcceleration * burnLength^2 ) ).


until tempVariable < 0 {
    statusDisplay().
    wait 0.05.
}
set startTime to time:seconds.

gear on.
set throttle to 1.
statusDisplay().

wait until ABS(shipVelocity) < 1 or ship:verticalspeed > 0.

set throttle to 0.
statusDisplay(15).
print time:seconds-startTime + " s" at (1,terminal:height-1).
unlock throttle.
unlock steering.

// ================================================================================

FUNCTION MANEUVER_TIME {
    PARAMETER dV.

    LIST ENGINES IN en.

    LOCAL f IS en[0]:availablethrust * 1000.  // Engine Thrust (kg * m/s²)
    LOCAL m IS SHIP:MASS * 1000.        // Starting mass (kg)
    LOCAL e IS CONSTANT():E.            // Base of natural log
    LOCAL p IS en[0]:ISP.               // Engine ISP (s)
    LOCAL g IS 9.80665.                 // Gravitational acceleration constant (m/s²)

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
    output:add("burnlength " + round(burnLength,3) + " s").
    output:add("maneuver t " + round(maneuver_time(shipvelocity),3) + " s").
    output:add("=============").
    output:add("radar alt " + round(alt:radar,3) + " m").
    output:add("meand alt " + round(ship:altitude,3) + " m").
    output:add("temp vari " + round(tempVariable,3)).
    readout(output,row,1).
}
