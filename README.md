# Farming Simulator modification - Quick Camera

Mod for Farming Simulator

To read more about this mod, find it on;
- https://www.farming-simulator.com/mods.php?title=fs2022&org_id=53574
- https://www.farming-simulator.com/mods.php?title=fs2019&org_id=53574
- https://www.farming-simulator.com/mods.php?title=fs2017&org_id=53574

## FS22 - Change-log

1.0.2.0
- (#37) Fix/Work-around for FS22_CabView completely overwriting the VehicleCamera.update() method, causing FS22_QuickCamera's prepended code to not be called.

1.0.1.0
- (#34, BETA) Added functionality for a one-button 'Change Direction' & 'Flip Camera'.

1.0.0.0
- Quick Camera for FS22 is now available on GIANTS Software's ModHub and via the in-game's 'downloadable content'.
- Italian language updated, by Xno
- German language updated, by GIANTS Software ModHub team


## FS19 - Change-Log

2.1.3.12:
- Russian language updated, by Gonimy_Vetrom
- Polish language updated, by Ziuta
- French language updated, by Anonymous

2.1.0.9:
- Moveable cabin camera (experimental, default set to unassigned input-key)

2.0.0.1
- Added "restore on game-load vehicle-cameras; last used, pitch and zoom settings" (available only in singleplayer)

1.0.0.0
- Upgraded to FS19
- Added additional camera, when vehicle is controlled by hired worker


## FS17 - Change-log

1.2.1.33
- Translations updated by contributers;
  - Polish by Ziuta
  - Russian by Gonimy_Vetrom
- Explicitly mentioned in ModDesc.XML that it should NOT be modified by contributing translators (as it may cause merge-conflicts)

1.2.1.31
- More functionality added to console-command, so it becomes easier to switch/try between "game default" and "QuickCamera fix":
  - modQuickCameraSteeringRotSpeed ON / OFF - to turn on/off feature for current active camera
  - modQuickCameraSteeringRotSpeed TOGGLE - to disable/enable feature for all affected vehicles
- Tweaked the values for articulated vehicle steering rotation fix

1.2.0.30
- Updated readme file, explaning the 'articulated vehicles steering rotation fix' features
- Machine translations done for; DE, ES, PL, RU
- Included vehicle for articulated vehicle steering rotation fix; Challenger MT900E
- Bug fixed in saving-code for articulated vehicle steering rotation fix

1.2.0.29
- Translations updated by contributers;
  - Italian by Xno
  - French by Anonymous

1.2.0.28
- Articulated vehicles steering rotation fix
  - Affected vehicles; Liebherr L 538, New Holland T9, JCB TM320S/435S, Ponsse ScorpionKing/Buffalo, Sampo Rosenlew HR46X
  - Currently only modifiable via console-command; modQuickCameraSteeringRotSpeed <new_rotation_value>
  - User configuration-file saved to; /modsSettings/QuickCamera_Config.xml

1.1.1.26
- Fix for 'look forward 359-degree rotation', so it now does a 'look forward -1 rotation' instead.

1.1.0.25
- Added player on-foot quick-rotation actions; 45� left/right, 180� turn
  - NOTE! Remember to set the action keys yourself, as they are default set to nothing.

1.0.1.24
- Translations updated by contributers

1.0.1.23
- Fix so QuickCamera keys won't be active when a GUI is shown

1.0.1.22
- Fix for reverse driving and looking forward/backwards

1.0.0.21
- Updated Polish translation by Ziuta

1.0.0.20
- Added Spanish translation by PromGames
- Updated Italian translation by Xno

1.0.0.18
- Updated translations
  - Italian by Xno
  - Russian by Gonimy-Vetrom
  - German from ModHub (GIANTS Software)

1.0.0.17
- Upgraded to FS17
- Changed versionnumbering-scheme due to ModHub


## FS15 - Change-log

2.6.1
- Polish translation updated by Ziuta

2.6.0
- Minor code cleanup

2.5.1
- Bug-fix.

2.5.0
- Optionally using 'ModsSettings'-mod for possible additional player-custom fixes for outside camera rotation of articulated vehicles.
  - Must be at least version 0.2.0 of 'ModsSettings'-mod.

2.4.2
- Misc. minor description changes

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
