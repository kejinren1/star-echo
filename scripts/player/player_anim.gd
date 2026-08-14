## 动画推断组件（F4-T7 · 2026-08-14 从 player.gd 拆出）
## 职责：换皮（_apply_character_sprite）+ sheet 帧元推断 + 动画状态机（F3-T6 枚举化 +
## F-32 索敌门控守卫 + F-33 flip_h 转向 + HIT 同值重入 stop+play 语义全保留）
## 范式：无 class_name；player preload 本组件；setup(player) 注入宿主引用——_anim/_state/
##      _sprite_prefix/_facing_left 字段由宿主持有（探针直接 get/set），组件经 _player 访问
extends Node

## 宿主脚本引用（取 PlayerState 枚举/ANIM_MAP——纯枚举文件零 Autoload 引用，探针可编译；
## 不可 preload player.gd 本体，其引用 Autoload 标识符）
const PlayerEnums: GDScript = preload("res://scripts/player/player_enums.gd")

## 宿主 player 实例（player._ensure_components 挂载时注入）
var _player: CharacterBody2D = null

func setup(player: CharacterBody2D) -> void:
	_player = player

# ========== 换皮（原 player._apply_character_sprite） ==========

## 换上英雄专属精灵（`sprite` 为资源名前缀）；缺资源时保留 Player.tscn 预设素材
func apply_character_sprite(prefix: String) -> void:
	if prefix.is_empty():
		return
	var idle_path: String = "%s%s_idle.png" % [_player.SPRITE_DIR, prefix]
	var walk_path: String = "%s%s_walk.png" % [_player.SPRITE_DIR, prefix]
	if not ResourceLoader.exists(idle_path) or not ResourceLoader.exists(walk_path):
		# 区分「文件不在」与「文件在但未生成 .import」，后者编辑器一开即消解，不算缺陷
		if FileAccess.file_exists(idle_path) and FileAccess.file_exists(walk_path):
			print_verbose("[Player] 英雄精灵尚未导入，沿用默认素材: %s" % _player.character_id)
		else:
			push_warning("[Player] 英雄精灵缺失，沿用默认素材: %s" % _player.character_id)
		return
	var idle_res := ResourceLoader.load(idle_path)
	var walk_res := ResourceLoader.load(walk_path)
	if not (idle_res is Texture2D) or not (walk_res is Texture2D):
		return
	_player.idle_texture = idle_res as Texture2D
	_player.walk_texture = walk_res as Texture2D
	_player._sprite_prefix = prefix
	# F3-T6（T-034）：_is_walking 布尔归并 → 复位行走态 = 状态机回 IDLE（换皮前复位，
	# 语义与原 `_is_walking = false` 一致——下次移动自动 walk）
	_player._state = PlayerEnums.PlayerState.IDLE
	_setup_animation()

# ========== 动画（原 player 动画段） ==========

## D28：从 sheet 尺寸自动推断帧元信息（消除 idle 4 / walk 6 / 帧 32px 硬编码）。
## 约定：横排 sheet，正方形帧 → 帧尺寸 = (sheet 高, sheet 高)，帧数 = 宽 ÷ 高。
## 兼容全部既有资产：fighter 等 32px 帧 sheet（128×32→4、192×32→6）；
## elin 拼豆图纸实装后 64px 帧（192×64→idle 3、640×64→walk 10）；attack/skill 32px strip 不变。
## D29：elin JPG 全动画实装后 idle 320×64→5 / walk 640×64→10 / attack 320×64→5 /
##      skill 384×64→6 / hit 128×64→2（hit 为 D29 新增动画，受击时播放）。
## 返回 {"size": Vector2i, "count": int}
func _sheet_meta(tex: Texture2D) -> Dictionary:
	if tex == null or tex.get_height() <= 0:
		return {"size": Vector2i(32, 32), "count": 1}
	var fh: int = tex.get_height()
	var count: int = maxi(1, tex.get_width() / fh)
	return {"size": Vector2i(fh, fh), "count": count}

