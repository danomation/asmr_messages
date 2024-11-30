#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

public Plugin myinfo =
{
        name = "You're welcome.",
        author = "SEA.LEVEL.RISESâ„¢",
        description = "You're welcome, and other fanciful things!",
        version = "0.4",
        url = "sealevelrises.net"
}


char Steam3ClientsOfInterest[][] = {
        // format "[STEAMID3]"
};

//static char Steam3ClientsWithLockedThanks[][][] = {
//        { "[U:1:10654161]", 19 }, // cartesian bear, (duck *)
//};

static int g_iPlayersWithLockedThanks[MAXPLAYERS];
//static char g_sPlayerLockedThanks[MAXPLAYERS][7];


ArrayList EventMessageClients;
int EventMessageClientCount = 0; // literally over-optimization


static bool g_bIsDystopia = false;
static char g_sCurrentMap[64];

static int g_iThankfulClient = 0;

static char g_sPunksThanksFormat[] = "\x087d2828(%s) \x08ff3d3d%N\x01: %s\x0a";
static char g_sCorpsThanksFormat[] = "\x082b4482(%s) \x084a7eff%N\x01: %s\x0a";


/* You're welcome. */
Handle Timer_YoureWelcome = INVALID_HANDLE;
Action YoureWelcomeChat( Handle timer ) {
        PrintToChatAll( "You're welcome." );
        Timer_YoureWelcome = INVALID_HANDLE; // extremely necessary
        return Plugin_Stop;
}


char ThanksInOtherLanguages[][] = {
        "Thanks",               // English
        "Thanks eh",    // Canadian
        "Ø´ÙƒØ±Ø§",                 // Arabic
        "Merci",                // French
        "Danke",                // German
        "Mahalo",               // Hawaiian
        "×ª×•×“×”",                 // Hebrew
        "ã‚ã‚ŠãŒã¨ã†",           // Japanese
        "è°¢è°¢",                 // Mandarin
        "Ð¡Ð¿Ð°ÑÐ¸Ð±Ð¾",              // Russian
        "Gracias",              // Spanish
        "Ngiyabonga",   // Zulu
        "qatlho'",              // Klingon
        "      ",               // Invisible
        "Quack",                // goose
        //"Meow",
        "ê°ì‚¬",                 // Korean
        "01010100 01101000 01100001 01101110 01101011 01110011",        // Binary
        "v54",                  // honk
        "Honk",                 // duck
        "QUACK!",               // (duck *) cartesian_bear = nullptr;
};

char WhichLanguageWasThat[][] = {
        "English",
        "Canadian",
        "Arabic",
        "French",
        "German",
        "Hawaiian",
        "Hebrew",
        "Japanese",
        "Mandarin",
        "Russian",
        "Spanish",
        "Zulu",
        "Klingon",
        "Invisible",
        "Duck",
        //"Cat",
        "Korean",
        "Binary",
        "v54",
        "Goose",
        "(duck *)",
};


