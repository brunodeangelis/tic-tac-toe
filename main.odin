/*
15/05/2024
Created by Bruno for CDTR's Kata challenge: https://www.codewars.com/kata/525caa5c1bf619d28c000335

If we were to set up a Tic-Tac-Toe game, we would want to know whether the board's current state is solved,
wouldn't we? Our goal is to create a function that will check that for us!

Assume that the board comes in the form of a 3x3 array, where the value is 0 if a spot is empty,
1 if it is an "X", or 2 if it is an "O", like so:

[[0, 0, 1],
 [0, 1, 2],
 [2, 1, 0]]

 We want our function to return:

-1 if the board is not yet finished AND no one has won yet (there are empty spots),
1  if "X" won,
2  if "O" won,
0  if it's a cat's game (i.e. a draw).

You may assume that the board passed in is valid in the context of a game of Tic-Tac-Toe.
*/

package main


import "core:fmt"
import "core:math"
import "core:math/ease"
import "core:math/linalg/glsl"

import rl "vendor:raylib"


WINDOW_SIZE :: 800
ROW_COUNT :: 3
COL_COUNT :: 3
BOARD_SIZE :: WINDOW_SIZE / 1.6
CELL_SIZE :: BOARD_SIZE / COL_COUNT

Cell_State :: enum {
    Empty,
    X,
    O,
}

Cell :: struct {
    rec:           rl.Rectangle,
    center:        rl.Vector2,
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
    rows:  [ROW_COUNT][COL_COUNT]Cell,
    state: Board_State,
}

// board := Board {
//     rows = {
//         {{state = .Empty}, {state = .Empty}, {state = .X}},
//         {{state = .Empty}, {state = .X}, {state = .O}},
//         {{state = .O}, {state = .X}, {state = .Empty}},
//     },
// }

board: Board
placing_sign := Cell_State.X

main :: proc() {
    rl.SetConfigFlags({.VSYNC_HINT, .MSAA_4X_HINT})

    rl.InitWindow(WINDOW_SIZE, WINDOW_SIZE, "Tic Tac Toe Kata")
    rl.SetTargetFPS(240)

    bg_img_bytes := #load("assets/bg.png")
    bg_texture := rl.LoadTextureFromImage(
        rl.LoadImageFromMemory(".png", raw_data(bg_img_bytes), i32(len(bg_img_bytes))),
    )

    initial_x := (WINDOW_SIZE - BOARD_SIZE) / 2
    initial_y := (WINDOW_SIZE - BOARD_SIZE) / 2

    for !rl.WindowShouldClose() {
        fps := rl.GetFPS()
        mouse_pos := rl.GetMousePosition()
        delta := rl.GetFrameTime()

        board.state = check_board(board)

        if rl.IsMouseButtonPressed(.RIGHT) {
            board.rows = {}
            placing_sign = Cell_State.X
        }

        {
            rl.BeginDrawing()
            rl.ClearBackground({30, 30, 30, 255})

            rl.DrawTexturePro(
                bg_texture,
                {0, 0, f32(bg_texture.width), f32(bg_texture.height)},
                {0, 0, WINDOW_SIZE, WINDOW_SIZE},
                {0, 0},
                0,
                rl.WHITE,
            )

            x := initial_x
            y := initial_y
            for &row in board.rows {
                for &cell in row {
                    cell.rec = rl.Rectangle{f32(x), f32(y), CELL_SIZE, CELL_SIZE}
                    cell.center = rl.Vector2{f32(x) + (CELL_SIZE / 2), f32(y) + (CELL_SIZE / 2)}

                    if cell.is_drawing {
                        cell.anim_progress += 1.75 * delta
                        if cell.anim_progress >= 1 {
                            cell.is_drawing = false
                        }
                    } else {
                        cell.anim_progress = 1
                    }

                    switch cell.state {
                    case .Empty:
                        if rl.CheckCollisionPointRec(mouse_pos, cell.rec) && board.state == .Unfinished {
                            if placing_sign == .X {
                                draw_x(cell.center, rl.DARKGRAY)
                            } else if placing_sign == .O {
                                draw_o(cell.center, rl.DARKGRAY)
                            }

                            if rl.IsMouseButtonPressed(.LEFT) {
                                cell.state = placing_sign
                                cell.is_drawing = true
                                cell.anim_progress = 0

                                placing_sign = .O if placing_sign == .X else .X
                            }
                        }

                    case .X:
                        draw_x(cell.center, rl.DARKGRAY)
                        draw_x(cell.center, rl.WHITE, cell.anim_progress)

                    case .O:
                        draw_o(cell.center, rl.DARKGRAY)
                        draw_o(cell.center, rl.WHITE, cell.anim_progress)
                    }

                    x += CELL_SIZE
                }
                y += CELL_SIZE
                x = initial_x
            }

            // Reset to draw board edges so batching doesn't break
            x = initial_x
            y = initial_y
            for row_idx in 0 ..< ROW_COUNT - 1 {
                for col_idx in 0 ..< COL_COUNT - 1 {
                    x += CELL_SIZE
                    rl.DrawLineEx({f32(x), f32(initial_y)}, {f32(x), f32(initial_y) + BOARD_SIZE}, 1, rl.WHITE)
                }
                y += CELL_SIZE
                x = initial_x
                rl.DrawLineEx({f32(x), f32(y)}, {f32(x) + BOARD_SIZE, f32(y)}, 1, rl.WHITE)
            }

            rl.EndDrawing()
        }
    }
}

