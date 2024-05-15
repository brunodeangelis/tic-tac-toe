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

import rl "vendor:raylib"

WIN_WIDTH :: 800
WIN_HEIGHT :: 800

ROW_COUNT :: 3
COL_COUNT :: 3

BOARD_SIZE :: 500
CELL_SIZE :: BOARD_SIZE / COL_COUNT

Cell_State :: enum {
	Empty,
	X,
	O,
}

Board_State :: enum {
	Unfinished = -1,
	Tie,
	X_Won,
	O_Won,
}

Board :: struct {
	rows:         [ROW_COUNT][COL_COUNT]Cell_State,
	placing_sign: Cell_State,
	state:        Board_State,
}

// board := Board {
// 	rows  = {{.Empty, .Empty, .X}, {.Empty, .X, .O}, {.O, .X, .Empty}},
// }

board: Board
placing_sign := Cell_State.X

main :: proc() {
	rl.SetConfigFlags({.VSYNC_HINT, .MSAA_4X_HINT})

	rl.InitWindow(WIN_WIDTH, WIN_HEIGHT, "Tic Tac Toe")
	rl.SetTargetFPS(480)

	initial_x := (WIN_WIDTH - BOARD_SIZE) / 2
	initial_y := (WIN_HEIGHT - BOARD_SIZE) / 2

	for !rl.WindowShouldClose() {
		if rl.IsMouseButtonPressed(.RIGHT) {
			board.rows = {}
			placing_sign = Cell_State.X
		}

		{
			rl.BeginDrawing()
			rl.ClearBackground({30, 30, 30, 255})


			fps := rl.GetFPS()
			mouse_pos := rl.GetMousePosition()
			delta_t := rl.GetFrameTime()

			board.state = check_board(board)
			fmt.println(board.state)

			x := initial_x
			y := initial_y
			for &row in board.rows {
				for &cell in row {
					cell_rec := rl.Rectangle{f32(x), f32(y), CELL_SIZE, CELL_SIZE}

					if board.state == .Unfinished &&
					   rl.CheckCollisionPointRec(mouse_pos, cell_rec) &&
					   cell == .Empty {
						rl.DrawRectangleRec(cell_rec, rl.DARKGRAY)

						if rl.IsMouseButtonPressed(.LEFT) {
							cell = placing_sign
							placing_sign = .O if placing_sign == .X else .X
						}
					}

					rl.DrawRectangleLinesEx(cell_rec, 2, rl.WHITE)

					sign_center := rl.Vector2{f32(x) + (CELL_SIZE / 2), f32(y) + (CELL_SIZE / 2)}
					if cell == .X {
						rl.DrawRectangleRec(cell_rec, rl.YELLOW)
					} else if cell == .O {
						rl.DrawRing(sign_center, 45, 60, 0, 360, 64, rl.WHITE)
					}

					x += CELL_SIZE
				}
				y += CELL_SIZE
				x = initial_x
			}

			// fmt.println(board.rows)

			rl.EndDrawing()
		}
	}
}

check_board :: proc(board: Board) -> Board_State {
	signs: [2]Cell_State = {.X, .O}
	for sign in signs {
		for row in board.rows {
			if row[0] == sign && row[1] == sign && row[2] == sign {
				return .X_Won if sign == .X else .O_Won
			}
		}

		for col in 0 ..< COL_COUNT {
			if board.rows[0][col] == sign &&
			   board.rows[1][col] == sign &&
			   board.rows[2][col] == sign {
				return .X_Won if sign == .X else .O_Won
			}
		}

		if board.rows[0][0] == sign && board.rows[1][1] == sign && board.rows[2][2] == sign {
			return .X_Won if sign == .X else .O_Won
		}

		if board.rows[0][2] == sign && board.rows[1][1] == sign && board.rows[2][0] == sign {
			return .X_Won if sign == .X else .O_Won
		}
	}

	count: int
	for row in board.rows {
		for col in row {
			if col != .Empty do count += 1
		}
	}
	if count == ROW_COUNT * COL_COUNT do return .Tie

	return .Unfinished
}
