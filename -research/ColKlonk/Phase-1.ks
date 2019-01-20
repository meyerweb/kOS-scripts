//==============================================================================
//License: The license is that there is no license.
//==============================================================================
//					THE COLONEL'S AUTOMATED KOS PROGRAM 
//						(SCRIPTS and SCRIBBLINGS)
//
//Preamble :- Use at your own risk ;-)
//
// This is a Kerbal Space Program, KOS mod program, for automated launches into
// orbit and docking procedures.
//
// The program is divided into phases..
//  Phase-1 - Launch into pre-orbit (Stages 1 & 2).
//  Phase-2 - Circularise orbit, LAN and Inclination Lock (Stages 3 & 4).
//  Phase-3 - Journey to Target Rendezvous (Stages 5).
//  Phase-4 - Docking procedure (Stage 6).
//
// This current section 'describes' Phase-1.
//
// Notes: 	'Cooked' control is used (planned) for Stages 1 - 5, and possibly
//			stage 6.
//			RAW control might be used later, but unlikely at this moment as
//			KOS's instruction rate relationship with KSP looks a bit slow for 
//			effective control in the early launch stages (1 - 5).
//			It most likely will be used in the last (docking) stage-6 as a high
//			instruction rate is not yet foreseen.
//			This all can change.
//==============================================================================
//==============================================================================

//************** TARGET INFORMATION ********************
//Set Target to VESSEL("DockingTest").					// Set to target name
Set b_Targ to FALSE.									// False for first launch, True for following ships.
Set Targ_INC to 0.										// Default values for first ship (you can change these).
Set Targ_Peri to 0.										//
Set Targ_Apo to 0.										//
Set Targ_LAN TO 0.										//
Set Targ_LANLong TO 0.									//
Set Targ_ArgP to 0.										//
Set Targ_OrbitPeriod to 0.								//
Set Targ_ETA_Apoapsis to 0.								//
Set Targ_ETA_Periapsis to 0.							//

//******************* SHIP Details *********************
Set LUNAR to SHIP:BODY.									// Planet/Body that this ship is orbiting
Set BASE_LAT TO SHIP:GEOPOSITION:LAT.					// Lauchpad Latitude
Set BASE_LONG TO SHIP:GEOPOSITION:LNG.					// Lauchpad Longitude
IF BASE_LONG < 0 {Set BASE_LONG to BASE_LONG + 360.}	// Adjust for [0,359]

Lock Ship_INC to SHIP:ORBIT:INCLINATION.				// Ships Orbital parameters
Lock Ship_Peri to SHIP:ORBIT:PERIAPSIS.					// All locked for easy referencing
Lock Ship_Apo to SHIP:ORBIT:PERIAPSIS.					//
Lock Ship_LAN TO SHIP:ORBIT:LONGITUDEOFASCENDINGNODE.	//
Lock Ship_ArgP to SHIP:ORBIT:ARGUMENTOFPERIAPSIS.		//
Lock Ship_ECC to SHIP:ORBIT:ECCENTRICITY.				//

Lock Ship_OrbPeriod to SHIP:ORBIT:PERIOD.				// 
Lock ETA_ApoTime to ETA:APOAPSIS.                       //
Lock ETA_PeriTime to ETA:PERIAPSIS.                     //
Lock HgtAPO to ALT:APOAPSIS.                            //
Lock HgtPERI to ALT:PERIAPSIS.                          //
Lock Hgt_Ship to SHIP:ALTITUDE.                         //

//**************** Launching Parameters ***************
Set ParkingOrbit to 220000.								// Approx parking orbit 
Set Ship_LAUNCHLong to 0.								// Longitude of launch
Set TtoLaunch to 0.										// Time to launch
Set b_AscNode to TRUE.									// Launch reference on ascending node
Set b_INC_Reduction to FALSE.							// Target INC < Base_LAT - NOT USED AS YET

//****************** Calc_Heights **********************
Set	Hgt_Atmosphere to 0.								// Planet atmospheric height (or target lunar height)
Set	Hgt_01 to 0.										// Action Group trigger heights
Set	Hgt_02 to 0.										//
Set	Hgt_03 to 0.										//

//********************* FLAGS *************************
Set b_TMP to FALSE.										// Temp no particular allocation
Set b_PitchUP to FALSE.									// Pitch ship up
Set b_PitchDWN to FALSE.								// Pitch ship down
Set b_MainLoop to TRUE.									// Main loop controller
Set b_ProGrade to FALSE.								// 

//****************** APOAPSIS TIMES *******************
Set ApoT_List to LIST(0,0,0,0,0,0,0,0).					// Averaging list to 'counter' KSP's nervousness
Set ApoT_ListIndex to 0.                                // Index into list
Set ApoT_AVG to 0.                                      // Current running average 
Set Last_ApoTime to 0.                                  // 
Set OrbitTD2 to 0.                                      //
Set ApoTime to 0.
Set ApoTime_Target to 150.								// How far you want ETA:APOAPSIS ahead of your ship
Set b_PostApo TO FALSE.                                 //
Set D_ApoTime TO 0.                                     //


