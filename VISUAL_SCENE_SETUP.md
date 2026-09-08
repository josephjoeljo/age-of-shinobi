# 🎨 Visual Scene Setup Guide

Complete guide for creating species visual scenes with AnimatedSprite2D, AnimationPlayer, and effects.

---

## 🏗️ Architecture Overview

### **Before (Old System):**
```
Boar (CharacterBody2D)
├─ boar.gd
├─ Sprite2D ← Manually managed
└─ CollisionShape2D
```

### **After (New System - Approach 1: Recommended):**
```
AIAgent (CharacterBody2D) ← Physics & AI
├─ CollisionShape2D ← Physics collision
├─ Visuals (Instanced from boar_visuals.tscn) ← Pure visuals
│   ├─ Body (Node2D)
│   │   └─ AnimatedSprite2D
│   ├─ AnimationPlayer ← Complex animations
│   ├─ DustParticles (CPUParticles2D)
│   └─ Sounds (Node)
│       ├─ SquealSound (AudioStreamPlayer2D)
│       └─ SnortSound (AudioStreamPlayer2D)
└─ [AI Components auto-added]
    ├─ PerceptionSystem
    └─ BehaviorTree
```

---

## 📝 Step 1: Create Visual Scene Template

### **Create `boar_visuals.tscn`:**

1. **In Godot:** Scene → New Scene
2. **Root Node:** Node2D (name it "BoarVisuals")
3. **Add children:**

```
BoarVisuals (Node2D)
├─ Body (Node2D) ← For rotation/squash-stretch
│   └─ Sprite (AnimatedSprite2D)
├─ AnimationPlayer
├─ Effects (Node2D)
│   ├─ DustParticles (CPUParticles2D)
│   ├─ BloodParticles (CPUParticles2D)
│   └─ SweatDrops (CPUParticles2D)
└─ Sounds (Node)
    ├─ SquealSound (AudioStreamPlayer2D)
    ├─ SnortSound (AudioStreamPlayer2D)
    └─ ChargeSound (AudioStreamPlayer2D)
```

4. **Save as:** `res://assets/visuals/boar_visuals.tscn`

---

## 📝 Step 2: Configure AnimatedSprite2D

### **Setup Sprite Frames:**

1. **Select** `Sprite` (AnimatedSprite2D)
2. **In Inspector:**
   ```
   Sprite Frames: [Create new SpriteFrames or load existing]
   Animation: "idle_down"
   Playing: ✓ (checked)
   ```

3. **Create animations:**
   ```
   idle_down, idle_up, idle_left, idle_right
   walk_down, walk_up, walk_left, walk_right
   run_down, run_up, run_left, run_right
   graze
   attack_down
   death
   ```

4. **Import sprites** for each animation

---

## 📝 Step 3: Setup AnimationPlayer

### **Create Complex Animations:**

AnimationPlayer can animate properties that SpriteFrames can't!

#### **Example: "charge" Animation**
```
AnimationPlayer Tracks:
├─ Body:scale (squash & stretch)
│   0.0s: Vector2(1.0, 1.0)
│   0.1s: Vector2(1.2, 0.8) ← Squash before charge
│   0.2s: Vector2(0.9, 1.1) ← Stretch during charge
│   0.4s: Vector2(1.0, 1.0)
│
├─ Sprite:modulate (flash red)
│   0.0s: Color(1, 1, 1)
│   0.1s: Color(1, 0.5, 0.5) ← Red tint
│   0.3s: Color(1, 1, 1)
│
└─ DustParticles:emitting
    0.1s: true
    0.4s: false
```

#### **Example: "hit" Animation**
```
Tracks:
├─ Body:position (knockback)
│   0.0s: Vector2(0, 0)
│   0.05s: Vector2(-5, 0)
│   0.1s: Vector2(0, 0)
│
├─ Sprite:modulate
│   0.0s: Color(1, 1, 1)
│   0.05s: Color(1, 0, 0) ← Flash red
│   0.15s: Color(1, 1, 1)
│
└─ BloodParticles:emitting
    0.0s: true
    0.1s: false
```

