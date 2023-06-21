package main

import "core:fmt"
import "core:math"
import "core:math/rand"
import lg "core:math/linalg"
import rl "vendor:raylib"
import tri "triangulation"
//make sure its even

//TODO use 
generate_points :: proc(radius: f32, count: int, points: ^Points) {
	temp: Temp
	temp.Max = count
	temp.Radius = radius
	initializeGrid(&temp)
	update(&temp)

	for point in temp.active {

		append(points, Point{{point.x * 12.2, point.y * 12.2}, 3, 2, 0, false})
	}
}

shuffle :: proc(points : ^Points, edges : ^Edges){
	for point, i in points{

			if bool(rand.int_max(1)-1){
	
				x := rand.choice(points[:])
				index := 0
				for p,  i in points{
					if x == p{
						index = i
					}
				}
	
				point, points[index]  = x, point
			}
	}
	intersections:= check_intersections(edges)
}

generate_edges :: proc(edges: ^Edges, points: ^Points) {
	pointss := make([dynamic]tri.Point, len(points))
	equiv := make(map[tri.Point]^Point, len(points))

	for point , i in points {
		pointss[i] = tri.Point{point.pos.x, point.pos.y}
		equiv[tri.Point{point.pos.x, point.pos.y}] = &point
	}

	triangles := tri.DelaunayTriangulation(pointss)

	for triangle in triangles {
		trueEdges := tri.triangleEdges(triangle)

		for edge in trueEdges {
			trueEdge : Edge
			num := points[0]

			if tri.isEdgeShared(edge, triangles) {
				trueEdge.shared = true
			}

			trueEdge.points.x = equiv[edge.x]
			trueEdge.points.y = equiv[edge.y]

			append(edges, trueEdge)
		}
	}
}

generate :: proc(max_points : int, points : ^Points, edges : ^Edges){
	edges^ = {}
	points^ = {}

	generate_points(7, max_points, points)
	//points = slice.to_dynamic(points[:max_points])
	not_good := false
	generate_edges(edges, points)
	count_connections(points, edges^)
	for point in points^{
		if point.connections == 0{
			not_good = true
		}
	}
	if not_good{
		generate(max_points, points, edges)
	}
	edges^ = remove_duplicates(edges^)
	rand_delete_edge(points, edges)
	shuffle(points,edges)

	if check_intersections(edges) == 0{
		generate(max_points, points, edges)
	}

	count_connections(points, edges^)
}