//***************** CONTROL STUFF *********************
Set myTrottle to 1.										// Engine Throttle
Set ShipPitch to 90.									// Steering stuff
Set ShipHeading to 28.									// Before launch.. orientation of launch pad.
Set MinPitch to 0.										// Do not pitch ship below this number
Set	MaxPitch to 7.5.									// Do not pitch ship above this number
Set	LaunchPitch to 7.5.									// End of turn exit angle - Helps keep apoTime ahead
Set ThisStage to 0.										// Ship stage controller
Set myFuel to 0.										// Well.. I guess it must mean fuel?
Set FlightTime to 240.									//


//************ PRESSURE ENGINE CONTROL *****************
Set ThisCNT to 0.                                       //
Set LastD_Hgt to 0.                                     // 
Set D_Hgt to 0.                                         // Height diff - 1st differential
Set DD_Hgt to 0.                                        // Height diff - 2nd differential
Set MarkSpace to 0.										// Mark/Space  = ON/OFF time for stage 3 engines 
Set GenEngCnt to 0.										// Current engines that are being switched
Set BangCnt to 0.                                       // ON/OFF timer for Mark/Space count

//************ TEST ********************************
Set DDINC to 0.

//******************************************************************************
//******************************************************************************
//						START OF PROGRAM - INITIALISE
//******************************************************************************
//******************************************************************************
ClearScreen.											// Get rid of screen junk
Lock Steering to Heading(ShipHeading,ShipPitch).		// Cooked steering
Lock throttle to myTrottle.								// Cooked throttle
RCS OFF.												// Dont need this yet
SAS OFF.												// Try keep the gimbals from going nuts
SET SASMODE to "STABILITYASSIST".						// I'm a bit unstable :-)

//******************************************************************************
//******************************************************************************
//								MAIN LOOP
//******************************************************************************
//******************************************************************************
Calc_Heights().					// Caculates Planets Orbital paramters
Calc_TargetInformation().		// Assigns Target parameters
Calc_ShipInformation(). 		// Same idea as target
Calc_LaunchAngle().				// As it says
StatInfo_Launch().				// Prints planet parameters
SetWhenWe().					// Early launch stabilisation triggers
Set ThisStage to 0.				// stage sequence controller

