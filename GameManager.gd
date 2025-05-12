extends Node

enum GameMode {FREE_ROAM, TEAM_DEATHMATCH}
var current_mode: GameMode
var teams = {
    "blue": [],
    "red": []
}

func setup_game(mode_name: String):
    match mode_name:
        "FreeRoam":
            current_mode = GameMode.FREE_ROAM
        "TeamDeathmatch":
            current_mode = GameMode.TEAM_DEATHMATCH

func register_player(player_id: int, team: String):
    if current_mode == GameMode.FREE_ROAM:
        return
    
    teams[team].append(player_id)
    # Синхронизация с клиентами
    rpc("update_teams", teams)

remote func update_teams(new_teams: Dictionary):
    teams = new_teams
