package main


import "core:fmt"
import "core:math"
import "core:math/rand"
import lg "core:math/linalg"
import rl "vendor:raylib"
import nvg "nanovg"
import nvg_gl "nanovg/gl"
import gl "vendor:OpenGL"
import glfw "vendor:glfw"

Points :: [dynamic]Point
Edges :: [dynamic]Edge

screenWidth: i32 = 1920
screenHeight: i32 = 1080

cam: rl.Camera2D
vg: ^nvg.Context


ColorTheme :: struct {
	backround: rl.Color,
	Points:    rl.Color,
	Text:      rl.Color,
}

vignette := #load("resources/shaders/vignette.frag")
contour := #load("resources/shaders/contour.frag")

menu := true
gaming := false
game_started := false

max_game_alpha: f32 = 0.
game_alpha := max_game_alpha

max_menu_alpha: f32 = 1.
menu_alpha := max_menu_alpha


max_end_alpha: f32 = 0.
end_alpha := max_end_alpha

setup :: proc() {
	//rl.SetTargetFPS(60)
	rl.SetConfigFlags(
		{rl.ConfigFlag.WINDOW_RESIZABLE, rl.ConfigFlag.MSAA_4X_HINT}, //rl.ConfigFlag.VSYNC_HINT rl.ConfigFlag.MSAA_4X_HINT,
	)
	rl.MaximizeWindow()
	rl.SetTraceLogLevel(.DEBUG) //.DEBUG


	rl.InitWindow(screenWidth, screenHeight, "unknott")
	gl.load_up_to(4, 5, glfw.gl_set_proc_address)
	vg = nvg_gl.Create({.ANTI_ALIAS, .STENCIL_STROKES, .DEBUG})
	nvg.CreateFontMem(
		vg,
		"bold_prompt",
		#load("resources/fonts/Rubik-VariableFont_wght.ttf"),
		true,
	)
	nvg.CreateFontMem(vg, "bold_Regular", #load("resources/fonts/Prompt-Regular.ttf"), true)
	nvg.CreateFontMem(vg, "TITLE", #load("resources/fonts/MoiraiOne-Regular.ttf"), true)
	cam.zoom = 1.6
}

moves: int
completed := 0

main :: proc() {

	setup()
	defer rl.CloseWindow()
	defer nvg_gl.Destroy(vg)

	points: Points
	edges: Edges

	//cam.target =
	//	findMiddlePoint(points).pos - {f32(screenWidth) / 2, f32(screenHeight) / 2} / cam.zoom

	max_points := completed

	Max_countdownSeconds: f32 = 120 //120
	countdownSeconds: f32 = Max_countdownSeconds // Two minutes


	target := rl.LoadRenderTexture(screenWidth, screenHeight)
	PatternShader := rl.LoadShaderFromMemory(nil, cstring(&contour[0]))
	vignetteShader := rl.LoadShaderFromMemory(nil, cstring(&vignette[0]))

	// Set shader uniform values
	vignetteI: f32 = 0.55
	vignetteI_loc := rl.GetShaderLocation(vignetteShader, "vignetteIntensity")

	blackness: f32 = 1.
	blackn_loc := rl.GetShaderLocation(vignetteShader, "blackness")

	screen: rl.Vector2 = {f32(screenWidth), f32(screenHeight)}
	V_screen_loc := rl.GetShaderLocation(vignetteShader, "iResolution")
	P_screen_loc := rl.GetShaderLocation(PatternShader, "iResolution")

	timer: f32
	iTime_loc := rl.GetShaderLocation(PatternShader, "iTime")

	offset: f32 = 1. //0.2 best looking, lerpt to this when playing, if main menu make it 1.
	offset_loc := rl.GetShaderLocation(PatternShader, "Offset")

	{
		rl.SetShaderValue(
			vignetteShader,
			rl.ShaderLocationIndex(vignetteI_loc),
			&vignetteI,
			.FLOAT,
		)

		rl.SetShaderValue(vignetteShader, rl.ShaderLocationIndex(blackn_loc), &blackness, .FLOAT)
		rl.SetShaderValue(vignetteShader, rl.ShaderLocationIndex(V_screen_loc), &screen, .VEC2)
		rl.SetShaderValue(PatternShader, rl.ShaderLocationIndex(P_screen_loc), &screen, .VEC2)
		rl.SetShaderValue(PatternShader, rl.ShaderLocationIndex(iTime_loc), &timer, .FLOAT)
		rl.SetShaderValue(PatternShader, rl.ShaderLocationIndex(offset_loc), &offset, .FLOAT)

	}

	cam_anim := false
	max_cam_target := cam.target

	max_offset: f32 = 1.0
	max_cam_zoom: f32 = 1.0

	timer2: f32
	puzzle_movement := 0

	game_loop: for !rl.WindowShouldClose() {
		deltaTime := rl.GetFrameTime()
		timer2 += deltaTime
		if gaming {
			timer += deltaTime
		}
		max_points = min(max(completed / 3, 2), 20)
		intersections := check_intersections(&edges)
		@(static)
		end: bool //TODO when end, show moves time and completed, make it exit on click and have a prompt down below telling you to do so
		if !end {
			if countdownSeconds <= 0 {
				end = true
			} else {
				end = false
				countdownSeconds -= deltaTime
			}
		}

		if lg.distance(max_cam_target, cam.target) < 0.01 {
			cam_anim = false
		} else if lg.distance(max_cam_target, cam.target) > 1000.01 {
			cam_anim = true
		}
		if cam_anim {
			cam.target += (max_cam_target - cam.target) * 1. * deltaTime
		}

		@(static)
		won: bool
		won = intersections == 0
		cam.zoom += (max_cam_zoom - cam.zoom) * 1. * deltaTime
		offset += (max_offset - offset) * deltaTime
		blackness += ((1.1 - (countdownSeconds / 12)) - blackness) * 10. * deltaTime
		game_alpha += (max_game_alpha - game_alpha) * 10. * deltaTime
		menu_alpha += (max_menu_alpha - menu_alpha) * 10. * deltaTime
		end_alpha += (max_end_alpha - end_alpha) * 10. * deltaTime
		rl.SetShaderValue(
			vignetteShader,
			rl.ShaderLocationIndex(vignetteI_loc),
			&vignetteI,
			.FLOAT,
		)

		if rl.IsMouseButtonPressed(.LEFT) {
			menu = false
			if end {
				generate(max_points, &points, &edges)
				menu = true
				end = false
				timer = 120 //120
				countdownSeconds = timer
				moves = 0
				completed = 0
			}
		}

		if !menu {
			max_offset = 0.2
			max_cam_zoom = 1.6
			max_game_alpha = 1.
			max_menu_alpha = 0.
		} else {
			max_offset = 1.0
			max_cam_zoom = 1.0
			max_game_alpha = 0.
			max_menu_alpha = 1.
		}

		rl.SetShaderValue(vignetteShader, rl.ShaderLocationIndex(blackn_loc), &blackness, .FLOAT)
		rl.SetShaderValue(PatternShader, rl.ShaderLocationIndex(iTime_loc), &timer2, .FLOAT)
		rl.SetShaderValue(PatternShader, rl.ShaderLocationIndex(offset_loc), &offset, .FLOAT)


		if !end || !menu{
			closest_p := closest_point(
				&points,
				rl.GetScreenToWorld2D(rl.GetMousePosition(), cam),
				200,
			)

			@(static)
			selected_p: ^Point
			@(static)
			start := true

			for point in &points {
				point.radius = 3
			}

			if closest_p != nil {
				closest_p.radius = 3.5
			}
			if rl.IsMouseButtonDown(.LEFT) {

				if start {
					selected_p = closest_p
				}

				if selected_p != nil {
					selected_p.pos = rl.GetScreenToWorld2D(rl.GetMousePosition(), cam)
					selected_p.selected = true
					selected_p.radius = 4
					if start {
						moves += 1
						puzzle_movement += 1
					}
				} else {
					cam.target -= rl.GetMouseDelta() / cam.zoom
					if lg.distance(max_cam_target, cam.target) < 9.1 {
						cam_anim = false
					}
				}
				start = false
			} else {

				if closest_p != nil {
					closest_p.selected = false
				}

				if won {
					completed += 1
					countdownSeconds += f32(max_points)
					countdownSeconds -= f32(puzzle_movement)
					generate(max_points, &points, &edges)
					if check_intersections(&edges) == 0 {
						generate(max_points, &points, &edges)
						fmt.println(check_intersections(&edges))
					}
					puzzle_movement = 0
					cam_anim = true
					max_cam_target =
						findMiddlePoint(points).pos -
						{f32(screenWidth) / 2, f32(screenHeight) / 2} / cam.zoom
					won = false
				}

				start = true
			}

		}

		nvg.BeginPath(vg)

		rl.BeginDrawing();{

			nvg.BeginFrame(vg, f32(screenWidth), f32(screenHeight), 1.0)
			rl.ClearBackground(purple_grey)
			when true {
				rl.BeginBlendMode(.ALPHA)
				rl.BeginShaderMode(PatternShader)
				rl.DrawTextureRec(
					target.texture,
					{0, 0, f32(screenWidth), f32(-screenHeight)},
					{},
					{},
				)
			}

			rl.BeginMode2D(cam);{
				draw_edges(edges)
				draw_points(points)
				rl.EndMode2D()
			}

			/* //for the tutorial levels
			nvg.BeginPath(vg)
			nvg.Circle(vg, pos.x, pos.y, (17 - math.sin(timer * 2) * 3))
			nvg.StrokeWidth(vg, -math.cos(timer * 2) * 2)
			color := rl.SKYBLUE
			colorr: nvg.Color = {f32(color.r), f32(color.g), f32(color.b), f32(color.a)} / 255
			nvg.StrokeColor(vg, colorr)
			nvg.Stroke(vg)
			*/

			nvg.EndFrame(vg)
			nvg.Restore(vg)

			rl.BeginShaderMode(vignetteShader)
			rl.DrawTextureRec(
				target.texture,
				{0, 0, f32(screenWidth), f32(-screenHeight)},
				{0, 0},
				rl.WHITE,
			)
			rl.EndShaderMode()
			rl.EndBlendMode()

			if end {
				for points in &points{
					points.selected = false
				}


				max_end_alpha = 1.

				nvg.FontFace(vg, "bold_prompt")
				nvg.FontSize(vg, 50.0)
				nvg.TextAlign(vg, .CENTER, .MIDDLE)
				end_color := nvg.RGBA(rl.WHITE.r, rl.WHITE.g, rl.WHITE.b, 255)
				end_color.a = end_alpha
				nvg.FillColor(vg, end_color)
				nvg.Text(
					vg,
					f32(screenWidth) / 2,
					f32(screenHeight) / 2,
					fmt.aprintf("completed : %i ", completed),
				)
				nvg.Text(
					vg,
					f32(screenWidth) / 2,
					(f32(screenHeight) / 2) + 20 + 50.,
					fmt.aprintf("moves : %i ", moves),
				)
			}

			//draw UI
			{
				nvg.BeginFrame(vg, f32(screenWidth), f32(screenHeight), 1.0)
				nvg.FontSize(vg, 30.0)
				nvg.FontFace(vg, "bold_prompt")
				nvg.TextAlign(vg, .LEFT, .BOTTOM)

				nvg.FillColor(vg, {1., 1., 1., game_alpha})
				nvg.Text(
					vg,
					10,
					f32(screenHeight),
					fmt.aprintf(
						"%02i:%02i",
						int(countdownSeconds / 60),
						int(countdownSeconds) % 60,
					),
				)

				nvg.GlobalCompositeBlendFuncSeparate(
					vg,
					.ONE_MINUS_DST_COLOR,
					.ONE_MINUS_SRC_COLOR,
					.ONE_MINUS_DST_ALPHA,
					.ONE_MINUS_SRC_ALPHA,
				)

				nvg.TextAlign(vg, .CENTER, .MIDDLE)
				nvg.Text(vg, f32(screenWidth) / 2, 30, fmt.aprintf("%i", int(completed)))
				nvg.BeginPath(vg)
				nvg.RoundedRect(vg, (f32(screenWidth) / 2) - 100 / 2, 30 - 30 / 2, 100, 30, 10)
				nvg.StrokeWidth(vg, 0.9)
				nvg.StrokeColor(vg, {1., 1., 1., game_alpha})
				nvg.ClosePath(vg)
				nvg.Stroke(vg)

				nvg.FontSize(vg, 50.0)
				nvg.TextAlign(vg, .CENTER, .MIDDLE)
				menu_color: nvg.Color = {1., 1., 1., 1.} * math.sin(timer2)
				menu_color.a *= menu_alpha
				nvg.FillColor(vg, menu_color)
				nvg.Text(
					vg,
					f32(screenWidth) / 2,
					f32(screenHeight) - (f32(screenHeight) / 3.5),
					"click to start",
				)

				nvg.FontFace(vg, "TITLE")
				nvg.FontSize(vg, 250.0)
				nvg.TextAlign(vg, .CENTER, .MIDDLE)
				title_color := nvg.RGBA(rl.SKYBLUE.r, rl.SKYBLUE.g, rl.SKYBLUE.b, 255)
				title_color.a = menu_alpha
				nvg.FillColor(vg, title_color)
				nvg.Text(vg, f32(screenWidth) / 2, 250 / 1., "disentangle")


			}
			nvg.EndFrame(vg)
			nvg.Restore(vg)

			rl.EndDrawing()
		}

		for edge in &edges {
			edge.intersect = false
		}

		if rl.IsWindowResized() {
			screenWidth = rl.GetScreenWidth()
			screenHeight = rl.GetScreenHeight()
			cam.target.x -= 20
			screen = {f32(screenWidth), f32(screenHeight)}
			rl.SetShaderValue(
				vignetteShader,
				auto_cast rl.GetShaderLocation(vignetteShader, "iResolution"),
				&screen,
				.VEC2,
			)

			rl.SetShaderValue(
				PatternShader,
				auto_cast rl.GetShaderLocation(PatternShader, "iResolution"),
				&screen,
				.VEC2,
			)
		}
	}
}