UNTIL b_MainLoop = FALSE
{

	IF ThisStage = 0
	{
		Do_Launch().			// Determine launch time and launch
	}
	ELSE IF ThisStage = 1
	{
		Do_Stage1().			// 1st stage full throttle to +-100Km
	}
	ELSE IF ThisStage = 2
	{
		Do_Stage2().			// 2nd stage to just before orbit
	}

//****************************************
// THESE FEW STAGES WILL BE AROUND LATER
//****************************************
//	ELSE IF ThisStage = 3
//	{
//		Do_Stage3().			// Circularise orbit
//		Set ThisStage to 5.
//	}
//	ELSE IF ThisStage = 4
//	{
//		NewStage4_Screen().		// New Info screen
//		NewStage_4().			// Performs LAN and INC locks
//		Set ThisStage to 5.
//	}
//	ELSE IF ThisStage = 5
//	{
//		Stage5().				// The chase to rendezvous
//		Set ThisStage to 6.
//	}
//	ELSE IF ThisStage = 6
//	{
//		Stage6().				// Docking procedure
//		Set ThisStage to 7.
//	}
   	ELSE
	{
		Set b_MainLoop to FALSE.
   		ClearScreen.
// AT THIS POINT ONE WOULD REQUIRE EITHER A SIMPLE PROCEDURE TO KEEP THE BASE
// STATION CORRECTLY ORIENTATED FOREVER... MAYBE PROGRADE SASMODE MIGHT DO THIS.
// PROBLEM IS THAT WHEN YOU EXI THE GAME THERE IS NO RELOADING OF THIS KOS
// PROCEDURE.. SO WOULD PROBABLY HAVE TO BE DONE MANUALLY ON RESTARTING THE GAME.
	}
}
//******************************************************************************
//******************************************************************************
//   					CALCULATE PLANET LAUNCH PARAMETERS
//******************************************************************************
//******************************************************************************
Function Calc_Heights
{
	SET Hgt_Atmosphere TO 15000.				// Default height for planets without atmosphere (moons ?)
	SET b_TMP TO LUNAR:ATM:EXISTS.				// Check for atmosphere - LUNAR is set above to current planet/moon
	IF b_TMP = TRUE 							// Assign new height info
	{
		SET Hgt_Atmosphere TO LUNAR:ATM:HEIGHT.
	}
	Set Hgt_01 to Hgt_Atmosphere * 0.7.			// Used for fairing jettison height
	Set Hgt_02 to Hgt_Atmosphere * 1.0.			// Unused..
	Set Hgt_03 to Hgt_Atmosphere * 1.1.			// Unused..
}
//******************************************************************************
//******************************************************************************
//   						TARGET ORBIT INFORMATION
//******************************************************************************
//******************************************************************************
Function Calc_TargetInformation
{
	// IF A TARGET SHIP IS ASSIGNED, USE IT'S ORBITAL DETAILS
	If b_Targ = TRUE
	{
		Set Targ_INC to Target:ORBIT:INCLINATION.					// Inclination of target
		Set Targ_Peri to Target:ORBIT:PERIAPSIS.					// Target Periapsis
		Set Targ_Apo to Target:ORBIT:APOAPSIS.						// Target Apoapsis

		Set Targ_LAN to Target:ORBIT:LAN.							// Ascendinding node longitude
		IF	Targ_LAN < 0 { Set Targ_LAN to Targ_LAN + 360.}			// Bound checks
		IF	Targ_LAN > 359 { Set Targ_LAN to Targ_LAN - 360.}

		Set Targ_ArgP to Target:ORBIT:ARGUMENTOFPERIAPSIS.			// PERIAPSIS argument.
		IF	Targ_ArgP < 0 { Set Targ_ArgP to Targ_ArgP + 360.}		// Bound checks
		IF	Targ_ArgP > 359 { Set Targ_ArgP to Targ_ArgP - 360.}
	}
	ELSE
	// ON FIRST LAUNCH THERE IS NO TARGET SHIP SO DEFAULT ORBITAL PARAMETERS
	// Set these to your fancy - I just set them for a quick launch
	{
		Set Targ_INC to 90.											// Inclination of target
		Set Targ_Peri to 399000.									// Target Periapsis
		Set Targ_Apo to 400000.										// Target Apoapsis
		Set Targ_LAN to 16.6.										// Ascendinding node longitude
		Set Targ_ArgP to 90.										// PERIAPSIS argument.
	}
}
//******************************************************************************
//******************************************************************************
//   							SHIP ORBIT INFORMATION
//******************************************************************************
//******************************************************************************
Function Calc_ShipInformation
{
	// THE BASE HEMISPHERE DETERMINES LAUNCH DIRECTION AND 
	// WHETHER TO LAUNCH ON LAN OR LDN

	If BASE_LAT < 0													// Determines launch position
	{																// and direction.
		Set b_AscNode to FALSE.
	}
	ELSE
	{
		Set b_AscNode to TRUE.
	}

	IF BASE_LONG < 0												// adjusted for 360 degrees
	{
		Set BASE_LONG to BASE_LONG + 360.
	}
	IF BASE_LONG > 360
	{
		Set BASE_LONG to BASE_LONG - 360.
	}

	Set Ship_LANLong to (Ship_LAN - Ship:ORBIT:BODY:ROTATIONANGLE).
	IF Ship_LANLong < 0 {Set Ship_LANLong to 360 + Ship_LANLong.}	// Bounds check
	IF Ship_LANLong > 360 {Set Ship_LANLong to Ship_LANLong - 360.}	//
}

