extends Node
var collected = 0
var total = 5
signal all_collected
func collect():
	collected += 1
	if collected >= total:
		all_collected.emit()
