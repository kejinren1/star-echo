## 玩家角色脚本
## 处理移动、属性、受伤、自动攻击触发
extends CharacterBody2D

# ========== 信号 ==========

signal died
signal health_changed(current_hp: float, max_hp: float)
signal stats_changed
signal took_damage(amount: float)
signal level_up(new_level: int)                 ## 升级（D4-T1：经验满触发）
signal xp_changed(current: float, need: float)  ## 经验变化（D4-T1：HUD 刷新用）

# ========== 导出属性 ==========

@export_group("基本属性")
@export var max_health: float = 100.0       ## 最大生命值
@export var move_speed: float = 300.0        ## 移动速度 (像素/秒)
@export var armor: float = 0.0               ## 护甲 (减伤)
@export var dodge: float = 0.0               ## 闪避率 (0~1)
@export var regen: float = 0.0               ## 每秒回复生命

@export_group("战斗属性")
@export var damage_multiplier: float = 1.0   ## 伤害倍率
@export var attack_speed: float = 1.0        ## 攻速倍率
@export var crit_chance: float = 0.05        ## 暴击率
@export var crit_damage: float = 2.0         ## 暴击伤害倍率
@export var range_multiplier: float = 1.0    ## 攻击范围倍率
@export var pickup_range: float = 80.0       ## 拾取范围
@export var life_steal: float = 0.0          ## 吸血：命中伤害回血比例 (0~1)（D4-T3）
## F-04（用户拍板 2026-08-06 · P0）：金手指攻击倍率（toggle_debug_cheat 写入；
## 默认 1.0 零回归；weapon_controller/skill_controller 聚合消费）
var debug_mult: float = 1.0
## D20-T2：遗物装配倍率（percent 键乘算目标；默认 1.0 零回归，新实例即复位）
var damage_taken_mult: float = 1.0        ## 受伤倍率（take_damage armor 减伤后乘，破碎王冠 +30%）
var structure_damage_mult: float = 1.0    ## 结构伤害倍率（turret 弹药消费，机械引擎 +100%）

@export_group("经济属性")
@export var coin_bonus: float = 0.0          ## 金币加成 (0~1)
@export var luck: float = 0.0                ## 幸运值 (影响商店品质)

@export_group("精灵资源")
@export var idle_texture: Texture2D          ## idle 动画 sprite sheet
@export var walk_texture: Texture2D          ## walk 动画 sprite sheet
@export var frame_size: Vector2i = Vector2i(32, 32)  ## 单帧尺寸
@export var idle_fps: float = 6.0            ## idle 动画 FPS
@export var walk_fps: float = 10.0           ## walk 动画 FPS

# ========== 角色（Day 2：hero id 消费） ==========

## 英雄精灵目录（配合 characters.json 的 `sprite` 前缀字段拼装）
const SPRITE_DIR: String = "res://assets/sprites/characters/"

## characters.json 的 passive/penalty 键 → apply_stat_modifier 的合法 stat 名
## mode: "add" 直接加 / "percent" 百分数转倍率乘算 / "ratio" 百分数转 0~1 后加
const STAT_MAP: Dictionary = {
	"max_hp": {"stat": "max_health", "mode": "add"},
	"speed_percent": {"stat": "move_speed", "mode": "percent"},
	"armor": {"stat": "armor", "mode": "add"},
	"regen": {"stat": "regen", "mode": "add"},
	"hp_regen": {"stat": "regen", "mode": "add"},
	"dodge_percent": {"stat": "dodge", "mode": "ratio"},
	"crit_chance_percent": {"stat": "crit_chance", "mode": "ratio"},
	"attack_speed_percent": {"stat": "attack_speed", "mode": "percent"},
	"melee_attack_speed_percent": {"stat": "attack_speed", "mode": "percent"},
	"damage_percent": {"stat": "damage", "mode": "percent"},
	"range_percent": {"stat": "range", "mode": "percent"},
	"luck": {"stat": "luck", "mode": "add"},
	"pickup_range": {"stat": "pickup_range", "mode": "add"},
	"life_steal_percent": {"stat": "life_steal", "mode": "ratio"},  ## D4-T3：莱恩 passive 5 → 0.05 进通道
	"crit_damage_percent": {"stat": "crit_damage", "mode": "percent"},  ## D11-12-T3：se_blade_core 20 → ×1.2（2.0→2.4）
	"damage_taken_percent": {"stat": "damage_taken_mult", "mode": "percent"},      ## D20-T2：破碎王冠 30 → ×1.3（take_damage armor 后乘）
	"structure_damage_percent": {"stat": "structure_damage_mult", "mode": "percent"},  ## D20-T2：机械引擎 100 → ×2.0（turret 弹药消费，D20-T6 §5）
}

