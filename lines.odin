package main

import "core:fmt"
import "core:math"
import "core:math/rand"
import lg "core:math/linalg"
import rl "vendor:raylib"
import "core:slice"

Point :: struct {
	pos:               rl.Vector2,
	radius:            f32,
	outline_thickness: f32,

	connections : int,
	selected : bool,
}

Edge :: struct {
	points:    [2]^Point,
	intersect: bool,
	shared : bool,
}



check_intersections :: proc(edges: ^Edges) -> int{
	intersections : int
	for edge1 in edges {
		for edge2 in edges {
			if edge1 == edge2{
				continue
			}
			if edge_intersect_check(&edge1, &edge2){
				intersections += 1
			}
		}
	}
	return intersections
}

edge_intersect_check :: proc(edge1: ^Edge, edge2: ^Edge) -> bool{
	if edge1.points[0] == edge2.points[0] ||
	   edge1.points[0] == edge2.points[1] ||
	   edge1.points[1] == edge2.points[0] ||
	   edge1.points[1] == edge2.points[1] {
		return false
	}

	is_intersect := CheckCollisionLines(
		edge1.points[0].pos,
		edge1.points[1].pos,
		edge2.points[0].pos,
		edge2.points[1].pos,
	)
	edge1.intersect = is_intersect || edge1.intersect
	edge2.intersect = is_intersect || edge2.intersect
	return is_intersect || edge2.intersect || is_intersect || edge2.intersect
}

closest_point :: proc(points: ^Points, pos: rl.Vector2, max_distance: f32) -> ^Point{
	closest_index: int = -1
	closest_distance: f32 = math.inf_f32(0)

	for i in 0 ..= len(points) - 1 {
		current_distance := distanceSquared(points[i].pos, pos)
		if current_distance < closest_distance {
			closest_distance = current_distance
			closest_index = i

			if closest_distance == 0 {
				break // Found an exact match, terminate early
			}
		}
	}
	return 	nil if closest_distance > max_distance else &points[closest_index]
}

distanceSquared :: proc(point1: rl.Vector2, point2: rl.Vector2) -> f32 {
	dx := point2.x - point1.x
	dy := point2.y - point1.y
	return dx * dx + dy * dy
}



rand_delete_edge :: proc(points : ^Points, edges : ^Edges){
    count := 0
    lenn := len(edges)
    for i in 0..<lenn{
        count_connections(points, edges^)
        edge := edges[i - count]
        choice := bool(rand.int_max(3))
        if !edge.shared && (edge.points.x.connections > 2 && edge.points.y.connections > 2) && edge.points.x.connections > 4 && edge.points.y.connections > 4 {

            if choice{
                unordered_remove(edges, i - count)
                count += 1
                edge.points.x.connections -= 1
                edge.points.y.connections -= 1
            }
        }
    }
}

CheckCollisionLines :: proc(start1, end1, start2, end2: rl.Vector2) -> bool {

	//Bounding box check
	if max(start1.x, end1.x) < min(start2.x, end2.x) ||
	   min(start1.x, end1.x) > max(start2.x, end2.x) ||
	   max(start1.y, end1.y) < min(start2.y, end2.y) ||
	   min(start1.y, end1.y) > max(start2.y, end2.y) {
		return false //Lines do not intersect
	}

	// Line equation representation
	m1 := (end1.y - start1.y) / (end1.x - start1.x)
	b1 := start1.y - m1 * start1.x

	m2 := (end2.y - start2.y) / (end2.x - start2.x)
	b2 := start2.y - m2 * start2.x

	//Line segment intersection conditions
	if (m1 == m2 && b1 == b2) || (m1 == m2) {

		return false //Lines are parallel or coincident, no intersection
	}

	//Intersection test
	x := (b2 - b1) / (m1 - m2)
	if x < min(start1.x, end1.x) ||
	   x < min(start2.x, end2.x) ||
	   x > max(start1.x, end1.x) ||
	   x > max(start2.x, end2.x) {
		return false //Intersection point lies outside the line segments
	}

	return true //Lines intersect
}

convert_to_pastel :: proc(color : rl.Color) -> rl.Color{

	r := u8((int(color.r) + 255) / 2)
	g := u8((int(color.g) + 255) / 2)
	b := u8((int(color.b)+ 255) / 2)

	return {r, g, b, color.a}

}

convert_to_neon :: proc(color : rl.Color) -> rl.Color{

	r := u8((int(color.r) * 2))
	g := u8((int(color.g) * 2))
	b := u8((int(color.b) * 2))

	return {r, g, b, color.a}

}
remove_duplicates :: proc(edges : Edges) -> Edges{
	occurred := make(map[Edge]bool)
	uniqueEdges : Edges

	for edge in edges {
		reversed_edge := edge
		reversed_edge.points = reversed_edge.points.yx //switch values around
		if !(edge in occurred) && !(reversed_edge in occurred){
			occurred[edge] = true
			append(&uniqueEdges, edge)
		}
	}

	return uniqueEdges
}