# BlockLibrary.gd
class_name BlockLibrary
extends Resource

var blocks := {}

func load_from_folder(path: String):
    var dir = DirAccess.open(path)
    if dir:
        dir.list_dir_begin()
        var file_name = dir.get_next()
        while file_name != "":
            if file_name.ends_with(".tres"):
                var block = load(path.path_join(file_name))
                blocks[block.id] = block
            file_name = dir.get_next()

func get_block(id: int) -> BlockResource:
    return blocks.get(id)

func get_all_blocks() -> Array:
    return blocks.values()

func get_default_block_id() -> int:
    return blocks.keys()[0] if not blocks.is_empty() else -1
