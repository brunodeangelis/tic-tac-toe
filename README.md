Solution for [this Kata.](https://www.codewars.com/kata/525caa5c1bf619d28c000335)

> _If we were to set up a Tic-Tac-Toe game, we would want to know whether the board's current state is solved,
> wouldn't we? Our goal is to create a function that will check that for us!_
>
> _Assume that the board comes in the form of a 3x3 array, where the value is 0 if a spot is empty, 1 if it is an "X", or 2 if it is an "O", like so:_
>
> `[[0, 0, 1],`<br> `[0, 1, 2],`<br> `[2, 1, 0]]`
>
> _We want our function to return:_
>
> - `-1` _if the board is not yet finished AND no one has won yet (there are empty spots)_
> - `1` _if "X" won,_
> - `2` _if "O" won,_
> - `0` _if it's a cat's game (i.e. a draw)._
>
> _You may assume that the board passed in is valid in the context of a game of Tic-Tac-Toe._
