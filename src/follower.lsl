//------------------------------------------------------------------------------
//### follower.lsl
//Simple Follower that is using various workarounds to make it work in OpenSim
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
float g_AvatarHeight = 0.0;
integer g_osFix;
key g_kTarget;
vector g_pTarget;
integer g_walkingStatus;
float g_lastDistance;
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

osMoveToTarget(vector target, float tau, integer osFix)
{
    //If the target in llMoveToTarget isn't at llGround(), it will make the Avatar fly
    //in the current OpenSIM versions, when standing on prims or in an upper floor of
    //a house.
    //But if we just set z to zero in the target vector, llMoveToTarget will drag the
    //Avatar through floors to the ground.
    //So we work around that issue by pointing to a position that is on the z-level of 
    //the feet of the Avatar on the targets x,y position and extend that to a position
    //that is on z = 0.
    //This will make the Avatar always walk on the ground.
    if (osFix) {
        //make sure that we know the Avatar Height
        if (g_AvatarHeight == 0.0) {
            vector avatarSize = llGetAgentSize(llGetOwner());
            g_AvatarHeight = avatarSize.z;
        }
        //get position of the wearer
        vector posOwn  = llGetPos();
        //doesn't matter if the target is far above or far underneath us,
        //make the Avatar always moves towards the point at his feet level
        target = <target.x, target.y, posOwn.z - g_AvatarHeight / 2>;
        //continue the path to the target till z is reaching 0
        float scale = posOwn.z / llFabs(target.z - posOwn.z);
        vector newTarget = posOwn + ((target - posOwn) * scale);
        //if out of sim borders, shorten path (this makes z non-zero again)
        float scaleX = 0.0;
        float scaleY= 0.0;
        if(newTarget.x > 255) {
            scaleX = (255 - posOwn.x) / llFabs(target.x - posOwn.x);
        }
        else if (newTarget.x < 0) {
            scaleX = posOwn.x / llFabs(target.x - posOwn.x);
        }
        if (newTarget.y > 255) {
            scaleY = (255 - posOwn.y) / llFabs(target.y - posOwn.y);
        }
        else if (newTarget.y < 0) {
            scaleY = posOwn.y / llFabs(target.y - posOwn.y);
        }
        if (scaleX != 0.0 && (scaleX < scaleY || scaleY == 0.0)) scale = scaleX;
        else if (scaleY != 0.0 && (scaleY < scaleX || scaleX == 0.0)) scale = scaleY;
        //reevaluate target
        target = posOwn + ((target - posOwn) * scale);
        //force z of target to be zero again
        target = target - <0.0, 0.0, target.z>;
        //make sure that we have the same speed as if directly walking to the target
        tau = tau * scale;
        //llOwnerSay("target: " + (string)target + " tau: " + (string)tau + " with scale: " + (string)scale);
    }
    llMoveToTarget(target, tau);
}

float distanceToTarget(vector ownPosition, vector targetPosition, integer osFix)
{
    //because the Avatar is walking on the ground, while the target could be flying,
    //we just check the x,y distance
    if (osFix) {
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
        float distance = distanceToTarget(ownPosition, tPosition, g_osFix);
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
            osMoveToTarget(g_pTarget, g_tau, g_osFix);
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
            osMoveToTarget(g_pTarget, g_tau, g_osFix);
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

            llOwnerSay("Starting following " + llKey2Name(g_kTarget));
            g_active = 1;
            g_walkingStatus = 0;
            if (g_osFix)
                llOffsetTexture(0.25, 0.25, 4);
            else
                llOffsetTexture(-0.25, -0.25, 4);
            llSetTimerEvent(0.5);
        }
    }
    
    touch_end(integer num_detected)
    {
        if (llDetectedKey(0)!=llGetOwner()) return;
        if (llGetAttached()==0) return;
        
        if (g_active==0) {
            //if double-click, deactivate fix
            if (llGetTime() < 1.1) {
                g_osFix = FALSE;
                return;
            } else {
                g_osFix = TRUE;
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

