run once "common_lib.ks".
clearvecdraws().
clearscreen.
sas off.
rcs off.

if (hastarget = false) {
    print "No target has been selected.".
    list Targets.
}

set ports to target:DOCKINGPORTS.

print "Choose a docking port:".

set dockVecs to list().

for port in ports {
    dockVecs:add(
        VECDRAW(
            port:position,
            v(0,0,0),
            RGB(1,0,0),
            "",
            1.0,
            TRUE,
            0.5  
        )
    ).
}

set loopEnd to 0.

until loopEnd = 1 {
    from {local d is 0.} until d = dockVecs:length step {set d to d + 1.} do {
        local vector is dockVecs[d].
        local port is ports[d].
        if port:tag <> "" {
            set label to  "#"+(d+1) + ": " + port:tag.
        } else {
            set label to "#"+(d+1).
        }
        updateVector(vector, port:position, 50*(port:facing:vector), label).
    }

    set ch to keypoll().
    if (ch > 0) and (ch <= ports:length) {
        set dockPick to ch:toNumber() - 1.
        set loopEnd to 1.
    }

}
print dockpick + 1.

clearvecdraws().

set dock to ports[dockpick].
set dockvec to dockvecs[dockpick].

set controlVector to VECDRAW(
    v(0,0,0),
    v(0,0,0),
    RGB(0,1,0),
    "",
    1.0,
    TRUE,
    0.33  
).

set dockingVector to VECDRAW(
    target:position,
    dock:facing:vector * 25,
    RGB(1,0,0),
    "",
    1.0,
    TRUE,
    0.33  
).

rcs on.

wait 0.1.
set target to dock.
wait 0.1.
clearscreen.

rawraw().

// =========================================================================
// cleanup
// =========================================================================

wait 2.5.
run once "clean.ks".

// =========================================================================
// functions
// =========================================================================

declare function updateVector {
    parameter vector.
    parameter start.
    parameter vec.
    parameter label is "".
    set vector:start to start.
    set vector:vec to vec.
    set vector:label to label.
}

declare function keypoll {
    if terminal:input:haschar {
        return terminal:input:getchar().
    } else {
        return "".
    }
}


declare function rawraw {

    // set zero to ship:controlpart:position.
    set p to 7.
    set i to p / 3.

    set st to target:facing:vector:normalized * -1.
    lock stering to st.
    lock u to (ship:controlpart:facing * R (-90, 0, 0)):vector:normalized.
    lock fwd to ship:controlpart:facing:vector:normalized.
    lock stb to (ship:controlpart:facing * R (0, 90, 0)):vector:normalized.
    lock cls to (target:ship:velocity:orbit - ship:velocity:orbit).

    lock adjustedTargetPosition to target:position - ship:controlpart:position.

    lock uerr to adjustedTargetPosition * u.
    lock ferr to adjustedTargetPosition * fwd.
    lock stberr to adjustedTargetPosition * stb.
    lock dup to cls * u.
    lock dstb to cls * stb.
    lock dfwd to cls * fwd.
    set f to 1.
    set uint to 0.
    set stbint to 0.
    set fint to 0.
    set standoff to adjustedTargetPosition:mag.
    if standoff < 15 {set standoff to 15.}.
    until status = "Docked" {
        set fwddes to (standoff - ferr) / 10.
        if (abs(uerr) < 0.5) and (abs(stberr) < 0.5) {
            set fwddes to (ferr/ 20) * -1.
            set standoff to ferr.
        }.
        if fwddes > 1.5 {set fwddes to 1.5.}.
        if fwddes < -1.5 {set fwddes to -1.5.}.
        set updes to (uerr / 12) * -1.
        set stbdes to (stberr / 12) * -1.
        if updes > 1.5 {set updes to 1.5.}.
        if updes < -1.5 {set updes to -1.5.}.
        if stbdes > 1.5 {set stbdes to 1.5.}.
        if stbdes < -1.5 {set stbdes to -1.5.}.
        set fpot to dfwd - fwddes.
        set upot to dup - updes.
        set stbpot to dstb - stbdes.
        set fint to fint + fpot * 0.1.
        set stbint to stbint + stbpot * 0.1.
        set uint to uint + upot * 0.1.
        if fint > 5 { set fint to 5.}.
        if fint < -5 { set fint to -5. }.
        if stbint > 5 { set stbint to 5.}.
        if uint > 5 { set uint to 5. }. 
        if stbint < -5 { set stbint to -5.}.
        if uint < -5 { set uint to -5. }.
        set fwdctr to fpot * p + fint * i.
        set ship:control:fore to (fwdctr).
        set upctr to upot * p + uint * i.
        set ship:control:top to (upctr).
        set stbctr to stbpot * p + stbint * i.
        set ship:control:starboard to (stbctr).
        // clearscreen.
        set dataout to list().
        dataout:add(ship:controlpart:position).
        dataout:add(target:position).
        dataout:add("fwdctr " + round(fwdctr,3)).
        dataout:add(" upctr " + round(upctr,3)).
        dataout:add("stbctr " + round(stbctr,3)).
        dataout:add("").
        dataout:add("   fwd " + round(ferr, 2) + "m | " + round(dfwd, 2)+"m/s ").
        dataout:add("    up " + round(uerr, 2) + "m | " + round(dup, 2)+"m/s ").
        dataout:add("   stb " + round(stberr, 2) + "m | " + round(dstb, 2)+"m/s ").
        if (abs(uerr) < 0.5) and (abs(stberr) < 0.5) {
            dataout:add("approaching").
        }.
        if (abs(uerr) > 0.5) or (abs(stberr) > 0.5) {
            dataout:add("holding at: " + round(standoff)).
        }.
        readout(dataout,0,0).
        updateVector(dockingVector,target:position, dockvec:vector).
        updateVector(controlVector, ship:controlpart:position, ship:controlpart:facing:vector*(adjustedTargetPosition:mag)).
        wait 0.1.
        if status = "Docked" {break.}
    }.

}