extends RefCounted
## One local workshop save slot. Task 03 adds the store and load; these helpers
## are generic so no machine needs its own save code.

## Saved machine state must have exactly the fields today's capture has.
static func same_shape(saved: Variant, fresh: Variant) -> bool:
	if not saved is Dictionary or not fresh is Dictionary or saved.size() != fresh.size():return false
	return fresh.keys().all(func(key):return saved.has(key))

## JSON turns every number into a float. Restore ints wherever today's value is
## an int, recursively, so typed fields and comparisons keep working.
static func coerce(saved: Variant, fresh: Variant) -> Variant:
	if fresh is int and saved is float:return int(saved)
	if fresh is Dictionary and saved is Dictionary:
		var result = {}
		for key in saved:result[key] = coerce(saved[key],fresh[key]) if fresh.has(key) else saved[key]
		return result
	if fresh is Array and saved is Array and not fresh.is_empty():
		var result = []
		for index in range(saved.size()):result.append(coerce(saved[index],fresh[mini(index,fresh.size()-1)]))
		return result
	return saved