#### **Example: "graze" Animation**
```
Tracks:
├─ Body:rotation
│   0.0s: 0°
│   0.5s: -5° ← Head down
│   1.0s: 0°
│   1.5s: -5°
│   2.0s: 0°
│
└─ SnortSound:playing
    0.0s: true
    1.0s: true
```

---

## 📝 Step 4: Configure Particles

### **Dust Particles (When Running):**

```gdscript
# In CPUParticles2D Inspector
Emitting: false  # Triggered by animations
Amount: 20
Lifetime: 0.5
One Shot: false

Emission Shape: Sphere
Sphere Radius: 5.0

Direction: Vector2(0, -1)
Spread: 45

Initial Velocity: 50
Initial Velocity Random: 0.3

Scale: 0.5
Scale Random: 0.5

Color: #8b7355 (brown/dirt)
```

### **Blood Particles (When Hit):**

```gdscript
Emitting: false
Amount: 15
Lifetime: 0.3
One Shot: true  # One burst

Emission Shape: Sphere
Sphere Radius: 3.0

Direction: Vector2(1, -1)  # Away from attacker
Spread: 180

Initial Velocity: 100
Gravity: Vector2(0, 200)

Color: #8b0000 (dark red)
```

---

## 📝 Step 5: Configure Sounds

### **Audio Setup:**

1. **Import audio files:**
   ```
   res://assets/sounds/boar/
   ├─ squeal.wav
   ├─ snort.wav
   ├─ charge.wav
   └─ hit.wav
   ```

2. **Configure AudioStreamPlayer2D:**
   ```
   Stream: [Load audio file]
   Volume Db: -10
   Pitch Scale: 1.0 (randomize in code)
   Max Distance: 500
   Attenuation: 1.0
   Bus: "SFX"
   ```

---

## 📝 Step 6: Update SpeciesDefinition

### **In `boar.tres`:**

```gdscript
# VISUALS Group
visual_scene: [Load] → boar_visuals.tscn
scale: 1.0
```

That's it! The AIAgent will automatically instance this scene.

---

## 📝 Step 7: Create Animation Controller Script

Since AIAgent doesn't know about your custom animations, create a helper:

### **Create `visual_controller.gd`:**

```gdscript
extends Node
## Controls visual feedback for boar actions
##
## Attach this to the BoarVisuals root node

@onready var sprite: AnimatedSprite2D = $Body/Sprite
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var dust_particles: CPUParticles2D = $Effects/DustParticles
@onready var blood_particles: CPUParticles2D = $Effects/BloodParticles

@onready var squeal_sound: AudioStreamPlayer2D = $Sounds/SquealSound
@onready var snort_sound: AudioStreamPlayer2D = $Sounds/SnortSound
@onready var charge_sound: AudioStreamPlayer2D = $Sounds/ChargeSound

var agent: AIAgent
var current_direction: String = "down"


func _ready() -> void:
	# Get parent AIAgent
	agent = get_parent()
	if not agent is AIAgent:
		push_error("VisualController must be child of AIAgent")


func _process(_delta: float) -> void:
	if not agent:
		return

	_update_direction()
	_update_sprite_animation()


## Update direction based on velocity
func _update_direction() -> void:
	if agent.velocity.length() < 5.0:
		return

	if abs(agent.velocity.x) > abs(agent.velocity.y):
		current_direction = "right" if agent.velocity.x > 0 else "left"
	else:
		current_direction = "down" if agent.velocity.y > 0 else "up"

	# Flip sprite for left/right
	sprite.flip_h = (current_direction == "left")


## Update sprite animation based on current action
func _update_sprite_animation() -> void:
	var action = agent.blackboard.get_value("current_action", ActionIntent.ActionType.IDLE)

	var anim_name := ""
	match action:
		ActionIntent.ActionType.IDLE:
			anim_name = "idle_" + current_direction

		ActionIntent.ActionType.WANDER, ActionIntent.ActionType.MOVE:
			anim_name = "walk_" + current_direction

		ActionIntent.ActionType.FLEE:
			anim_name = "run_" + current_direction
			_emit_dust()

		ActionIntent.ActionType.ATTACK:
			anim_name = "attack_" + current_direction
			_play_charge_animation()

		ActionIntent.ActionType.GRAZE:
			anim_name = "graze"
			_play_graze_animation()

		ActionIntent.ActionType.DIE:
			anim_name = "death"
			_play_death_animation()

	if sprite.animation != anim_name:
		sprite.play(anim_name)


## Play charge animation with effects
func _play_charge_animation() -> void:
	if not anim_player.is_playing():
		anim_player.play("charge")
		charge_sound.pitch_scale = randf_range(0.9, 1.1)
		charge_sound.play()


## Play graze animation with snort sounds
func _play_graze_animation() -> void:
	if not anim_player.is_playing():
		anim_player.play("graze")


## Play death animation
func _play_death_animation() -> void:
	if not anim_player.is_playing():
		anim_player.play("death")
		squeal_sound.pitch_scale = randf_range(0.7, 0.9)
		squeal_sound.play()


## Emit dust particles when running
func _emit_dust() -> void:
	if not dust_particles.emitting:
		dust_particles.emitting = true


## Called when boar takes damage (from AIAgent.take_damage)
func on_hit() -> void:
	anim_player.play("hit")
	blood_particles.restart()
	squeal_sound.pitch_scale = randf_range(0.9, 1.1)
	squeal_sound.play()
```

