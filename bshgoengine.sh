#!/bin/sh

# BshGoEngine. 9x9 go engine in bash Linux script.
# Copyright (C) 2025 Toni Helminen
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# Go Game with Random Black Player in POSIX shell
# Human plays as White, computer plays as Black with random moves

# Board representation using variables
BOARD_SIZE=9
BLACK="●"
WHITE="○"
EMPTY="·"
CURRENT_PLAYER=$BLACK
GAME_OVER=false
PASS_COUNT=0

# Initialize the board
initialize_board() {
    i=0
    while [ $i -lt $BOARD_SIZE ]; do
        j=0
        while [ $j -lt $BOARD_SIZE ]; do
            eval "board_${i}_${j}=\"$EMPTY\""
            j=$((j+1))
        done
        i=$((i+1))
    done
}

# Get cell value
get_cell() {
    eval "echo \$board_${1}_${2}"
}

# Set cell value
set_cell() {
    eval "board_${1}_${2}=\"$3\""
}

print_board() {
    # Print column labels
    printf "  "
    j=0
    while [ $j -lt $BOARD_SIZE ]; do
        printf "%2d" $((j+1))
        j=$((j+1))
    done
    printf "\n"

    # Print board with row labels
    i=0
    while [ $i -lt $BOARD_SIZE ]; do
        printf "%2d " $((i+1))
        j=0
        while [ $j -lt $BOARD_SIZE ]; do
            printf "%s " "$(get_cell $i $j)"
            j=$((j+1))
        done
        printf "\n"
        i=$((i+1))
    done
}

is_valid_move() {
    row=$1
    col=$2

    # Check if position is on the board
    if [ $row -lt 0 ] || [ $row -ge $BOARD_SIZE ] || [ $col -lt 0 ] || [ $col -ge $BOARD_SIZE ]; then
        return 1
    fi

    # Check if position is empty
    if [ "$(get_cell $row $col)" != "$EMPTY" ]; then
        return 1
    fi

    return 0
}

get_valid_moves() {
    i=0
    while [ $i -lt $BOARD_SIZE ]; do
        j=0
        while [ $j -lt $BOARD_SIZE ]; do
            if is_valid_move $i $j; then
                printf "%d %d " $i $j
            fi
            j=$((j+1))
        done
        i=$((i+1))
    done
}

place_stone() {
    row=$1
    col=$2

    if is_valid_move $row $col; then
        set_cell $row $col "$CURRENT_PLAYER"
        PASS_COUNT=0
        return 0
    else
        return 1
    fi
}

switch_player() {
    if [ "$CURRENT_PLAYER" = "$BLACK" ]; then
        CURRENT_PLAYER=$WHITE
    else
        CURRENT_PLAYER=$BLACK
    fi
}

make_random_move() {
    valid_moves=$(get_valid_moves)
    set -- $valid_moves
    num_moves=$(( $# / 2 ))

    if [ $num_moves -eq 0 ]; then
        echo "Black passes (no valid moves)"
        PASS_COUNT=$((PASS_COUNT + 1))
        return
    fi

    random_index=$(( $(awk 'BEGIN { srand(); print int(rand() * ARGV[1]) }' $num_moves) * 2 + 1 ))
    row=$(eval echo \${$random_index})
    col=$(eval echo \${$((random_index + 1))})

    place_stone $row $col
    echo "Black plays at $((row+1)) $((col+1))"
}

check_game_over() {
    if [ $PASS_COUNT -ge 2 ]; then
        GAME_OVER=true
        echo "Game over! Both players passed consecutively."
        print_board
        # Simple scoring (count stones)
        black_count=0
        white_count=0
        i=0
        while [ $i -lt $BOARD_SIZE ]; do
            j=0
            while [ $j -lt $BOARD_SIZE ]; do
                cell=$(get_cell $i $j)
                if [ "$cell" = "$BLACK" ]; then
                    black_count=$((black_count + 1))
                elif [ "$cell" = "$WHITE" ]; then
                    white_count=$((white_count + 1))
                fi
                j=$((j+1))
            done
            i=$((i+1))
        done
        echo "Final score:"
        echo "Black: $black_count, White: $white_count"
        if [ $black_count -gt $white_count ]; then
            echo "Black wins!"
        elif [ $white_count -gt $black_count ]; then
            echo "White wins!"
        else
            echo "The game is a tie!"
        fi
    fi
}

play_game() {
    initialize_board

    while [ "$GAME_OVER" = "false" ]; do
        clear
        echo "Current player: $CURRENT_PLAYER"
        print_board

        if [ "$CURRENT_PLAYER" = "$WHITE" ]; then
            # Human player's turn (White)
            while true; do
                echo "Enter your move as 'row col' (e.g., '3 4') or 'pass':"
                read input

                if [ "$input" = "pass" ]; then
                    PASS_COUNT=$((PASS_COUNT + 1))
                    echo "White passes"
                    break
                fi

                # Parse input
                row=$(echo "$input" | awk '{print $1}')
                col=$(echo "$input" | awk '{print $2}')

                if [ -z "$row" ] || [ -z "$col" ]; then
                    echo "Invalid input! Please enter 'row col' or 'pass'"
                    continue
                fi

                row=$((row - 1))
                col=$((col - 1))

                if place_stone $row $col; then
                    break
                else
                    echo "Invalid move! Try again."
                fi
            done
        else
            # Computer's turn (Black)
            sleep 1  # Pause so human can see the move
            make_random_move
        fi

        check_game_over
        switch_player
    done
}

# Main game loop
echo "Welcome to BshGoEngine!"
echo "You are playing as White ($WHITE) against the computer (Black $BLACK)"
echo "Black will play random valid moves"
echo "Enter moves as 'row col' (e.g., '3 4' for row 3, column 4)"
echo "Enter 'pass' when you want to pass"
echo "Game ends when both players pass consecutively"
echo "Press Enter to start..."
read dummy

play_game