## 刻意不进 STAT_MAP 的键（进 bonus_stats 等后续系统消费），附不映射的原因
## `range`：JSON 里是「像素平直加减」（如 brawler -50），而 range_multiplier 是倍率，
##          直接加会把倍率打成负数使武器射程失效 —— 口径统一属 Day 4 强化面板的决策
const STAT_MAP_EXCLUDED: PackedStringArray = ["range"]

## P0-Bug2 修复（2026-08-10）：未映射键中「已有消费方」的白名单 —— 收进 bonus_stats 即生效，不警告
## 消费方：orbit_blade_count → orbit_weapon.gd；elemental_damage → skill_controller 燃烧 dps；
##         summon_count → skill_controller 炮台数量。其余未映射键无消费方 → 收进 bonus_stats + 警告登记
const CONSUMED_BONUS_KEYS: PackedStringArray = ["orbit_blade_count", "elemental_damage", "summon_count"]

var character_id: String = ""                ## 当前英雄 id（空 = 未经角色选择）
var bonus_stats: Dictionary = {}             ## 引擎尚未实现的被动/惩罚键，Day 3 技能与 Day 4 面板读此字典

# ========== 内部状态 ==========

var health: float                            ## 当前生命值
## P0-Bug1 修复（2026-08-10）：希亚「神圣庇护」护盾 —— 受击优先吸收，时长到自动归零
var shield: float = 0.0                      ## 护盾值（神圣庇护等技能来源）
var _shield_timer: float = 0.0               ## 护盾剩余时长（<=0 归零）
var _shield_duration: float = 0.0            ## 护盾总时长
var is_alive: bool = true
var _invulnerable_timer: float = 0.0         ## 无敌帧计时
var _last_stand_active: bool = false         ## D24-F13-2（F-13 low_health · last_stand 背水一战）当前是否生效

# 经验与升级（D4-T1）
var exp: float = 0.0                         ## 当前经验值
var level: int = 1                           ## 当前等级（1 起）
var _xp_curve_cache: Expression = null       ## 经验曲线表达式缓存（解析一次，避免逐级重复 parse）

# 动画
var _anim: AnimatedSprite2D
var _is_walking: bool = false
## F-33（08-09 用户反馈）：朝向 —— true=朝左（原图默认），false=朝右（flip_h 镜像）
var _facing_left: bool = true
## D21-22-T3：角色精灵前缀（_apply_character_sprite 写入；空 = 默认 fighter 无 attack/skill）
var _sprite_prefix: String = ""

# ========== 生命周期 ==========

func _ready() -> void:
	health = max_health
	health_changed.emit(health, max_health)
	_setup_animation()
	# D21-22-T3：连接技能释放信号 → 播技能动画（SkillController 为子节点，_ready 先于本节点执行）
	var sc: Node = get_node_or_null("SkillController")
	if sc and sc.has_signal("skill_cast"):
		sc.skill_cast.connect(_play_skill_anim)

# ========== 角色装载（由 Main 在 _ready 中调用） ==========

## 应用 characters.json 中的一条英雄数据：被动 + 惩罚 + 精灵资源
## 空字典直接返回（调试直开 Main.tscn 时保持出厂属性）
func apply_character(char_data: Dictionary) -> void:
	if char_data.is_empty():
		return

	character_id = str(char_data.get("id", ""))
	bonus_stats.clear()
	# 惩罚与被动同表处理：值为负数走同一入口即可
	_apply_stat_dict(char_data.get("passive", {}))
	_apply_stat_dict(char_data.get("penalty", {}))
	_apply_character_sprite(str(char_data.get("sprite", "")))

	# 起始满血：被动/惩罚可能改动了上限
	health = max_health
	health_changed.emit(health, max_health)
	stats_changed.emit()

