run once "common_lib.ks".
clearscreen.

//ER = Error
//PT = Previous time
//TS = Time step
//VP = vessel position (in a global vector mode)
//TL = Terrain level = geolocation under predicted vessel position

Set ER to 1000.
Set PT to Time:Seconds.
Set TS to 1.

until alt:radar < 1 {
    //Set VP to vessel position at PT + TS.
    Set VP to POSITIONAT(SHIP,(PT + TS)).
    
    //Set TL to VP:geolocation.
    set TL to BODY:GEOPOSITIONOF(VP):TerrainHeight.
    Set ER to ((VP - BODY:POSITION):MAG - BODY:RADIUS - TL).
    Set PT to PT + TS.

    set output to list().

    output:add("VP " + VP).
    output:add("").
    output:add("MG " + VP:MAG).
    output:add("TL " + TL).
    output:add("ER " + ER).
    output:add("PT " + PT).
    readout(output).
    wait 0.5.
}.

print (PT + TS) - time:Seconds.
