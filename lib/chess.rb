class Board
  attr_accessor :board, :player_one, :player_two

  def initialize(player_one="White", player_two="Black")
    @player_one = player_one
    @player_two = player_two

    @board = Array.new(8){Array.new(8){Square.new}}
  end

  class Square
    attr_accessor :position, :piece, :under_attack

    def initialize
      @coordinates = []
      @piece = ""
      @under_attack = false
    end
  end

  def generate_square_coordinates
    @board.each_with_index do |row, row_index|
      row.each_with_index do |square, square_index|
        square.coordinates << row_index
        square.coordinates << square_index
      end
    end
  end


  def translate_move(move) #a1 = [0,0], a2 = [1,0] (1=2-1, 0=a)
    col_mapping = {"a"=>0, "b"=>1, "c"=2, "d"=>3, "e"=4, "f"=>5, "g"=>6, "h"=>7}
    move = move.split("")
    return move[1]-1, col_mapping[move[0]]
  end


  class Piece
    attr_accessor :position, :symbol, :color

    def initialize(position, symbol, color)
      @position = position #square <> thing
      @symbol = symbol
      @color = color
    end
  end

  class King < Piece
    attr_accessor :moved

    def initialize(position, symbol, color, moved=false) #potential under attack here too
      super(position, symbol, color)
      @moved = moved
    end

    def generate_moves
      row, col = self.position.coordinates #this is the square  <Sqr nr thing> and it has coordinates, piece and under attack thingies
      available_moves = []

      king_move_pairs = [[1,0],[1,1],[0,1],[-1,1],[-1,0],[-1,-1],[0,-1],[1,-1]]

      king_move_pairs.each do |pair|
        available_moves << [row+pair[0], col+pair[1]] if
        ((row+pair[0]).between?(0,7) && (col+pair[1]).between?(0,7)) &&
        @board[ row+pair[0] ][ col+pair[1] ].under_attack.false? &&
        @board[ row+pair[0] ][ col+pair[1] ].piece.color != self.color
      end

      #castling #try to think of something simpler later
      if self.moved.false?
        first_rook = @board[row].first.piece
        second_rook = @board[row].last.piece
        #rook to king.last(3)
        if first_rook.class.name == "Rook" && first_rook.moved.false?
          path_start = first_rook.coordinates[1]
          path_end = self.coordinates[1]
          path = row[path_start..path_end]
          if path.last(3).all? {|square| square.under_attack.false?}
            if path.last(2).all {|square| square.piece.empty?}
              available_moves << [row, col-2]
            end
          end
        end
        if second_rook.class.name == "Rook" && second_rook.moved.false?
          path_start = second_rook.coordinates[1]
          path_end = self.coordinates[1]
          path = row[path_start..path_end]
          if path.last(3).all? {|square| square.under_attack.false?}
            if path.last(2).all {|square| square.piece.empty?}
              available_moves << [row, col-2]
            end
          end
        end
      available_moves
    end

    def move(move = gets.chomp)
      potential_move = translate_move(move) #ex. from a1 to [0,0]
      if self.available_moves.any? {|move| potential_move == move}
        self.position = @board[potential_move[0]][potential_move[1]]
        self.moved = true
      end
    end

  end

  class Queen < Piece
    def initialize(position, symbol, color)
      super(position, symbol, color)
    end
  end

  class Rook < Piece
    attr_accessor :moved

    def initialize(position, symbol, color, moved=false)
      super(position, symbol, color)
      @moved = moved
    end
  end

  class Bishop < Piece
    def initialize(position, symbol, color)
      super(position, symbol, color)
    end
  end

  class Knight < Piece
    def initialize(position, symbol, color)
      super(position, symbol, color)
    end
  end

  class Pawn < Piece
    attr_accessor :moved

    def initialize(position, symbol, color, moved=false)
      super(position, symbol, color)
      @moved = moved
    end
  end

  def print_board
    h_index = 8
    @board.reverse.each do |row|
      puts "#{h_index} #{row.map { |square| square.piece.empty? ? "_" : square.piece }.join(" ")}"
      h_index -= 1
    end
    puts "  a b c d e f g h"
  end
end

board = Board.new
board.print_board
