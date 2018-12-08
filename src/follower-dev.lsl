//------------------------------------------------------------------------------
//### follower.lsl
// v.0.3
//Simple Follower that is using the osMoveToTarget function of OpenSim
//that is available in the dev branch
//
//  Copyright (c) 2008 - 2017 uriesk
//  This script is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published
//  by the Free Software Foundation, version 2.
//
//  This script is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this script; if not, see www.gnu.org/licenses/gpl-2.0
//-----------------------------------------------------------------------------
//hardcoded adjustable values
float g_tau = 1.5;
float g_Length = 2.7;
//for following
integer g_active = 0;
//g_mode 0: Follow
//g_mode >0: TP to avatar
integer g_mode;
key g_kTarget;
vector g_pTarget;
integer g_walkingStatus;
float g_lastDistance;
float g_OSVersion;
//for menu
integer g_handle;
list g_uuids;
list g_names;
integer g_page;

stopfollow()
{
    g_active = 0;
    llOffsetTexture(-0.25, 0.25, 4);
    llOwnerSay("Stoped following " + llKey2Name(g_kTarget));
    llSetTimerEvent(0.0);
    llStopMoveToTarget();
    llReleaseControls();
    return;
}

list multipagemenubuttons(list buttons, integer page)
{
    integer amount = llGetListLength(buttons);
    if (page * 9 >= amount) page = 0;

    if (amount <= 11) {
        buttons = (list)"[Cancel]" + buttons;
    }
    else {
        buttons = ["[Cancel]", "<", ">"] + llList2List(buttons, page * 9, page * 9 + 8);
    }
    return buttons;
}

float distanceToTarget(vector ownPosition, vector targetPosition, integer notOsFix)
{
    //because the Avatar is walking on the ground, while the target could be flying,
    //we just check the x,y distance
    if (!notOsFix) {
        ownPosition = <ownPosition.x, ownPosition.y, 0.0>;
        targetPosition = <targetPosition.x, targetPosition.y, 0.0>;
    }
    return llVecDist(targetPosition, ownPosition);
}


default
{
    on_rez(integer iStartParam)
    {
        llScaleTexture(0.5, 0.5, 4);
        llOffsetTexture(-0.25, 0.25, 4);
        llResetScript();
    }
    
    timer()
    {
        list details = llGetObjectDetails(g_kTarget, [OBJECT_POS]);
        if (details == []){
            stopfollow();
            return;
        }
        vector tPosition = llList2Vector(details, 0);
        vector ownPosition = llGetPos();
        float distance = distanceToTarget(ownPosition, tPosition, g_mode);
        if (distance < g_Length) {
            if (g_walkingStatus == 1){
                llStopMoveToTarget();
                g_walkingStatus = 0;
                llReleaseControls();
            }
        }
        else if (g_walkingStatus == 0) {
            llRequestPermissions(llGetOwner(), PERMISSION_TAKE_CONTROLS);
        }
        else if (tPosition != g_pTarget || distance > g_lastDistance) {
            llStopMoveToTarget();
            g_pTarget = tPosition;
            integer options = OS_NO_FLY;
            if (llGetAgentInfo(g_kTarget) & AGENT_FLYING) {
                options = OS_FLY;
            }
            osMoveToTarget(g_pTarget, g_tau, options);
        }
        g_lastDistance = distance;
    }
    
    run_time_permissions(integer perm)
    {
        if (perm & PERMISSION_TAKE_CONTROLS)
        {
            llTakeControls(CONTROL_ROT_LEFT | CONTROL_ROT_RIGHT | CONTROL_LEFT | CONTROL_RIGHT | CONTROL_FWD | CONTROL_BACK| CONTROL_UP | CONTROL_DOWN, TRUE, FALSE);
            g_pTarget = llList2Vector(llGetObjectDetails(g_kTarget, [OBJECT_POS]), 0);
            g_walkingStatus = 1;
            osMoveToTarget(g_pTarget, g_tau, OS_NO_FLY);
        }
        else if (perm & PERMISSION_TELEPORT)
        {
            g_pTarget = llList2Vector(llGetObjectDetails(g_kTarget, [OBJECT_POS]), 0);
            llTeleportAgent(llGetOwner(), "", g_pTarget + <0.3, 0.3, 0.0>, g_pTarget);
        }
    }
    
    listen(integer chan, string name, key id, string msg)
    {
        llListenRemove(g_handle);
        if (msg == "[Cancel]") return;

        if (msg == ">") {
            ++g_page;
            list buttons = multipagemenubuttons(g_names, g_page);
            g_handle = llListen(313, "", llGetOwner(), "");
            llDialog(llGetOwner(), "Select user you want to follow", buttons, 313);
            return;
        }
        else if (msg == "<") {
            --g_page;
            list buttons = multipagemenubuttons(g_names, g_page);
            g_handle = llListen(313, "", llGetOwner(), "");
            llDialog(llGetOwner(), "Select user you want to follow", buttons, 313);
            return;
        }
        else {
            //user selected
            integer pos = llListFindList(g_names, (list)msg);
            g_kTarget = llList2Key(g_uuids, pos);
            if (g_mode == 0)
            {
                llOffsetTexture(0.25, 0.25, 4);
            }
            else
            {
                llRequestPermissions(llGetOwner(), PERMISSION_TELEPORT);
                return;
            }
            llOwnerSay("Starting following " + llKey2Name(g_kTarget));
            g_OSVersion = (float)llGetSubString(osGetSimulatorVersion(), 8, 10);
            g_active = 1;
            g_walkingStatus = 0;
            llSetTimerEvent(0.5);
        }
    }
    
    touch_end(integer num_detected)
    {
        if (llDetectedKey(0)!=llGetOwner()) return;
        if (llGetAttached()==0) return;
        
        if (g_active==0) {
            //if multiple-click, increment mode
            if (llGetTime() < 1.1) {
                ++g_mode;
                return;
            } else {
                g_mode = 0;
            }
            llResetTime();
            //get user selection menu
            g_uuids = llGetAgentList(AGENT_LIST_PARCEL, []);
            integer pos_own = llListFindList(g_uuids, (list)llGetOwner());
            g_uuids = llDeleteSubList(g_uuids, pos_own, pos_own);
            integer length = llGetListLength(g_uuids);
            if (length == 0) {
                llOwnerSay("No other avatar in Parcel.");
                return;
            }
            integer cnt;
            g_names = [];
            for (cnt = 0; cnt < length && cnt < 11; ++cnt) {
                g_names += (list)llGetSubString(llKey2Name(llList2Key(g_uuids, cnt)), 0, 23);
            }
            g_page = 0;
            list buttons = multipagemenubuttons(g_names, g_page);
            g_handle = llListen(313, "", llGetOwner(), "");
            llDialog(llGetOwner(), "Select user you want to follow", buttons, 313);
        } else {
            //stop following
            stopfollow();
        }
    }
}

