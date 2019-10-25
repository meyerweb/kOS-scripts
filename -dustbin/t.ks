clearscreen.

run once "orbital_mechanics.ks".

from {local x is 31.} until x = 390 step {set x to x+1.} do {
	log x + "	" + round(findTimeBetweenTAs(x,0,675000,0.1),4) to tas.txt.
}
