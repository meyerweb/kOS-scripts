parameter dV is 100.

print dV + "dV maneuver".
set burnTime to maneuver_time(dV).
print "Burn time is " + burnTime.

set throttle to 1.
wait burnTime.
set throttle to 0.
unlock throttle.


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
