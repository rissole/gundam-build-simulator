extends "res://tests/chest_delivery_test.gd"
## Reuse the complete two-leg mechanical fixture before the chest branch.
func run() -> void:
	with_legs=true
	await super.run()
