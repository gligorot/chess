class Board
  attr_accessor :player_one, :player_two, :board

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

  def board_accessor(row, col)
    @board[row][col]
  end


  class Piece
    attr_accessor :position, :symbol, :color, :moved

    def initialize(position, symbol, color, moved=false)
      @position = position #square <> thing
      @symbol = symbol
      @color = color
      @moved = moved
    end

    def move(move = gets.chomp) #fixfifxfixxxfix
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
  end

  def generate_moves_king(figure)
    figure = board_accessor(figure[0], figure[1]).piece
    row, col = figure.position.coordinates
    available_moves = []

    king_move_pairs = [[1,0],[1,1],[0,1],[-1,1],[-1,0],[-1,-1],[0,-1],[1,-1]]

    king_move_pairs.each do |pair|
      board_pos = board_accessor(row+pair[0], col+pair[1])
      if ((row+pair[0]).between?(0,7) && (col+pair[1]).between?(0,7)) && board_pos.under_attack == false
        if board_pos.piece == ""
          available_moves << [row+pair[0], col+pair[1]]
        elsif board_pos.piece.color != figure.color
          available_moves << [row+pair[0], col+pair[1]]
        end
      end
    end

    #castling #try to think of something simpler later
    if figure.moved == false
      first_rook = board_accessor(row, 0).piece
      second_rook = board_accessor(row, 7).piece
      if first_rook.class.name == "Rook" && first_rook.moved == false
        path_start = first_rook.coordinates[1]
        path_end = figure.coordinates[1]
        path = row[path_start..path_end]
        if path.last(3).all? {|square| square.under_attack.false?}
          if path.last(2).all {|square| square.piece.empty?}
            available_moves << [row, col-2]
          end
        end
      end
      if second_rook.class.name == "Rook" && second_rook.moved.false?
        path_start = second_rook.coordinates[1]
        path_end = figure.position.coordinates[1] #problem alert
        path = row[path_start..path_end]
        if path.last(3).all? {|square| square.under_attack == false}
          if path.last(2).all {|square| square.piece == ""}
            available_moves << [row, col-2]
          end
        end
      end
    end
    available_moves
  end

  class Queen < Piece
    def initialize(position, symbol, color, moved=false)
      super(position, symbol, color, moved)
    end
  end

  def generate_moves_queen(figure)
    figure = board_accessor(figure[0], figure[1]).piece
    row, col = figure.position.coordinates
    available_moves = []
    all_directions = []

    #horizontal
    left = board_accessor(row, 0...col)#@board[row][row.first...col]
    right = board_accessor(row, col+1..8)#@board[row][col+1..row.last]
    all_directions << left << right

    #vertical
    top, bottom = [], []
    8.times do |row_index|
      square = board_accessor(row_index, col)#@board[row_index][col]
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
      while (row+row_inc).between?(0,7) && (col+col_inc).between?(0,7)
        diagonal << board_accessor(row+row_inc, col+col_inc)#@board[row+row_inc][col+col_inc]
        row_inc > 0 ? row_inc+=1 : row_inc-=1 #increases in each counter's specific direction
        col_inc > 0 ? col_inc+=1 : col_inc-=1
      end
      all_directions << diagonal
    end

    all_directions.each do |direction|
      direction.each do |square|
        if square.piece == ""
          available_moves << square.coordinates
        else
          if square.piece.color != figure.color
            available_moves << square.coordinates
            break
          end
        end
      end
    end

    available_moves
  end

  class Rook < Piece
    def initialize(position, symbol, color, moved=false)
      super(position, symbol, color, moved)
    end
  end

  def generate_moves_rook(figure)
    figure = board_accessor(figure[0], figure[1]).piece
    row, col = figure.position.coordinates
    available_moves = []

    #horizontal
    left = board_accessor(row, 0...col)#@board[row][row.first...col] #elements left to rook #moved reverse down
    right = board_accessor(row, col+1..8)#@board[row][col+1..row.last] #elements right to rook

    #vertical
    top, bottom = [], []
    8.times do |row_index|
      square = board_accessor(row_index, col)#@board[row_index][col]
      if row_index < row
        top << square
      elsif row_index > row
        bottom << square
      end
    end

    [left, right, top, bottom].each do |direction|
      direction.each do |square|
        if square.piece == ""
          available_moves << square.coordinates
        else
          if square.piece.color != figure.color
            available_moves << square.coordinates
            break
          end
        end
      end
    end

    available_moves
  end

  class Bishop < Piece
    def initialize(position, symbol, color, moved=false)
      super(position, symbol, color, moved)
    end
  end


  def generate_moves_bishop(figure)
    figure = board_accessor(figure[0], figure[1]).piece
    row, col = figure.position.coordinates
    available_moves = []
    all_directions = []

    directions = [[1,1],[1,-1],[-1,-1],[-1,1]] #++, +-, -, -+

    directions.each do |direction|
      row_inc, col_inc = direction
      diagonal = []
      while (row+row_inc).between?(0,7) && (col+col_inc).between?(0,7)
        diagonal << board_accessor(row+row_inc, col+col_inc)#@board[row+row_inc][col+col_inc]
        row_inc > 0 ? row_inc+=1 : row_inc-=1 #increases in each counter's specific direction
        col_inc > 0 ? col_inc+=1 : col_inc-=1
      end
      all_directions << diagonal
    end

    all_directions.each  do |direction|
      direction.each do |square|
        if square.piece == ""
          available_moves << square.coordinates
        else
          if square.piece.color != figure.color
            available_moves << square.coordinates
            break
          end
        end
      end
    end

    available_moves
  end

  class Knight < Piece
    def initialize(position, symbol, color, moved=false)
      super(position, symbol, color, moved)
    end
  end

  def generate_moves_knight(figure)
    figure = board_accessor(figure[0], figure[1]).piece
    row, col = figure.position.coordinates
    available_moves = []

    directions = [[-2,1],[-2,-1],[1,2],[-1,2],[2,1],[2,-1],[1,-2],[-1,-2]]

    directions.each do |direction|
      row_inc, col_inc = direction
      if (row+row_inc).between?(0,7) && (col+col_inc).between?(0,7)
        square = board_accessor(row+row_inc, col+col_inc)#@board[row+row_inc][col+col_inc]
        if square.piece == ""
          available_moves << square.coordinates
        else
          available_moves << square.coordinates if square.piece.color != figure.color
        end
      end
    end
    available_moves
  end

  class Pawn
    attr_accessor :double_move, :moved, :position, :symbol, :color

    def initialize(position, symbol, color, moved=false, double_move=false)
      @position = position #square <> thing
      @symbol = symbol
      @color = color
      @moved = moved
      @double_move = double_move
    end
  end

  def generate_moves_pawn(figure)
    figure = board_accessor(figure[0], figure[1]).piece
    row, col = figure.position.coordinates
    available_moves = []

    if figure.color == "white"
      move_inc = 1
    else
      move_inc = -1
    end

    #normal move
    available_moves << [row+move_inc, col] if (row+1).between?(0,7) #the if will not be needed later when promotion is done
    #start position double move
    available_moves << [row+(move_inc*2), col] if figure.moved == false #unless there is something in front !!!!!!!! FIX LATER

    #normal taking
    if (col+1).between?(0,7)
      front_right = board_accessor(row+move_inc, col+1)#@board[row+move_inc][col+1]
      if !(front_right.piece == "")
        available_moves << [row+move_inc, col+1] if front_right.piece.color != figure.color
      end
    end

    if (col-1).between?(0,7)
      front_left = board_accessor(row+move_inc, col-1)#@board[row+move_inc][col-1]
      if !(front_left.piece == "")
        available_moves << [row+move_inc, col-1] if front_left.piece.color != figure.color
      end
    end

    #en passant
    if (col+1).between?(0,7) #repated with above, fix it up later
      right = board_accessor(row, col+1)#@board[row][col+1]
      if !(right.piece == "")
        if right.piece.class.name == "Pawn" && right.piece.color != figure.color
          if right.piece.double_move.true?
            available_moves << [row, col+1]
          end
        end
      end
    end

    if (col-1).between?(0,7) #repated with above, fix it up later
      left = board_accessor(row, col-1) #@board[row][col-1]
      if !(left.piece == "")
        if left.piece.class.name == "Pawn" && left.piece.color != figure.color
          if left.piece.double_move.true?
            available_moves << [row, col-1]
          end
        end
      end
    end
  available_moves
  end


  def print_board
    h_index = 8
    @board.reverse.each do |row|
      puts "#{h_index} #{row.map { |square| square.piece == "" ? "_" : square.piece.symbol }.join(" ")}"
      h_index -= 1
    end
    puts "  a b c d e f g h"
    #puts "#{@board[1][0].piece.generate_moves}" #CURRENT PROBLEM
    #puts "#{@board[0][2].piece.generate_moves}"
  end

  def initialize_board_with_pieces
    #testing
    @board[4][4].piece = knight = Knight.new(@board[4][4], "♘", "white")
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
#board.print_board
board.generate_square_coordinates
board.initialize_board_with_pieces
board.print_board
puts print board.generate_moves_pawn([1,1])
puts print board.generate_moves_queen([4,4])