//******************************************************************************
//******************************************************************************
//								CALCULATE LAUNCH ANGLE
//******************************************************************************
//******************************************************************************
// To obtain a final orbital inclination the ship has to be launched in a 
// certain direction that compensates for earth rotation, final altitude and 
// geographical position of the launch base. This is that algorithm.
// http://www.orbiterwiki.org/wiki/Launch_Azimuth
//******************************************************************************
Function Calc_LaunchAngle
{
Local V_Orb is 0.
Local V_xrot is 0.
Local V_yrot is 0.
Local A_Tmp is 0.
Local B_Tmp is 0.

	Set b_INC_Reduction to FALSE.										// FLAG 

	// TARGET INCLINATION IS AT A HIGHER LATITUDE THAN BASE LATITUDE
	// ENABLES A DIRECT ROUTE TO TARGET INCLINATION

	Set A_Tmp to ABS(BASE_LAT).											//
	IF Targ_INC > A_Tmp													// INCLINATION limitation
	{
		Set B_Tmp to ARCSIN(COS(Targ_INC)/COS(A_Tmp)).					// Desired angle at Base Latitude
		Set V_Orb to SQRT(LUNAR:Mu/(LUNAR:Radius + ParkingOrbit)).		// End Maneuver velocity (orbit insertion)
		Set V_xrot to (V_Orb * SIN(B_Tmp)) - (465.9 * COS(A_Tmp)).		// X-velocity component minus surface velocity at latitude.
		Set V_yrot to (V_Orb * COS(B_Tmp)).								// Y-valocity component.
		Set A_Tmp to ARCCOS(COS(B_Tmp)/SIN(Targ_INC)).					// Asc Node to Base longitudes.
		Set B_Tmp to ARCTAN(V_xrot/V_yrot).								// Launch angle

		IF b_AscNode = TRUE												// Ascending node launch ?
		{
			IF 	B_Tmp < 0 {Set B_Tmp to B_Tmp + 360.}
			IF BASE_LAT > 0
			{
				Set Ship_LAUNCHLong to (BASE_LONG - A_Tmp).
			}
			ELSE
			{
				Set Ship_LAUNCHLong to (BASE_LONG + A_Tmp).
			}
		}
		ELSE															//Descending node launch
		{
			Set B_Tmp to 180 - B_Tmp.
			IF 	B_Tmp < 0 {Set B_Tmp to B_Tmp + 360.}
			IF BASE_LAT < 0
			{
				Set Ship_LAUNCHLong to (BASE_LONG - A_Tmp).
			}
			ELSE
			{
				Set Ship_LAUNCHLong to (BASE_LONG + A_Tmp).
			}
		}

		// APPLY OFFSET ANGLE TO ACHIEVE INCLINATION BEFORE LAST STAGE
		// ** THIS MAY CHANGE FOR DIFFERENT TARGET INCLINATIONS **

		Set Ship_LaunchHead to B_Tmp - 0.9.
		IF Ship_LAUNCHLong < 0 { Set Ship_LAUNCHLong to Ship_LAUNCHLong + 360.}
		IF Ship_LAUNCHLong > 360 { Set Ship_LAUNCHLong to Ship_LAUNCHLong - 360.}

		// SETS THE INCLINATION LOCK TRIGGER POINT
		// ** THIS MAY CHANGE FOR DIFFERENT TARGET INCLINATIONS **

		Set DDINC to ABS(Ship_LaunchHead - (90 - Targ_INC)).
		IF DDINC > 10 {Set DDINC to 360 - DDINC.}
		Set DDINC to DDINC/5.
	}
	ELSE
	// TARGET INCLINATION LESS THAN BASE LATITUDE REQUIRES A 
	// 90 DEGREES LAUNCH PLUS IN-ORBIT MANEUVERS TO LOWER INCLINATION
	// ** THIS HAS NOT BEEN TESTED AND THERE IS NO CODE FOR IT, YET **
	{
		Set b_INC_Reduction to TRUE.
		Set Ship_LaunchHead to 90.
	}
}

//******************************************************************************
//******************************************************************************
// 						STATUS PARAMETERS AT TOP OF SCREEN
//******************************************************************************
//******************************************************************************
// Just displays in-flight parmeters, so you can see what's going on.
//******************************************************************************
Function StatInfo_Launch
{
	IF b_Targ = TRUE
	{	
		Print "Target Vessel       : " + Target:SHIPNAME at (1,1).
	}
	ELSE
	{
		Print "Target Vessel       :    NO TARGET" at (1,1).
	}

	Print "Target Inclination  : " at (1,2).
	Print "Target AscNode      : " at (1,3).
	Print "Target AscNode Long : " at (1,4).

	Print "Ship Launch Long    : " at (1,6).
	Print "Ship AscNode Long   : " at (1,7).
	Print "Ship Inclination    : " at (1,8).

	Print "Ship Heading        : " at (1,10).
	Print "Ship Pitch          : " at (1,11).
	Print "Ship Roll           : " at (1,12).

	Print "SHIP STATUS         : " at (1,15).
}

