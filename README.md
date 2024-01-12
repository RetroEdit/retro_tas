# retro_tas
General purpose tools to help with [tool-assisted speedrunning](https://tasvideos.org/).

Currently, this includes two main scripts:
- retro_tas.lua: general purpose functions for well-aligned pixel text display and pointer dereferencing
- rewind_rerecords.lua: count rerecords during rewind in BizHawk, which is [not a feature of BizHawk itself yet](https://github.com/TASEmulators/BizHawk/issues/3707)

Called 'Retro TAS' because I'm so egotistical I named the project after myself. (Actually, I originally called this 'TAS tools' locally, but that name has already been used and is overall kind of generic. Although perhaps 'Retro TAS' is not much better in some ways.)

## lag_resync
As of January 2024, I've pushed two scripts for resyncing TASes based on lag frames (or equivalently, based on input polls). These are very rough and not refined enough to be able to generally recommend, but they may be useful to others.

Incidentally, I recently came across https://github.com/gocha/gocha-tas/tree/master/Tools/Lua/resync , which is a similar concept, but I had the idea independently and my code was written and refined through my own testing.

## Similar projects
- [ScriptHawk](https://github.com/Isotarge/ScriptHawk)