## 按 STAT_MAP 落实一组属性键；未映射的键原样收进 bonus_stats（禁止静默丢弃）
func _apply_stat_dict(source: Dictionary) -> void:
	if source.is_empty():
		return

	for key: String in source:
		var amount: float = float(source[key])
		if not STAT_MAP.has(key):
			# 同名键叠加而非覆盖（passive 与 penalty 可能命中同一键）
			bonus_stats[key] = float(bonus_stats.get(key, 0.0)) + amount
			continue

		var rule: Dictionary = STAT_MAP[key]
		var stat_name: String = str(rule["stat"])
		match str(rule["mode"]):
			"add":
				apply_stat_modifier(stat_name, amount)
			"percent":
				apply_stat_modifier(stat_name, 1.0 + amount / 100.0, true)
			"ratio":
				apply_stat_modifier(stat_name, amount / 100.0)

## D11-12-T3：被动道具装配（买了必生效）/ 回退（remove=true 反向还原）
## P0-Bug2 修复（2026-08-10）：未映射键不再静默跳过 —— 一律收进 bonus_stats（与角色
## _apply_stat_dict 同口径）；已有消费方的键（CONSUMED_BONUS_KEYS）零噪音生效，
## 无消费方的键 push_warning 显式暴露（登记 docs/TECH_DEBT_ISSUES.md，F 阶段接线或删死数据）。
## percent 模式 remove 用除法精确还原（乘算非对称：撤销 +8% 是 ÷1.08 而非 ×0.92）。
func apply_item_bonuses(item: Resource, remove: bool = false) -> void:
	if item == null or not item.has_method("get_stat"):
		return
	var bonuses: Dictionary = item.call("get_all_stats")
	if bonuses.is_empty():
		return

	for key: String in bonuses:
		var amount: float = float(bonuses[key])
		if not STAT_MAP.has(key):
			# P0-Bug2：收进 bonus_stats（数值不丢，remove 对称还原）
			if remove:
				bonus_stats[key] = float(bonus_stats.get(key, 0.0)) - amount
			else:
				bonus_stats[key] = float(bonus_stats.get(key, 0.0)) + amount
			# 无消费方的键仍显式暴露（有消费方 = 白名单零噪音）
			if not CONSUMED_BONUS_KEYS.has(key):
				push_warning("[Player] 被动效果键无消费方，仅登记 bonus_stats: %s" % key)
			continue
		var rule: Dictionary = STAT_MAP[key]
		var stat_name: String = str(rule["stat"])
		if remove:
			amount = -amount
		match str(rule["mode"]):
			"add":
				apply_stat_modifier(stat_name, amount)
			"percent":
				if remove:
					# amount 已取负，absf 还原原倍率分母 → 除法撤销
					apply_stat_modifier(stat_name, 1.0 / (1.0 + absf(amount) / 100.0), true)
				else:
					apply_stat_modifier(stat_name, 1.0 + amount / 100.0, true)
			"ratio":
				apply_stat_modifier(stat_name, amount / 100.0)

## 换上英雄专属精灵（`sprite` 为资源名前缀）；缺资源时保留 Player.tscn 预设素材
func _apply_character_sprite(prefix: String) -> void:
	if prefix.is_empty():
		return
	var idle_path: String = "%s%s_idle.png" % [SPRITE_DIR, prefix]
	var walk_path: String = "%s%s_walk.png" % [SPRITE_DIR, prefix]
	if not ResourceLoader.exists(idle_path) or not ResourceLoader.exists(walk_path):
		# 区分「文件不在」与「文件在但未生成 .import」，后者编辑器一开即消解，不算缺陷
		if FileAccess.file_exists(idle_path) and FileAccess.file_exists(walk_path):
			print_verbose("[Player] 英雄精灵尚未导入，沿用默认素材: %s" % character_id)
		else:
			push_warning("[Player] 英雄精灵缺失，沿用默认素材: %s" % character_id)
		return

	var idle_res := ResourceLoader.load(idle_path)
	var walk_res := ResourceLoader.load(walk_path)
	if not (idle_res is Texture2D) or not (walk_res is Texture2D):
		return
	idle_texture = idle_res as Texture2D
	walk_texture = walk_res as Texture2D
	_sprite_prefix = prefix
	_is_walking = false
	_setup_animation()

