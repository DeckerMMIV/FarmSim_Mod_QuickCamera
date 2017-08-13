[b]QuickCamera[/b]

Mod for Farming Simulator 17


[b][u]Changelog[/u][/b]
1.2.1.31
- Added articulated vehicles steering rotation fix (see ModHub or below for instructions)
- Added player on-foot quick-rotation actions; 45° left/right, 180° turn
- Translations updated by contributers & some machine-translated
- Fix for reverse driving and looking forward/backwards
- Fix so QuickCamera keys won't be active when a GUI is shown


[b][u]What can this mod be used for?[/u][/b]

With all the additional key-controls that modern vehicles and implements now has, it is not always feasible to switch between keyboard, mouse and steering-wheel all the time, as it may cause driving errors or worse...

So to look quickly around, this QuickCamera mod introduce "quick-tap keys" for both cabin camera and external cameras of a vehicle.

Make sure you go into 'Options' - 'Controls' in the game, and [b]assign your own keys[/b] to the "QuickCam:Look..." actions.

Now in-game, quick-tap the key that you assigned to the 'QuickCam:Look 45° Left' action, and the camera will rotate to the next 45-degree angle to the left, and so too for the 'QuickCam:Look 45° Right' action.

To look backwards, quick-tap the key that you assigned to the 'QuickCam:Look backward' action, and like so for the 'QuickCam:Look forward' action. You can also toggle between looking forward/backward by assigning a key to the 'QuickCam:Toggle look for/back' action.

If the selected camera is capable of zooming, a quick-tap on your 'QuickCam:Zoom out' key, will cause it to zoom out 15 units at a time. And likewise for your 'QuickCam:Zoom in' key.


[u]When player is 'on foot'[/u]

Version 1.1.0 introduced "quick-keys keys" for when the player avatar is 'on foot'.

In 'Options' - 'Controls' you can now specify which keys to use, to quickly turn the player 45 degrees left/right or do a u-turn.


[u]Default action/key assignments[/u]

When player is in a vehicle:
[b]RIGHT[/b] - Look 45° right
[b]LEFT[/b] - Look 45° left
[i]none[/i] - Look 90° right
[i]none[/i] - Look 90° left
[i]none[/i] - Peek 45° right
[i]none[/i] - Peek 45° left
[b]UP[/b] - Look forwards
[b]DOWN[/b] - Look backwards
[b]END[/b] - Toggle look forwards/backwards
[b]PAGE-UP[/b] - Zoom in
[b]PAGE-DOWN[/b] - Zoom out

When player is 'on foot':
[i]none[/i] - On foot turn 45° right
[i]none[/i] - On foot turn 45° left
[b]END[/b] - On foot turn 180°


[u]Articulated vehicles steering camera-rotation fix[/u]

Personally I've been a bit annoyed that some of the articulated vehicles internal/external cameras are not turning towards the driving direction.

So to remedy that, a feature have been added to QuickCamera, which can modify the game's default 'steering-Y-rotation-speed' value for articulated vehicles.

The following default articulated vehicles are affected by this feature in QuickCamera:
- New Holland T9
- Challenger MT900E
- Liebherr L 538
- JCB TM320S/435S
- Ponsse ScorpionKing/Buffalo
- Sampo Rosenlew HR46X

[i]How to modify (or disable/enable) steering camera-rotation[/i]

If you need to tweak the rotation value yourself on articulated vehicles, you need to enable the in-game console and use this console-command; [color=blue]modQuickCameraSteeringRotSpeed[/color]

The command takes the following arguments, by which you should be able to modify and test the active camera's steering rotation:

 modQuickCameraSteeringRotSpeed                  - to get current value for active camera
 modQuickCameraSteeringRotSpeed <NUMERIC-VALUE>  - to set new value for active camera (usually in the range -0.9 .. 0.9)
 modQuickCameraSteeringRotSpeed OFF              - turns off the feature for just this active camera
 modQuickCameraSteeringRotSpeed ON               - turns on the feature for just this active camera
 modQuickCameraSteeringRotSpeed TOGGLE           - to disable/enable the feature entirely for all affected vehicles

The settings will automatically be saved to file; modsSettings/QuickCamera_Config.XML


[b][u]Restrictions[/u][/b]

This mod's script files MAY NOT, SHALL NOT and MUST NOT be embedded in any other mod nor any map-mod!

Please do NOT upload this mod to any other hosting site - I can do that myself, when needed!

Keep the original download link!


[b][u]Problems or bugs?[/u][/b]

If you encounter problems or bugs using this mod, please use the support-thread.

Known bugs/problems/ToDo:
- Because this QuickCamera mod does not override the normal camera movement script, there might be a little movement first, before the camera snaps into position - IF you have assigned the same keys as for the normal look left/right/up/down.


Credits:
Script:
- Decker_MMIV
Contributors:
- DLH007, _dj_, Gonimy-Vetrom, jules.stmp537, Ziuta, Xno, PromGames, Anonymous
