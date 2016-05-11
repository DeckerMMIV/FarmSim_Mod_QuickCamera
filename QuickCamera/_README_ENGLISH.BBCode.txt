[b]QuickCamera (v2.5.0)[/b]


[b][u]Changelog[/u][/b]
2.5.0
- Using 'ModsSettings'-mod for possible additional player-custom fixes for outside camera rotation of articulated vehicles.
2.4.1
- Fix for QuickCamera affected other vehicles too, even though the player was not occupying them.
2.4.0
- Added controls for allowing 90-degree left/right camera rotation.
 - These are NOT binded to any default-keys, so remember to check your game Options->Controls.
 - Suggested by dertien due to using TrackIR. And it seemed to be an easy addition to the code.
2.3.1
- Polish translation updated/fixed by Ziuta
2.3.0
- Camera can now be changed, even if hired worker is turned on.
  - Credits to jules.stmp537 for finding a solution for that problem.


[b][u]What can this mod be used for?[/u][/b]

With all the additional key-controls that modern vehicles and implements now has, it is not always feasible to switch between keyboard, mouse and steering-wheel all the time, as it may cause driving errors or worse...

So to look quickly around, this QuickCamera mod introduce "quick-tap keys" for both cabin camera and external cameras of a vehicle.

Make sure you go into 'Options' - 'Controls' in the game, and [b]assign your own keys[/b] to the "QuickCam:Look..." actions.

Now in-game, quick-tap the key that you assigned to the 'QuickCam:Look 45° Left' action, and the camera will rotate to the next 45-degree angle to the left, and so too for the 'QuickCam:Look 45° Right' action.

To look backwards, quick-tap the key that you assigned to the 'QuickCam:Look backward' action, and like so for the 'QuickCam:Look forward' action. You can also toggle between looking forward/backward by assigning a key to the 'QuickCam:Toggle look for/back' action.

If the selected camera is capable of zooming, a quick-tap on your 'QuickCam:Zoom out' key, will cause it to zoom out 15 units at a time. And likewise for your 'QuickCam:Zoom in' key.

[u]Remembers camera position and direction[/u]

When switching back and forth between vehicles, the last selected camera and its position/direction is now remembered.

This option can be toggled off/on using the 'QuickCam:Toggle auto-reset' action (default LEFT-ALT K), if you want to revert back to normal.

Remember though that these positions/directions are not saved between game-sessions.

[u]Default action/key assignments[/u]:

[b]RIGHT[/b] - Look 45° right
[b]LEFT[/b] - Look 45° left
[b]UP[/b] - Look forwards
[b]DOWN[/b] - Look backwards
[b]END[/b] - Toggle look forwards/backwards
[b]PAGE-UP[/b] - Zoom in
[b]PAGE-DOWN[/b] - Zoom out
[b]LEFT-ALT K[/b] - Toggle auto-reset
[i]press-and-hold[/i] [b]C[/b] - Toggle current camera world-alignment on/off 


[b][u]Fixes for articulated vehicles' outside camera rotation[/u][/b]

Whoever at GIANTS Software that decided the outside camera on articulated vehicles should rotate to the opposite direction of the steering, have probably never spend much time in-game with it.

So this mod also adds some fixes for the following articulated vehicles:
- Liebherr L538 (wheel loader)
- New Holland W170C (wheel loader, New Holland DLC pack)
- JCB 435S (wheel loader, JCB DLC pack)
- JCB TM320S (telehandler, JCB DLC pack)

Additional vehicles can be added, if using the 'ModsSettings'-mod.


[b][u]Restrictions[/u][/b]

This mod's script files MAY NOT, SHALL NOT and MUST NOT be embedded in any other mod nor any map-mod! - However it is accepted if this mod is packed into a mod-pack archive, when this mod's original ZIP-file and hash-value is kept intact.

Please do NOT upload this mod to any other hosting site - I can do that myself, when needed!

Keep the original download link!


[b][u]Problems or bugs?[/u][/b]

If you encounter problems or bugs using this mod, please use the support-thread.

Known bugs/problems/ToDo:
- Because this QuickCamera mod does not override the normal camera movement script, there might be a little movement first, before the camera snaps into position - IF you have assigned the same keys as for the normal look left/right/up/down.
- Sometimes when snapping to look forward/backward, the camera-rotation may rotate several times quickly. There's some math that I still haven't quite figured out how to solve.
- Nothing is saved between game-sessions, with regards to 'last selected camera' or the positions/directions.


Credits:
Script: Decker_MMIV
Some German translation corrections: DLH007
Some French translation corrections: _dj_
