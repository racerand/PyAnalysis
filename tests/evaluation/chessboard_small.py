class Piece(str):
    __slots__ = ()


class BlackChessRook(Piece):
    __slots__ = ()

    def __new__(Class):
        return super().__new__(Class, "Black")

testPiece = BlackChessRook()
testPiece2 = BlackChessRook()