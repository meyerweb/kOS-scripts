clearscreen.
set currTime to ceiling(time:seconds).
set phase to "Booster Ascent".
lock srb to ship:partstagged("srb")[0]:getmodule("moduleengines"):getfield("status").
set pathData to lexicon().
set altData to list().
set geoData to list().
set vecData to list().
set phaseData to list().
pathData:add("alt", altData).
pathData:add("geo", geoData).
pathData:add("vec", vecData).
pathData:add("phase", phaseData).

when srb = "flame-out!" then {
  set phase to "Main Engine Ascent".
  stage.
}.

when ship:obt:apoapsis > 75000 then {
  set phase to "Coast to OIB".
  lock throttle to 0.
  lock steering to prograde.
}.

when ship:altitude > 74000 then {
  set phase to "Orbital Insertion Burn".
  lock throttle to 1.
}.

when ship:obt:periapsis > 70500 then {
  set phase to "Orbit Achieved".
  lock throttle to 0.
}.

print "logging data...".
until 0 {
  wait until time:seconds - currTime > 1.
  set currTime to floor(time:seconds).

  if ship:velocity:surface:mag > 1 {
    geoData:add(ship:geoposition).
    altData:add(ship:altitude).
    vecData:add(ship:facing:vector).
    phaseData:add(phase).
    writejson(pathData, "path.json").
  }
}