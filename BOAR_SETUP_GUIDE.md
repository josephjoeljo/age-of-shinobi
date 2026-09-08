# 🐗 Boar AI Setup Guide

Complete guide to upgrading your boar from old state machine to the new AI system.

---

## 📋 Step-by-Step Setup

### **1. Create Boar SpeciesDefinition Resource**

1. **In Godot Editor:**
   - Navigate to `res://data/species/`
   - Right-click → **New Resource**
   - Search for and select **SpeciesDefinition**
   - Name it `boar.tres`

2. **Fill in Inspector values** (use `boar_example.gd` as reference):

```
Identity:
  species_id: "boar"
  display_name: "Wild Boar"
  category: PREY

Behavior:
  behavior_tree: [Browse] -> prey_herd_bt.gd

Timing:
  reaction_time_min: 0.2
  reaction_time_max: 0.35
  decision_interval: 0.25

Perception:
  vision_range: 80.0
  vision_angle: 100.0
  hearing_range: 60.0

Movement:
  base_speed: 70.0
  sprint_speed: 130.0

Boids:
  separation_weight: 1.0
  alignment_weight: 0.8
  cohesion_weight: 1.2
  separation_radius: 25.0
  neighbor_radius: 60.0

Herd:
  herd_type: HERD
  can_rally: false

Combat:
  base_health: 120.0
  base_damage: 20.0
  attack_range: 15.0
  flee_health_threshold: 0.5
  aggression: 0.2

BT Thresholds:
  panic_threshold: 0.5
  danger_radius: 80.0
  pack_loyalty: 0.7
```

3. **Save the resource** (Ctrl+S)

---

### **2. Create Boar SpriteFrames**

1. **In Godot Editor:**
   - Create new **SpriteFrames** resource
   - Name it `boar_animations.tres`

2. **Add animations:**

   **Required animations** (for PreyHerdBT):
   ```
   idle_down    - Standing still facing down
   idle_up      - Standing still facing up
   idle_left    - Standing still facing left
   idle_right   - Standing still facing right

   walk_down    - Walking down
   walk_up      - Walking up
   walk_left    - Walking left
   walk_right   - Walking right

   run_down     - Running/fleeing down
   run_up       - Running up
   run_left     - Running left
   run_right    - Running right

   graze        - Eating/grazing (optional direction)
   attack_down  - Tusk charge down (if fights when cornered)
   death        - Death animation
   ```

3. **Import sprite sheets:**
   - Drag your boar sprite sheets into the frames
   - Set FPS (e.g., 8 FPS for walk, 12 FPS for run)
   - Set loop appropriately (loop walk/run, no loop death)

4. **In boar.tres:**
   - Set `sprite_frames` to your `boar_animations.tres`

---

### **3. Update Boar Scene Structure**

**Old Structure:**
```
Boar (CharacterBody2D)
  ├─ boar.gd (old state machine)
  └─ Sprite2D
```

**New Structure:**
```
Boar (CharacterBody2D)
  ├─ boar_new.gd (extends AIAgent)
  ├─ AnimatedSprite2D
  │   └─ [sprite_frames: boar_animations.tres]
  ├─ AnimationHandler
  │   └─ animation_handler.gd
  └─ CollisionShape2D
```

**In Godot:**

1. **Open your boar scene**

2. **Change root script:**
   - Select Boar root node
   - Remove old `boar.gd` script
   - Attach `boar_new.gd` (or rename it to `boar.gd`)

3. **Replace Sprite2D with AnimatedSprite2D:**
   - Delete old `Sprite2D` node
   - Add **AnimatedSprite2D** as child
   - In Inspector: set **Sprite Frames** to `boar_animations.tres`

4. **Add AnimationHandler:**
   - Add **Node** as child of Boar
   - Rename to "AnimationHandler"
   - Attach `animation_handler.gd` script
   - Verify it can find `AnimatedSprite2D` sibling

5. **Remove old AnimationStates:**
   - Delete the old `animation_states.gd` file (no longer needed)

---

### **4. Configure Project Autoloads**

**Required for the system to work:**

1. **Open:** Project → Project Settings → Autoload

2. **Add:**
   ```
   SpeciesDatabase: res://src/scripts/species_database.gd ✓
   HerdManager:     res://src/scripts/herd/herd_manager.gd ✓
   ```

3. **Click "Add" for each**

---

### **5. Test the Boar**

**Quick Test Scene:**

