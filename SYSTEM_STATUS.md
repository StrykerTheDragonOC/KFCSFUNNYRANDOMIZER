# FPS Game System Status & Fix Plan

## Critical Issues (Blocks Gameplay)

### 1. First-Person Camera Lock ❌ BROKEN
**Problem**: When unequipping weapons, camera stays locked in first person
**Impact**: Player can't zoom out after using any weapon
**Location**: ViewmodelSystem.lua / Camera handling
**Fix Priority**: **CRITICAL**

### 2. Deployment/Respawn System ❌ BROKEN  
**Problem**: On death/respawn, menu shows but is non-functional, player stuck in first-person
**Impact**: Can't respawn/redeploy after first death
**Location**: DeployHandler.server.lua, MenuController.client.lua
**Fix Priority**: **CRITICAL**

### 3. Weapon Firing CFrame Errors ❌ BROKEN
**Problem**: CFrame.new() getting invalid normal vector when firing
**Impact**: Weapons don't fire, throw errors
**Location**: Weapon LocalScripts, BallisticsSystem.lua
**Fix Priority**: **CRITICAL**

### 4. Viewmodel Display ❌ PARTIALLY WORKING
**Problem**: Some viewmodels don't show up, animations don't play
**Impact**: Weapons look broken, no visual feedback
**Location**: ViewmodelSystem.lua
**Fix Priority**: **CRITICAL**

## High Priority Issues (Breaks Features)

### 5. Menu NPC/Desk Not Showing ❌ BROKEN
**Problem**: ViewportFrame character and desk don't render properly
**Impact**: Menu looks unfinished/broken
**Location**: MenuUIGenerator.client.lua lines 1236-1390
**Fix Priority**: **HIGH**

### 6. Sound Effects Not Playing ❌ BROKEN
**Problem**: AudioSystem not integrated with weapon firing
**Impact**: No audio feedback, feels lifeless
**Location**: AudioSystem.lua, weapon scripts
**Fix Priority**: **HIGH**

### 7. Settings Sliders Non-Functional ❌ BROKEN
**Problem**: Sliders create but mouse interaction doesn't update values properly
**Impact**: Can't adjust settings
**Location**: SettingsController.client.lua lines 183-220
**Fix Priority**: **HIGH**

### 8. Gamemode Voting Doesn't Show ❌ BROKEN  
**Problem**: Voting panel never appears on server start
**Impact**: No gamemode selection
**Location**: VotingHandler.server.lua, MenuUIGenerator.client.lua
**Fix Priority**: **HIGH**

### 9. Grenade System Spam/Viewmodels ❌ BROKEN
**Problem**: Can spam grenades, no viewmodels shown
**Impact**: Exploitable, looks unfinished
**Location**: GrenadeHandler.server.lua, grenade LocalScripts
**Fix Priority**: **HIGH**

### 10. Tab Scoreboard Not Functional ❌ BROKEN
**Problem**: Shows but doesn't populate with real player data
**Impact**: Can't see match stats
**Location**: TabScoreboard.client.lua
**Fix Priority**: **MEDIUM**

## Medium Priority (Missing Features)

### 11. Vicious Stinger Abilities ❌ NOT IMPLEMENTED
**Problem**: G/R/E abilities don't work
**Impact**: Special weapon incomplete
**Location**: ViciousStingerWeapon.server.lua, client scripts
**Fix Priority**: **MEDIUM**

### 12. Perk System ❌ NOT IMPLEMENTED
**Problem**: Double jump, speed boost, etc. not working
**Impact**: Gameplay features missing
**Location**: Need to create PerkSystem.lua
**Fix Priority**: **MEDIUM**

### 13. Attachment System ❌ PARTIALLY WORKING
**Problem**: Attachments don't visually attach to viewmodels correctly
**Impact**: Customization broken
**Location**: AttachmentHandler.server.lua, ViewmodelSystem.lua
**Fix Priority**: **MEDIUM**

## Low Priority (Polish/Future)

### 14. Vehicles & Destruction ⚠️ NOT STARTED
**Problem**: Not implemented yet
**Fix Priority**: **LOW** (add after core gameplay works)

### 15. Scope System (T to switch) ⚠️ NOT IMPLEMENTED
**Problem**: Can't switch between 3D and UI scopes
**Fix Priority**: **LOW**

### 16. Skin Shop ⚠️ NOT FUNCTIONAL
**Problem**: Shop exists but can't buy/apply skins
**Fix Priority**: **LOW**

## Fix Execution Order

Based on dependencies and impact, fixes should be done in this order:

1. **Fix First-Person Camera Lock** - Unblocks basic movement
2. **Fix Weapon Firing Errors** - Unblocks combat testing
3. **Fix Deployment/Respawn** - Unblocks game loop
4. **Fix Viewmodel Display** - Unblocks visual testing
5. **Fix Sound System Integration** - Adds critical feedback
6. **Fix Menu NPC/Viewport** - Polish, but visible bug
7. **Fix Settings Sliders** - QoL improvement
8. **Fix Gamemode Voting** - Needed for proper matches
9. **Fix Grenade System** - Secondary combat
10. **Fix Tab Scoreboard** - Match feedback

After these 10 fixes, the game should be **playable and testable**.

Then proceed with medium priority features:
- Vicious Stinger abilities
- Perk system
- Attachment visual system
- Tab scoreboard population

## Testing Checkpoints

### Checkpoint 1: Basic Gameplay (Fixes 1-4)
- ✅ Can equip/unequip weapons freely
- ✅ Camera unlocks properly
- ✅ Weapons fire without errors
- ✅ Can see viewmodels
- ✅ Can respawn after death

### Checkpoint 2: Combat Feel (Fixes 5-6)  
- ✅ Menu looks professional
- ✅ Weapon sounds play
- ✅ Combat feels responsive

### Checkpoint 3: Full Match (Fixes 7-10)
- ✅ Can adjust settings
- ✅ Gamemode voting works
- ✅ Can throw grenades properly
- ✅ Can see match stats

## Notes

- Focus on making existing systems work before adding new ones
- Test each fix independently before moving to next
- Some fixes may require changes across multiple files
- Keep CLAUDE.md rules in mind (no over-complication, use existing systems)
