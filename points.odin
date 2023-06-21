package main

import "core:fmt"
import "core:math"
import lg "core:math/linalg"
import rl "vendor:raylib"
import "core:time"
import "core:math/rand"
import "core:slice"


// Constants
K      :: 300
Width  :: 800
Height :: 800

Temp :: struct{
	active  : [dynamic]rl.Vector2,
	cols    : int,
	rows    : int,
	grid    : [][]rl.Vector2,
	ordered : [dynamic]rl.Vector2,
	Radius : f32,
	Max : int,
}



initializeGrid :: proc(temp : ^Temp) {
    using temp
    // Calculate grid dimensions based on window size and point radius
    cols = int(math.floor(f32(Width) / (Radius / math.SQRT_TWO)))
    rows = int(math.floor(f32(Height) / (Radius / math.SQRT_TWO)))

    // Initialize the grid
    grid = make([][]rl.Vector2, cols)
    for i := 0; i < cols; i += 1 {
        grid[i] = make([]rl.Vector2, rows)
    }

    active = {}
    ordered = {}

    // Add the first point to the grid
    x, y := f32(0), f32(0)
    i, j := calculateGridIndices(temp, rl.Vector2{x, y})
    pos := rl.Vector2{x, y}
    grid[i][j] = pos
    append(&active, pos)
}


update :: proc(temp : ^Temp) {
	using temp
	for i in 0..=Max{
		if len(active) > 0 {
			randomlySelectPoint(temp)
		} else {
			break
		}
	}
}

count_connections :: proc(points : ^Points, edges : Edges){
	for point in points{
		point.connections = 0
	}
	
	for edge in edges{
		for point in points{
			if edge.points.x == &point || edge.points.y == &point{
				point.connections += 1
			}
		}
	}
}


randomlySelectPoint :: proc(	temp : ^Temp) {
	using temp
	randIndex := rand.int_max(len(active))
	pos := active[randIndex]
	found := false

	for j := 0; j < K; j+=1 {
        //fmt.println("hey1")
		sample := generateRandomSample(temp,pos)
        //fmt.println("hey2")
		col, row := calculateGridIndices(temp,sample)
        //fmt.println("hey3")
		if isValidSample(temp,sample, col, row) {
            //fmt.println("hey4")
            if hasValidNeighbors(temp,sample, col, row) {
                //fmt.println("hey5")

				addSampleToGridAndActive(temp,sample, col, row)
				addSampleToOrdered(temp,sample)


				found = true
				break
			}
		}
	}

	if !found {
		//removeInactivePoint(temp,randIndex)
	}
}

generateRandomSample :: proc(temp : ^Temp,pos : rl.Vector2) -> rl.Vector2 {
	using temp
	sample := rl.Vector2{rand.float32()*2-1, rand.float32()*2-1}
	m := rand.float32()*Radius + Radius
	sample *= m
	sample += pos
	return sample
}

calculateGridIndices :: proc(temp : ^Temp, sample : rl.Vector2) -> (int, int) {
    using temp
    col := int(math.floor(f64(sample.x / (Radius / math.SQRT_TWO))))
    row := int(math.floor(f64(sample.y / (Radius / math.SQRT_TWO))))
    // Ensure the indices are within valid range
    if col < 0 {
        col = 0
    } else if col >= cols {
        col = cols - 1
    }
    if row < 0 {
        row = 0
    } else if row >= rows {
        row = rows - 1
    }
    return col, row
}

isValidSample :: proc(temp : ^Temp, sample : rl.Vector2, col, row : int) -> bool {
    using temp
    // Check if the indices are within valid range
    if col < 0 || col >= cols || row < 0 || row >= rows {
        return false
    }
    return grid[col][row].x == 0 && grid[col][row].y == 0
}


hasValidNeighbors :: proc(temp : ^Temp, sample : rl.Vector2, col, row : int) -> bool {
    using temp
    for i := -1; i <= 1; i += 1 {
        for j := -1; j <= 1; j += 1 {
            // Check if the indices are within valid range
            if col+i >= 0 && col+i < cols && row+j >= 0 && row+j < rows {
                neighbor := grid[col+i][row+j]
                if neighbor.x != 0 && neighbor.y != 0 {
                    d := lg.distance(sample, neighbor)
                    if d < Radius {
                        return false
                    }
                }
            }
        }
    }
    return true
}

addSampleToGridAndActive :: proc(temp : ^Temp,sample : rl.Vector2, col, row : int) {
	using temp
	grid[col][row] = sample
	append(&active, sample)
}

addSampleToOrdered :: proc(temp : ^Temp,sample : rl.Vector2) {
	using temp
	append(&ordered, sample)
}

removeInactivePoint :: proc(temp : ^Temp,randIndex :  int) {
	using temp
	//active = slice.to_dynamic(active[:randIndex])
	append(&active, ..active[randIndex:])
}

findMiddlePoint :: proc(points : Points) -> Point {
    totalPoints := len(points)
    sumX :f32= 0.0
    sumY :f32= 0.0

    for point in points {
        sumX += point.pos.x
        sumY += point.pos.y
    }

    avgX := sumX / f32(totalPoints)
    avgY := sumY / f32(totalPoints)

    middlePoint := Point{{avgX, avgY}, 0, 0, 0, false}
    return middlePoint
}