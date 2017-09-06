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

#helper method
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

      pawn_hash.each do |pawn_info|
        puts print "pawn info #{pawn_info}"
        row = pawn_info[0]
        col = pawn_info[1]
        count = pawn_info[2]

        puts row, col, count
        ph = get_pawn_hash
        ph[board_accessor(row, col).piece] = count
      end

    end
  end
  puts "Load successful! Have fun playing!"
  print_board
end

#helper method
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