draw_x :: proc(center: rl.Vector2, color: rl.Color, anim_progress: f32 = 1) {
    length: f32 = 65

    eased_progress := ease.quartic_in_out(anim_progress)
    t1 := clamp(math.remap(eased_progress, 0, 0.5, 0, 1), 0, 1)
    t2 := clamp(math.remap(eased_progress, 0.5, 1, 0, 1), 0, 1)

    rl.rlPushMatrix()
    {
        // Lines are drawn with coords at the center (0, 0)
        // The matrix takes care of positioning and rotating
        rl.rlTranslatef(center.x, center.y, 0)
        rl.rlRotatef(45, 0, 0, 1)

        // Line top to bottom
        end_value := glsl.lerp(glsl.vec2{0, -length}, glsl.vec2{0, length}, glsl.vec2(t1))
        rl.DrawLineEx({0, -length}, cast(rl.Vector2)end_value, 18, color)

        // Line left to right
        end_value = glsl.lerp(glsl.vec2{-length, 0}, glsl.vec2{length, 0}, glsl.vec2(t2))
        rl.DrawLineEx({-length, 0}, cast(rl.Vector2)end_value, 18, color)
    }
    rl.rlPopMatrix()
}

draw_o :: proc(center: rl.Vector2, color: rl.Color, anim_progress: f32 = 1) {
    eased_progress := clamp(ease.quartic_in_out(anim_progress), 0, 1)
    start_angle := math.remap(eased_progress, 0, 1, 300, -60)
    rl.DrawRing(center, 45, 60, start_angle, 300, 64, color)
}

check_board :: proc(board: Board) -> Board_State {
    valid_signs: [2]Cell_State = {.X, .O}

    for sign in valid_signs {
        for row in board.rows {
            // If the 3 are in a row
            if row[0].state == sign && row[1].state == sign && row[2].state == sign {
                return who_won(sign)
            }
        }

        // If the 3 are in a column
        for col in 0 ..< COL_COUNT {
            if board.rows[0][col].state == sign &&
               board.rows[1][col].state == sign &&
               board.rows[2][col].state == sign {
                return who_won(sign)
            }
        }

        // If the 3 are diagonal left to right
        if board.rows[0][0].state == sign && board.rows[1][1].state == sign && board.rows[2][2].state == sign {
            return who_won(sign)
        }

        // If the 3 are diagonal right to left
        if board.rows[0][2].state == sign && board.rows[1][1].state == sign && board.rows[2][0].state == sign {
            return who_won(sign)
        }
    }

    filled_cells: int
    for row in board.rows {
        for col in row {
            if col.state != .Empty do filled_cells += 1
        }
    }
    if filled_cells == ROW_COUNT * COL_COUNT {
        return .Tie
    }

    return .Unfinished
}

who_won :: proc(sign: Cell_State) -> Board_State {
    return .X_Won if sign == .X else .O_Won
}
