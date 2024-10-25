extends CharacterBody2D

const SPEED = 150.0  # Velocidad horizontal del personaje
const JUMP_VELOCITY = -550.0  # Velocidad del salto (negativa porque va hacia arriba)
const STAND_TO_IDLE_DELAY = 0.5  # Tiempo antes de pasar de "stand" a "idle"
const DUCK_DURATION = 0.2  # Duración de la animación "duck" al aterrizar después de un salto o caída

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D  # Referencia al sprite animado del personaje

# Variables de estado
var stand_timer = 0.0  # Temporizador para cambiar de "stand" a "idle"
var duck_timer = 0.0  # Temporizador para controlar la duración de la animación "duck"
var was_in_air = false  # Indica si el personaje estaba en el aire (por salto o caída)
var is_ducking = false  # Indica si el personaje está actualmente agachado
var landed_from_jump = false  # Indica si el personaje acaba de aterrizar de un salto o caída

# Función principal del ciclo de físicas que se ejecuta cada frame
func _physics_process(delta):
	handle_gravity(delta)  # Aplicar la gravedad si no está en el suelo
	handle_movement(delta)  # Controlar el movimiento horizontal
	handle_jump()  # Verificar si el personaje salta
	handle_manual_duck()  # Manejar el agachado manual con la tecla abajo
	handle_landing(delta)  # Verificar y manejar el aterrizaje después de un salto o caída
	move_and_slide()  # Mover el personaje y aplicar la física de colisiones

# Aplica la gravedad cuando el personaje está en el aire
func handle_gravity(delta):
	if not is_on_floor():
		velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity") * delta
		if not was_in_air:
			was_in_air = true  # Marca que el personaje está en el aire
			sprite.play("Jump")  # Cambia la animación a "Jump" al estar en el aire

# Controla el movimiento horizontal del personaje, según la dirección y si está agachado o acaba de aterrizar
func handle_movement(delta):
	var direction = Input.get_axis("ui_left", "ui_right")  # Obtener la dirección de entrada (izquierda/derecha)
	
	if direction != 0 and not is_ducking and not landed_from_jump:
		# Mover el personaje en la dirección ingresada si no está agachado o aterrizando
		velocity.x = direction * SPEED
		sprite.flip_h = direction < 0  # Voltear el sprite si se mueve a la izquierda
		if is_on_floor() and not is_ducking:
			sprite.play("Run")  # Reproducir la animación de correr
		reset_timers()  # Reiniciar los temporizadores cuando se mueve
	else:
		# Detener el movimiento horizontal gradualmente
		velocity.x = move_toward(velocity.x, 0, SPEED * delta)
		if is_on_floor() and not is_ducking and not landed_from_jump:
			handle_idle_transition(delta)  # Controlar la transición a "idle" si no se mueve

# Verifica si el personaje debe saltar
func handle_jump():
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		sprite.play("Jump")
		was_in_air = true  # Marcar que el personaje ha saltado
		is_ducking = false

# Maneja el agachado manual con la tecla hacia abajo
func handle_manual_duck():
	if Input.is_action_pressed("ui_down") and is_on_floor():
		is_ducking = true
		sprite.play("Crouch")
	else:
		is_ducking = false

# Controla el aterrizaje después de un salto o caída
func handle_landing(delta):
	if was_in_air and is_on_floor():
		was_in_air = false
		landed_from_jump = true
		duck_timer = DUCK_DURATION
		sprite.play("Crouch")  # Reproduce la animación de "Crouch" al aterrizar

	if landed_from_jump:
		duck_timer -= delta
		if duck_timer <= 0:
			landed_from_jump = false  # Fin de la animación de aterrizaje
			sprite.play("Idle")

# Controla la transición de "stand" a "idle" si el personaje está quieto
func handle_idle_transition(delta):
	stand_timer += delta
	if stand_timer >= STAND_TO_IDLE_DELAY:
		sprite.play("Idle")  # Reproduce la animación "Idle"

# Reinicia todos los temporizadores y estados
func reset_timers():
	stand_timer = 0.0
	duck_timer = 0.0
	landed_from_jump = false
	was_in_air = false
	is_ducking = false