### **Attach to BoarVisuals:**
1. Select root `BoarVisuals` node
2. Attach `visual_controller.gd`

---

## 📝 Step 8: Call Visual Effects from AIAgent

### **Update boar.gd to trigger visual effects:**

```gdscript
extends AIAgent

func _ready() -> void:
	species_id = "boar"
	super._ready()


## Override to add visual feedback
func take_damage(amount: float, attacker: Node2D) -> void:
	super.take_damage(amount, attacker)

	# Trigger hit visual effect
	if has_node("Visuals"):
		var visuals = $Visuals
		if visuals.has_method("on_hit"):
			visuals.on_hit()


## Override to add sounds
func execute_action(intent: ActionIntent) -> void:
	super.execute_action(intent)

	# Visuals will react automatically via visual_controller.gd
```

---

## 🎯 Benefits of This Approach

### **✅ Separation of Concerns:**
- **AIAgent** = Pure logic (AI, physics, health)
- **Visuals** = Pure presentation (sprites, effects, sounds)

### **✅ Reusability:**
```gdscript
# Different colored boars use same AI, different visuals
wolf.tres:
  visual_scene: wolf_visuals.tscn  # Gray wolf

white_wolf.tres:
  visual_scene: white_wolf_visuals.tscn  # White variant
```

### **✅ Designer-Friendly:**
- Artists build visuals in editor without touching code
- Animator creates complex AnimationPlayer sequences
- VFX artist adds particles and shaders
- Sound designer sets up audio

### **✅ Easy Variants:**
```
boar_visuals.tscn          ← Normal boar
boar_elite_visuals.tscn    ← Glowing eyes, bigger
boar_zombie_visuals.tscn   ← Green tint, particle trail
```

---

## 📁 Final File Structure

```
res://
├─ assets/
│   ├─ visuals/
│   │   ├─ boar_visuals.tscn ← Visual scene
│   │   ├─ wolf_visuals.tscn
│   │   └─ deer_visuals.tscn
│   │
│   ├─ sprites/
│   │   └─ boar_spritesheet.png
│   │
│   └─ sounds/
│       └─ boar/
│           ├─ squeal.wav
│           └─ snort.wav
│
├─ data/species/
│   └─ boar.tres ← References boar_visuals.tscn
│
└─ src/scripts/wildlife/boar/
    ├─ boar.gd ← Extends AIAgent
    └─ visual_controller.gd ← Attached to BoarVisuals
```

---

## ✅ Quick Checklist

- [ ] Created visual scene (boar_visuals.tscn)
- [ ] Added AnimatedSprite2D with sprite frames
- [ ] Added AnimationPlayer with complex animations
- [ ] Added CPUParticles2D for effects
- [ ] Added AudioStreamPlayer2D for sounds
- [ ] Created visual_controller.gd script
- [ ] Attached visual_controller.gd to BoarVisuals
- [ ] Set visual_scene in boar.tres
- [ ] Tested boar spawns with visuals
- [ ] Tested animations play correctly
- [ ] Tested particles emit on actions
- [ ] Tested sounds play on events

---

**Your boar now has full visual/audio separation!** 🎨🔊
