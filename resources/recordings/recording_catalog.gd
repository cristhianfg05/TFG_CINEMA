class_name RecordingCatalog
extends RefCounted

# 15 and 18 are intentionally undefined until their text and triggers arrive.
# The archive exposes only discovered definitions, never the planned total.
const INTRO_LINES := [
	"Vamos, arriba. La sesión ha terminado y alguien tiene que recoger esto.",
	"Empieza por la primera fila. Recoge primero lo que puedas ver.",
	"Lo que se esconde debajo de las butacas siempre acaba apareciendo.",
	"Cuando tengas la bolsa llena tíralo todo en la papelera del fondo, no tiene pérdida.",
]

const DEFINITIONS: Array[Dictionary] = [
	{"id": "01", "lines": INTRO_LINES},
	{"id": "02", "lines": [
		"La primera sala está lista.",
		"No pierdas demasiado tiempo persiguiendo la perfección.",
		"Un cine puede abrir con un poco de polvo.",
		"Eso sí, activa la pantalla cuando la tengas limpia del todo.",
	]},
	{"id": "03", "lines": [
		"Mi despacho.",
		"Clara decía que pasaba más tiempo aquí que en casa.",
		"Yo le contestaba que el despacho estaba más cerca.",
		"En la mesa tienes mis antiguas herramientas. Puedes usarlas; yo ya no puedo.",
		"En la pared tienes las palancas que inician las películas.",
		"Recuerda: una película sienta mejor con una sala totalmente limpia.",
	]},
	{"id": "04", "lines": [
		"Las cuentas las llevaba Clara.",
		"Yo escribía los números y ella tachaba mis excusas...",
		"Cuando dejó de hacerlo, tardé tres meses en aceptar que el cine ya estaba cerrado.",
	]},
	{"id": "05", "lines": [
		"Sala dos.",
		"Clara la llamó romántica. Yo la llamé incendio decorativo.",
		"Los pétalos, los lazos y los corazones forman parte de la sala.",
		"Todo lo pegajoso probablemente no.",
	]},
	{"id": "06", "lines": [
		"Elena escondía mensajes dentro de las entradas usadas.",
		"Decía que nadie tira un papel sin mirarlo",
		"si cree que quizá está escrito para él.",
		"Encontré casi todos.",
	]},
	{"id": "07", "lines": [
		"Taquillas junto a la entrada. Palomitas al fondo.",
		"Cuando esto estaba lleno, me quejaba del ruido.",
		"Es curioso lo que uno empieza a echar de menos cuando desaparece.",
	]},
	{"id": "08", "lines": [
		"Cada noche miraba estas puertas esperando que entrara un cliente más.",
		"Al final las miraba esperando que nadie se diera cuenta de que estábamos vacíos.",
	]},
	{"id": "09", "lines": [
		"Una figura del Palace.",
		"Clara las escondía por las salas para que los niños las buscaran mientras esperaban.",
		"No le dije que yo cambiaba algunas de sitio.",
	]},
	{"id": "10", "lines": [
		"Cinco. La mitad del reparto.",
		"Intentamos venderlas para pagar una reparación del tejado.",
		"No pagaron el tejado, pero durante una semana",
		"todos los niños del barrio quisieron una.",
	]},
	{"id": "11", "lines": [
		"Clara llenó esta sala de monstruos.",
		"La noche de la inauguración, un niño salió llorando.",
		"Cinco minutos después volvió para preguntar cuándo repetiríamos la película.",
	]},
	{"id": "12", "lines": [
		"Clara quería que el público saliera de esta sala haciendo ruido.",
		"Explosiones, persecuciones y música demasiado alta. Funcionó.",
		"Durante un tiempo volvimos a escuchar gente en los pasillos.",
	]},
	{"id": "13", "lines": [
		"El médico me pidió que grabara las rutinas antes de olvidarlas.",
		"Pensé que hablaba de las luces, las puertas y el proyector.",
		"No se me ocurrió preguntarle qué pasaría",
		"cuando empezara a olvidar los nombres.",
	]},
	{"id": "14", "lines": [
		"Las salas vuelven a responder.",
		"Queda una más. No aparece en los planos",
		"porque pedí que levantaran una pared delante.",
		"En mi despacho está la maza. Podrás echarla abajo sin problema.",
	]},
	{"id": "16", "lines": [
		"Escribí esa carta tres veces.",
		"En cada versión cambié la última frase.",
		"Después la escondí y fingí que todavía estaba buscando las palabras correctas.",
		"Supongo que esconder algo es otra forma de decidir.",
	]},
	{"id": "17", "lines": [
		"Las diez.",
		"Entonces Clara ha ganado. Yo escondí la última en esta sala",
		"y ella nunca dejó de buscarla.",
		"Dile que…",
	]},
]


static func has_definition(recording_id: String) -> bool:
	return not get_definition(recording_id).is_empty()


static func get_definition(recording_id: String) -> Dictionary:
	for definition in DEFINITIONS:
		if String(definition.id) == recording_id:
			return definition.duplicate(true)
	return {}


static func narrator_for(recording_id: String, mateo_revealed: bool) -> String:
	return "Mateo" if int(recording_id) >= 13 and mateo_revealed else "Manager"