//******************************************************************************
//******************************************************************************
//						LAUNCH STABILISATION TRIGGERS
//******************************************************************************
//******************************************************************************
// Just sets a few triggers to stabilse early launch
//******************************************************************************
Function SetWhenWe
{
	// EFFECTIVELY THE 'ROLL PROGRAM' TO SET THE ROCKET ON
	// REQUIRED COURSE
	When SHIP:Altitude > 400 THEN
	{
		Set ShipHeading to Ship_LaunchHead.					// Ship_LaunchHead calculated in Calc_LaunchAngle PROCEDURE 
	}

	// SWITCH SAS ON TO STABILISE - DOESN'T ALWAYS WORK !!
	When SHIP:Altitude > 700 THEN
	{
		SAS ON.
		SET SASMODE to "STABILITYASSIST".
	}

	// SWITCH SAS OFF TO BEGIN 'GRAVITY TWITCH'
	When SHIP:Altitude > 1000 THEN
	{
		SAS Off.
	}

	// GIVE 'GRAVITY TWITCH' TIME TO STABLISE THEN SAS ON AGAIN
	When SHIP:Altitude > 1500 THEN
	{
		SAS ON.
		SET SASMODE to "STABILITYASSIST".
	}
}
//******************************************************************************
//******************************************************************************
//							DETERMINES LAUNCH TIME
// 				(This proc might still need some fine tuning - later)
//******************************************************************************
//******************************************************************************
// The ship must be launched at a specific time so as to place it directly
// under the target ships orbit. The targets LAN and ship's current Longitude
// are used for this purpose.
// But that is not enough.. an offset time must be accounted for. This time is
// half the flight time is takes for the ship to obtain the targets inclination.
//******************************************************************************
Function Calc_PreLaunch_Longitude
{
	Set Targ_LANLong to (Targ_LAN - Ship:ORBIT:BODY:ROTATIONANGLE).	// Current Longitude
	IF Targ_LANLong < 0 {Set Targ_LANLong to 360 + Targ_LANLong.}	// Bounds check
	IF Targ_LANLong > 360 {Set Targ_LANLong to Targ_LANLong - 360.}	//

	Set TtoLaunch to (Targ_LANLong - Ship_LAUNCHLong) * 240.		// Convert Longitude to seconds
	Set TtoLaunch to TtoLaunch - FlightTime.						// Adjust for 8 minutes of flight.

	Print Targ_INC at (23,2).										// INFORMATION STATS
	Print Targ_LAN at (23,3).										// Original LAN          							
	Print Targ_LANLong at (23,4).									// The moving LAN
                                        							
	Print Ship_LAUNCHLong at (23,6).								// Launch base longitude
	Print Ship_LAN at (23,7).										// Ascending node
	Print Ship_INC at (23,8).										// Inclination

	If TtoLaunch < 5		// Start launch sequence at 5 seconds
	{                       //
		Return TRUE.        // Flag time to start launch
                            //
	}                       //
	ELSE                    //
	{                       //
		Return FALSE.       // Don't start yet
	}                       //
}

//******************************************************************************
//******************************************************************************
// Calulates the Apoapsis time to be either in front or behind ship, flagging
// if Apoapsis is behind - Used to place all engines at full power to try 
// attempt orbit 'recovery' during launch phase.
//
// Apoapsis time is averaged over 8 samples to try smooth out KSP wild number
// results when Apsides are of nearly equal height.
//
// Apoapsis times are mainly used in the Stage 3 Engine Controller 
//******************************************************************************
//******************************************************************************
Function DoAPOTime
{
	Set Last_ApoTime to ApoTime.							//Save previous time stamp
	Set OrbitTD2 to Ship_OrbPeriod/2.						//Half Orbital period 

	Set ApoT_AVG to ApoT_AVG - ApoT_List[ApoT_ListIndex].	// An Attempt to smooth out 
	Set ApoT_List[ApoT_ListIndex] to (ETA_ApoTime / 8).		// jumping kerbals
	Set ApoT_AVG to ApoT_AVG + ApoT_List[ApoT_ListIndex].	//
	Set ApoT_ListIndex to ApoT_ListIndex + 1.
	If ApoT_ListIndex > 7 {Set ApoT_ListIndex to 0.}

	Set ApoTime to Ship_OrbPeriod - ApoT_AVG.				//Get time to APOAPSIS 
	IF ApoTime > OrbitTD2									//
	{ 														// APOAPSIS IS AHEAD OF SHIP
		Set b_PostApo to FALSE.								// De-Flag it
		Set ApoTime to ApoT_AVG.							// Recalculate
	}
	ELSE
	{ 														// APOAPSIS IS BEHIND SHIP
		Set b_PostApo to TRUE.								// Flag it
		Set ApoTime to ApoT_AVG - Ship_OrbPeriod.			//Get time to APOAPSIS 
	}
	Set D_ApoTime to ApoTime - Last_ApoTime.				// APOAPSIS TIME RATE		
}

