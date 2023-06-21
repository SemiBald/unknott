package triangulation

import "core:math/rand"
import "core:slice"
import rl "vendor:raylib"


screenWidth  :: 1920
screenHeight :: 1080

Point :: [2]f32

Edge :: [2]Point


Triangle :: [3]Point

DelaunayTriangulation :: proc(points : [dynamic]Point) ->  [dynamic]Triangle {
	// Sort points by X coordinate
	slice.sort_by(points[:], proc(i, j : Point) -> bool{
		return (i.x < j.x)
	})
	
	superTriangle := createSuperTriangle(points)
	triangles := [dynamic]Triangle{superTriangle}

	for point in points {
		badTriangles := make([dynamic]Triangle, 0)

		for triangle in triangles {
			if pointInsideCircumcircle(point, triangle) {
				append(&badTriangles, triangle)
			}
		}

		polygon := make([dynamic]Edge, 0)
		for triangle in badTriangles {
			for edge in triangleEdges(triangle) {
				if isEdgeShared(edge, badTriangles) {
					append(&polygon, edge)
				}
			}
		}

		triangles = removeBadTriangles(triangles, badTriangles)

		for edge in polygon {
			triangle := Triangle{edge.x, edge.y, point}
			append(&triangles, triangle)
		}
	}

	triangles = removeSuperTriangle(triangles, superTriangle)

	return triangles
}

createSuperTriangle :: proc(points : [dynamic]Point) -> Triangle {
	minX, minY := points[0].x, points[0].y
	maxX, maxY := points[0].x, points[0].y

	for point in points {
		if point.x < minX {
			minX = point.x
		}
		if point.x > maxX {
			maxX = point.x
		}
		if point.y < minY {
			minY = point.y
		}
		if point.y > maxY {
			maxY = point.y
		}
	}

	delta := max(maxX-minX, maxY-minY)
	midX := (minX + maxX) / 2
	midY := (minY + maxY) / 2
	sideLength := 2 * delta
	superTriangle := Triangle{
		Point{midX, midY + sideLength},
		Point{midX - sideLength, midY - sideLength},
		Point{midX + sideLength, midY - sideLength},
	}

	return superTriangle
}

pointInsideCircumcircle :: proc(point : Point, triangle : Triangle) -> bool {
	ax, ay := triangle.x.x, triangle.x.y
	bx, by := triangle.y.x, triangle.y.y
	cx, cy := triangle.z.x, triangle.z.y
	d := 2 * (ax*(by-cy) + bx*(cy-ay) + cx*(ay-by))
	ux := ((ax*ax+ay*ay)*(by-cy) + (bx*bx+by*by)*(cy-ay) + (cx*cx+cy*cy)*(ay-by)) / d
	uy := ((ax*ax+ay*ay)*(cx-bx) + (bx*bx+by*by)*(ax-cx) + (cx*cx+cy*cy)*(bx-ax)) / d
	r := ((ax-ux)*(ax-ux) + (ay-uy)*(ay-uy))

	px, py := point.x, point.y
	distance := ((px-ux)*(px-ux) + (py-uy)*(py-uy))

	return distance <= r
}

isEdgeShared :: proc(edge :Edge, triangles : [dynamic]Triangle) -> bool {
	count := 0
	for triangle in triangles {
		if (edge.x == triangle.x || edge.x == triangle.y || edge.x == triangle.z) &&
			(edge.y == triangle.x || edge.y == triangle.y || edge.y == triangle.z) {
			count+=1
		}
	}
	return count == 1
}

triangleEdges :: proc (triangle : Triangle) -> [dynamic]Edge {
	a, b, c := triangle.x, triangle.y, triangle.z
	edges := [dynamic]Edge{{a, b}, {b, c}, {c, a}}
	return edges
}

removeBadTriangles :: proc(triangles, badTriangles : [dynamic]Triangle) -> [dynamic]Triangle {
	remainingTriangles := make([dynamic]Triangle, 0)
	for triangle in triangles {
		if !containsTriangle(badTriangles, triangle) {
			append(&remainingTriangles, triangle)
		}
	}
	return remainingTriangles
}

removeSuperTriangle :: proc(triangles : [dynamic]Triangle, superTriangle : Triangle) -> [dynamic]Triangle {
	remainingTriangles := make([dynamic]Triangle, 0)
	for triangle in triangles {
		if !containsPoint(superTriangle.x, triangle) &&
			!containsPoint(superTriangle.y, triangle) &&
			!containsPoint(superTriangle.z, triangle) {
			append(&remainingTriangles, triangle)
		}
	}
	return remainingTriangles
}

containsTriangle :: proc(triangles : [dynamic]Triangle, target : Triangle) -> bool {
	for triangle in triangles {
		if triangle == target {
			return true
		}
	}
	return false
}

containsPoint :: proc(point : Point, triangle : Triangle) -> bool {
	return point == triangle.x || point == triangle.y || point == triangle.z
}

countConnections :: proc(triangles : [dynamic]Triangle) -> map[Point]int {
	connections := make(map[Point]int)
	for triangle in triangles {
		connections[triangle.x]+=1
		connections[triangle.y]+=1
		connections[triangle.z]+=1
	}
	return connections
}

