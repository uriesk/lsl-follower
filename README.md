# OpenSim Follower HUD
![logo](images/logo.png)


This is a simple HUD for following other users in OpenSim.
- It is using a workaround for BUG 8250 http://opensimulator.org/mantis/view.php?id=8250 (setting a target vector with z to zero, which results in the avatar always getting pulled towards the ground).
- Additionally it is asking for permissions to Control the Avatar to lock it down, to avoid llMoveToTarget() from stopping when the Avatar moves.
- To do this, it is using llTakeControls(..., TRUE, FALSE) to avoid BUG 6455 http://opensimulator.org/mantis/view.php?id=6455
- The timer is used instead of llTarget because OpenSim would launch not_at_target many many many times very fast after another, which would cause lag, and because keeping the avatar on the ground wouldn't be possible with it (wouldn't trigger for hovering target avatar).

In dev version:
Using just the osMoveToTarget function that got recently added to OpenSim

## Installation
Create a Prim, attach it as HUD (face 4 facing towards you), put texture follower-buttons.png on face 4, add script to it, detach and attach it.
