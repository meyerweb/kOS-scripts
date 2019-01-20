// PIDloop()
// https://www.reddit.com/r/Kos/comments/48k7bp/understanding_pidloop/
// IPU: 9/65

SET g TO KERBIN:MU / KERBIN:RADIUS^2.
LOCK accvec TO SHIP:SENSORS:ACC - SHIP:SENSORS:GRAV.
LOCK gforce TO accvec:MAG / g.

SET Kp TO 0.01.
SET Ki TO 0.006.
SET Kd TO 0.006.
SET PID TO PIDLOOP(Kp, Kp, Kd).
SET PID:SETPOINT TO 1.2.

SET thrott TO 1.
LOCK THROTTLE TO thrott.
WAIT UNTIL SHIP:ALTITUDE > 100.
UNTIL SHIP:ALTITUDE > 40000 {
    SET thrott TO thrott + PID:UPDATE(TIME:SECONDS, gforce). 
    //pid:update() is given the input time and input and returns the output. gforce is the input.
    WAIT 0.001.
}