//******************************************************************************
//**************************ENGINE CONTROLLERS**********************************
//******************************************************************************
//******************************************************************************
// 			RD-120s THROTTLE FROM 50-110%, SO WE'LL MAKE IT FROM 50-100%
//******************************************************************************
//******************************************************************************
// Rocket engines are mostly more efficient at full power, so this procedure is
// hardly used for throttle control but more for pitch control.
// I've just combined the two operations as it's easier to implement.
//******************************************************************************
Function EngCtl_RD120
{
local mT is 0.
local mT2 is 0.

	// IF APOAPSIS HAS PASSED WE'RE A BIT LATE AND MUST THROTTLE UP TO BRING
	// APOAPSIS IN FRONT AGAIN. 
	// PITCHING UP ALSO HELPS BUT ALSO INCREASES THE APOAPSIS HEIGHT

	IF b_PostApo = TRUE							// APOAPSIS has slipped by ??
	{											//
		Set mT to myTrottle + 0.01.				// 
		IF mT > 1								// Already at max throttle - Pitch up
		{										//
			Set mT to 1.						// Max throttle
			Set b_PitchUP to TRUE.				// Pitch control flags
			Set b_PitchDWN to FALSE.			//
		}										//
		Set myTrottle to mT.					// Thtrottle assignment to locked variable
	}											//

	// APOAPSIS IS NORMALLY IN FRONT, BUT WE MUST NOT LET IT RUN AWAY AS THEN
	// WE'LL HAVE A VERY ECCENTRIC ORBIT TO CORREECT COSTING EXTRA DELTA-V
	// TWO TIME LIMITS ARE IMPLEMENTED TO THROTTLE BACK IF APOTIME RUNS AWAY	
	ELSE										// APOAPSIS is ahead
	{
		Set mT2 to FALSE.
		IF ApoTime > ApoTime_Target				// APOAPSIS time limit has been reached
		{
			Set mT2 to TRUE.
		}
		IF ApoTime > 60							// APOAPSIS time limit has been reached
		{
			Set mT2 to TRUE.
		}

		// APOAPSIS TIME RUN-AWAY FLAGGED - THROTTLE BACK OR PITCH DOWN
		If mT2 = TRUE
		{
			IF Hgt_Ship > Hgt_01				// Above Minumum Pitching height
			{
				IF D_ApoTime > 0				// Gap is widening
				{
					IF ShipPitch > MinPitch		// Pitch down if necessary
					{
						Set b_PitchUP to FALSE.
						Set b_PitchDWN to TRUE.
					}
					Set mT to myTrottle - 0.01.
					If mT < 0.5
					{
						Set mT to 0.5.
					}
					Set myTrottle to mT.
				}
				ELSE							// Gap is narrowing, leave
				{								
					Set b_PitchUP to FALSE.			
					Set b_PitchDWN to TRUE.		// Pitch down if necessary
				}
			}
		}

		// APOAPSIS TIME NORMAL
		ELSE										// APOAPSIS time limit has not been reached
		{
			IF Hgt_Ship > Hgt_01					// Above Minumum Pitching height
			{
				IF D_ApoTime < 0					// APOAPSIS gap is narrowing - Crank it up!!	
				{
					Set mT to myTrottle + 0.01.
					IF mT > 1						// Already at max throttle - Pitch up
					{
						Set mT to 1.
						Set b_PitchUP to TRUE.
						Set b_PitchDWN to FALSE.
					}
					Set myTrottle to mT.
				}
				ELSE								// APOAPSIS gap is widening - Pitch down if necessary
				{
					Set b_PitchUP to FALSE.
					Set b_PitchDWN to TRUE.
				}
			}
			ELSE								// Below MinPitch - In early launch stage
			{
				Set b_PitchUP to FALSE.
				Set b_PitchDWN to FALSE.
				IF D_ApoTime < 0				// Gap is narrowing - Crank it up	
				{
					Set mT to myTrottle + 0.01.
					IF mT > 1					// Already at max throttle - Pitch up
					{
						Set mT to 1.
					}
					Set myTrottle to mT.
				}
			}
		}
	}
}
//******************************************************************************
//******************************************************************************
//								Pitch Angle Control
//
// - During Stage-1 sets a altitude dependent pitch profile. (this profile will
//   be changed in the near future once everything is working well).
// - During Stage-2 a Max/Min Pitch Angle (7.5/0) is used for APOAPSIS time
//   management.
//******************************************************************************
//******************************************************************************
Function DoPitchAngle
{
local P is 0.

	// PITCH CONTROL WHILE SASMODE IS NOT SET TO 'PROGRADE'
	IF b_ProGrade = FALSE
	{
		Set P to ShipPitch.
		IF	Hgt_Ship > Hgt_01							// Minimum Pitching heights
		{
			IF b_PitchUP = TRUE
			{
				Set P to ShipPitch + 0.01.
				IF P > MaxPitch							// Do want it going on forever
				{										// Max is 7.5 degrees
					Set P to MaxPitch.
				}
				PRINT "Pitch UP  " AT (40,1).
			}
			ELSE IF b_PitchDWN = TRUE
			{
				Set P to ShipPitch - 0.01.
				IF P < MinPitch							// Min is Zero
				{
					Set P to MinPitch.
				}
				PRINT "Pitch DOWN" AT (40,1).
			}
			ELSE
			{
				PRINT "          " AT (40,1).
			}
		}
		ELSE											// Standard rotation
		{
			// STAGE-1 CONTROL SECTION ABOVE 1000m
			IF Hgt_Ship > 1000
			{
				Set P TO 85 - ((85 * Hgt_Ship) / Hgt_01).
			}
			ELSE
			// STAGE-1 CONTROL SECTION BELOW 1000m (STRAIGHT UP)
			{
				Set P to 90.
			}
			if P < LaunchPitch {Set P to LaunchPitch.}
		}
		Set ShipPitch to P.
	}
}
//******************************************************************************
//******************************************************************************
//	Sets Inclination Lock point, and controls ship direction in a manner
//  proportional to the Ship/Target Inclination difference.
// 
//  The lock point and proportional gradient factor might change for lower
//  inclination orbits, as it's only been tested on a polar orbit.
//******************************************************************************
//******************************************************************************
Function DoHeading_Stage2Plus
{
local d_Inc is 0.
local B is 0.

	IF b_ProGrade = FALSE										// Only function under no PROGRADE
	{
		Set d_Inc to (Targ_INC - Ship_INC).						// Inclination difference
		IF ABS(d_Inc) < DDINC									// Within lock limit ?
		{
			Set B to 90 - (Targ_INC + (5 * d_Inc)).				// Calc new ship heading
			IF B < 0 {Set B to B + 360.}						// limti check/adjust
			IF B > 360 {Set B to B - 360.}
			Set ShipHeading to B.								// Find I have to reassign
			Lock Steering to Heading(ShipHeading,ShipPitch).	// for it to work ??
			PRINT "LOCKING TO INCLINATION     " at (23,15).		// MONITOR MESSAGE
			PRINT ShipHeading at (23,10).
			IF ABS(d_Inc) < 0.02								// PROGRADE ASSIGNMENT TRIGGER
			{													// It take a while for the ship
				lock steering TO SHIP:PROGRADE.					// to settle so I found that a
				Set b_ProGrade to TRUE.							// 0.02 degree trigger point works
				PRINT "PROGRADE               " at (23,10).		// fairly well.
			}
		}
	}
}