# ========== 动画 ==========

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
	_anim = get_node_or_null("AnimatedSprite2D")
	if not _anim:
		return
	# 如果未通过 @export 指定纹理，尝试从默认路径加载
	if not idle_texture:
		idle_texture = load("res://assets/sprites/characters/fighter_idle.png")
	if not walk_texture:
		walk_texture = load("res://assets/sprites/characters/fighter_walk.png")
	if not idle_texture or not walk_texture:
		return
	# 构建 SpriteFrames（帧尺寸/帧数按各自 sheet 推断：elin 64px 帧 idle 3 / walk 10）
	var idle_meta: Dictionary = _sheet_meta(idle_texture)
	var walk_meta: Dictionary = _sheet_meta(walk_texture)
	var sf := SpriteFrameFactory.create_multi([
		{"texture": idle_texture, "frame_count": idle_meta.count, "frame_size": idle_meta.size, "fps": idle_fps, "loop": true, "name": "idle"},
		{"texture": walk_texture, "frame_count": walk_meta.count, "frame_size": walk_meta.size, "fps": walk_fps, "loop": true, "name": "walk"},
	])
	# D21-22-T3：追加 attack/skill 动画（D19① 守卫：缺帧文件不追加该动画，防 create_multi 吃 null 纹理）
	if not _sprite_prefix.is_empty():
		var attack_path: String = "%s%s_attack.png" % [SPRITE_DIR, _sprite_prefix]
		var skill_path: String = "%s%s_skill.png" % [SPRITE_DIR, _sprite_prefix]
		var hit_path: String = "%s%s_hit.png" % [SPRITE_DIR, _sprite_prefix]
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
	_anim.sprite_frames = sf
	_anim.play("idle")
	# D19③：attack/skill 播完回 idle（命名方法，_ready 前已连一次即可；此处守卫防重复连接）
	if not _anim.animation_finished.is_connected(_on_anim_finished):
		_anim.animation_finished.connect(_on_anim_finished)

func _update_animation() -> void:
	if not _anim:
		return
	# D21-22-T3（D19②）：攻击/技能动画播放中禁止 move_and_slide 立即切回 idle 打断
	# D29：hit 受击动画同规则（2 帧极短，播完 _on_anim_finished 自动回 idle/walk）
	if _anim.animation in ["attack", "skill", "hit"]:
		return
	var moving := velocity.length() > 10.0
	if moving and not _is_walking:
		_is_walking = true
		_anim.play("walk")
	elif not moving and _is_walking:
		_is_walking = false
		_anim.play("idle")

## D21-22-T3（D19②/③）：开火 → 播 attack（武器控制器调用；动画缺失静默降级）
## F-32（08-09 用户反馈）：skill 播放中禁止 attack 抢占 —— 空格技能 6 帧可完整播放
func _play_attack_anim() -> void:
	if not _anim or not _anim.sprite_frames or not _anim.sprite_frames.has_animation("attack"):
		return
	if _anim.animation in ["attack", "skill"]:
		return
	_anim.play("attack")

## D21-22-T3：技能释放 → 播 skill（skill_cast 信号连接；动画缺失静默降级）
func _play_skill_anim(_skill_id: String = "") -> void:
	if not _anim or not _anim.sprite_frames or not _anim.sprite_frames.has_animation("skill"):
		return
	if _anim.animation == "skill":
		return
	_anim.play("skill")

## D21-22-T3（D19③）：attack/skill 播完 → 回 idle 且复位行走态（下次移动自动 walk）
## D29：hit 播完同规则（受击 2 帧播完自动回 idle/walk）
func _on_anim_finished() -> void:
	if not _anim:
		return
	if _anim.animation in ["attack", "skill", "hit"]:
		_is_walking = false
		_anim.play("idle")

## D29：受击动画（elin_hit 2 帧）；无 hit 动画/正在播攻击技能 → 静默降级仅红闪
func _play_hit_anim() -> void:
	if not _anim or not _anim.sprite_frames or not _anim.sprite_frames.has_animation("hit"):
		return
	if _anim.animation in ["attack", "skill"]:
		return
	if _anim.animation == "hit":
		_anim.stop()
	_anim.play("hit")

## 受击闪烁特效
func _play_hit_flash() -> void:
	if not _anim:
		return
	_anim.modulate = Color(1, 0.3, 0.3)
	var tw := create_tween()
	tw.tween_property(_anim, "modulate", Color.WHITE, 0.15)

