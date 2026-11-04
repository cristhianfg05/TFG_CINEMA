class_name CollectibleCatalog
extends RefCounted

const TOTAL_SLOTS := 14
const FIGURE_01 := preload("res://assets/models/source/collectibles/1.glb")
const FIGURE_02 := preload("res://assets/models/source/collectibles/2.glb")
const FIGURE_03 := preload("res://assets/models/source/collectibles/3.glb")
const FIGURE_04 := preload("res://assets/models/source/collectibles/4.glb")
const FIGURE_05 := preload("res://assets/models/source/collectibles/5.glb")
const FIGURE_06 := preload("res://assets/models/source/collectibles/6.glb")
const FIGURE_07 := preload("res://assets/models/source/collectibles/7.glb")
const FIGURE_08 := preload("res://assets/models/source/collectibles/8.glb")
const FIGURE_09 := preload("res://assets/models/source/collectibles/9.glb")
const FIGURE_10 := preload("res://assets/models/source/collectibles/10.glb")
const SALA_1_POSTER := preload("res://assets/movies/room_1/Movie_Cartel.jpeg")
const SALA_2_POSTER := preload("res://assets/movies/room_2/Movie_Cartel.jpeg")
const SALA_3_POSTER := preload("res://assets/movies/room_3/Movie_Cartel.jpeg")
const SALA_4_POSTER := preload("res://assets/movies/room_4/Movie_Cartel.jpeg")