func _setup_animation() -> void:
	_player._anim = _player.get_node_or_null("AnimatedSprite2D")
	if not _player._anim:
		return
	# 如果未通过 @export 指定纹理，尝试从默认路径加载
	if not _player.idle_texture:
		_player.idle_texture = load("res://assets/sprites/characters/fighter_idle.png")
	if not _player.walk_texture:
		_player.walk_texture = load("res://assets/sprites/characters/fighter_walk.png")
	if not _player.idle_texture or not _player.walk_texture:
		return
	# 构建 SpriteFrames（帧尺寸/帧数按各自 sheet 推断：elin 64px 帧 idle 3 / walk 10）
	var idle_meta: Dictionary = _sheet_meta(_player.idle_texture)
	var walk_meta: Dictionary = _sheet_meta(_player.walk_texture)
	var sf := SpriteFrameFactory.create_multi([
		{"texture": _player.idle_texture, "frame_count": idle_meta.count, "frame_size": idle_meta.size, "fps": _player.idle_fps, "loop": true, "name": "idle"},
		{"texture": _player.walk_texture, "frame_count": walk_meta.count, "frame_size": walk_meta.size, "fps": _player.walk_fps, "loop": true, "name": "walk"},
	])
	# D21-22-T3：追加 attack/skill 动画（D19① 守卫：缺帧文件不追加该动画，防 create_multi 吃 null 纹理）
	if not _player._sprite_prefix.is_empty():
		var attack_path: String = "%s%s_attack.png" % [_player.SPRITE_DIR, _player._sprite_prefix]
		var skill_path: String = "%s%s_skill.png" % [_player.SPRITE_DIR, _player._sprite_prefix]
		var hit_path: String = "%s%s_hit.png" % [_player.SPRITE_DIR, _player._sprite_prefix]
		if ResourceLoader.exists(attack_path):
			var attack_tex: Texture2D = ResourceLoader.load(attack_path)
			if attack_tex is Texture2D:
				var a_meta: Dictionary = _sheet_meta(attack_tex)
				sf.add_animation("attack")
				sf.set_animation_loop("attack", false)
				sf.set_animation_speed("attack", 12.0)
				for i in a_meta.count:
					var atlas := AtlasTexture.new()
					atlas.atlas = attack_tex
					atlas.region = Rect2(i * a_meta.size.x, 0, a_meta.size.x, a_meta.size.y)
					sf.add_frame("attack", atlas)
		if ResourceLoader.exists(skill_path):
			var skill_tex: Texture2D = ResourceLoader.load(skill_path)
			if skill_tex is Texture2D:
				var s_meta: Dictionary = _sheet_meta(skill_tex)
				sf.add_animation("skill")
				sf.set_animation_loop("skill", false)
				sf.set_animation_speed("skill", 10.0)
				for i in s_meta.count:
					var atlas := AtlasTexture.new()
					atlas.atlas = skill_tex
					atlas.region = Rect2(i * s_meta.size.x, 0, s_meta.size.x, s_meta.size.y)
					sf.add_frame("skill", atlas)
		# D29：追加 hit 受击动画（elin_hit 2 帧；缺帧文件不追加，静默降级红闪）
		if ResourceLoader.exists(hit_path):
			var hit_tex: Texture2D = ResourceLoader.load(hit_path)
			if hit_tex is Texture2D:
				var h_meta: Dictionary = _sheet_meta(hit_tex)
				sf.add_animation("hit")
				sf.set_animation_loop("hit", false)
				sf.set_animation_speed("hit", 14.0)
				for i in h_meta.count:
					var atlas := AtlasTexture.new()
					atlas.atlas = hit_tex
					atlas.region = Rect2(i * h_meta.size.x, 0, h_meta.size.x, h_meta.size.y)
					sf.add_frame("hit", atlas)
	_player._anim.sprite_frames = sf
	# F3-T6（T-034）：初始播放同步状态（换皮重建 sprite_frames 后回 IDLE，防状态漂移）
	_player._state = PlayerEnums.PlayerState.IDLE
	_player._anim.play("idle")
	# D19③：attack/skill 播完回 idle（命名方法，_ready 前已连一次即可；此处守卫防重复连接）
	if not _player._anim.animation_finished.is_connected(_on_anim_finished):
		_player._anim.animation_finished.connect(_on_anim_finished)

