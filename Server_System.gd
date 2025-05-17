# server_system.gd
extends Node

const SERVER_CONFIG_DIR = "user://server_configs/"
const CUSTOM_CONTENT_DIR = "user://custom_content/"
const DISCLAIMER = "Разработчики не несут ответственности за содержимое пользовательских серверов!"

var available_servers = []
var favorite_servers = []
var server_browser_udp = PacketPeerUDP.new()
const BROADCAST_PORT = 9051

signal server_list_updated
signal server_created(status)

func _ready():
    _setup_directories()
    load_favorite_servers()
    start_server_discovery()

func _setup_directories():
    DirAccess.make_dir_recursive_absolute(SERVER_CONFIG_DIR)
    DirAccess.make_dir_recursive_absolute(CUSTOM_CONTENT_DIR + "maps/")
    DirAccess.make_dir_recursive_absolute(CUSTOM_CONTENT_DIR + "mods/")

func show_disclaimer():
    var alert = AcceptDialog.new()
    alert.title = "Уведомление"
    alert.dialog_text = DISCLAIMER
    get_tree().root.add_child(alert)
    alert.popup_centered()

# Серверная часть
func create_custom_server(config: Dictionary):
    show_disclaimer()
    
    # Проверка кастомного контента
    if config.use_custom_map and not validate_custom_content(config.map_path):
        emit_signal("server_created", false)
        return
    
    # Сохранение конфига
    save_server_config(config)
    
    # Запуск сервера
    var peer = ENetMultiplayerPeer.new()
    var error = peer.create_server(config.port, config.max_players)
    
    if error == OK:
        multiplayer.multiplayer_peer = peer
        start_broadcast_service(config)
        emit_signal("server_created", true)
    else:
        emit_signal("server_created", false)

func validate_custom_content(path: String):
    return FileAccess.file_exists(path)

func save_server_config(config: Dictionary):
    var file = FileAccess.open(SERVER_CONFIG_DIR + config.name + ".cfg", FileAccess.WRITE)
    file.store_string(JSON.stringify(config))
    file.close()

# Клиентская часть
func start_server_discovery():
    server_browser_udp.bind(BROADCAST_PORT)
    server_browser_udp.set_broadcast_enabled(true)
    
    var timer = Timer.new()
    timer.wait_time = 2.0
    timer.timeout.connect(update_server_list)
    add_child(timer)
    timer.start()

func update_server_list():
    # Широковещательный запрос
    server_browser_udp.put_packet("DISCOVER_SERVERS".to_utf8_buffer(), "255.255.255.255", BROADCAST_PORT)
    
    # Обработка ответов
    var new_servers = []
    while server_browser_udp.get_available_packet_count() > 0:
        var packet = server_browser_udp.get_packet()
        var server = JSON.parse_string(packet.get_string_from_utf8())
        if server: new_servers.append(server)
    
    # Обновление списка
    available_servers = new_servers
    available_servers.sort_custom(sort_servers)
    emit_signal("server_list_updated")

func sort_servers(a, b):
    return a.ping < b.ping && a.players > b.players

func load_favorite_servers():
    var config = ConfigFile.new()
    if config.load("user://favorites.cfg") == OK:
        for section in config.get_sections():
            favorite_servers.append(config.get_value(section, "server_data"))

func connect_to_server(ip: String, port: int):
    var peer = ENetMultiplayerPeer.new()
    var error = peer.create_client(ip, port)
    
    if error == OK:
        multiplayer.multiplayer_peer = peer
        return true
    return false

# Бродкаст сервис для сервера
func start_broadcast_service(config: Dictionary):
    var timer = Timer.new()
    timer.wait_time = 1.0
    timer.timeout.connect(broadcast_server_info.bind(config))
    add_child(timer)
    timer.start()

func broadcast_server_info(config: Dictionary):
    var info = {
        "name": config.name,
        "ip": _get_local_ip(),
        "port": config.port,
        "players": multiplayer.get_peers().size(),
        "max_players": config.max_players,
        "map": config.map,
        "mode": config.mode,
        "ping": 0
    }
    
    server_browser_udp.put_packet(JSON.stringify(info).to_utf8_buffer())

func _get_local_ip() -> String:
    for ip in IP.get_local_addresses():
        if ip.count(":") == 0 and !ip.begins_with("127."):
            return ip
    return ""
