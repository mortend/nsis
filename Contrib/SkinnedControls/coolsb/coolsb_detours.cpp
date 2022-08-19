#include <windows.h>

#include "coolsb_detours.h"
#include "coolscroll.h"

BOOL WINAPI CoolSB_InitializeApp(void)
{
	DWORD dwVersion = GetVersion();

	// Only available under Windows NT, 2000 and XP
	if(dwVersion < 0x80000000)
	{
		return TRUE;
	}
	else
	{
		return FALSE;
	}	
}

BOOL WINAPI CoolSB_UninitializeApp(void)
{
	DWORD dwVersion = GetVersion();

	// Only available under Windows NT, 2000 and XP
	if(dwVersion < 0x80000000)
	{
		return TRUE;
	}
	else
	{
		return FALSE;
	}
}
