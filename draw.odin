package main

import "core:fmt"
import "core:math"
import "core:math/rand"
import lg "core:math/linalg"
import rl "vendor:raylib"
import nvg "nanovg"
import nvg_gl "nanovg/gl"

purple_grey := rl.Color{35, 34, 43, 255}

draw_edge :: proc(edge: Edge) {
	if edge.intersect {
		draw_line(vg,edge.points[0].pos, edge.points[1].pos, { 230, 41, 55, 70})
	} else {
		draw_line(vg,edge.points[0].pos, edge.points[1].pos, rl.BLUE)
	}
}

draw_edges :: proc(edges: Edges) {
	for edge in edges {
		draw_edge(edge)
	}
}

draw_points :: proc(points: Points) {
	for point, i in points {

		// use this for nano vg GetWorldToScreen2D
		draw_circle(vg, point.pos, cam.zoom * (point.radius + point.outline_thickness), purple_grey)
		if point.selected {
			draw_circle(vg, point.pos, cam.zoom * point.radius, rl.SKYBLUE )
		}else{
			draw_circle(vg, point.pos, cam.zoom * point.radius, rl.BLUE)
			//nvg.Text(vg,rl.GetWorldToScreen2D(point.pos,cam).x,rl.GetWorldToScreen2D(point.pos,cam).y,fmt.aprintf("  %i , index %i",point.connections,i))
		}
		//rl.DrawText(rl.TextFormat("%i",point.connections),i32(point.pos.x) +  6,i32(point.pos.y) + 6,10,rl.WHITE)
	}
}

draw_circle :: proc(vg: ^nvg.Context, pos: rl.Vector2, radius: f32, color: rl.Color) {
	color: nvg.Color = {f32(color.r),f32(color.g),f32(color.b),f32(color.a)} / 255
	color.a *= game_alpha
	pos := rl.GetWorldToScreen2D(pos, cam)

	nvg.BeginPath(vg)
	nvg.Circle(vg, pos.x, pos.y, radius)
	nvg.StrokeWidth(vg, radius)
	nvg.StrokeColor(vg, color)
	nvg.FillColor(vg, color)
	nvg.Fill(vg)
	nvg.ClosePath(vg)
	nvg.Stroke(vg)

}

draw_line :: proc(vg : ^nvg.Context,startPos, endPos: rl.Vector2, color: rl.Color){
	color: nvg.Color = {f32(color.r),f32(color.g),f32(color.b),f32(color.a)} / 255
	color.a *= game_alpha
	startPos := rl.GetWorldToScreen2D(startPos, cam)
	endPos := rl.GetWorldToScreen2D(endPos, cam)


    nvg.BeginPath(vg)

    nvg.MoveTo(vg, startPos.x, startPos.y)
    nvg.LineTo(vg, endPos.x, endPos.y)

    nvg.ClosePath(vg)

    nvg.StrokeWidth(vg, 4.0);
    nvg.StrokeColor(vg, color);
	nvg.FillColor(vg, color)
    nvg.Stroke(vg)
}