```gdscript
# test_boar.gd
extends Node2D

func _ready():
    # Spawn a boar
    var boar_scene = preload("res://path/to/boar.tscn")
    var boar = boar_scene.instantiate()
    boar.position = Vector2(200, 200)
    add_child(boar)

    # Add to entities group for perception
    boar.add_to_group("entities")

    print("Boar spawned with species: ", boar.species_id)
```

**Expected Behavior:**
1. ✅ Boar spawns and stands idle
2. ✅ After a moment, starts wandering (WANDER action)
3. ✅ Plays walk animation in movement direction
4. ✅ When player approaches, flees (FLEE action)
5. ✅ Plays run animation when fleeing

---

## 🎯 What Changed?

### **Old System → New System**

| Old | New | Benefit |
|-----|-----|---------|
| Manual state machine | PreyHerdBT | Automatic prey behavior |
| Hard-coded constants | SpeciesDefinition | Data-driven, tweakable |
| Direct velocity control | ReactionQueue + Steering | Realistic delays |
| Simple Sprite2D | AnimatedSprite2D + SpriteFrames | Better animations |
| No perception | PerceptionSystem | Detects threats |
| Solo only | HerdGroup support | Flocks together |

---

## 🐛 Troubleshooting

### **Boar doesn't move:**
- ✅ Check SpeciesDatabase is registered as autoload
- ✅ Check `boar.tres` exists in `res://data/species/`
- ✅ Check `behavior_tree` is set in boar.tres
- ✅ Check boar has `species_id = "boar"`

### **No animations play:**
- ✅ Check `sprite_frames` is set in boar.tres
- ✅ Check AnimatedSprite2D node exists
- ✅ Check AnimationHandler can find AnimatedSprite2D
- ✅ Check animation names match (idle_down, walk_up, etc.)

### **Errors about missing classes:**
- ✅ Check all new scripts are in correct locations
- ✅ Check class_name declarations match
- ✅ Restart Godot editor to refresh script cache

### **Boar doesn't flee from player:**
- ✅ Player must be in "player" group: `add_to_group("player")`
- ✅ PerceptionSystem must be running (Tier 0-1)
- ✅ Player must be within vision_range (80 pixels)

---

## 🎮 Behavior Customization

### **Make boars more/less timid:**

Edit `boar.tres`:
```
panic_threshold: 0.3   # Lower = easier to scare (0.5 is default)
danger_radius: 120.0   # Larger = flee from farther away (80 is default)
```

### **Make boars faster/slower:**

```
base_speed: 100.0      # Faster wandering
sprint_speed: 180.0    # Faster fleeing
```

### **Make boars more aggressive when cornered:**

```
aggression: 0.5        # Higher = more likely to fight (0.2 is default)
flee_health_threshold: 0.3  # Lower = fights longer before fleeing
```

### **Adjust herd cohesion:**

```
cohesion_weight: 1.5   # Higher = stays closer to herd
separation_weight: 0.8 # Lower = allows more crowding
```

---

## 🚀 Advanced: Custom Boar Behaviors

### **Add custom tusk charge:**

```gdscript
# In boar_new.gd

func _perform_attack(target: Node2D) -> void:
    # Tusk charge: brief speed boost toward target
    var charge_direction = (target.global_position - global_position).normalized()
    velocity = charge_direction * species.sprint_speed * 1.5

    # Play charge particle effect
    _spawn_dust_particles()

    # Deal damage
    super._perform_attack(target)

func _spawn_dust_particles():
    # TODO: Add CPUParticles2D for dust cloud
    pass
```

### **Add grazing spots:**

```gdscript
# In boar_new.gd

func _physics_process(delta: float) -> void:
    super._physics_process(delta)

    # Check for nearby food sources
    var food = _find_nearest_food()
    if food and not current_target:
        blackboard.set_value("graze_location", food.global_position)
```

---

## ✅ Migration Checklist

- [ ] Created boar.tres SpeciesDefinition
- [ ] Created boar_animations.tres SpriteFrames
- [ ] Replaced boar.gd with boar_new.gd
- [ ] Replaced Sprite2D with AnimatedSprite2D
- [ ] Added AnimationHandler node
- [ ] Removed old animation_states.gd
- [ ] Registered SpeciesDatabase autoload
- [ ] Registered HerdManager autoload
- [ ] Tested boar spawns correctly
- [ ] Tested boar wanders around
- [ ] Tested boar flees from player
- [ ] Tested animations play correctly

---

**Your boar is now using the full AI system!** 🎉

All prey behavior (fleeing, herding, grazing) is handled automatically by PreyHerdBT. You can create deer, rabbits, and other prey animals using the exact same setup with different species parameters.