func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	_handle_movement()
	_handle_regeneration(delta)
	_handle_shield(delta)

	if _invulnerable_timer > 0.0:
		_invulnerable_timer -= delta

# ========== 移动 ==========

func _handle_movement() -> void:
	var input_vector := Vector2.ZERO
	input_vector.x = Input.get_axis("move_left", "move_right")
	input_vector.y = Input.get_axis("move_up", "move_down")
	input_vector = input_vector.normalized()

	velocity = input_vector * move_speed
	move_and_slide()
	# F-33（08-09 用户反馈）：左右转向 —— 原图默认朝左，按水平移动方向镜像翻转
	_update_facing()
	_update_animation()

## F-33（08-09 用户反馈）：原图默认朝左，向右移动/面向时 flip_h 镜像；
## 静止时保持最后朝向；idle/walk/attack/skill/hit 全部动画共享当前朝向
func _update_facing() -> void:
	if not _anim:
		return
	if absf(velocity.x) > 1.0:
		_facing_left = velocity.x < 0.0
		_anim.flip_h = not _facing_left

# ========== 主动技能（大纲 §5：玩家控制的主动技能，带冷却/资源） ==========
# D1 打桩：输入动作 skill_cast 已注册；D3-T1 转发到 SkillController 统一释放。

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("skill_cast"):
		_try_cast_skill()

## 主动技能释放（转发给 SkillController；节点缺失时保留空实现分支防崩）
func _try_cast_skill() -> void:
	var controller: Node = get_node_or_null("SkillController")
	if controller and controller.has_method("try_cast"):
		controller.try_cast()
	# 无 SkillController 时静默 pass（Player.tscn 未更新路径防崩）

# ========== 生命与受伤 ==========

func _handle_regeneration(delta: float) -> void:
	if regen > 0.0 and health < max_health:
		heal(regen * delta)

## 护盾倒计时（P0-Bug1 修复）：时长耗尽护盾归零（溢出值丢弃，不累计下次）
func _handle_shield(delta: float) -> void:
	if _shield_timer <= 0.0:
		return
	_shield_timer -= delta
	if _shield_timer <= 0.0:
		shield = 0.0

## 添加护盾（技能调用；同源重复施放 = 刷新时长并叠加值）
func add_shield(amount: float, duration: float) -> void:
	shield += maxf(amount, 0.0)
	_shield_duration = maxf(duration, 0.0)
	_shield_timer = _shield_duration

## 受到伤害
func take_damage(amount: float) -> void:
	if not is_alive or _invulnerable_timer > 0.0:
		return

	# 护盾吸收（P0-Bug1 修复）：护盾优先于闪避/护甲；全吸收时仅受击反馈 + 无敌帧
	if shield > 0.0:
		var absorbed: float = minf(shield, amount)
		shield -= absorbed
		amount -= absorbed
		if amount <= 0.0:
			_play_hit_flash()
			_invulnerable_timer = 0.4
			return

	# 闪避判定
	if randf() < dodge:
		return

	# 护甲减伤
	var actual_damage: float = max(amount - armor, 1.0)
	# D20-T2（破碎王冠）：受伤倍率（armor 平直减伤先减后乘；默认 1.0 零回归）
	actual_damage *= damage_taken_mult
	# F-04（金手指）：受伤 0.1%（≈无敌，试玩效率工具；关闭时恒 1 零回归）
	if GameManager and GameManager.debug_cheat:
		actual_damage *= 0.001
	health -= actual_damage
	health_changed.emit(health, max_health)
	took_damage.emit(actual_damage)
	_play_hit_flash()
	_play_hit_anim()   # D29：受击动画（无 hit 帧时静默降级仅红闪）
	AudioManager.play_sfx("hit")   # D24-T3-④：受击 SFX
	# 短无敌帧，避免被群体敌人每帧叠伤
	_invulnerable_timer = 0.4
	# D24-F13-2（F-13 low_health · last_stand 背水一战）：受击后统一刷新低血状态（乘算开/关 + 逆运算回滚）
	_update_last_stand()

	if health <= 0.0:
		die()

## 治疗
func heal(amount: float) -> void:
	health = min(health + amount, max_health)
	health_changed.emit(health, max_health)
	# D24-F13-2（F-13 low_health · last_stand 背水一战）：回血后刷新低血状态（回血 >30% 自动解除）
	_update_last_stand()

