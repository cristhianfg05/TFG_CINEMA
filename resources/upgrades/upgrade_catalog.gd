class_name UpgradeCatalog
extends RefCounted

const Rules := preload("res://resources/upgrades/incremental_rules.gd")
const CATEGORIES: Array[StringName] = [&"collection", &"vacuum", &"broom"]

const CATEGORY_TITLES := {
	"collection": "LIMPIEZA",
	"vacuum": "ASPIRADORA",
	"broom": "ESCOBA",
}

const ACTIVE_ABILITIES: Array[Dictionary] = [
	{"upgrade_id": "sealed_bags", "action": "ability_1", "key": "1", "status": "sacks"},
	{"upgrade_id": "all_seeing_eye", "action": "ability_2", "key": "2", "status": "cooldown"},
]

const TOOL_DEFINITIONS := {
	"vacuum": {"title": "ASPIRADORA DE MANO", "description": "Recoge cualquier basura de forma continua. Funciona con batería y se recarga al soltar el botón.", "cost": 1200, "icon": "vacuum", "model": "res://assets/models/source/tools/aspiradora.glb"},
	"broom": {"title": "ESCOBA", "description": "Barre cualquier basura para formar montones cerca de la papelera. Solo mueve: recoge después a mano o con aspiradora.", "cost": 150, "icon": "broom", "model": "res://assets/pipeline/props/cinema_broom.glb"},
}

# Prices and replacement values are deliberately centralized here for balancing.
# Historical prices are retained only to migrate and refund retired purchases.
const LEGACY_BRANCHES: Array[Dictionary] = [
	{"id": "quick_hands", "category": "collection", "title": "Manos ágiles", "description": "Reduce la espera entre recogidas manuales.", "icon": "quick_hands", "effect": "pickup_cooldown", "initial": 0.75, "costs": [15, 40, 90, 180, 350], "values": [0.60, 0.50, 0.40, 0.32, 0.25], "unit": "s"},
	{"id": "reinforced_bag", "category": "collection", "title": "Bolsa reforzada", "description": "Aumenta la capacidad de la bolsa y de cada saco cerrado.", "icon": "reinforced_bag", "effect": "bag_capacity", "initial": 10.0, "costs": [20, 55, 130, 280, 550], "values": [15.0, 20.0, 30.0, 45.0, 60.0], "unit": "uds."},
	{"id": "sealed_bags", "category": "collection", "title": "Sacos cerrados", "description": "Permite cerrar una bolsa llena y dejarla en el mundo.", "icon": "sealed_bags", "effect": "sealed_bags", "initial": 0.0, "costs": [60, 170, 380, 800, 1600], "values": [1.0, 3.0, 5.0, 10.0, 20.0], "unit": "sacos"},
	{"id": "sprint", "category": "collection", "title": "Sprint", "description": "Desbloquea y mejora el sprint y su recuperación.", "icon": "sprint", "effect": "sprint", "initial": 4.5, "secondary_initial": 0.0, "recharge_initial": 0.0, "costs": [40, 100, 220, 450, 900], "values": [5.2, 5.8, 6.4, 7.0, 7.5], "secondary": [3.0, 4.0, 5.0, 6.5, 8.0], "recharge": [7.0, 6.0, 5.0, 4.0, 3.0], "unit": "m/s"},
	{"id": "multi_pickup", "category": "collection", "title": "Recogida múltiple", "description": "Recoge varios objetos válidos visibles alrededor del puntero.", "icon": "multi_pickup", "effect": "manual_multi", "initial": 1.0, "costs": [80, 190, 420, 850], "values": [2.0, 3.0, 4.0, 5.0], "unit": "objetos"},
	{"id": "manual_reach", "category": "collection", "title": "Alcance manual", "description": "Aumenta la distancia de interacción manual.", "icon": "manual_reach", "effect": "manual_reach", "initial": 1.5, "costs": [25, 70, 160, 350], "values": [1.75, 2.0, 2.3, 2.6], "unit": "m"},
	{"id": "recycle_value", "category": "collection", "title": "Valor de reciclaje", "description": "Multiplica el valor base entero de cada entrega.", "icon": "recycle_value", "effect": "recycle_multiplier", "initial": 1.0, "costs": [200, 600, 1400, 3000], "values": [2.0, 3.0, 4.0, 5.0], "unit": "×"},
	{"id": "all_seeing_eye", "category": "collection", "title": "El ojo que todo lo ve", "description": "Revela temporalmente toda la basura de la sala, incluso detrás de obstáculos.", "icon": "all_seeing_eye", "effect": "all_seeing_eye", "initial": 0.0, "costs": [120, 300, 700], "values": [5.0, 8.0, 12.0], "cooldowns": [180.0, 120.0, 60.0], "unit": "s"},

	{"id": "vacuum_reach", "category": "vacuum", "tool": "vacuum", "title": "Alcance de aspiración", "description": "Aumenta el radio de aspiración compatible.", "icon": "vacuum", "effect": "vacuum_reach", "initial": 1.5, "costs": [220, 500, 1050, 2000], "values": [2.0, 2.5, 3.25, 4.0], "unit": "m"},
	{"id": "vacuum_battery", "category": "vacuum", "tool": "vacuum", "title": "Batería", "description": "Aumenta el uso continuo de la aspiradora.", "icon": "battery", "effect": "vacuum_battery", "initial": 8.0, "costs": [180, 420, 900, 1800], "values": [12.0, 18.0, 26.0, 40.0], "unit": "s"},
	{"id": "vacuum_recharge", "category": "vacuum", "tool": "vacuum", "title": "Velocidad de recarga", "description": "Aumenta la recarga automática en reposo.", "icon": "vacuum", "effect": "vacuum_recharge", "initial": 1.0, "costs": [160, 380, 800, 1600], "values": [1.5, 2.0, 3.0, 4.0], "unit": "×"},

	{"id": "boti_capacity", "category": "boti", "tool": "boti", "title": "Capacidad máxima", "description": "Aumenta las unidades que puede transportar Boti.", "icon": "boti_capacity", "effect": "boti_capacity", "initial": 50.0, "costs": [300, 650, 1300, 2600], "values": [75.0, 100.0, 150.0, 250.0], "unit": "uds."},
	{"id": "boti_rest", "category": "boti", "tool": "boti", "title": "Tiempo de descanso", "description": "Reduce la pausa de Boti después de descargar.", "icon": "boti_rest", "effect": "boti_rest", "initial": 10.0, "costs": [260, 600, 1250, 2500], "values": [8.0, 6.0, 4.0, 2.0], "unit": "s"},
	{"id": "boti_speed", "category": "boti", "tool": "boti", "title": "Velocidad de viaje", "description": "Aumenta la velocidad de Boti por los pasillos.", "icon": "boti_speed", "effect": "boti_speed", "initial": 2.0, "costs": [220, 520, 1100, 2200], "values": [2.75, 3.5, 4.5, 6.0], "unit": "m/s"},
]