func _update_animation() -> void:
	if not _player._anim:
		return
	# D21-22-T3（D19②）：攻击/技能动画播放中禁止 move_and_slide 立即切回 idle 打断
	# D29：hit 受击动画同规则（2 帧极短，播完 _on_anim_finished 自动回 idle/walk）
	if _player._anim.animation in ["attack", "skill", "hit"]:
		return
	var moving := _player.velocity.length() > 10.0
	_transition_state(PlayerEnums.PlayerState.WALK if moving else PlayerEnums.PlayerState.IDLE)

## F3-T6（T-034 · 2026-08-13）：行为态转移统一入口——同值早退（HIT 同值重入例外：
## 受击连续触发须从头重播，保留原 _play_hit_anim stop+play 语义）→ 转移守卫 →
## 赋值 → ANIM_MAP 播放。守卫逐条保留原播放函数内语义（行为零改动）。
func _transition_state(next: int) -> void:
	if next == PlayerEnums.PlayerState.HIT and _player._state == PlayerEnums.PlayerState.HIT:
		if _player._anim and _player._anim.sprite_frames and _player._anim.sprite_frames.has_animation("hit"):
			_player._anim.stop()
			_player._anim.play("hit")
		return
	if _player._state == next:
		return
	match next:
		PlayerEnums.PlayerState.ATTACK:
			if not _player._anim or not _player._anim.sprite_frames or not _player._anim.sprite_frames.has_animation("attack"):
				return
			if _player._state == PlayerEnums.PlayerState.ATTACK or _player._state == PlayerEnums.PlayerState.SKILL:
				return
		PlayerEnums.PlayerState.SKILL:
			if not _player._anim or not _player._anim.sprite_frames or not _player._anim.sprite_frames.has_animation("skill"):
				return
			if _player._state == PlayerEnums.PlayerState.SKILL:
				return
		PlayerEnums.PlayerState.HIT:
			if not _player._anim or not _player._anim.sprite_frames or not _player._anim.sprite_frames.has_animation("hit"):
				return
			if _player._state == PlayerEnums.PlayerState.ATTACK or _player._state == PlayerEnums.PlayerState.SKILL:
				return
		PlayerEnums.PlayerState.WALK, PlayerEnums.PlayerState.IDLE:
			if not _player._anim:
				return
		PlayerEnums.PlayerState.DEAD:
			return
	_player._state = next
	if _player._anim:
		_player._anim.play(str(PlayerEnums.ANIM_MAP.get(next, "")))

## D21-22-T3（D19②/③）：开火 → 播 attack（武器控制器调用；动画缺失静默降级）
## F-32（08-09 用户反馈）：skill 播放中禁止 attack 抢占 —— 空格技能 6 帧可完整播放
func _play_attack_anim() -> void:
	_transition_state(PlayerEnums.PlayerState.ATTACK)

## D21-22-T3：技能释放 → 播 skill（skill_cast 信号连接；动画缺失静默降级）
func _play_skill_anim(_skill_id: String = "") -> void:
	_transition_state(PlayerEnums.PlayerState.SKILL)

## D21-22-T3（D19③）：attack/skill 播完 → 回 idle 且复位行走态（下次移动自动 walk）
## D29：hit 播完同规则（受击 2 帧播完自动回 idle/walk）
func _on_anim_finished() -> void:
	if not _player._anim:
		return
	if _player._anim.animation in ["attack", "skill", "hit"]:
		_transition_state(PlayerEnums.PlayerState.IDLE)

## D29：受击动画（elin_hit 2 帧）；无 hit 动画/正在播攻击技能 → 静默降级仅红闪
func _play_hit_anim() -> void:
	_transition_state(PlayerEnums.PlayerState.HIT)

## 受击闪烁特效
func _play_hit_flash() -> void:
	if not _player._anim:
		return
	_player._anim.modulate = Color(1, 0.3, 0.3)
	var tw := _player.create_tween()
	tw.tween_property(_player._anim, "modulate", Color.WHITE, 0.15)

## F-33（08-09 用户反馈）：原图默认朝左，向右移动/面向时 flip_h 镜像；
## 静止时保持最后朝向；idle/walk/attack/skill/hit 全部动画共享当前朝向
func _update_facing() -> void:
	if not _player._anim:
		return
	if absf(_player.velocity.x) > 1.0:
		_player._facing_left = _player.velocity.x < 0.0
		_player._anim.flip_h = not _player._facing_left
