// Write out planetary data

set bodylist to list(
	"Ciro",
	"Icarus",
	"Thalia",
	"Eta",
	"Niven",
	"Gael",
	"Iota",
	"Ceti",
	"Tellumo",
	"Lili",
	"Gratian",
	"Geminus",
	"Otho",
	"Augustus",
	"Hephaestus",
	"Jannah",
	"Gauss",
	"Loki",
	"Catullus",
	"Tarsiss",
	"Nero",
	"Hadrian",
	"Narisse",
	"Muse",
	"Minona",
	"Agrippina",
	"Julia",
	"Hox",
	"Argo",
	"Leto",

	"Grannus",
	"Sarnus",
	"Hale",
	"Ovok",
	"Eeloo",
	"Slate",
	"Tekto",
	"Urlum",
	"Polta",
	"Priax",
	"Wal",
	"Tal",
	"Neidon",
	"Thatmo",
	"Nissee",
	"Plock",
	"Karen"

).

log("Body|Radius|Mass|GM|RotationPeriod|AtmosphereHeight|SOI") to pd.txt.
for b in bodylist {
	set bodyname to Body(b).
	print bodyname.
	log(bodyname:NAME + "|" + 
		bodyname:RADIUS + "|" + 
		bodyname:MASS + "|" + 
		bodyname:MU + "|" + 
		bodyname:ROTATIONPERIOD + "|" + 
		bodyname:ATM:HEIGHT + "|" + 
		bodyname:SOIRADIUS) to pd.txt.
}