public void OnPluginStart() {
        char game[64];
        GetGameFolderName( game, sizeof(game) );

        if ( !StrEqual( game, "dystopia", false ) )
                return;

        g_bIsDystopia = true;

        HookEvent( "round_restart", Event_RoundRestart, EventHookMode_Post );

        HookUserMessage( GetUserMessageId( "VoiceComm" ), MsgHook_DysVoiceComm, true, MsgPostHook_DysVoiceComm );

        RegAdminCmd( "thanks_test", ThanksTest, ADMFLAG_RCON );

        HookEvent( "player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre );

        // Clients to send debug messages to
        EventMessageClients = CreateArray( /* default is 1, 0 */ );

        // Scan connected clients, like if the plugin is reloaded
        int cc = GetClientCount();
        while ( cc ) {
                if ( IsClientConnected(cc) && !IsFakeClient(cc) && IsClientAuthorized(cc) ) {
                        CheckEventMessageClient(cc);
                        //CheckLockedThanksClient(cc);
                        //EXPERIMENTAL FUNCTION BY ALPHA
                        if (IsPlayerAlive(cc)) {
                                char cid[64];
                                GetClientAuthString(cc, cid, sizeof(cid));
                                char nick[64];
                                GetClientName(cc, nick, sizeof(nick));
                                float locbuff[3];
                                GetClientAbsOrigin(cc, locbuff);
                                PrintToConsoleAll("client: %s, name:%s, position: %f, %f, %f", cid, nick, locbuff[0], locbuff[1], locbuff[2]); 
                        }
                }
                cc--;
        }
}

public Action Event_PlayerDisconnect( Handle:event, const String:name[], bool:dontBroadcast ) {
        if ( !dontBroadcast ) {

                int client = GetClientOfUserId( GetEventInt(event, "userid") );

                if ( client ) {
                        char reason[255];
                        GetEventString(event, "reason", reason, sizeof(reason));

                        char message[255];
                        Format(
                                message,
                                sizeof(message),
                                "%L (%s)",
                                client,
                                reason
                        );

                        SendEventMessage( "Disconnect", message, true );
                }

                SetEventBroadcast( event, true );
        }

        return Plugin_Continue;
}


public void OnClientPostAdminCheck( int client ) {
        CheckEventMessageClient(client);
        //CheckLockedThanksClient(client);
}

//void CheckLockedThanksClient ( int client ) {
//        if ( !IsFakeClient(client) || !IsClientAuthorized(client) )
//                return;
//
//        char auth[64];
//        if ( !GetClientAuthId( client, AuthId_Steam3, auth, sizeof(auth), true ) )
//                return;
//
//        //for ( int j = 0; j < sizeof(Steam3ClientsWithLockedThanks); j++ ) {
//        //        if ( 0 == strcmp( Steam3ClientsWithLockedThanks[j][0], auth, false ) ) {
//        //                g_iPlayersWithLockedThanks[client] = 1;
//        //                g_sPlayerLockedThanks[client][1] = Steam3ClientsWithLockedThanks[j][1];
//        //                continue;
//        //        }
//        //}
//}

int GetEventMessageClient( int index ) {
        return GetArrayCell( EventMessageClients, index, 0, false );
}

void CheckEventMessageClient( int client ) {
        if ( !IsFakeClient(client) || !IsClientAuthorized(client) )
                return;

        char auth[64];
        if ( !GetClientAuthId( client, AuthId_Steam3, auth, sizeof(auth), true ) )
                return;

        for ( int k = 0; k < sizeof(Steam3ClientsOfInterest); k++ ) {

                if ( strcmp( auth, Steam3ClientsOfInterest[k] ) != 0 )
                        continue;

                PushArrayCell( EventMessageClients, client );
                EventMessageClientCount++;
                return;

        }
}

void SendEventMessage( const char[] event_name, const char[] message, bool print_chat=true ) {
        if ( !EventMessageClientCount )
                return;

        int client;
        int j = EventMessageClientCount;
        while ( j ) {
                j--;

                if ( !(client = GetEventMessageClient(j)) )
                        continue;

                if ( print_chat )
                        PrintToChat( client, "\x04%s\x01: %s", event_name, message );

                PrintToConsole(
                        client,
                        "\x04%s\x01: %s",
                        event_name,
                        message
                );
        }

}

public void OnClientDisconnect( int client ) {
        g_iPlayersWithLockedThanks[client] = 0;

        if ( EventMessageClientCount ) {
                int cell;

                int j = EventMessageClientCount;
                while ( j ) {
                        j--;

                        if ( (cell = GetEventMessageClient(j)) && client == cell ) {
                                RemoveFromArray( EventMessageClients, j );
                                EventMessageClientCount--;
                                return;
                        }
                }
        }
}

public void OnMapStart() {
        if ( !g_bIsDystopia )
                return;

        GetCurrentMap( g_sCurrentMap, sizeof(g_sCurrentMap) );

        FindThemAndDestroyThem();

        // char soundname[255];
        // for ( int i = 0; i < sizeof(ThanksInOtherVoices); i++ ) {
                // if ( !PrecacheSound( ThanksInOtherVoices[i] ) ) {
                        // ThrowError( "Failed to precache sound: %s", ThanksInOtherVoices[i] );
                // }
                // Format( soundname, sizeof(soundname), "sound/%s", ThanksInOtherVoices[i] );
                // if ( !AddFileToDownloadsTable( soundname ) ) {
                        // ThrowError( "Failed to add file to downloads table: %s", soundname );
                // }
        // }
}

public Action Event_RoundRestart( Event event, const char[] name, bool dontBroadcast ) {
        if ( !g_bIsDystopia )
                return Plugin_Continue;

        FindThemAndDestroyThem();

        return Plugin_Continue;
}

// char ThanksInOtherVoices[][] = {
        // "asmr/v54_1.wav",
// };

// char WhoseVoiceWasThat[][] = {
        // "Therm0ptic",
        // // "Prox",
// };

Action MsgHook_DysVoiceComm( UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init ) {
        int client = msg.ReadByte(); // client id
        int category = msg.ReadByte();
        int slot = msg.ReadByte();

        if ( category != 5 || slot != 4 )
                return Plugin_Continue;

        if ( Timer_YoureWelcome != INVALID_HANDLE )
                CloseHandle(Timer_YoureWelcome);

        Timer_YoureWelcome = CreateTimer( 3.0, YoureWelcomeChat );

        if ( g_iPlayersWithLockedThanks[client] ) {
                g_iThankfulClient = client;
                return Plugin_Handled;
        }

        if ( GetRandomInt( 0, 9 ) ) // 10% chance to change the language
                return Plugin_Continue;

        g_iThankfulClient = client;

        return Plugin_Handled;
}

void MsgPostHook_DysVoiceComm( UserMsg msg_id, bool sent ) {
        BeThankful();
}

void BeThankful() {

        if ( !g_iThankfulClient )
                return;

        int client = g_iThankfulClient;

        g_iThankfulClient = 0;

        // if ( !GetRandomInt( 0, 9 ) ) { // 10% chance to be a player voiceover

                // switch ( iClientTeam ) {
                        // case 2: {
                                // PrintToChatAll(
                                        // g_sPunksThanksFormat,
                                        // WhoseVoiceWasThat[lang],
                                        // client,
                                        // "Thanks"
                                // );
                        // }
                        // case 3: {
                                // PrintToChatAll(
                                        // g_sCorpsThanksFormat,
                                        // WhoseVoiceWasThat[lang],
                                        // client,
                                        // "Thanks"
                                // );
                        // }
                        // default: {
                                // char message[255];
                                // Format(
                                        // message,
                                        // sizeof(message),
                                        // "(%s) %N: %s\x0a", // 0x0a is newline
                                        // WhoseVoiceWasThat[lang],
                                        // client,
                                        // "Thanks"
                                // );

                                // Handle hBf = StartMessageAll( "SayText" );
                                // if ( hBf != INVALID_HANDLE ) {
                                        // BfWriteByte( hBf, client );
                                        // BfWriteString( hBf, message );
                                        // BfWriteByte( hBf, 1 );
                                        // EndMessage();
                                // }

                        // }
                // }

                // EmitSoundToAll(
                        // ThanksInOtherVoices[GetRandomInt( 0, sizeof(ThanksInOtherVoices)-1 )],                       // sample
                        // _,                                   // emitting entity
                        // SNDCHAN_VOICE,               // channel
                        // SNDLEVEL_NORMAL,     // level
                        // _,                                   // flags
                        // 1.0                                  // volume
                // );

                // return;
        // }

        int lang = GetRandomInt( 0, sizeof(ThanksInOtherLanguages)-1 );

        // get the clients team and class
        int iClientTeam = GetEntProp( client, Prop_Data, "m_iTeamNum" );

        switch ( iClientTeam ) {
                case 2: {
                        PrintToChatAll(
                                g_sPunksThanksFormat,
                                WhichLanguageWasThat[lang],
                                client,
                                ThanksInOtherLanguages[lang]
                        );
                }
                case 3: {
                        PrintToChatAll(
                                g_sCorpsThanksFormat,
                                WhichLanguageWasThat[lang],
                                client,
                                ThanksInOtherLanguages[lang]
                        );
                }
                default: {
                        char message[255];
                        Format(
                                message,
                                sizeof(message),
                                "(%s) %N: %s\x0a", // 0x0a is newline
                                WhichLanguageWasThat[lang],
                                client,
                                ThanksInOtherLanguages[lang]
                        );

                        Handle hBf = StartMessageAll( "SayText" );
                        if ( hBf != INVALID_HANDLE ) {
                                BfWriteByte( hBf, client );
                                BfWriteString( hBf, message );
                                BfWriteByte( hBf, 1 );
                                EndMessage();
                        }
                        return;
                }
        }

        char sClientModel[64];
        GetClientModel( client, sClientModel, sizeof(sClientModel) );

        // play appropriate sound for clients team and class
        // a safer codemonkey would check if these sounds are precached
        char sSoundName[32];
        if ( -1 != StrContains( sClientModel, "heavy", false ) ) {
                sSoundName = "vox_new/cheavy_thanks1.wav";
        } else {
                switch (iClientTeam) {
                        case 2: {
                                sSoundName = "vox_new/punk_thanks1.wav";
                        }
                        case 3: {
                                sSoundName = "vox_new/corp_thanks.wav";
                        }
                }
        }

        EmitSoundToAll(
                sSoundName,                     // sample
                _,                                      // emitting entity
                SNDCHAN_VOICE,          // channel
                SNDLEVEL_NORMAL,        // level
                _,                                      // flags
                1.0                                     // volume
        );

}

Action ThanksTest( int client, int args ) {
        g_iThankfulClient = client;

        BeThankful();

        return Plugin_Handled;
}


/* Map Start/Round Restart triggers for the fun things */
void FindThemAndDestroyThem() {
        if ( StrEqual( g_sCurrentMap, "dys_detonate", false ) ) {
                HuntDownTheDoorzilla();
                return;
        }
        if ( StrEqual( g_sCurrentMap, "dys_cybernetic", false ) ) {
                TakeANapThenFireTheMissiles();
                return;
        }
        if ( StrEqual( g_sCurrentMap, "dys_vaccine", false ) ) {
                DoYouKnowWhereYouAre();
                return;
        }
}



/* Detonate */
void HuntDownTheDoorzilla() {
        int ent = -1;
        char targetname[64];
        while ( (ent = FindEntityByClassname( ent, "logic_branch" )) != -1 ) {
                GetEntPropString( ent, Prop_Data, "m_iName", targetname, sizeof(targetname) );
                if ( StrEqual( targetname, "testsicle", false ) ) {
                        HookSingleEntityOutput( ent, "OnTrue", DZMessage, false );
                        HookSingleEntityOutput( ent, "OnFalse", DZMessage, false );
                }
        }
}

static char DZFailMessages[][] = {
        "\x04WHAT ARE YOU TRYING TO DO, GET US ALL KILLED?\x01"
};

static char DZSuccessMessages[][] = {
        "\x04DOORZILLA IS REAL !\x01",
        "\x04BEWARE, OBLIVION IS AT HAND\x01",
        "\x04WHAT HAS BEEN SEEN CANNOT BE UNSEEN !\x01"
};

void DZFailMessage() {
        PrintToChatAll( "%s", DZFailMessages[GetRandomInt( 0, sizeof(DZFailMessages)-1 )] );
}

void DZSuccessMessage() {
        PrintToChatAll( "%s", DZSuccessMessages[GetRandomInt( 0, sizeof(DZSuccessMessages)-1 )] );
}

Action DZMessage ( const char[] output, int caller, int activator, float delay ) {
        if ( StrEqual( output, "OnTrue", false ) ) {
                CreateTimer( 2.0, DZSuccessTimer );
        } else {
                DZFailMessage();
        }
}

Action DZSuccessTimer( Handle timer ) {
        DZSuccessMessage();
        return Plugin_Stop;
}



/* Cybernetic */
Action TakeANapThenFireTheMissiles() {
        int ent = -1;
        char targetname[64];
        while ( (ent = FindEntityByClassname( ent, "path_track" )) != -1 ) {
                GetEntPropString( ent, Prop_Data, "m_iName", targetname, sizeof(targetname) );
                if ( StrEqual( targetname, "path_rocket", false ) ) {
                        HookSingleEntityOutput( ent, "OnPass", MissileMessage, false );
                }
        }
}

static char MissileMessages[][] = {
        "\x04FIRE ZE MISSILES !\x01",
        "\x04DON'T LET THEM TAKE THE LOLI !\x01",
        "\x04DARIUS, YOU NEED TO HAVE A SERIOUS TALK WITH YOUR DAUGHTER...\x01",
        "\x04Prox: \"that girl has access to \x01all\x04 the whereabouts of \x01every punk organization\x04\"\x01"
};

Action MissileMessage( const char[] output, int caller, int activator, float delay ) {
        if ( GetRandomInt( 0, 1 ) ) { // bump down to 50%
                CreateTimer( 5.0, MissileMessageTimer );
        }
}

Action MissileMessageTimer( Handle timer ) {
        PrintToChatAll( "%s", MissileMessages[GetRandomInt( 0, sizeof(MissileMessages)-1 )] );
        return Plugin_Stop;
}



/* Vaccine */
Action DoYouKnowWhereYouAre() {
        int ent = -1;
        int hammerid = 0;
        while ( (ent = FindEntityByClassname( ent, "logic_timer" )) != -1 ) {
                hammerid = GetEntProp( ent, Prop_Data, "m_iHammerID" );
                if ( 1267297 == hammerid ) {
                        HookSingleEntityOutput( ent, "OnTimer", TieFidgetMessage, false );
                }
        }
}

static char TieFidgetMessages[][] = {
        "\x04BOO !\x01",
        "\x04DO YOU KNOW WHERE YOU ARE?\x01"
};

Action TieFidgetMessage( const char[] output, int caller, int activator, float delay ) {
        if ( !GetRandomInt( 0, 1 ) ) {
                PrintToChatAll( "%s", TieFidgetMessages[GetRandomInt( 0, sizeof(TieFidgetMessages)-1 )] );
        }
}
