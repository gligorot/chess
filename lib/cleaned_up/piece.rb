class Piece
  attr_accessor :position, :symbol, :color, :moved, :available_moves

  def initialize(position, symbol, color, moved=false, available_moves=[])
    @position = position #square <> thing
    @symbol = symbol
    @color = color
    @moved = moved
    @available_moves = available_moves
  end
end

class King < Piece
  def initialize(position, symbol, color, moved=false, available_moves=[]) #potential under attack here too
    super(position, symbol, color, moved, available_moves)
  end
end

class Queen < Piece
  def initialize(position, symbol, color, moved=false, available_moves=[])
    super(position, symbol, color, moved, available_moves)
  end
end

class Rook < Piece
  def initialize(position, symbol, color, moved=false, available_moves=[])
    super(position, symbol, color, moved, available_moves)
  end
end

class Bishop < Piece
  def initialize(position, symbol, color, moved=false, available_moves=[])
    super(position, symbol, color, moved, available_moves)
  end
end

class Knight < Piece
  def initialize(position, symbol, color, moved=false, available_moves=[])
    super(position, symbol, color, moved, available_moves)
  end
end

class Pawn < Piece
  attr_accessor :double_move
  def initialize(position, symbol, color, moved=false, double_move=false, available_moves=[])
    super(position, symbol, color, moved, available_moves)
    @double_move = double_move
  end
end
