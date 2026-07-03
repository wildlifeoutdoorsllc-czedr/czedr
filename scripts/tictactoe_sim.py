"""Monte Carlo tic-tac-toe simulation."""
import random
from collections import Counter

WINS = [
    (0, 1, 2), (3, 4, 5), (6, 7, 8),
    (0, 3, 6), (1, 4, 7), (2, 5, 8),
    (0, 4, 8), (2, 4, 6),
]


def winner(board: list) -> str | None:
    for a, b, c in WINS:
        if board[a] and board[a] == board[b] == board[c]:
            return board[a]
    if all(board):
        return "D"
    return None


def play_random() -> str:
    board = [None] * 9
    turn = "X"
    while True:
        empties = [i for i, v in enumerate(board) if v is None]
        i = random.choice(empties)
        board[i] = turn
        w = winner(board)
        if w:
            return w
        turn = "O" if turn == "X" else "X"


def main() -> None:
    random.seed(42)
    n = 1_000_000
    counts: Counter[str] = Counter()
    for _ in range(n):
        counts[play_random()] += 1

    print("Tic-Tac-Toe Monte Carlo Simulation")
    print("=" * 42)
    print(f"Games simulated: {n:,}")
    print("Seed: 42")
    print("Strategy: uniform random legal moves")
    print()
    labels = {"X": "X wins", "O": "O wins", "D": "Draws"}
    for k in ("X", "O", "D"):
        c = counts[k]
        print(f"  {labels[k]:8}  {c:>10,}  ({100.0 * c / n:6.3f}%)")
    print()
    print(f"First player (X) advantage: {100.0 * counts['X'] / n:.3f}% win rate")
    print(f"Non-draw games: {counts['X'] + counts['O']:,} ({100.0 * (counts['X'] + counts['O']) / n:.3f}%)")
    print()
    print("Reference (perfect play): 100% draws (game theory)")


if __name__ == "__main__":
    main()