## D24-F13-2（F-13 low_health · last_stand 背水一战）：低血爆发状态统一入口
## 持有 last_stand 且血量 ≤ max_health×30% → damage ×1.5 + attack_speed ×1.2（乘算开）；
## 解除/未持有 → 逆运算回滚（×1/1.5、×1/1.2）。状态变化才切换一次，防每帧重复应用。
## ⚠️ 边缘风险（D29 已标注可接受）：开启期间若发生其它乘算 buff 变更（遗物装配/升级），
## 关闭逆运算可能引入 ±小偏差——低血状态通常数秒即回血解除，期间装配/升级概率极低。
func _update_last_stand() -> void:
	var should: bool = false
	if is_alive and health > 0.0 and GameManager and GameManager.inventory \
			and GameManager.inventory.has_item_id(DataLoader.ITEM_LAST_STAND) \
			and health <= max_health * 0.3:
		should = true
	if should and not _last_stand_active:
		apply_stat_modifier("damage", 1.5, true)
		apply_stat_modifier("attack_speed", 1.2, true)
		_last_stand_active = true
	elif not should and _last_stand_active:
		apply_stat_modifier("damage", 1.0 / 1.5, true)
		apply_stat_modifier("attack_speed", 1.0 / 1.2, true)
		_last_stand_active = false

## 死亡
func die() -> void:
	is_alive = false
	health = 0.0
	health_changed.emit(health, max_health)
	died.emit()
	GameManager.end_game(false)

# ========== 经验与升级（Day 4 · D4-T1） ==========
## 经验曲线唯一权威：stats.json.leveling.xp_per_level 字符串表达式
## （"20 + current_level * 10"），用 Godot Expression 解析并绑定 current_level=level，
## 禁止在代码里硬编码第二份曲线（双源漂移）。

## 获得经验（由 enemy._drop_rewards 击杀掉落调用）
func gain_exp(amount: float) -> void:
	if not is_alive or amount <= 0.0:
		return
	exp += amount
	_check_level_up()
	xp_changed.emit(exp, get_xp_to_next_level())
	stats_changed.emit()

## 当前等级升到下一级所需经验（HUD / 测试读取）
func get_xp_to_next_level() -> float:
	var need: float = _eval_xp_curve()
	return maxf(need, 1.0)

## 检查升级：while 循环，一次大量经验可连升多级
func _check_level_up() -> void:
	while exp >= get_xp_to_next_level():
		exp -= get_xp_to_next_level()
		level += 1
		# H-01 升级体验（反馈专员 2026-08-07 用户拍板）：升级光效 + 击退 + 普攻级伤害
		_trigger_level_impact()
		level_up.emit(level)
		AudioManager.play_sfx("levelup")   # D24-T3-⑤：升级 SFX

# ========== 升级冲击波（H-01 升级体验反馈 2026-08-07 · 用户拍板） ==========
## 「升级有光效，会对周围敌人进行击退并造成和普攻差不多的伤害」——
## 占位特效机制验证（色块/复用动画，不建 GPU 基建）；伤害对齐普攻口径
## weapon_controller._spawn_projectile（base_damage × damage_multiplier × debug_mult）。
const LEVEL_IMPACT_RADIUS: float = 140.0      ## 冲击半径（640×360 视口约 1/3 屏宽）
const LEVEL_IMPACT_KNOCKBACK: float = 500.0   ## 击退初速（px/s，衰减 50%/帧 ≈ 15-20px 推离）
const LEVEL_IMPACT_DAMAGE_FALLBACK: float = 10.0  ## 无武器兜底（对齐普攻基准）

