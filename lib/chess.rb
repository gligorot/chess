require 'csv'

class Board
  attr_accessor :player_one, :player_two, :board, :pawn_hash

  def initialize(player_one="white", player_two="black")
    @player_one = player_one
    @player_two = player_two

    @board = Array.new(8){Array.new(8){Square.new}}
    @pawn_hash = Hash.new
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

  def get_pawn_hash #done
    @pawn_hash
  end

  def switch_players #done
    @player_one, @player_two = @player_two, @player_one
  end

  def move(color_on_turn)
    begin
      puts "It's #{color_on_turn.upcase}'s turn!"
      puts "Insert location of piece and where you want it to move: (ex a2a4)"
      puts "Alternatively insert DRAW, SAVE or LOAD"
      move = gets.chomp
      save_load_check(move)
      draw_offer_check(move) #find a way to stop it later FIX/problem alert
      move_validity_check(move) #potential error #1
      move_color_check(move, color_on_turn)

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
    double_move_setter(move, current)

    #future square
    future = board_accessor(future_position[0], future_position[1])

    #in case of en passant do this then the rest
    en_passant_case(current, future, current_position, future_position)

    future.piece = current.piece
    current.piece.position = future
    current.piece = ""
    future.piece.moved = true
  end

  #helper method
  def save_load_check(move)
    if move == "SAVE"
      save_game
    elsif move == "LOAD"
      load_game
    end
  end

  def save_game
    save_name = save_name_and_legitimacy
    time = Time.now

    CSV.open("/home/bategjorgija/the_odin_project/chess/saves.csv", 'a') do |save_file|
      #board
      board_string = ""
      @board.each do |row|
        row =  row.map {|square| square.piece == "" ? "_" : square.piece.symbol}.join("")
        board_string << row
      end
      puts "brd string done"

      #moved
      moved_string = ""
      @board.each do |row|
        row_str = ""
        row.each do |square|
          if square.piece == ""
            row_str << "_"
          else
            if square.piece.moved == true
              row_str << "T"
            else
              row_str << "F"
            end
          end
        end
        moved_string << row_str
      end
      puts "moved string done"

      #double move
      double_move_string = ""
      @board.each do |row|
        row_str = ""
        row.each do |square|
          if square.piece.class.name == "Board::Pawn"
            if square.piece.double_move == true
              row_str << "T"
            else
              row_str << "F"
            end
          else
            row_str << "_"
          end
        end
        double_move_string << row_str
      end

      #pawn hash
      ph_string = ""
      @pawn_hash.each do |k,v|
        k.position.coordinates.each {|crd| ph_string << crd }
        ph_string << v
      end
      save_file << [time, save_name, @player_one, @player_two, board_string, moved_string, double_move_string, ph_string]
    end
    puts "Save successful!"
  end

  #helper
  def save_name_and_legitimacy
    begin
      puts "Enter a name for your save file:"
      save_name = gets.chomp

      save_file = CSV.read "/home/bategjorgija/the_odin_project/chess/saves.csv", headers: true, header_converters: :symbol

      save_file.each do |save_instance|
        raise ArgumentError if save_instance[:savename] == save_name
      end
    rescue
      puts "A file with that name already exists, please use another name"
      retry
    end
    save_name
  end

  def load_game
    save_file = print_available
    save_name = load_legitimacy(save_file)

    save_file.each do |row|
      if row[:savename] == save_name
        puts "Loading save with name: #{row[:savename]}, made on date: #{row[:date]}"

        @player_one = row[:player_one]
        @player_two = row[:player_two]

        rows = row[:board_string].scan(/.{8}/)
        moved = row[:moved_string].scan(/.{8}/)
        double_move = row[:double_move_string].scan(/.{8}/)
        pawn_hash = row[:ph_string].scan(/.{3}/)


        8.times do |row_index|
          8.times do |col_index|
            square = board_accessor(row_index, col_index)
            square.piece = symbol_transcribe(rows[row_index][col_index], square)
            square.piece.moved = status_translate(moved[row_index][col_index]) if square.piece != ""
            square.piece.double_move = status_translate(double_move[row_index][col_index]) if square.piece.class.name == "Board::Pawn"
          end
        end

        #stopped working below, whatever

        puts "Load successful! Have fun playing!"
        print_board

        pawn_hash.each do |pawn_info|
          row = pawn_info[0]
          col = pawn_info[1]
          count = pawn_info[2]

          ph = get_pawn_hash
          ph[board_accessor(row, col).piece] = count
        end
      end
    end
  end

  def symbol_transcribe(symbol, square)
    if symbol == "_"
      return ""
    else
      case symbol
      #WHITE
      when "♙"
        Pawn.new(square, "♙", "white")
      when "♘"
        Knight.new(square, "♘", "white")
      when "♗"
        Bishop.new(square, "♗", "white")
      when "♖"
        Rook.new(square, "♖", "white")
      when "♕"
        Queen.new(square, "♕", "white")
      when "♔"
        King.new(square, "♔", "white")
      #BLACK
      when "♟"
        Pawn.new(square,"♟", "black")
      when "♞"
        Knight.new(square, "♞", "black")
      when "♝"
        Bishop.new(square, "♝", "black")
      when "♜"
        Rook.new(square, "♜", "black")
      when "♛"
        Queen.new(square, "♛", "black" )
      when "♚"
        King.new(square, "♚", 'black')
      end
    end
  end

  #helper method
  def status_translate(status)
    if status == "F"
      return false
    elsif status == "T"
      return true
    end
  end

  #helper method
  def print_available
    puts "You've chosen to load a save file!"
    puts "Printing available save files..."
    save_file = CSV.read "/home/bategjorgija/the_odin_project/chess/saves.csv", headers: true, header_converters: :symbol

    save_file.each do |save|
      puts print save[:date], "|", save[:savename]
    end
    save_file
  end

  #helper method
  def load_legitimacy(save_file)
    begin
      puts "Insert the exact name of the file you wish to load:"
      name = gets.chomp

      raise ArgumentError unless save_file.any? {|row| row[:savename] == name}
    rescue
      puts "A save with that name doesn't exist, try again"
      retry
    end
    name
  end

  #helper method
  def draw_offer_check(draw_offer)
    if draw_offer == "DRAW"
      begin
        puts "You have been offered a draw, return DRAW if you accept or an empty input if you don't :"
        draw_answer = gets.chomp
        if draw_answer == "DRAW"
          puts "You have agreed to a draw, the game is over without a winner."
          exit
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
  def move_color_check(move, color_on_turn)
    pos = translate_move(move[0..1])
    sqr = board_accessor(pos[0], pos[1])
    raise ArgumentError if sqr.piece.color != color_on_turn
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
  def double_move_setter(move, current)
    #raise values since a move has been made
    @pawn_hash.each_key{|key| @pawn_hash[key] += 1}

    #double move = false since it only stays for one move
    @pawn_hash.each do |pawn, moves_since_dbl|
      pawn.double_move = false if moves_since_dbl == 1
    end

    #if a pawn makes a double move it goes into pawn_hash
    if current.piece.class.name == "Board::Pawn" && current.piece.moved == false # moved may be useless
      if (move[1].to_i == 2 && move[3].to_i == 4) || (move[1].to_i == 7 && move[3].to_i == 5)
        current.piece.double_move = true
        @pawn_hash[current.piece] = 0
      end
    end
  end

  #helper method
  def en_passant_case(current, future, current_position, future_position)
    if current.piece.class.name == "Board::Pawn" && future.piece == "" && future_position[1] != current_position[1]
      if current.piece.color == "white"
        #note the -1
        en_passant_square = board_accessor(future_position[0]-1, future_position[1])
        en_passant_square.piece = ""
      elsif current_piece.color == "black"
        #note the +1
        en_passant_square = board_accessor(future_position[0]+1, future_position[1])
        en_passant_square.piece = ""
      end
    end
  end


  #helper method
  def castle_move(move)
    current_position, future_position = translate_move(move[0..1]), translate_move(move[2..3])
    current = board_accessor(current_position[0], current_position[1])
    future = board_accessor(future_position[0], future_position[1])

    future.piece = current.piece
    current.piece.position = future
    current.piece = ""
    future.piece.moved = true
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
    global_under_attack_check
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
        puts print king_moves
        if king_moves.empty?
          counter_attacks = available_moves_under_check(attacker_path, king_color)
          if counter_attacks.empty? #there was a && king here, what did it mean???
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

    @board.each do |row|
      row.each  do |square|
        local = generate_moves(square.coordinates) if square.piece != "" && square.piece.color == king_color
        local.each {|move| global_available_moves<<move } unless local.nil?
      end
    end
    global_under_attack_check
    return true if global_available_moves.empty? && check_check != true && king_moves.empty?
  end

  def global_under_attack_check
    theory = true if caller_locations(1,1)[0].label.split(" ").last == "theoretical_check_screen"
    #for king check case
    king_attacker = ""
    #first reset the board
    reset_board_attack
    #then set the new situation
    @board.each do |row|
      row.each do |square|
        if square.piece != ""
          under_attack = generate_moves(square.coordinates, false, theory)
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


  #helper method
  def reset_board_attack
    @board.each do |row|
      row.each do |square|
        square.attacked_by_white = false
        square.attacked_by_black = false
      end
    end
  end

  #helper method
  def theoretical_check_screen(piece, available_moves)
    row, col = piece.position.coordinates
    current = piece.position
    current_position = [] << row << col
    bad_moves = []

    available_moves.each do |move|
      #this guy is changing every move-VARIABLE
      future = board_accessor(move[0], move[1])
      current_copy = current.piece
      future_copy = future.piece

      #test move
      future.piece = current.piece
      current.piece.position = future
      current.piece = ""

      global_under_attack_check

      bad_moves << move if check_check == true

      #reverse
      current.piece = current_copy
      current.piece.position = current
      future.piece = future_copy
    end
    available_moves - bad_moves
  end


  def generate_moves(figure, attack_check=false, theory=false) #done
    #ruby i fucking love you
    attack_check = true if caller_locations(1,1)[0].label.split(" ").last == "global_under_attack_check"
    piece = board_accessor(figure[0], figure[1]).piece
    case piece.class.name
    when "Board::King"
      piece.available_moves = generate_moves_king(figure, attack_check, theory)
    when "Board::Queen"
      piece.available_moves = generate_moves_queen(figure, attack_check, theory)
    when "Board::Rook"
      piece.available_moves = generate_moves_rook(figure, attack_check, theory)
    when "Board::Bishop"
      piece.available_moves = generate_moves_bishop(figure, attack_check, theory)
    when "Board::Knight"
      piece.available_moves = generate_moves_knight(figure, attack_check, theory)
    when "Board::Pawn"
      piece.available_moves = generate_moves_pawn(figure, attack_check, theory)
    end
  end


  def generate_moves_king(king, attack_check, theory)
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



  def generate_moves_queen(queen, attack_check, theory)
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
    theory == false ? theoretical_check_screen(queen, available_moves) : available_moves
  end



  def generate_moves_rook(rook, attack_check, theory)
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
    theory == false ? theoretical_check_screen(rook, available_moves) : available_moves
  end


  def generate_moves_bishop(bishop, attack_check, theory)
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
    theory == false ? theoretical_check_screen(bishop, available_moves) : available_moves
  end

  def generate_moves_knight(knight, attack_check, theory)
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
    theory == false ? theoretical_check_screen(knight, available_moves) : available_moves
  end



  def generate_moves_pawn(pawn, attack_check, theory)
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
          available_moves << [row+move_inc, col+option] if pot.color != pawn.color && pot.double_move == true
        end
      end
    end
    theory == false ? theoretical_check_screen(pawn, available_moves) : available_moves
  end


  def OLD_print_board #done
    h_index = 8
    puts ""
    puts "  a b c d e f g h"
    @board.reverse.each do |row|
      puts "#{h_index} #{row.map { |square| square.piece == "" ? "☐" : square.piece.symbol }.join(" ")} #{h_index}"
      h_index -= 1
    end
    puts "  a b c d e f g h"
  end

  def print_board
    h_index = 8
    puts ""
    puts "  a b c d e f g h"
    @board.reverse.each do |row|
      new_row = []

       h_index % 2 == 0 ? start_white = false : start_white = true

      row.each do |square|
        if square.piece == ""
          start_white == true ? new_row << "■" : new_row << "□"
        else
          new_row << square.piece.symbol
        end
        start_white == true ? start_white = false : start_white = true
      end

      puts new_row.unshift(h_index).push(h_index).join(" ")
      h_index -= 1
    end
    puts "  a b c d e f g h"
  end

  #for testing different scenarios
  def test_init
    #@board[0][5].piece = Bishop.new(@board[0][5], "♗", "white")
    @board[0][4].piece = King.new(@board[0][4], "♔", 'white')

    @board[7][4].piece = Queen.new(@board[7][4], "♛", "black" )
    @board[7][3].piece = Rook.new(@board[7][3], "♜", "black")
    @board[7][5].piece = Rook.new(@board[7][5], "♜", "black")
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

  def play
    generate_square_coordinates
    initialize_board_with_pieces
    print_board

    while true
      global_under_attack_check

      if stalemate_check(player_on_turn) == true
        puts "STALEMATE"
        return
      end

      if checkmate_check(player_on_turn) == true
        puts "CHECKMATE"
        return
      end


      move(player_on_turn)
      print_board
      switch_players
    end
  end
end

board = Board.new
board.play


#DONE MOTHER FUCKERRRRRR
