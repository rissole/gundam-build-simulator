class_name PoseCodec
extends RefCounted
## JSON-safe vectors and rigid poses, with the validators every snapshot uses.
static func vector(value: Vector3) -> Array:
	return [value.x,value.y,value.z]

static func pose(value: Transform3D) -> Array:
	return vector(value.basis.x)+vector(value.basis.y)+vector(value.basis.z)+vector(value.origin)

static func to_vector(value: Array) -> Vector3:
	return Vector3(value[0],value[1],value[2])

static func to_pose(value: Array) -> Transform3D:
	return Transform3D(Basis(Vector3(value[0],value[1],value[2]),Vector3(value[3],value[4],value[5]),Vector3(value[6],value[7],value[8])),Vector3(value[9],value[10],value[11]))

static func number(value: Variant, limit: float = 256.0) -> bool:
	return (value is int or value is float) and is_finite(value) and absf(value) <= limit

static func valid_vector(value: Variant, count: int = 3) -> bool:
	return value is Array and value.size() == count and value.all(func(n):return number(n))

static func valid_pose(value: Variant) -> bool:
	if not valid_vector(value,12):return false
	var b = to_pose(value).basis
	return absf(b.determinant()-1.0) < 0.002 and absf(b.x.length_squared()-1.0) < 0.002 and absf(b.y.length_squared()-1.0) < 0.002 and absf(b.z.length_squared()-1.0) < 0.002 and absf(b.x.dot(b.y)) < 0.002 and absf(b.x.dot(b.z)) < 0.002 and absf(b.y.dot(b.z)) < 0.002

static func same_keys(value: Variant, expected: Array) -> bool:
	return value is Dictionary and value.size() == expected.size() and expected.all(func(key):return value.has(key))
