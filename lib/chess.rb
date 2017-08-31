class Board
  attr_accessor :board, :player_one, :player_two

  def initialize(player_one="White", player_two="Black")
    @player_one = player_one
    @player_two = player_two

    @board = Array.new(8){Array.new(8){Square.new}}
  end

  class Square
    attr_accessor :position, :piece, :under_attack

    def initialize(position="", piece="")
      @position = position
      @piece = piece
      @under_attack = false
    end
  end

  class Piece
    attr_accessor :position, :symbol, :color

    def initialize(position, symbol, color)
      @position = position
      @symbol = symbol
      @color = color
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

  def generate_square_coordinates
    @board.each_with_index do |row, row_index|
      row.each_with_index do |square, square_index|
        square.position << row_index
        square.position << square_index
      end
    end
  end
end

board = Board.new
board.print_board
