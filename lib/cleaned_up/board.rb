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

  require_relative "piece.rb"
  require_relative "move.rb"
  require_relative "save_load.rb"
  require_relative "check.rb"
  require_relative "move_generators.rb"


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

  def generate_square_coordinates #done
    @board.each_with_index do |row, row_index|
      row.each_with_index do |square, square_index|
        square.coordinates << row_index
        square.coordinates << square_index
      end
    end
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

puts "THIS ISN'T MEANT TO WORK, ITS JUST SPLITTING CLASSES FOR BREVITY"
puts "THIS ISN'T MEANT TO WORK, ITS JUST SPLITTING CLASSES FOR BREVITY"
puts "THIS ISN'T MEANT TO WORK, ITS JUST SPLITTING CLASSES FOR BREVITY"
puts "THIS ISN'T MEANT TO WORK, ITS JUST SPLITTING CLASSES FOR BREVITY"
puts "THIS ISN'T MEANT TO WORK, ITS JUST SPLITTING CLASSES FOR BREVITY"
puts "THIS ISN'T MEANT TO WORK, ITS JUST SPLITTING CLASSES FOR BREVITY"
puts "THIS ISN'T MEANT TO WORK, ITS JUST SPLITTING CLASSES FOR BREVITY"
puts "THIS ISN'T MEANT TO WORK, ITS JUST SPLITTING CLASSES FOR BREVITY"
board = Board.new
board.play




#DONE MOTHER FUCKERRRRRR
