class Board
  attr_accessor :board, :player_one, :player_two

  def initialize(player_one="White", player_two="Black")
    @player_one = player_one
    @player_two = player_two

    @board = Array.new(8){Array.new(8){Square.new}}
  end

  class Square
    attr_accessor :coordinates, :piece, :under_attack

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
    col_mapping = {"a"=>0, "b"=>1, "c"=>2, "d"=>3, "e"=>4, "f"=>5, "g"=>6, "h"=>7}
    move = move.split("")
    return move[1]-1, col_mapping[move[0]]
  end


  class Piece
    attr_accessor :position, :symbol, :color, :moved

    def initialize(position, symbol, color, moved=false)
      @position = position #square <> thing
      @symbol = symbol
      @color = color
      @moved = moved
    end

    def move(move = gets.chomp)
      potential_move = translate_move(move) #ex. from a1 to [0,0]
      if self.available_moves.any? {|move| potential_move == move}
        self.position = @board[potential_move[0]][potential_move[1]]
        self.moved = true
      end
    end

  end

  class King < Piece

    def initialize(position, symbol, color, moved=false) #potential under attack here too
      super(position, symbol, color, moved)
    end

    def generate_moves
      row, col = self.position.coordinates #this is the square  <Sqr nr thing> and it has coordinates, piece and under attack thingies
      available_moves = []

      king_move_pairs = [[1,0],[1,1],[0,1],[-1,1],[-1,0],[-1,-1],[0,-1],[1,-1]]

      king_move_pairs.each do |pair|
        available_moves << [row+pair[0], col+pair[1]] if ((row+pair[0]).between?(0,7) && (col+pair[1]).between?(0,7)) && @board[ row+pair[0] ][ col+pair[1] ].under_attack.false? && @board[ row+pair[0] ][ col+pair[1] ].piece.color != self.color
      end

      #castling #try to think of something simpler later
      if self.moved.false?
        first_rook = @board[row].first.piece
        second_rook = @board[row].last.piece
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
      end
      available_moves
    end

  end

  class Queen < Piece
    def initialize(position, symbol, color, moved=false)
      super(position, symbol, color, moved)
    end

    def generate_moves
      row, col = self.position.coordinates
      available_moves = []
      all_directions = []

      traverse = Proc.new do |square| #Later move this alongside rooks and queens to somewhere else
        if square.piece.empty?
          available_moves << square.coordinates
        else
          available_moves << square.coordinates if square.piece.color != self.color
          break
        end
      end

      #horizontal
      left = @board[row][row.first...col]
      right = @board[row][col+1..row.last]
      all_directions << left << right

      #vertical
      top, bottom = [], []
      8.times do |row_index|
        square = @board[row_index][col]
        if row_index < row
          top << square
        elsif row_index > row
          bottom << square
        end
      end
      all_directions << top << bottom

      #diagonals
      directions = [[1,1],[1,-1],[-1,-1],[-1,1]] #++, +-, -, -+
      directions.each do |direction|
        row_inc, col_inc = direction
        diagonal = []
        while row_inc.between?(0,7) && col_inc.between?(0,7)
          diagonal << @board[row+row_inc][col+col_inc]
          row_inc > 0 ? row_inc+=1 : row_inc-=1 #increases in each counter's specific direction
          col_inc > 0 ? col_inc+=1 : col_inc-=1
        end
        all_directions << diagonal
      end

      all_directions.each {|direction| direction.each(&traverse)}

      available_moves
    end
  end

  class Rook < Piece
    def initialize(position, symbol, color, moved=false)
      super(position, symbol, color, moved)
    end

    def generate_moves
      row, col = self.position.coordinates
      available_moves = []

      traverse = Proc.new do |square| #CAN BE USED ANYWHERE
        if square.piece.empty?
          available_moves << square.coordinates
        else
          available_moves << square.coordinates if square.piece.color != self.color
          break
        end
      end

      #horizontal
      left = @board[row][row.first...col] #elements left to rook #moved reverse down
      right = @board[row][col+1..row.last] #elements right to rook

      #vertical
      top, bottom = [], []
      8.times do |row_index|
        square = @board[row_index][col]
        if row_index < row
          top << square
        elsif row_index > row
          bottom << square
        end
      end

      left.reverse.each(&traverse)
      right.each(&traverse)
      top.reverse.each(&traverse)
      bottom.each(&traverse)

      available_moves
    end
  end

  class Bishop < Piece
    def initialize(position, symbol, color, moved=false)
      super(position, symbol, color, moved)
    end

    def generate_moves
      row, col = self.position.coordinates
      available_moves = []
      all_directions = []

      traverse = Proc.new do |square| #Later move this alongside rooks and queens to somewhere else
        if square.piece.empty?
          available_moves << square.coordinates
        else
          available_moves << square.coordinates if square.piece.color != self.color
          break
        end
      end

      directions = [[1,1],[1,-1],[-1,-1],[-1,1]] #++, +-, -, -+
      directions.each do |direction|
        row_inc, col_inc = direction
        diagonal = []
        while row_inc.between?(0,7) && col_inc.between?(0,7)
          diagonal << @board[row+row_inc][col+col_inc]
          row_inc > 0 ? row_inc+=1 : row_inc-=1 #increases in each counter's specific direction
          col_inc > 0 ? col_inc+=1 : col_inc-=1
        end
        all_directions << diagonal
      end

      all_directions.each {|direction| direction.each(&traverse)}

      available_moves
    end

  end

  class Knight < Piece
    def initialize(position, symbol, color, moved=false)
      super(position, symbol, color, moved)
    end

    def generate_moves
      row, col = self.position.coordinates
      available_moves = []

      directions = [[-2,1],[-2,-1],[1,2],[-1,2],[2,1],[2,-1],[1,-2],[-1,-2]]

      directions.each do |direction|
        row_inc, col_inc = direction
        if (row+row_inc).between?(0,7) && (col+col_inc).between?(0,7)
          square = @board[row+row_inc][col+col_inc]
          if square.piece.empty?
            available_moves << square.coordinates
          else
            available_moves << square.coordinates if square.piece.color != self.color
          end
        end
      end
      available_moves
    end
  end

  class Pawn < Piece
    attr_accessor :double_move, :move_inc
    def initialize(position, symbol, color, moved=false, double_move=false, move_inc=0)
      super(position, symbol, color)#, moved)
      @double_move = double_move
      self.color == "white" ? move_inc = 1 : move_inc = -1
    end

    def generate_moves
      row, col = self.position.coordinates
      available_moves = []

      #normal move
      available_moves << [row+move_inc, col] if (row+1).between?(0,7) #the if will not be needed later
      #start position double move
      available_moves << [row+(move_inc*2), col] if self.moved.false?

      #normal taking
      if (col+1).between?(0,7)
        front_right = @board[row+move_inc][col+1]
        if !(front_right.piece.empty?)
          available_moves << [row+move_inc, col+1] if front_right.piece.color != self.color
        end
      end
      if (col-1).between?(0,7)
        front_left = @board[row+move_inc][col-1]
        if !(front_left.piece.empty?)
          available_moves << [row+move_inc, col-1] if front_left.piece.color != self.color
        end
      end

      #en passant
      if (col+1).between?(0,7) #repated with above, fix it up later
        right = @board[row][col+1]
        if !(right.piece.empty?)
          if right.piece.class.name == "Pawn" && right.piece.color != self.color
            if right.piece.double_move.true?
              available_moves << [row, col+1]
            end
          end
        end
      end

      if (col-1).between?(0,7) #repated with above, fix it up later
        left = @board[row][col-1]
        if !(left.piece.empty?)
          if left.piece.class.name == "Pawn" && left.piece.color != self.color
            if left.piece.double_move.true?
              available_moves << [row, col-1]
            end
          end
        end
      end
    end
  end

  def print_board
    h_index = 8
    @board.each do |row|
      puts "#{h_index} #{row.map { |square| square.piece == "" ? "_" : square.piece.symbol }.join(" ")}"
      h_index -= 1
    end
    puts "  a b c d e f g h"
  end

  def initialize_board_with_pieces
    #white
    @board[1].each_with_index {|square, ind| @board[1][ind].piece = pawn = Pawn.new(square, "♙", "white") }

    @board[0][0].piece = left_rook = Rook.new(@board[0][0], "♖", "white")
    # = left_rook
    @board[0][7].piece = right_rook = Rook.new(@board[0][7], "♖", "white")

    @board[0][1].piece = left_knight = Knight.new(@board[0][1], "♘", "white")
    @board[0][6].piece = right_knight = Knight.new(@board[0][6], "♘", "white")

    @board[0][2].piece = right_bishop = Knight.new(@board[0][2], "♗", "white")
    @board[0][5].piece = left_bishop = Knight.new(@board[0][5], "♗", "white")

    @board[0][3].piece = queen = Queen.new(@board[0][3], "♕", "white" )
    @board[0][4].piece = king = King.new(@board[0][4], "♔", 'white')

    #black
    @board[6].each_with_index {|square, ind| @board[6][ind].piece = black_pawn = Pawn.new(square,"♟", "black") }

    @board[7][0].piece = left_black_rook = Rook.new(@board[7][0], "♜", "black")
    @board[7][7].piece = right_black_rook = Rook.new(@board[7][7], "♜", "black")

    @board[7][1].piece = left_black_knight = Knight.new(@board[7][1], "♞", "black")
    @board[7][6].piece = right_black_knight = Knight.new(@board[7][6], "♞", "black")

    @board[7][2].piece = right_black_bishop = Knight.new(@board[7][2], "♝", "black")
    @board[7][5].piece = left_black_bishop = Knight.new(@board[7][5], "♝", "black")

    @board[7][3].piece = black_queen = Queen.new(@board[7][3], "♛", "black" )
    @board[7][4].piece = black_king = King.new(@board[7][4], "♚", 'black')
  end
end

board = Board.new
board.print_board
board.initialize_board_with_pieces
board.print_board

=begin
♔	U+2654	&#9812;
white chess queen	♕	U+2655	&#9813;
white chess rook	♖	U+2656	&#9814;
white chess bishop	♗	U+2657	&#9815;
white chess knight	♘	U+2658	&#9816;
white chess pawn	♙	U+2659	&#9817;
black chess king	♚	U+265A	&#9818;
black chess queen	♛	U+265B	&#9819;
black chess rook	♜	U+265C	&#9820;
black chess bishop	♝	U+265D	&#9821;
black chess knight	♞	U+265E	&#9822;
black chess pawn	♟
=end
