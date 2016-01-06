/*
    A rough fix for building outside of the map (Hydro, Gate, Coast...)

    1.3.9   Test Travis Build System
    
    1.3	    Changes to the plugin for Redstone by Vertex
	
    1.2     more glitches fix (thx Phi)
            using dynamic array
            reversed coordinates

    1.1     initial version

*/


#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.3.9"
#define DEBUG 0

new bool:validMap = false;

new Handle:HAX = INVALID_HANDLE;

new tmpAxisCount;
new tmpAxisViolated;

public Plugin:myinfo = 
{
    name = "[ND] Off Map Buildings Fixes",
    author = "yed_, edited by Stickz",
    description = "Prevents building things in glitched locations",
    version = PLUGIN_VERSION,
    url = "git@vanyli.net:nd-plugins"
}

public OnPluginStart() 
{
    HAX = CreateArray(4);
    
    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    decl String:map[64];
    GetCurrentMap(map, sizeof(map));
    
    ClearArray(HAX);

    if (StrEqual(map, "hydro")) 
  	HandleHydro();
    else if (StrEqual(map, "coast"))
        HandleCoast();
    else if (StrEqual(map, "gate"))
        HandleGate();
  	  	
    validMap = GetArraySize(HAX) > 0;
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
    validMap = false;
}

public OnMapEnd() 
{
    validMap = false;
}

HandleGate() 
{
    /*
    +
    y
    - x +

    this one handles the spot close to prime

    a - 3668.344726 1132.599365 0.000000
    b - 4004.024658 1103.116699 154.177978
    c - 4627.127929 1161.775512 -63.968750
    d - 4634.593750 944.216247 -63.968750

       |
      d|
      cba
       |
       |
    */
    new Float:hax[4] = {0.0, ...};
    hax[0] = 4000.0; //minX
    PushArrayArray(HAX, hax);
}

HandleHydro() 
{
    /*
    -
    y
    + x -

    this one disable building from east secondary to Cons base

    */

    float hax[4] = {
        0.0,
        -7000.0,    //maxX
        0.0,
        -1000.0     //maxY
    };
    PushArrayArray(HAX, hax);
}

HandleCoast() 
{
    /*
    - y +
    x
    +

    roof
    x - 5246.656250 52.499198 1615.631225
    w - 5247.633300 -726.002502 1615.631225
    v - 4465.646484 49.810642 1615.631225
    
    -----v
         |
    w----x
    */

    new Float:hax[4] = {0.0, ...};
    hax[0] = 4466.0;    // minX
    hax[1] = 5246.0;    // maxX
    hax[2] = 0.0;       // minY
    hax[3] = 52.0;      // maxY
    PushArrayArray(HAX, hax);

    /*
    east secondary
    b - 5217.833984 6646.136230 95.915893
    c - 3518.860351 6597.848144 49.899757

     c ------
     |    
     |
     b ------

    - y +
    x
    +
    */

    hax[0] = 3518.0;    // minX
    hax[1] = 5217.0;    // maxX
    hax[2] = 6597.0;    // minY
    hax[3] = 0.0;       // maxY
    PushArrayArray(HAX, hax);
}

public OnEntityCreated(entity, const String:classname[])
{
    if (!validMap)
    {
        #if DEBUG == 1
	PrintToChatAll("debug: Map is Valid");
	#endif
		
	return;	
    }

    if (strncmp(classname, "struct_", 7) == 0) 
        CreateTimer(0.1, CheckBorders, entity);
}

public Action:CheckBorders(Handle timer, any entity) 
{
    float position[3];
    GetEntPropVector(entity, Prop_Data, "m_vecOrigin", position);
    //PrintToChatAll("placed location %f - %f - %f", position[0], position[1], position[2]);
    new Float:hax[4];
    
    for (new i=0; i<GetArraySize(HAX); i++) 
    {
        tmpAxisCount = 0;
    	tmpAxisViolated = 0;
    
    	// minX
    	GetArrayArray(HAX, i, hax);
    	if (hax[0] != 0.0) 
    	{
      	    tmpAxisCount++;
      	    
      	    if (hax[0] < position[0])
      	        tmpAxisViolated++;      
        }
    
        // maxX
    	if (hax[1] != 0.0) 
    	{
      	    tmpAxisCount++;
      			
            #if DEBUG == 1
      	    PrintToChatAll("checking max X hax %f > pos %f?", hax[1], position[0]);
            #endif
      
      	    if (hax[1] > position[0]) 
      	        tmpAxisViolated++;
    	}
    
    	if (hax[2] != 0.0) 
    	{
      	    tmpAxisCount++;
      	    
      	    if (hax[2] < position[1])
      	        tmpAxisViolated++;
    	}
    
    	if (hax[3] != 0.0) 
    	{
      	    tmpAxisCount++;
      			
      	    if (hax[3] > position[1])
      	        tmpAxisViolated++;
    	}
    
    	if (tmpAxisViolated && (tmpAxisCount == tmpAxisViolated)) 
    	    AcceptEntityInput(entity, "Kill");
    }
}
