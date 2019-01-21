run once "common_lib.ks".
clearvecdraws().

if (hastarget = false) {
    print "No target has been selected.".
    list Targets.
}

set ports to target:DOCKINGPORTS.

print ports.

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
            0.67  
        )
    ).
}

set loopEnd to 0.

until loopEnd = 1 {
    from {local d is 0.} until d = dockVecs:length step {set d to d + 1.} do {
        local vector is dockVecs[d].
        local port is ports[d].
        set vector:start to port:position.
        set vector:vec to 50*(port:portfacing:vector).
        if port:tag <> "" {
            set vector:label to  "#"+(d+1) + ": " + port:tag.
        } else {
            set vector:label to "#"+(d+1).
        }
    }
    if terminal:input:haschar {
        set ch to terminal:input:getchar().
        if (ch > 0) and (ch <= ports:length) {
            set dockPick to ch:toNumber() - 1.
            set loopEnd to 1.
        }
    }
}


clearvecdraws().