const DEFINITIONS: Array[Dictionary] = [
	{
		"id": "capitan_orbita",
		"number": 1,
		"title": "Capitán Órbita",
		"location": "Sala 1, detrás del altavoz delantero izquierdo, entre el escenario y la pared.",
		"description": "El héroe espacial más valiente del Palace, aunque no necesariamente el más competente. Su casco ocupaba más que el decorado y su pistola nunca apuntaba hacia donde debía.",
		"model_scene": FIGURE_01,
		"preview_scale": Vector3.ONE * 1.15,
		"preview_offset": Vector3(0.0, 0.16, 0.0),
		"preview_rotation": Vector3(0.0, -18.0, 0.0),
		"found": false,
		"viewed": false,
	},
	{
		"id": "amelia_del_anden", "number": 2, "title": "Amelia del Andén",
		"location": "Sala 2, bajo uno de los corazones colgantes.",
		"description": "Amelia esperó en el mismo andén durante toda una película. El tren nunca llegó, pero durante tres semanas no quedó una sola butaca libre.",
		"model_scene": FIGURE_02, "preview_scale": Vector3.ONE * 1.15, "preview_offset": Vector3(0, 0.16, 0),
		"found": false, "viewed": false,
	},
	{
		"id": "hombre_del_paraguas", "number": 3, "title": "El Hombre del Paraguas",
		"location": "Sala 2, detrás de una cortina lateral de la pantalla.",
		"description": "Nadie llegó a verle el rostro. En los carteles siempre aparecía unos pasos detrás de Amelia, incluso en escenas donde se suponía que no estaba.",
		"model_scene": FIGURE_03, "preview_scale": Vector3.ONE * 1.15, "preview_offset": Vector3(0, 0.16, 0),
		"found": false, "viewed": false,
	},
	{
		"id": "palomito", "number": 4, "title": "Palomito",
		"location": "Vestíbulo, zona del futuro puesto de palomitas.",
		"description": "La mascota oficial del Palace: pajarita, zapatos relucientes y una cantidad poco razonable de mantequilla. Su trabajo consistía en recordar al público que todavía no había comprado suficientes palomitas.",
		"model_scene": FIGURE_04, "preview_scale": Vector3.ONE * 1.15, "preview_offset": Vector3(0, 0.16, 0),
		"found": false, "viewed": false,
	},
	{
		"id": "reina_refresco", "number": 5, "title": "Reina Refresco",
		"location": "Vestíbulo, zona de la futura taquilla.",
		"description": "Rival publicitaria de Palomito y autoproclamada soberana del vestíbulo. Exigía una corona, mucho hielo y el vaso más grande del expositor.",
		"model_scene": FIGURE_05, "preview_scale": Vector3.ONE * 5.0, "preview_offset": Vector3(0, -0.20, 0),
		"found": false, "viewed": false,
	},
	{
		"id": "devorapalomitas", "number": 6, "title": "El Devorapalomitas",
		"location": "Sala 4 (Miedo), entre las decoraciones monstruosas.",
		"description": "Una criatura formada por palomitas rancias que crecía con cada crujido escuchado durante la película. Los niños la adoraban; el personal de limpieza, bastante menos.",
		"model_scene": FIGURE_06, "preview_scale": Vector3.ONE * 1.15, "preview_offset": Vector3(0, 0.16, 0),
		"found": false, "viewed": false,
	},
	{
		"id": "acomodador_sin_rostro", "number": 7, "title": "El Acomodador sin Rostro",
		"location": "Sala 4 (Miedo), junto a la última fila de butacas.",
		"description": "Un uniforme vacío que recorría los pasillos con una linterna encendida. Los niños se retaban a mirarlo cuando la luz se apagaba.",
		"model_scene": FIGURE_07, "preview_scale": Vector3.ONE * 1.15, "preview_offset": Vector3(0, 0.16, 0),
		"found": false, "viewed": false,
	},
	{
		"id": "detective_mecha_corta", "number": 8, "title": "Detective Mecha Corta",
		"location": "Sala 3 (Acción), junto a un altavoz frontal.",
		"description": "El detective más pequeño de la ciudad y el que llevaba la gabardina más grande. Nunca resolvía un crimen sin provocar antes otros dos.",
		"model_scene": FIGURE_08, "preview_scale": Vector3.ONE * 1.15, "preview_offset": Vector3(0, 0.16, 0),
		"found": false, "viewed": false,
	},
	{
		"id": "paloma_dinamita", "number": 9, "title": "Paloma Dinamita",
		"location": "Sala 3 (Acción), en el suelo junto al pasillo lateral; la barandilla aún no existe.",
		"description": "Especialista en alejarse caminando de explosiones sin mirar atrás. Según el cartel, realizó todas sus escenas de riesgo sin dobles ni migas de pan.",
		"model_scene": FIGURE_09, "preview_scale": Vector3.ONE * 1.15, "preview_offset": Vector3(0, 0.16, 0),
		"found": false, "viewed": false,
	},
	{
		"id": "dama_de_la_linterna", "number": 10, "title": "La Dama de la Linterna",
		"location": "Pendiente: vitrina dañada de la Antigua Sala Palace, aún no construida.",
		"description": "Una acomodadora sostiene una pequeña luz frente a una fila de butacas vacías. La pintura está mucho más cuidada que en las demás figuras. En la base hay dos iniciales grabadas a mano: E. R.",
		"model_scene": FIGURE_10, "preview_scale": Vector3.ONE * 1.15, "preview_offset": Vector3(0, 0.16, 0),
		"found": false, "viewed": false,
	},
	{
		"id": "arcade_reel_rescue_normal_poster",
		"number": 11,
		"title": "Más allá del horizonte",
		"location": "Recreativa del pasillo derecho — Rescata el carrete (Normal).",
		"description": "Cartel obtenido superando el juego «Rescata el carrete» en Normal.",
		"film_synopsis": "Un aventurero sigue un mapa entre montañas y ruinas para descubrir qué se esconde más allá del horizonte.",
		"display_type": "poster",
		"poster_texture": SALA_1_POSTER,
		"found": false,
		"viewed": false,
	},
	{
		"id": "arcade_reel_rescue_hard_poster",
		"number": 12,
		"title": "Abril entre nosotros",
		"location": "Recreativa del pasillo derecho — Rescata el carrete (Difícil).",
		"description": "Cartel obtenido superando el juego «Rescata el carrete» en Difícil.",
		"film_synopsis": "Un ramo de flores desmesurado convierte un encuentro bajo la lluvia en una historia de amor llena de pequeños equívocos.",
		"display_type": "poster",
		"poster_texture": SALA_2_POSTER,
		"found": false,
		"viewed": false,
	},
	# Segunda recreativa: conserva los IDs y huecos persistentes 13 y 14.
	{
		"id": "arcade_second_game_normal_poster",
		"number": 13,
		"title": "Última salida",
		"location": "Recreativa del pasillo izquierdo — El último acomodador (Normal).",
		"description": "Cartel obtenido superando el juego «El último acomodador» en Normal.",
		"film_synopsis": "Entre explosiones y una persecución por carretera, un hombre busca la última salida antes de quedar atrapado en el túnel.",
		"display_type": "poster",
		"poster_texture": SALA_3_POSTER,
		"found": false,
		"viewed": false,
	},
	{
		"id": "arcade_second_game_hard_poster",
		"number": 14,
		"title": "La puerta del fondo",
		"location": "Recreativa del pasillo izquierdo — El último acomodador (Difícil).",
		"description": "Cartel obtenido superando el juego «El último acomodador» en Difícil.",
		"film_synopsis": "Una puerta que ayer no estaba al fondo del pasillo aparece de pronto en casa; tras ella aguarda un misterio cada vez más inquietante.",
		"display_type": "poster",
		"poster_texture": SALA_4_POSTER,
		"found": false,
		"viewed": false,
	},
]


static func get_definitions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for definition in DEFINITIONS:
		result.append(definition.duplicate(true))
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.number) < int(b.number))
	return result


static func get_definition_by_number(number: int) -> Dictionary:
	for definition in DEFINITIONS:
		if int(definition.number) == number:
			return definition.duplicate(true)
	return {}
