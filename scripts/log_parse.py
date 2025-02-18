import re

def parse_log(log_file, print_output = True):

    patterns = {
        "attachment_received_pattern" : r"<(?P<timestamp>[^>]+)> \[Notice\] <(?P<event>[^>]+)> Player\[(?P<player>[^\]]+)\] Attachment\[(?P<attachment_full>[^,]+), (?P<attachment_name>[^,]+), (?P<attachment_id>\d+)\] Status\[(?P<status>[^\]]+)\] Port\[(?P<port>[^\]]+)\] Elapsed\[(?P<elapsed>[\d.]+)\]",
        "inventory_management_pattern" : r"<(?P<timestamp>[^>]+)> \[Notice\] <(?P<event>InventoryManagement)> New request\[(?P<request_id>\d+)\] Player\[(?P<player>[^\]]+)\] Type\[(?P<type>[^\]]+)\] SourceInventory\[(?P<source_inventory>[^:]+):(?P<source_container>[^:]+):(?P<source_index>\d+)\] TargetInventory\[(?P<target_inventory>[^\]]+)\] ItemClass\[(?P<item_class>[^\]]*)\] StoredEntity\[(?P<stored_entity>[^\]]+)\] LocallyDetached\[(?P<locally_detached>[^\]]+)\] LocalAttached\[(?P<local_attached>[^\]]*)\] PendingMoves\[(?P<pending_moves>[^\]]+)\] Caller\[(?P<caller>[^\]]+)\]",
        "qd_update_match" : r"<(?P<timestamp>[^>]+)> SCItemQuantumDrive::Update\(\) Warning: (?P<warning_message>.+)",
        "entity_trying_qt_match" : r"<(?P<timestamp>[^>]+)> -- Entity Trying To QT: (?P<entity_name>.+)",
        "jd_change_state_match" : r"<(?P<timestamp>[^>]+)> \[Notice\] <(?P<event>Jump Drive Changing State)> CSCItemJumpDrive::OnStateChanged \| (?P<ship>[^\|]+) \| (?P<auth_status>[^\|]+) \| (?P<location>[^\|]+) \| (?P<jump_drive>[^\|]+) \[(?P<jump_drive_id>\d+)\] \| State is now (?P<state>[^\[]+)",
        "create_hauling_objective_match" : r"<(?P<timestamp>[^>]+)> \[Notice\] <(?P<event>CreateHaulingObjectiveHandler)> (?P<objective_type>Pick|Dropoff) created - \[Cient\] sourcename: (?P<sourcename>[^,]+), missionId: (?P<mission_id>[0-9a-fA-F-]+), locationName: (?P<location_name>[^,]+) \[(?P<location>[^]]+)\], locationHash: (?P<location_hash>\d+), locationSuperGUID: (?P<location_super_guid>[^\s,]+), objectiveId: (?P<objective_id>[^\s,]+), objectiveTokenDebugName: (?P<objective_token_debug_name>[^ ]+)",
        "actor_death_match" : r"<(?P<timestamp>[^>]+)> \[Notice\] <(?P<event>Actor Death)> CActor::Kill: '(?P<victim>[^']+)' \[(?P<victim_id>\d+)\] in zone '(?P<zone>[^']+)' killed by '(?P<attacker>[^']+)' \[(?P<attacker_id>\d+)\] using '(?P<weapon>[^']+)' \[Class (?P<class>[^]]+)\] with damage type '(?P<damage_type>[^']+)' from direction x: (?P<x>[-\d.]+), y: (?P<y>[-\d.]+), z: (?P<z>[-\d.]+)",
        "corpse_match" : r"<(?P<timestamp>[^>]+)> \[Notice\] <(?P<event>Corpse)> Player '(?P<player>[^']+)' <(?P<client_type>[^>]+)>: IsCorpseEnabled: (?P<corpse_enabled>Yes|No), there is no local inventory.",
        "player_instance_info_match" : r"<(?P<timestamp>[^>]+)> \[Notice\] <(?P<event>Get player instance info)> Request instance info for player (?P<player_id>\d+)",
        "proximity_sensor_match" : r"<(?P<timestamp>[^>]+)> \[Notice\] <(?P<event>ProximitySensorMakingLocalHelper)> Proximity sensor \[(?P<sensor_name>[^-]+) - Class\((?P<sensor_class>[^\)]+)\) - Context\((?P<sensor_context>[^\)]+)\) - Socpak\((?P<sensor_socpak>[^\)]*)\)\] is creating a local helper for cross-zone detection\. Master zone is \[(?P<master_zone_name>[^-]+) - Class\((?P<master_zone_class>[^\)]+)\) - Context\((?P<master_zone_context>[^\)]+)\) - Socpak\((?P<master_zone_socpak>[^\)]*)\)\], helper is being made in zone \[(?P<helper_zone_name>[^-]+) - Class\((?P<helper_zone_class>[^\)]+)\) - Context\((?P<helper_zone_context>[^\)]+)\) - Socpak\((?P<helper_zone_socpak>[^\)]*)\)\]",
        "physics_start_match" : r"<(?P<timestamp>[^>]+)> PHYSICS INSTANCE STATS BEGIN (?P<instance_id>\d+)",
        "physics_entities_match" : r"<(?P<timestamp>[^>]+)>   entities:\s+(?P<entities>\d+) allocated:\s+(?P<allocated>\d+), reallocs :\s+(?P<reallocs>\d+), deletion queue :\s+(?P<deletion_queue>\d+)\(stalled :\s+(?P<stalled>\d+)\)",
        "physics_instances_match" : r"<(?P<timestamp>[^>]+)>   instances:\s+(?P<instances>\d+) size:\s+(?P<size>\d+) bytes type: (?P<type>\S+)",
        "physics_planet_cell_match" : r"<(?P<timestamp>[^>]+)>   planet cells:\s+(?P<planet_cells>\d+) \[\s*(?P<planet_cell_data>\d+)\] meshes:\s+(?P<meshes>\d+) \[\s*(?P<mesh_data>\d+)\] name: (?P<planet_name>\S+)",
        "physics_part_mem_match" : r"<(?P<timestamp>[^>]+)> total size of part container memory chunks: (?P<part_memory>\d+) bytes",
        "physics_part_instance_mem_match" : r"<(?P<timestamp>[^>]+)> total size of part container instance memory chunks: (?P<instance_memory>\d+) bytes",
        "physics_end_match" : r"<(?P<timestamp>[^>]+)> PHYSICS INSTANCE STATS END"
        }
    

    with open(log_file, "r", encoding="utf-8") as f:
        
        for line in f:
            for name, pattern in patterns.items():
                pattern = re.compile(pattern)
                pattern_match = pattern.search(line)
                if pattern_match:
                    if print_output:
                        print(f"{name} found")
                    else:
                        pass
            


if __name__ == "__main__":
    parse_log(r"C:\Users\jackd\Downloads\Game.log")