//******************************************************************************
//****************************** LAUNCH STAGES *********************************
//******************************************************************************
//******************************************************************************
// Controls the launch procedure before liftoff.
//
// Calls 'Calc_PreLaunch_Longitude' to detemine when to launch. This could be 
// 24 hours, so make sure your ship has ground fuel and power supplied.
// Runs a countdown sequence of 5 seconds (exciting ?).
// Start main engines and then releases towers and clamps for a launch.
//******************************************************************************

Function Do_Launch
{
	// STOP GIMBALS GOING NUTS - AN ANNOYING VISUAL :-)
	SAS ON.
	SET SASMODE to "STABILITYASSIST".	

	// MONITOR SCREEN INFO
	Print "WAITING FOR LAUNCH         " at (23,15).
	Print "SECONDS TO LAUNCH.. :                            "  at (1,17).

	// TRIGGERS LAUNCH SEQUENCE AT CORRECT TIME
	Until Calc_PreLaunch_Longitude() = TRUE
	{
		Print TtoLaunch at (23,17).
	}

	// LAUNCH SEQUENCE HAS STARTED
	PRINT "COUNTDOWN COMMENCING       " AT (23,15).
	FROM {local countdown is 5.} UNTIL countdown = 0 STEP {SET countdown to countdown - 1.} DO
	{
		PRINT "                           "  AT (23,17).
		PRINT countdown AT (23,17).

		// GIVE MAIN ENGINES A SECOND TO THROTTLE UP 
		// PREVENTS ROCKETS FROM SINKING INTO LAUNCHPAD
		IF countdown = 1
	 	{
			Set myTrottle to 1.
			PRINT "MAIN ENGINE IGNITION       " AT (23,15).
			Toggle (AG248).
		}
	    WAIT 1.
	}
	Toggle (AG250).											// Main Tower release action group
	wait 0.001.												// Proverbial KOS delay to make things work 
	SAS OFF.												// Gimbals are stable at this stage
	Toggle (AG249).											// Base Clamp release action group
	PRINT "WE HAVE A LAUNCH !         " AT (23,15).			// Tell the world
	Set ThisStage to 1.										// Set stage controller to next stage
}

