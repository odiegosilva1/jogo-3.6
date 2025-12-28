extends Node3D

# Variáveis básicas
var player = null
var score = 0
var game_time = 0.0

func _ready():
	# Inicializações básicas
	randomize()  # Para números aleatórios
	
	# Encontra o player na cena (se já estiver colocado manualmente)
	_find_player()
	
	# Inicializa UI básica
	_setup_basic_ui()
	
	print("World inicializado!")

func _process(delta):
	# Atualiza tempo de jogo
	game_time += delta
	
	# Atualiza UI a cada frame
	_update_ui(delta)
	
	# Inputs de debug (opcional)
	_handle_debug_input()

func _find_player():
	# Procura o player na cena
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		print("Player encontrado: ", player.name)
	else:
		# Tenta encontrar por nome
		if has_node("Player"):
			player = $Player
			print("Player encontrado por nome")
		else:
			print("AVISO: Player não encontrado na cena!")

func _setup_basic_ui():
	# Verifica se já existe UI
	if not has_node("UI"):
		# Cria UI mínima se não existir
		var ui = Control.new()
		ui.name = "UI"
		add_child(ui)
		
		# Cria label de score
		var score_label = Label.new()
		score_label.name = "ScoreLabel"
		score_label.text = "Score: 0"
		score_label.position = Vector2(10, 10)
		ui.add_child(score_label)
		
		# Cria label de tempo
		var time_label = Label.new()
		time_label.name = "TimeLabel"
		time_label.text = "Time: 0"
		time_label.position = Vector2(10, 30)
		ui.add_child(time_label)
		
		print("UI básica criada")

func _update_ui(delta):
	# Atualiza labels da UI
	if has_node("UI/ScoreLabel"):
		$UI/ScoreLabel.text = "Score: " + str(score)
	
	if has_node("UI/TimeLabel"):
		var minutes = int(game_time) / 60
		var seconds = int(game_time) % 60
		$UI/TimeLabel.text = "Time: %02d:%02d" % [minutes, seconds]
	
	# Atualiza health do player se existir
	if player and has_node("UI/HealthLabel"):
		if player.has_method("get_health"):
			$UI/HealthLabel.text = "Health: " + str(player.get_health())
		elif player.has("CurrentHP"):
			$UI/HealthLabel.text = "Health: " + str(player.CurrentHP)

func _handle_debug_input():
	# Funções de debug (remova em versão final)
	if Input.is_action_just_pressed("debug_add_score"):
		add_score(10)
		print("Debug: +10 score (Total: ", score, ")")
	
	if Input.is_action_just_pressed("debug_kill_player") and player:
		if player.has_method("takeDemage"):
			player.takeDemage(100)
			print("Debug: Player morto")

# Funções públicas
func add_score(points: int):
	score += points
	print("Score: +", points, " (Total: ", score, ")")

func get_player():
	return player

func get_game_time():
	return game_time

func reset_game():
	# Recarrega a cena
	get_tree().reload_current_scene()

# Função chamada quando player morre
func on_player_died():
	print("Game Over!")
	
	# Mostra game over se tiver UI
	if has_node("UI"):
		var game_over_label = Label.new()
		game_over_label.name = "GameOverLabel"
		game_over_label.text = "GAME OVER\nScore: " + str(score) + "\nPress R to restart"
		game_over_label.position = Vector2(200, 200)
		game_over_label.size = Vector2(200, 100)
		game_over_label.align = Label.ALIGNMENT_CENTER
		$UI.add_child(game_over_label)
	
	# Configura input para restart
	set_process_input(true)

func _input(event):
	# Restart do jogo
	if event.is_action_pressed("restart"):
		reset_game()
