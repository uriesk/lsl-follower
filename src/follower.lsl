//------------------------------------------------------------------------------
//### follower.lsl
//Simple Follower that is using various workarounds to make it work in OpenSIM
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
key g_kTarget;
float g_tau = 1.0;
integer g_walkingStatus;
integer g_active = 0;
vector g_pTarget;
integer g_TargetHandle;
//for menu
integer g_handle;
list g_uuids;
list g_names;
integer g_page;
//Textures
string g_textureF = "follow";
string g_textureFS = "followstop";

stopfollow()
{
    g_active = 0;
    llSetTexture(g_textureF, 4);
    llOwnerSay("Stoped following " + llKey2Name(g_kTarget));
    llSetTimerEvent(0.0);
    llStopMoveToTarget();
    llReleaseControls();
    llTargetRemove(g_TargetHandle);
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

default
{
    on_rez(integer iStartParam)
    {
        llSetTexture(g_textureF, 4);
        llResetScript();
    }
    
    timer()
    {
        list details = llGetObjectDetails(g_kTarget, [OBJECT_POS]);
        if (details == []){
            stopfollow();
        }
        vector tPosition = llList2Vector(details, 0);
        if (llVecDist(tPosition, llGetPos()) < 3.0) {
            return;
        }
        else if (g_walkingStatus == 0) {
            //llOwnerSay("Starting moving again");
            llRequestPermissions(llGetOwner(), PERMISSION_TAKE_CONTROLS);
        }
        else if (tPosition != g_pTarget) {
            //llOwnerSay("Target moved");
            llStopMoveToTarget();
            g_pTarget = tPosition;
            llTargetRemove(g_TargetHandle);
            g_TargetHandle = llTarget(g_pTarget, 3.0);
            vector v = <g_pTarget.x, g_pTarget.y, 1.0>;
            llMoveToTarget(v, g_tau);
        }
    }
    
    
    at_target(integer tnum, vector targetpos, vector ourpos)
    {
        llTargetRemove(g_TargetHandle);
        if (g_walkingStatus == 1){
            llStopMoveToTarget();
            llTargetRemove(g_TargetHandle);
            g_walkingStatus = 0;
            //llOwnerSay("Arrived at target!");
            llReleaseControls();
        }
    }
    
    run_time_permissions(integer perm)
    {
        if (perm & PERMISSION_TAKE_CONTROLS)
        {
            llTakeControls(CONTROL_ROT_LEFT | CONTROL_ROT_RIGHT | CONTROL_LEFT | CONTROL_RIGHT | CONTROL_FWD | CONTROL_BACK| CONTROL_UP | CONTROL_DOWN, TRUE, FALSE);
            vector tPosition = llList2Vector(llGetObjectDetails(g_kTarget, [OBJECT_POS]), 0);
            g_pTarget = tPosition;
            vector v = <g_pTarget.x, g_pTarget.y, 1.0>;
            g_TargetHandle = llTarget(g_pTarget, 3.0);
            g_walkingStatus = 1;
            llMoveToTarget(v, g_tau);
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
            integer pos = llListFindList(g_names, (list)msg) - 1;
            g_kTarget = llList2Key(g_uuids, pos);

            llOwnerSay("Starting following " + llKey2Name(g_kTarget));
            g_active = 1;
            g_walkingStatus = 0;
            llSetTexture(g_textureFS, 4);
            llSetTimerEvent(0.5);
        }
    }
    
    touch_end(integer num_detected)
    {
        
        if (llDetectedKey(0)!=llGetOwner()) return;
        if (llGetAttached()==0) return;

        if (g_active==0) {
            g_uuids = llGetAgentList(AGENT_LIST_PARCEL, []);
            integer pos_own = llListFindList(g_uuids, (list)llGetOwner());
            g_uuids = llDeleteSubList(g_uuids, pos_own, pos_own);
            integer length = llGetListLength(g_uuids);
            if (length == 0) {
                llOwnerSay("No other avatar in Parcel.");
                return;
            }
            integer cnt;
            for (cnt = 0; cnt < length && cnt < 11; ++cnt) {
                g_names += (list)llGetSubString(llKey2Name(llList2Key(g_uuids, cnt)), 0, 23);
            }
            g_page = 0;
            list buttons = multipagemenubuttons(g_names, g_page);
            g_handle = llListen(313, "", llGetOwner(), "");
            llDialog(llGetOwner(), "Select user you want to follow", buttons, 313);
        } else {
            stopfollow();
        }
    }
}

