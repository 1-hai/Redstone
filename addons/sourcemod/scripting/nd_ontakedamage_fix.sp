/*
This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/

#include <sourcemod>
#include <sdktools>
#include <nd_breakdown>
#include <nd_commander>

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("GetCommanderTeam");
	MarkNativeAsOptional("GetSniperCount");
	MarkNativeAsOptional("GetStealthCount");
	MarkNativeAsOptional("GetAntiStructureCount");
}

//Version is auto-filled by the travis builder
public Plugin:myinfo =
{
	name 		= "[ND] Damage Fixes",
	author 		= "stickz",
	description 	= "Fixes critical issues with ND damage calculations",
    	version 	= "dummy",
    	url     	= "https://github.com/stickz/Redstone/"
}

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_ontakedamage_fix/nd_ontakedamage_fix.txt"
#include "updater/standard.sp"

ConVar UseClassReset;
ConVar UseSquadBlock;

public OnPluginStart()
{
	HookEvent("player_changeclass", Event_ChangeClass, EventHookMode_Pre);
	HookEvent("player_spawn", Event_ChangeClass, EventHookMode_Pre);
	
	AddCommandListener(CommandListener:CMD_JoinSquad, "joinsquad");
	AddUpdaterLibrary(); //for updater support
	
	UseClassReset = CreateConVar("sm_otdf_creset", "0", "Use class reset feature");
	UseSquadBlock = CreateConVar("sm_otdf_sblock", "0", "Use the squad block feature");
}

public Event_ChangeClass(Handle:event, const String:name[], bool:dontBroadcast) 
{
	CheckCommanderClass(GetClientOfUserId(GetEventInt(event, "userid"))); //CheckCommanderClass(client)
	return Plugin_Continue;
}

public Action:CMD_JoinSquad(client, args)
{
	if (UseSquadBlock.BoolValue && NDC_IsCommander(client))
		return Plugin_Handled;
		
	return Plugin_Continue; 
}

CheckCommanderClass(client)
{
	if (UseClassReset.BoolValue && NDC_IsCommander(client))
	{
		new iClass = GetEntProp(client, Prop_Send, "m_iPlayerClass");
		new iSubClass = GetEntProp(client, Prop_Send, "m_iPlayerSubclass");
		
		if (IsExoSeigeKit(iClass, iSubClass)) 
			ResetClass(client, MAIN_CLASS_EXO, EXO_CLASS_SUPRESSION, 0);

		else if (IsSupportBBQ(iClass, iSubClass))
			ResetClass(client, MAIN_CLASS_SUPPORT, SUPPORT_CLASS_ENGINEER, 0);
			
		else if (IsStealthSab(iClass, iSubClass))
			ResetClass(client, MAIN_CLASS_STEALTH, STEALTH_CLASS_ASSASSIN, 0);
	}
}
