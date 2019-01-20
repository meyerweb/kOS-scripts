run once "common_lib.ks".

set start to time:seconds.
set interval to 1000.
lock elapsed to (start + interval) - time:seconds.

set warpspeed to getWarpSpeed(interval).
set warp to warpspeed.
print warpspeed.

wait until elapsed < 120.
set warp to 1.
wait until elapsed < 30.
set warp to 0.
