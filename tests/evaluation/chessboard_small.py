class Piece(object):
    def __new__(cls, str):
        return super().__new__(cls)

    __slots__ = ()


class BlackChessRook(Piece):
    __slots__ = ()

    def __new__(Class):
        return super().__new__(Class, "\N{black chess rook}")

testPiece = BlackChessRook()