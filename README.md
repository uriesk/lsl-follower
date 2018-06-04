==OpenSim Follower HUD==

This is a simple HUD for following other users in OpenSim.
• It is using a workaround for BUG 8250 http://opensimulator.org/mantis/view.php?id=8250 (setting the z-value of the target always to 1.0, which results in the avatar always getting pulled towards the ground).
• Additionally it is asking for permissions to Control the Avatar to lock it down, to avoid llMoveToTarget() from stopping when the Avatar moves.
• And to do this, it is using llTakeControls(..., TRUE, FALSE) to avoid BUG 6455 http://opensimulator.org/mantis/view.php?id=6455
• The timer is used instead of not_at_target because OpenSim would launch not_at_target many many many times very fast after another, which would cause lag

===Installation===
Create a Prim, attach it as HUD (face 4 facing towards you), put texture followr-button.png on face 4, add script to it, detach and attach it.
