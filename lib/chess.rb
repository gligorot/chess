class Board
  attr_accessor :player_one, :player_two, :board

  def initialize(player_one="white", player_two="black")
    @player_one = player_one
    @player_two = player_two

    @board = Array.new(8){Array.new(8){Square.new}}
  end

  class Square
    attr_accessor :coordinates, :piece, :attacked_by_black, :attacked_by_white

    def initialize
      @coordinates = []
      @piece = ""
      @attacked_by_white = false
      @attacked_by_black = false
    end
  end

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

  def board_accessor(row, col) #done
    @board[row][col]
  end

  def player_on_turn #done
    @player_one
  end

  def switch_players #done
    @player_one, @player_two = @player_two, @player_one
  end

  def move
    begin
      puts "Insert location of piece and where you want it to move: (ex a2a4)"
      puts "Alternatively DRAW to offer a draw"
      move = gets.chomp
      draw_offer_check(move) #find a way to stop it later FIX/problem alert
      move_validity_check(move) #potential error #1

      current_position = translate_move(move[0..1])
      current = board_accessor(current_position[0], current_position[1])
      future_position = available_moves_check(move, current_position, current.piece)
      #potential error #2
    rescue
      puts "", "Move INVALID, try again!", ""
      retry
    end

    castling(move, current.piece)
    pawn_promotion(move, current)

    #future square
    future = board_accessor(future_position[0], future_position[1])

    future.piece = current.piece
    current.piece.position = future
    current.piece = ""
  end

  #helper method
  def draw_offer_check(draw_offer)
    if draw_offer == "DRAW"
      begin
        puts "You have been offered a draw, return DRAW if you accept or an empty input if you don't :"
        draw_answer = gets.chomp
        if draw_answer == "DRAW"
          puts "You have agreed to a draw, the game is over without a winner."
          #find a way to stop the game later FIX/problem alert
        elsif draw_answer.empty?
          puts "You have rejected the draw offer, the game will proceed."
        else
          raise ArgumentError
        end
      rescue
        puts "", "DRAW or empty input please", ""
        retry
      end
    end
  end

  #helper method
  def move_validity_check(move)
    raise ArgumentError if move.size != 4 || !(move[0] =~ /[a-h]/ && move[2] =~ /[a-h]/) || !(move[1] =~ /[1-8]/ && move[3] =~ /[1-8]/)
  end

  #helper method
  def available_moves_check(move, current_position, current_piece)
    generate_moves(current_position)
    if current_piece.available_moves.any? {|mov| mov == translate_move(move[2..3])}
      return translate_move(move[2..3])
    else
      raise ArgumentError
    end
  end

  #meant to be incorporated in move
  def pawn_promotion(move, current)
    if current.piece.class.name == "Board::Pawn"
      if current.piece.color == "white"
        if move[-1].to_i == 8
          promotion_piece = promotion_validity_check

          case promotion_piece
          when "Q"
            current.piece = Queen.new(current, "♕", "white" )
          when "R"
            current.piece= Rook.new(current, "♖", "white")
          when "B"
            current.piece = Bishop.new(current, "♗", "white")
          when "N"
            current.piece = Knight.new(current, "♘", "white")
          end
        end
      end

      if current.piece.color == "black"
        if move[-1].to_i == 1
          promotion_piece = promotion_validity_check

          case promotion_piece
          when "Q"
            current.piece = Queen.new(current, "♛", "black" )
          when "R"
            current.piece= Rook.new(current, "♜", "black")
          when "B"
            current.piece = Bishop.new(current, "♝", "black")
          when "N"
            current.piece = Knight.new(current, "♞", "black")
          end
        end
      end

    end
  end

  #helper method
  def promotion_validity_check
    begin
      puts "Enter Q, R, B or N to promote your pawn: "
      promotion_piece = gets.chomp
      raise ArgumentError unless ["Q", "R", "B", "N"].any?{|piece| piece == promotion_piece}
    rescue
      puts "", "Request INVALID, try again!", ""
      retry
    end
    promotion_piece
  end

  #helper method
  def castle_move(move)
    current_position, future_position = translate_move(move[0..1]), translate_move(move[2..3])
    current = board_accessor(current_position[0], current_position[1])
    future = board_accessor(future_position[0], future_position[1])

    future.piece = current.piece
    current.piece.position = future
    current.piece = ""
  end

  #helper method
  def castling(move, current_piece)
    #king => rook
    castling_moves = {"e1g1" => "h1f1", "e1c1" => "a1d1", "e8g8" => "h8f8", "e8c8" => "a8d8"}
    if current_piece.class.name == "Board::King" && castling_moves.keys.any? {|pot| pot == move}
      castle_move(castling_moves[move])
    end
  end

  def generate_square_coordinates #done
    @board.each_with_index do |row, row_index|
      row.each_with_index do |square, square_index|
        square.coordinates << row_index
        square.coordinates << square_index
      end
    end
  end


  def translate_move(move) #done
    col_mapping = {"a"=>0, "b"=>1, "c"=>2, "d"=>3, "e"=>4, "f"=>5, "g"=>6, "h"=>7}
    if move.is_a? Array
      return [col_mapping.invert[move[1]], move[0]+1].join("")  #[0,0] > a1
    else
      return move[1].to_i-1, col_mapping[move[0]] #"a1" > [0,0]
    end
  end

  def find_king(color)
    king = ""
    @board.each do |row|
      row.each do |square|
        king = square if square.piece != "" && square.piece.class.name == "Board::King" && square.piece.color == color
      end
    end
    king
  end

  #finally finds the king...now onto doing the famous global method
  def check_check
    if player_on_turn == "white" #player one is player on turn
      return true if find_king("white").attacked_by_black == true
    elsif player_on_turn == "black"
      return true if find_king("black").attacked_by_white == true
    end
  end

  #under attack, cant move without entering a check(everything around under attack) AND cant be saved
  def checkmate_check(king_color)
    king_square = find_king(king_color)
    if check_check == true # make a king can/t move method here]
      puts "#{king_color.capitalize} king is under check"

      king_attacker = global_under_attack_check #find attacker
      king_attacker_coordinates = king_attacker.position.coordinates
      king_moves = generate_moves(king_square.coordinates)
      attacker_path = []

      #check if there are pieces that can take the pawn/knight, #if none its a checkmate
      #or just print out available moves unde rcheck and check that if empty >checkmate
      if king_attacker.class.name == "Board::Knight" || king_attacker.class.name == "Board::Pawn"
        attacker_path << king_attacker_coordinates
        #has to be taken #IF KING CANT MOVE
        if king_moves.empty?
          counter_attacks = available_moves_under_check(attacker_path, king_color)
          if counter_attacks.empty?
            return true
          else
            puts "Your available moves are:"
            puts print counter_attacks.map {|move| translate_move(move)}.join(" ")
            #also limit the next move to these somehow
          end
        end
      else
        attacker_path = find_attacker_path(king_square, king_attacker)

        if king_moves.empty?
          counter_attacks = available_moves_under_check(attacker_path, king_color)
          if counter_attacks.empty? && king
            return true
          else
            puts "Your available moves are:"
            puts print counter_attacks.map {|move| translate_move(move)}.join(" ")
          end
        end
      end
    end
  end

  #helper method
  #ONLY FOR WHEN THE KING CANT MOVE
  def available_moves_under_check(attacker_path, king_color)
    counter_attacks = []
    @board.each do |row|
      row.each do |square|
        if square.piece != "" && square.piece.color == king_color
          defend_moves = generate_moves(square.coordinates)
          defend_moves.each do |crds| #coordinates
            counter_attacks << crds if attacker_path.any? {|point| point == crds}
          end
        end
      end
    end
    counter_attacks
  end


  #helper method
  def find_attacker_path(king, king_attacker)
    #90 % of the code repeats from gen_moves_queen, find a way to DRY
    row, col = king.coordinates
    king_attacker_coordinates = king_attacker.position.coordinates
    all_directions = []

    #horizontal
    left = board_accessor(row, 0...col)
    right = board_accessor(row, col+1..8)
    all_directions << left.reverse << right
    potential = []

    #vertical
    top, bottom = [], []
    8.times do |row_index|
      square = board_accessor(row_index, col)
      if row_index < row
        top << square
      elsif row_index > row
        bottom << square
      end
    end
    all_directions << top.reverse << bottom

    #diagonals
    diagonals = [[1,1],[1,-1],[-1,-1],[-1,1]]

    diagonals.each do |direction|
      row_inc, col_inc = direction
      diagonal = []
      while (row+row_inc).between?(0,7) && (col+col_inc).between?(0,7)
        diagonal << board_accessor(row+row_inc, col+col_inc)
        row_inc > 0 ? row_inc+=1 : row_inc-=1 #increases in each counter's specific direction
        col_inc > 0 ? col_inc+=1 : col_inc-=1
      end
      all_directions << diagonal
    end

    all_directions.each do |direction|
      potential = direction if direction.any? {|sqr| sqr.coordinates == king_attacker_coordinates}
    end

    #shaves off unneeded path "behind" the attacker
    until potential[-1].coordinates == king_attacker_coordinates
      potential.pop
    end

    #final path king > attacker
    potential.map{|point| point.coordinates}

  end

  def stalemate_check(king_color)
    king_square = find_king(king_color)
    king_moves = generate_moves(king_square.coordinates)
    global_available_moves = []
    if check_check == false
      if king_moves.empty? # this is not needed as gam checks everything
        @board.each do |row|
          row.each  do |square|
            global_available_moves << generate_moves(square.coordinates) if square.piece != "" && square.piece.color == king_color
          end
        end
      end
    end
    return true if global_available_moves.empty?
  end

  def global_under_attack_check
    #for king check case
    king_attacker = ""
    #first reset the board
    reset_board_attack
    #then set the new situation
    @board.each do |row|
      row.each do |square|
        if square.piece != ""
          under_attack = generate_moves(square.coordinates)
          under_attack.each do |crds| #coordinates
            current_square = board_accessor(crds[0], crds[1])
            current_square.attacked_by_white = true if square.piece.color == "white"
            current_square.attacked_by_black = true if square.piece.color == "black"
            king_attacker = square.piece if current_square.piece.class.name == "Board::King" && current_square.piece.color != square.piece.color
          end
        end
      end
    end
    return king_attacker unless king_attacker == false
  end

  def reset_board_attack
    @board.each do |row|
      row.each do |square|
        square.attacked_by_white = false
        square.attacked_by_black = false
      end
    end
  end


  def generate_moves(figure, attack_check=false) #done
    #ruby i fucking love you
    attack_check = true if caller_locations(1,1)[0].label.split(" ").last == "global_under_attack_check"
    piece = board_accessor(figure[0], figure[1]).piece
    case piece.class.name
    when "Board::King"
      piece.available_moves = generate_moves_king(figure, attack_check)
    when "Board::Queen"
      piece.available_moves = generate_moves_queen(figure, attack_check)
    when "Board::Rook"
      piece.available_moves = generate_moves_rook(figure, attack_check)
    when "Board::Bishop"
      piece.available_moves = generate_moves_bishop(figure, attack_check)
    when "Board::Knight"
      piece.available_moves = generate_moves_knight(figure, attack_check)
    when "Board::Pawn"
      piece.available_moves = generate_moves_pawn(figure, attack_check)
    end
  end


  def generate_moves_king(king, attack_check)
    king = board_accessor(king[0], king[1]).piece
    row, col = king.position.coordinates
    available_moves = []

    king_move_pairs = [[1,0],[1,1],[0,1],[-1,1],[-1,0],[-1,-1],[0,-1],[1,-1]]

    king_move_pairs.each do |pair|
      if ((row+pair[0]).between?(0,7) && (col+pair[1]).between?(0,7))
        board_pos = board_accessor(row+pair[0], col+pair[1])
        if player_on_turn == "white" #more elegant solution for this since they repeat? FIX
          if board_pos.attacked_by_black == false
            if attack_check == true
              available_moves << [row+pair[0], col+pair[1]]
            else
              available_moves << [row+pair[0], col+pair[1]] if board_pos.piece == "" || board_pos.piece.color != king.color
            end
          end
        elsif player_on_turn == "black"
          if board_pos.attacked_by_white == false
            if attack_check == true
              available_moves << [row+pair[0], col+pair[1]]
            else
              available_moves << [row+pair[0], col+pair[1]] if board_pos.piece == "" || board_pos.piece.color != king.color
            end
          end
        end
      end
    end

    #castling
    if king.moved == false
      first_rook = board_accessor(row, 0).piece
      second_rook = board_accessor(row, 7).piece

      [first_rook, second_rook].each do |rook|
        if rook.class.name == "Board::Rook" && rook.moved == false
          path_start = rook.position.coordinates[1].to_i
          path_end = king.position.coordinates[1].to_i

          if path_start > path_end
            path_start, path_end = path_end, path_start
            increment_value = 2 #used in the bottom here
          else
            increment_value = -2 #more elegant way to do this?
          end

          path = @board[row][path_start..path_end]

          if path.first(3).all? { |square| player_on_turn == "white" ? square.attacked_by_black == false : square.attacked_by_white == false }
            if path[1..2].all? {|square| square.piece == ""}
              available_moves << [row, col+increment_value]
            end
          end

        end
      end
    end
    available_moves
  end



  def generate_moves_queen(queen, attack_check)
    queen = board_accessor(queen[0], queen[1]).piece
    row, col = queen.position.coordinates
    available_moves = []
    all_directions = []

    #horizontal
    left = board_accessor(row, 0...col)#@board[row][row.first...col]
    right = board_accessor(row, col+1..8)#@board[row][col+1..row.last]
    all_directions << left.reverse << right

    #vertical
    top, bottom = [], []
    8.times do |row_index|
      square = board_accessor(row_index, col)
      #has to stay like this bc in case of == it shouldn't go anywhere
      if row_index < row
        top << square
      elsif row_index > row
        bottom << square
      end
    end
    all_directions << top.reverse << bottom

    #diagonals
    diagonals = [[1,1],[1,-1],[-1,-1],[-1,1]] #++, +-, -, -+

    diagonals.each do |direction|
      row_inc, col_inc = direction
      diagonal = []
      while (row+row_inc).between?(0,7) && (col+col_inc).between?(0,7)
        diagonal << board_accessor(row+row_inc, col+col_inc)
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
          if attack_check == true
            available_moves << square.coordinates
          else
            available_moves << square.coordinates if square.piece.color != queen.color
          end
          break
        end
      end
    end
    available_moves
  end



  def generate_moves_rook(rook, attack_check)
    rook = board_accessor(rook[0], rook[1]).piece
    row, col = rook.position.coordinates
    available_moves = []

    #horizontal
    left = board_accessor(row, 0...col)
    right = board_accessor(row, col+1..8)

    #vertical
    top, bottom = [], []
    8.times do |row_index|
      square = board_accessor(row_index, col)
      if row_index < row
        top << square
      elsif row_index > row
        bottom << square
      end
    end

    [left.reverse, right, top.reverse, bottom].each do |direction|
      direction.each do |square|
        if square.piece == ""
          available_moves << square.coordinates
        else
          if attack_check == true
            available_moves << square.coordinates
          else
            available_moves << square.coordinates if square.piece.color != rook.color
          end
          break
        end
      end
    end
    available_moves
  end


  def generate_moves_bishop(bishop, attack_check)
    bishop = board_accessor(bishop[0], bishop[1]).piece
    row, col = bishop.position.coordinates
    available_moves = []
    all_directions = []

    directions = [[1,1],[1,-1],[-1,-1],[-1,1]] #++, +-, -, -+

    directions.each do |direction|
      row_inc, col_inc = direction
      diagonal = []
      while (row+row_inc).between?(0,7) && (col+col_inc).between?(0,7)
        diagonal << board_accessor(row+row_inc, col+col_inc)
        row_inc > 0 ? row_inc+=1 : row_inc-=1
        col_inc > 0 ? col_inc+=1 : col_inc-=1
      end
      all_directions << diagonal
    end

    all_directions.each  do |direction|
      direction.each do |square|
        if square.piece == ""
          available_moves << square.coordinates
        else
          if attack_check == true
            available_moves << square.coordinates
          else
            available_moves << square.coordinates if square.piece.color != bishop.color
          end
          break
        end
      end
    end
    available_moves
  end

  def generate_moves_knight(knight, attack_check)
    knight = board_accessor(knight[0], knight[1]).piece
    row, col = knight.position.coordinates
    available_moves = []

    directions = [[-2,1],[-2,-1],[1,2],[-1,2],[2,1],[2,-1],[1,-2],[-1,-2]]

    directions.each do |direction|
      row_inc, col_inc = direction
      if (row+row_inc).between?(0,7) && (col+col_inc).between?(0,7)
        square = board_accessor(row+row_inc, col+col_inc)
        if square.piece == ""
          available_moves << square.coordinates
        else
          if attack_check == true
            available_moves << square.coordinates
          else
            available_moves << square.coordinates if square.piece.color != knight.color
          end
        end
      end
    end
    available_moves
  end



  def generate_moves_pawn(pawn, attack_check)
    pawn = board_accessor(pawn[0], pawn[1]).piece
    row, col = pawn.position.coordinates
    available_moves = []


    move_inc= pawn.color=="white" ? 1 : -1

    #normal move
    if attack_check == false
      available_moves << [row+move_inc, col] if (row+move_inc).between?(0,7) && board_accessor(row+move_inc, col).piece == "" #fix with promotion in mid
      #start position double move
      available_moves << [row+(move_inc*2), col] if pawn.moved == false && board_accessor(row+move_inc, col).piece == "" && board_accessor(row+(move_inc*2), col).piece == ""
    end

    #normal taking
    [1,-1].each do |option|
      if (col+option).between?(0,7)
        pot = board_accessor(row+move_inc, col+option).piece
        available_moves << [row+move_inc, col+option] if pot != "" && pot.color != pawn.color
      end
    end
    #en passant
    [1,-1].each do |option|
      if (col+option).between?(0,7)
        pot = board_accessor(row, col+option).piece
        if pot != "" && pot.class.name == "Board::Pawn"
          available_moves << [row+move_inc, col+option] if pot.color != pawn.color && pot.double_move == false
        end
      end
    end
  available_moves
  end


  def print_board #done
    h_index = 8
    puts ""
    puts "  a b c d e f g h"
    @board.reverse.each do |row|
      puts "#{h_index} #{row.map { |square| square.piece == "" ? "☐" : square.piece.symbol }.join(" ")} #{h_index}"
      h_index -= 1
    end
    puts "  a b c d e f g h"
  end

  def experimental_print_board
    h_index = 8
    puts ""
    puts "  a b c d e f g h"
    @board.reverse.each do |row|
      new_row = []
      new_row << h_index
       h_index % 2 == 0 ? start_white = false : start_white = true

      row.each do |square|
        if square.piece == ""
          start_white == true ? new_row << "■" : new_row << "□"
        else
          new_row << square.piece.symbol
        end
        start_white == true ? start_white = false : start_white = true
      end

      new_row << h_index
      h_index -= 1
      puts new_row.join(" ")
    end
    puts "  a b c d e f g h"
  end


  def initialize_board_with_pieces #done

    #white
    @board[1].each_with_index {|square, ind| @board[1][ind].piece = Pawn.new(square, "♙", "white") }

    @board[0][0].piece = Rook.new(@board[0][0], "♖", "white")
    # = left_rook
    @board[0][7].piece = Rook.new(@board[0][7], "♖", "white")

    @board[0][1].piece = Knight.new(@board[0][1], "♘", "white")
    @board[0][6].piece = Knight.new(@board[0][6], "♘", "white")

    @board[0][2].piece = Bishop.new(@board[0][2], "♗", "white")
    @board[0][5].piece = Bishop.new(@board[0][5], "♗", "white")

    @board[0][3].piece = Queen.new(@board[0][3], "♕", "white" )
    @board[0][4].piece = King.new(@board[0][4], "♔", 'white')

    #black
    @board[6].each_with_index {|square, ind| @board[6][ind].piece = Pawn.new(square,"♟", "black") }

    @board[7][0].piece = Rook.new(@board[7][0], "♜", "black")
    @board[7][7].piece = Rook.new(@board[7][7], "♜", "black")

    @board[7][1].piece = Knight.new(@board[7][1], "♞", "black")
    @board[7][6].piece = Knight.new(@board[7][6], "♞", "black")

    @board[7][2].piece = Bishop.new(@board[7][2], "♝", "black")
    @board[7][5].piece = Bishop.new(@board[7][5], "♝", "black")

    @board[7][3].piece = Queen.new(@board[7][3], "♛", "black" )
    @board[7][4].piece = King.new(@board[7][4], "♚", 'black')
  end
end

board = Board.new
board.generate_square_coordinates
board.initialize_board_with_pieces
board.experimental_print_board
board.global_under_attack_check

50.times do
  board.checkmate_check(board.player_on_turn)
  board.move
  board.experimental_print_board
  #board.switch_players
  board.global_under_attack_check
end