//******************************************************************************
//******************************************************************************
//								STAGE-1
// Stage-1 one has a couple of RD120s, plus extra tanks, also with RD120s.
// It pushes the ship up to approx 130Km, Dropping SRB side tanks on the way.
//
// The SRB's shpuld be dropped at about 40Km and end-of-stage velocity should be
// around 2690 m/s. If it is lot less the rocket might not make orbit.
// This is the Stage-1 check point for abort procedure (err.. blow it up with
// the big red button)
//
// This stage experiences a max of 5Gs
//******************************************************************************
//******************************************************************************
Function DO_STAGE1 
{
local b_Proc is FALSE.
local b_ThisTrig is FALSE.

	// MONITOR SCREEN INFO
	PRINT "STAGE 1 -- LAUNCH          " AT (23, 15).
	PRINT "FUEL                :                            " AT (1,17).

	// TRIGGER - DUMP PAYLOAD FAIRING AT Hgt_01	
	When Ship:Altitude > Hgt_01 then
	{
		Toggle (AG243).								// Fairing Action Group
	}

	// DUMP SIDE SRB TANKS 
	// THE FUEL LEVEL IS THE STAGES TOTAL FUEL - BIT OF A MISSION TO FIDDLE
	Set myFuel to STAGE:LQDHYDROGEN.
	when myFuel < 380000 then
 	{
		Toggle (AG247).								// SRB Action Group
	}

	//********************************************
	// 				STAGE-1 MAIN LOOP
	//****************************************T****
	Set b_Proc to TRUE.
	UNTIL b_Proc = FALSE
	{
		DoAPOTime().								// Apside time calcs
		EngCtl_RD120().								// Engine control
		DoPitchAngle().								// Pitch control

		// ALWAYS LH FOR FUEL CHECKS - IT DISSAPEARS FASTER WITH BOIL OFF
		// SETS FUEL POINT TO TRIGGER STAGE SEPARATION

		Set myFuel to STAGE:LQDHYDROGEN.			// Repeat fuel assignment to work
		If myFuel < 20	 							// Fuel level
		{
			Toggle (AG246). 						// Stage 2 Action Group
			Wait 0.5.								// Proverbial wait for AGs to work
			Set myTrottle to 1.						// Always KSP.. does funny things
			Toggle (AG245).							// Start Stage-2 RD120 Engines Action Group
			Set b_Proc to False.					// Exit this loop
			Set ThisStage to 2.						// Set next function (Stage)
		}

		// MONITOR SCREEN INFO
		PRINT myFUEL AT (23,17).
		PRINT Ship_LAN at (23,7).
		PRINT Ship_INC AT (23,8).
		PRINT ShipHeading at (23,10).

		Set Targ_LANLong to (Targ_LAN - Ship:ORBIT:BODY:ROTATIONANGLE).
		IF Targ_LANLong < 0 {Set Targ_LANLong to 360 + Targ_LANLong.}
		IF Targ_LANLong > 360 {Set Targ_LANLong to Targ_LANLong - 360.}
		Print Targ_LANLong at (23,4).

		WAIT 0.001.
	}
}
//******************************************************************************
//******************************************************************************
//								STAGE-2
// Same as Stage-1 but now we're at 100Km+ and the race for orbital speed is on.
//******************************************************************************
//******************************************************************************
Function DO_STAGE2
{
local b_Proc is FALSE.

	// MONITOR SCREEN INFO
	PRINT "STAGE 2 -- PRE-ORBIT       " AT (23, 15).
	PRINT "FUEL                :                            " AT (1,17).
	PRINT "APOAPSIS TIME       :                            " AT (1,19).
	PRINT "APOAPSIS            :                            " AT (1,21).
	PRINT "PERIAPSIS           :                            " AT (1,23).
	PRINT "Prograde            :                            " AT (1,25).


	TOGGLE (AG1).			// COM32 aerial Action Group
	WAIT 0.01.
	TOGGLE (AG9).			// NAV LIGHTS Action Group
	WAIT 0.01.
	TOGGLE (AG10).			// LIGHTS Action Group
	//********************************************
	// 				STAGE-2 MAIN LOOP
	//********************************************
	Set b_Proc to TRUE.
	UNTIL b_Proc = FALSE
	{
		DoAPOTime().								// Apside time calcs
		EngCtl_RD120().								// Engine control

		IF b_ProGrade = FALSE						// Pitch control only if not
		{											// SASMODE 'PROGRADE'
			DoPitchAngle().							// Pitch control
		}
		DoHeading_Stage2Plus().						// 
		Set myFuel to STAGE:LQDHYDROGEN.
		If myFuel < 20
		{
			Toggle (AG244).
			Set myTrottle to 1.
			Set b_Proc to False.
			Set ThisStage to 3.
			Toggle (AG90).			// Separate payload from that big empty tank
			Wait 2.					// 2 secs is enough
			Toggle (AG89).			// 
		}

		// MONITOR SCREEN INFO
		PRINT Ship_LAN at (23,7).
		PRINT Ship_INC AT (23,8).
		PRINT myFUEL AT (23,17). 					//Fuel monitor 
		PRINT ApoTime AT (23,19).
		PRINT HgtAPO AT (23,21).
		PRINT HgtPERI AT (23,23).
		PRINT b_ProGrade AT (23,25).

		Set Targ_LANLong to (Targ_LAN - Ship:ORBIT:BODY:ROTATIONANGLE).
		IF Targ_LANLong < 0 {Set Targ_LANLong to 360 + Targ_LANLong.}
		IF Targ_LANLong > 360 {Set Targ_LANLong to Targ_LANLong - 360.}
		Print Targ_LANLong at (23,4).
		WAIT 0.001.
	}
}
//******************************************************************************
//								MORE	LATER
//******************************************************************************