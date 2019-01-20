// Ship structure scanning experiment
// Thanks to Steve Malding for direction (http://forum.kerbalspaceprogram.com/index.php?/topic/61827-113-kos-scriptable-autopilot-system-v100-2016814/&page=179#comment-2732597)

CLEARSCREEN.

set root to ship:rootpart.
set parts to ship:parts.
set clamps to ship:partsdubbed("launchClamp1").

//print root.
//print "-----".
print parts.
print "-----".
print clamps.
print "-----".
print clamps[0]:parent.
print clamps[1]:parent.
print (clamps[0]:parent = clamps[1]:parent).