static var BRANCHES: Array[Dictionary] = _make_incremental_branches()

static func _make_incremental_branches() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for original in LEGACY_BRANCHES:
		if String(original.id).begins_with("boti_"):
			continue
		var branch := original.duplicate(true)
		branch.costs = Rules.COSTS[String(branch.id)].duplicate()
		if branch.id == "reinforced_bag":
			branch.initial = 25.0
			branch.values = [40.0,65.0,100.0,150.0,220.0]
		if branch.id == "quick_hands":
			branch.description = "Acelera recogida y entrega. El primer nivel permite mantener pulsado para recoger sin repetir clics."
		result.append(branch)
	result.append({"id":"broom_speed","category":"broom","tool":"broom","title":"Velocidad de barrido","description":"Reduce la pausa entre barridos.","icon":"broom","initial":1.20,"costs":[125,300],"values":[0.85,0.55],"unit":"s"})
	result.append({"id":"broom_width","category":"broom","tool":"broom","title":"Ancho de barrido","description":"Mueve más basura con cada barrido.","icon":"broom","initial":0.75,"costs":[150,350],"values":[1.15,1.60],"unit":"m"})
	return result


static func get_branch(branch_id: StringName) -> Dictionary:
	for branch in BRANCHES:
		if StringName(branch.id) == branch_id:
			return branch
	return {}


static func get_category_branches(category: StringName) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for branch in BRANCHES:
		if StringName(branch.category) == category:
			result.append(branch)
	return result


static func get_value(branch: Dictionary, level: int) -> float:
	if level <= 0:
		return float(branch.get("initial", 0.0))
	var values: Array = branch.get("values", [])
	return float(values[clampi(level - 1, 0, values.size() - 1)])


static func get_secondary_value(branch: Dictionary, level: int) -> float:
	if level <= 0:
		return float(branch.get("secondary_initial", 0.0))
	var values: Array = branch.get("secondary", [])
	if values.is_empty():
		return 0.0
	return float(values[clampi(level - 1, 0, values.size() - 1)])


static func get_sprint_recharge_time(branch: Dictionary, level: int) -> float:
	if level <= 0:
		return float(branch.get("recharge_initial", 0.0))
	var values: Array = branch.get("recharge", [])
	if values.is_empty():
		return 0.0
	return float(values[clampi(level - 1, 0, values.size() - 1)])


static func get_ability_cooldown(branch: Dictionary, level: int) -> float:
	if level <= 0:
		return 0.0
	var cooldowns: Array = branch.get("cooldowns", [])
	if cooldowns.is_empty():
		return 0.0
	return float(cooldowns[clampi(level - 1, 0, cooldowns.size() - 1)])
