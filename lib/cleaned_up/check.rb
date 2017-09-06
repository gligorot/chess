
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
def find_king(color)
  king = ""
  @board.each do |row|
    row.each do |square|
      king = square if square.piece != "" && square.piece.class.name == "Board::King" && square.piece.color == color
    end
  end
  king
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
