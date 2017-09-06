
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
