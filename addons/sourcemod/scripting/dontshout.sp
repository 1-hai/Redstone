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

#pragma semicolon 1

#include <sourcemod>

#define MAX_LINE_LENGTH			   192		// maximum length of a single line of text
#define PLUGIN_DEBUG				 1		// debug mode enabled when set

ConVar g_minAlphaCount;		// minimum amount of alphanumeric characters
ConVar g_maxPercent;			// Maximum percent of characters thay may be uppercase
ConVar g_isEnabled;			// Var for storing whether the plugin is enabled

//Version is auto-filled by the travis builder
public Plugin myinfo = 
{
	name 		= "Don't Shout",
	author		= "Brainstorm, stickz",
	description 	= "Changes chat messages to lowercase when they are (almost) fully in uppercase",
	version 	= "dummy",
	url 		= "http://"	
};

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/dontshout/dontshout.txt"
#include "updater/standard.sp"

public void OnPluginStart()
{
	// load translation files
	LoadTranslations("common.phrases");

	// create convars
	g_isEnabled = CreateConVar("bd_shout_enabled", "1", "Whether the anti-shout plugin is enabled.", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	g_maxPercent = CreateConVar("bd_shout_percent", "0.7", "Percent of alphanumeric characters that need to be uppercase before the plugin will kick in.", 0, true, 0.01, true, 1.0);
	g_minAlphaCount = CreateConVar("bd_shout_mincharcount", "6", "Minimum amount of alphanumeric characters before the sentence will be altered.");

	// listen for commands
	RegConsoleCmd("say", Command_HandleSay);
	RegConsoleCmd("say2", Command_HandleSay);
	RegConsoleCmd("say_team", Command_HandleSay);
	
	AddUpdaterLibrary(); //auto-updater
}

public Action Command_HandleSay(int client, int args)
{
	// do not handle console stuff and do not work when the plugin is disabled
	if (client < 1 || !g_isEnabled.BoolValue)
		return Plugin_Continue;

	// get argument string
	decl String:argString[MAX_LINE_LENGTH];
	GetCmdArgString(argString, sizeof(argString));
	
	int upperCount = 0;			// total amount of upper text chars
	int totalCount = 0;			// total amount of text chars (no numeric or other chars)
	for (int i = 0; i < strlen(argString); i++)
	{
		if (IsCharAlpha(argString[i]))
		{
			totalCount++;
			if (IsCharUpper(argString[i]))
			{
				upperCount++;
			}
		}
	}
	
	// calculate percentage of characters that is uppercase
	float percentageUpper = float(upperCount) / float(totalCount);

	if (totalCount >= g_minAlphaCount.IntValue && percentageUpper >= g_maxPercent.FloatValue)
	{
		// remove the surrounding quotes, if they are present
		if (argString[0] == '"' && argString[strlen(argString) - 1] == '"')
		{
			// bit of an ugly call to substring, but it'll always work here.
			SubString(argString, argString, 1, strlen(argString) - 1);
		}
		
		// replace all alphanumeric chars, except the first char
		for (int i = 1; i < strlen(argString); i++)
		{
			if (IsCharAlpha(argString[i]))
			{
				argString[i] = CharToLower(argString[i]);
			}
		}
		
		// get the original command
		char command[20];
		GetCmdArg(0, command, sizeof(command));

		// Have the client say the altered text.
		FakeClientCommand(client, "%s \"%s\"", command, argString);
		
		// We've handled it.
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

/*
 * Converts a string entirely to lowercase characters
 * @param arg		Text to convert to lowercase
 */
public void StrToLower(String:arg[])
{
	for (new i = 0; i < strlen(arg); i++)
	{
		arg[i] = CharToLower(arg[i]);
	}
}

/*
 * Calls the GetClientName() function, but replaces the name of client 0 (the console)
 * with a small piece of text, instead of the entire server name.
 */
public void ClientName(client, String:name[MAX_NAME_LENGTH])
{
	if (client == 0)
	{
		name = "[console]";
	}
	else
	{
		GetClientName(client, name, sizeof(name));
	}
}

/*
 * Copies a part of a string to a new string.
 * @param text			Source text from which the characters are copies
 * @param result		Destionation string
 * @param startIndex	Position in the source string at which copying will start. Zero based.
 * @param endIndex		Position in the source string at which copying will end. This means the character specified by the end index is NOT copied.
 */
public void SubString(const String:text[], String:result[MAX_LINE_LENGTH], startIndex, endIndex)
{
	// check input
	new length = endIndex - startIndex;
	if (length <= 0 || startIndex >= strlen(text))
		return;

	// perform char-by-char copy
	for(new index = 0; index < length; index++)
	{
		result[index] = text[index + startIndex];
	}

	// add termination character	
	result[length] = '\0';
}
