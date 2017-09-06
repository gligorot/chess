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

def translate_move(move) #done
  col_mapping = {"a"=>0, "b"=>1, "c"=>2, "d"=>3, "e"=>4, "f"=>5, "g"=>6, "h"=>7}
  if move.is_a? Array
    return [col_mapping.invert[move[1]], move[0]+1].join("")  #[0,0] > a1
  else
    return move[1].to_i-1, col_mapping[move[0]] #"a1" > [0,0]
  end
end