## 触发升级冲击：光效 + 范围内敌人击退并造成普攻级伤害（容器缺失静默跳过不崩）
func _trigger_level_impact() -> void:
	# 光效：复用现成 fx_levelup 6 帧动画（VfxPlayer 占位特效机制）
	var container: Node = null
	if GameManager and GameManager.vfx_container:
		container = GameManager.vfx_container
	elif get_tree() and get_tree().current_scene:
		container = get_tree().current_scene
	if container:
		VfxPlayer.spawn(container, global_position, "levelup")
	# 伤害：当前武器 base_damage × 玩家倍率（对齐普攻口径；无武器兜底 10.0）
	var dmg: float = LEVEL_IMPACT_DAMAGE_FALLBACK * damage_multiplier * debug_mult
	var wc: Node = get_node_or_null("WeaponController")
	if wc and "equipped_weapons" in wc:
		var weapons: Array = wc.equipped_weapons
		if not weapons.is_empty() and weapons[0] and "base_damage" in weapons[0]:
			dmg = float(weapons[0].base_damage) * damage_multiplier * debug_mult
	# 击退 + 伤害：遍历存活敌人容器，半径内伤害 + 背离玩家方向击退
	if GameManager and GameManager.enemies_container:
		for enemy in GameManager.enemies_container.get_children():
			if enemy == null or not is_instance_valid(enemy):
				continue
			if not ("is_alive" in enemy and enemy.is_alive):
				continue
			if not enemy.has_method("take_damage"):
				continue
			var dist := global_position.distance_to(enemy.global_position)
			if dist > LEVEL_IMPACT_RADIUS:
				continue
			enemy.take_damage(dmg)
			if enemy.has_method("apply_knockback") and dist > 1.0:
				enemy.apply_knockback(enemy.global_position - global_position, LEVEL_IMPACT_KNOCKBACK)

## 解析并求值经验曲线表达式；任何异常回退默认曲线并告警，禁止崩溃
func _eval_xp_curve() -> float:
	var expr_text: String = ""
	var leveling: Dictionary = DataLoader.get_leveling()
	if not leveling.is_empty():
		expr_text = str(leveling.get("xp_per_level", ""))
	if expr_text.is_empty():
		expr_text = "20 + current_level * 10"
	if _xp_curve_cache == null:
		_xp_curve_cache = Expression.new()
		var err: Error = _xp_curve_cache.parse(expr_text, ["current_level"])
		if err != OK:
			push_warning("[Player] 经验曲线表达式解析失败(%s): %s，回退默认曲线" % [err, expr_text])
			_xp_curve_cache = null
			return 20.0 + float(level) * 10.0
	var result: Variant = _xp_curve_cache.execute([float(level)], _xp_curve_cache)
	if _xp_curve_cache.has_execute_failed():
		push_warning("[Player] 经验曲线求值失败，回退默认曲线")
		return 20.0 + float(level) * 10.0
	return float(result)

# ========== 属性修改接口 ==========

## 应用属性修改 (供道具系统调用)
func apply_stat_modifier(stat_name: String, value: float, is_multiplicative: bool = false) -> void:
	match stat_name:
		"max_health":
			if is_multiplicative:
				max_health *= value
			else:
				max_health += value
			health = min(health, max_health)
		"move_speed":
			move_speed = apply_value(move_speed, value, is_multiplicative)
		"armor":
			armor = apply_value(armor, value, is_multiplicative)
		"damage":
			damage_multiplier = apply_value(damage_multiplier, value, is_multiplicative)
		"attack_speed":
			attack_speed = apply_value(attack_speed, value, is_multiplicative)
		"crit_chance":
			crit_chance = apply_value(crit_chance, value, is_multiplicative)
		"range":
			range_multiplier = apply_value(range_multiplier, value, is_multiplicative)
		"regen":
			regen = apply_value(regen, value, is_multiplicative)
		"pickup_range":
			pickup_range = apply_value(pickup_range, value, is_multiplicative)
		"crit_damage":
			crit_damage = apply_value(crit_damage, value, is_multiplicative)
		"dodge":
			dodge = clampf(apply_value(dodge, value, is_multiplicative), 0.0, 0.9)
		"luck":
			luck = apply_value(luck, value, is_multiplicative)
		"life_steal":
			life_steal = clampf(apply_value(life_steal, value, is_multiplicative), 0.0, 1.0)
		"damage_taken_mult":  ## D20-T2：受伤倍率（percent 键乘算；remove 走除法还原）
			damage_taken_mult = apply_value(damage_taken_mult, value, is_multiplicative)
		"structure_damage_mult":  ## D20-T2：结构伤害倍率（turret 弹药消费）
			structure_damage_mult = apply_value(structure_damage_mult, value, is_multiplicative)
		"coin_bonus":
			coin_bonus = apply_value(coin_bonus, value, is_multiplicative)
	stats_changed.emit()

func apply_value(base: float, mod: float, multiplicative: bool) -> float:
	if multiplicative:
		return base * mod
	else:
		return base + mod
