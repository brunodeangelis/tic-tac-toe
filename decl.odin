package main

import rl "vendor:raylib"


Vec2 :: [2]f32 // to unify rl.Vector2 and linalg.Vector2f32

WINDOW_SIZE :: 800
BOARD_SIZE :: WINDOW_SIZE / 1.6
BOARD_DIM :: 3 // Assume a square grid.
CELL_SIZE :: BOARD_SIZE / BOARD_DIM
CELL_AMOUNT :: BOARD_DIM * BOARD_DIM
VICTORY_ANIM_DURATION :: 2
victory_anim_progress: f32 = 0

SHAPE_EXTENSION :: CELL_SIZE / 2.5
LINE_THICKNESS :: SHAPE_EXTENSION / 3

Cell_State :: enum {
    Empty,
    X,
    O,
}

Cell :: struct {
    rec:           rl.Rectangle,
    center:        Vec2,
    state:         Cell_State,
    anim_progress: f32,
    is_drawing:    bool,
}

Board_State :: enum {
    Unfinished = -1,
    Tie,
    X_Won,
    O_Won,
}

Board :: struct {
    rows:  [BOARD_DIM][BOARD_DIM]Cell,
    state: Board_State,
}

board: Board
// board := Board {
//     rows = {
//         {{state = .Empty}, {state = .Empty}, {state = .X}},
//         {{state = .Empty}, {state = .X}, {state = .O}},
//         {{state = .O}, {state = .X}, {state = .Empty}},
//     },
// }

strikethrough_positions: [3]Vec2
placing_sign: Cell_State = .X
wireframe: bool
fading_in: bool
blur_intensity: f32
screen_opacity: f32 = 1
noise_texture: rl.Texture2D
blur_intensity_loc, screen_opacity_loc: rl.ShaderLocationIndex

initial_camera := rl.Camera2D {
    target = {WINDOW_SIZE / 2, WINDOW_SIZE / 2},
    offset = {WINDOW_SIZE / 2, WINDOW_SIZE / 2},
    zoom   = 1,
}
camera := initial_camera

initial_x := (WINDOW_SIZE - BOARD_SIZE) / 2
initial_y := (WINDOW_SIZE - BOARD_SIZE) / 2
