/*
Author: Bruno De Angelis
15/05/2024
========================

https://www.codewars.com/kata/525caa5c1bf619d28c000335

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
import "core:math/linalg"

import rl "vendor:raylib"


main :: proc() {
    rl.SetConfigFlags({.VSYNC_HINT, .MSAA_4X_HINT})

    rl.InitWindow(WINDOW_SIZE, WINDOW_SIZE, "Tic Tac Toe Kata")
    rl.SetTargetFPS(240)

    bg_img_bytes := #load("assets/bg.png")
    bg_texture := rl.LoadTextureFromImage(
        rl.LoadImageFromMemory(".png", raw_data(bg_img_bytes), i32(len(bg_img_bytes))),
    )

    postprocess_shader_bytes := #load("postprocess.fs", cstring)
    postprocess_shader := rl.LoadShaderFromMemory(nil, postprocess_shader_bytes)
    blur_intensity_loc = rl.GetShaderLocation(postprocess_shader, "blurIntensity")
    screen_opacity_loc = rl.GetShaderLocation(postprocess_shader, "opacity")

    target_rt := rl.LoadRenderTexture(WINDOW_SIZE, WINDOW_SIZE)
    rl.SetTextureFilter(target_rt.texture, .ANISOTROPIC_16X)

    for !rl.WindowShouldClose() {
        delta := rl.GetFrameTime()

        board.state, strikethrough_positions = check_board(board)

        if rl.IsMouseButtonPressed(.RIGHT) && (board.state == .Unfinished || board.state == .Tie) {
            reset_game()
        }

        rl.BeginTextureMode(target_rt)
        {
            rl.BeginMode2D(camera)

            mouse_pos := rl.GetMousePosition()

            rl.ClearBackground({30, 30, 30, 255})

            rl.DrawTexturePro(
                bg_texture,
                {0, 0, f32(bg_texture.width), f32(bg_texture.height)},
                {-(WINDOW_SIZE / 2), -(WINDOW_SIZE / 2), WINDOW_SIZE * 2, WINDOW_SIZE * 2},
                {0, 0},
                0,
                rl.WHITE,
            )

            x := initial_x
            y := initial_y
            for &row in board.rows {
                for &cell in row {
                    cell.rec = rl.Rectangle{f32(x), f32(y), CELL_SIZE, CELL_SIZE}
                    cell.center = Vec2{f32(x) + (CELL_SIZE / 2), f32(y) + (CELL_SIZE / 2)}

                    if cell.is_drawing {
                        cell.anim_progress += 1.75 * delta
                        if cell.anim_progress >= 1 {
                            cell.anim_progress = 1
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

            // Reset coords to draw board edges so batching doesn't break
            x = initial_x
            y = initial_y
            for _ in 0 ..< BOARD_DIM - 1 {
                for _ in 0 ..< BOARD_DIM - 1 {
                    x += CELL_SIZE
                    rl.DrawLineEx({f32(x), f32(initial_y)}, {f32(x), f32(initial_y) + BOARD_SIZE}, 1, rl.WHITE)
                }
                y += CELL_SIZE
                x = initial_x
                rl.DrawLineEx({f32(x), f32(y)}, {f32(x) + BOARD_SIZE, f32(y)}, 1, rl.WHITE)
            }

            if board.state == .O_Won || board.state == .X_Won {
                victory_anim_progress += delta
                t := victory_anim_progress / VICTORY_ANIM_DURATION // remap 0 to 1

                camera.zoom += 0.3 * delta
                camera.zoom = clamp(camera.zoom, 1, 1.25)

                camera.rotation = linalg.lerp(camera.rotation, 15, t)
                camera.target = linalg.lerp(camera.target, strikethrough_positions[1], t)

                blur_intensity += delta

                rl.DrawLineEx(
                    strikethrough_positions[0],
                    linalg.lerp(
                        strikethrough_positions[0],
                        strikethrough_positions[2],
                        ease.cubic_in_out(clamp(t * 3, 0, 1)),
                    ),
                    LINE_THICKNESS,
                    rl.YELLOW,
                )

                if t >= 0.7 {
                    screen_opacity -= delta
                    if screen_opacity <= 0 {
                        screen_opacity = 0
                        fading_in = true
                        reset_game()
                    }
                }
            }

            if fading_in {
                screen_opacity += delta
                if screen_opacity >= 1 {
                    screen_opacity = 1
                    fading_in = false
                }
            }

            rl.EndMode2D()
        }
        rl.EndTextureMode()

        rl.BeginDrawing()
        {
            rl.SetShaderValue(postprocess_shader, blur_intensity_loc, &blur_intensity, .FLOAT)
            rl.SetShaderValue(postprocess_shader, screen_opacity_loc, &screen_opacity, .FLOAT)
            rl.BeginShaderMode(postprocess_shader)
            {
                rl.DrawTextureRec(target_rt.texture, {0, 0, WINDOW_SIZE, -WINDOW_SIZE}, {0, 0}, rl.WHITE)
            }
            rl.EndShaderMode()
        }
        rl.EndDrawing()
    }
}

draw_x :: proc(center: Vec2, color: rl.Color, anim_progress: f32 = 1) {
    // Split progress into two, so each line animates individually
    // and not at the same time
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
        end_value := linalg.lerp(Vec2{0, -SHAPE_EXTENSION}, Vec2{0, SHAPE_EXTENSION}, Vec2(t1))
        rl.DrawLineEx({0, -SHAPE_EXTENSION}, cast(Vec2)end_value, LINE_THICKNESS, color)

        // Line left to right
        end_value = linalg.lerp(Vec2{-SHAPE_EXTENSION, 0}, Vec2{SHAPE_EXTENSION, 0}, Vec2(t2))
        rl.DrawLineEx({-SHAPE_EXTENSION, 0}, cast(Vec2)end_value, LINE_THICKNESS, color)
    }
    rl.rlPopMatrix()

    rl.EndShaderMode()
}

draw_o :: proc(center: Vec2, color: rl.Color, anim_progress: f32 = 1) {
    eased_progress := clamp(ease.quartic_in_out(anim_progress), 0, 1)
    start_angle := math.remap(eased_progress, 0, 1, 300, -60)
    rl.DrawRing(center, LINE_THICKNESS * 1.8, LINE_THICKNESS * 2.7, start_angle, 300, 64, color)
}

check_board :: proc(board: Board) -> (Board_State, [3]Vec2) {
    valid_signs: [2]Cell_State = {.X, .O}
    strikethrough_positions: [3]Vec2
    line_extension: f32 = CELL_SIZE / 1.75

    for sign in valid_signs {
        for row in board.rows {
            // If the 3 are in a row
            if row[0].state == sign && row[1].state == sign && row[2].state == sign {
                strikethrough_positions = {
                    {row[0].center.x - line_extension, row[0].center.y},
                    {row[1].center.x, row[1].center.y},
                    {row[2].center.x + line_extension, row[2].center.y},
                }
                return who_won(sign), strikethrough_positions
            }
        }

        // If the 3 are in a column
        for col in 0 ..< BOARD_DIM {
            cell1 := board.rows[0][col]
            cell2 := board.rows[1][col]
            cell3 := board.rows[2][col]
            if cell1.state == sign && cell2.state == sign && cell3.state == sign {
                strikethrough_positions = {
                    {cell1.center.x, cell1.center.y - line_extension},
                    {cell2.center.x, cell2.center.y},
                    {cell3.center.x, cell3.center.y + line_extension},
                }
                return who_won(sign), strikethrough_positions
            }
        }

        // If the 3 are diagonal left to right
        tl := board.rows[0][0] // Top Left cell
        mid := board.rows[1][1] // Middle cell
        br := board.rows[2][2] // Bottom Right cell
        if tl.state == sign && mid.state == sign && br.state == sign {
            strikethrough_positions = {
                {tl.center.x - line_extension, tl.center.y - line_extension},
                {mid.center.x, mid.center.y},
                {br.center.x + line_extension, br.center.y + line_extension},
            }
            return who_won(sign), strikethrough_positions
        }

        // If the 3 are diagonal right to left
        tr := board.rows[0][2] // Top Right cell
        bl := board.rows[2][0] // Bottom Left cell
        if tr.state == sign && mid.state == sign && bl.state == sign {
            strikethrough_positions = {
                {tr.center.x + line_extension, tr.center.y - line_extension},
                {mid.center.x, mid.center.y},
                {bl.center.x - line_extension, bl.center.y + line_extension},
            }
            return who_won(sign), strikethrough_positions
        }
    }

    filled_cells: int
    for row in board.rows {
        for col in row {
            if col.state != .Empty do filled_cells += 1
        }
    }
    if filled_cells == CELL_AMOUNT {
        return .Tie, {}
    }

    return .Unfinished, {}
}

who_won :: proc(sign: Cell_State) -> Board_State {
    return .X_Won if sign == .X else .O_Won
}

reset_game :: proc() {
    board = {}
    placing_sign = .X
    camera = initial_camera
    victory_anim_progress = 0
    blur_intensity = 0
}
