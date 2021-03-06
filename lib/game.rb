require './lib/player.rb'
require './lib/hand.rb'

class Game
  attr_reader :deck
  attr_accessor :players, :current_bet, :current_player, :cycle, :pot
  
  SUIT_UNI = {:heart => "\u2665", :spade => "\u2660", :diamond => "\u2666", :club => "\u2663"}
  
  def initialize
    @deck = Deck.new
    @players = []
    @pot = 0
    @current_bet = 0
    @current_player = 0
    @cycle = 0
  end
  
  def play_round
    begin
      shuffle_deck
      get_players
      betting_round until betting_round_over? || self.players.length == 1
      raise GameOver if self.players.length == 1
      
      
      self.current_player = 0
      self.players.length.times {|_| swapping_round}
      self.current_player = 0
      
      old_bet_amt = self.current_bet
      self.current_bet = 0
      self.cycle = 0
      betting_round(old_bet_amt) until betting_round_over?(old_bet_amt) || self.players.length == 1
      determine_winner
    rescue GameOver
      determine_winner
    end
  end
  
  def betting_round_over?(old_bet_amt = 0)
    if self.current_bet == 0
      self.cycle == 1
    else
      self.players.all? { |player| player.thrown_in - old_bet_amt == self.current_bet}
    end
      
  end
  
  def betting_round(old_bet_amt = 0)
    thrown_in = self[self.current_player].thrown_in
    betting_round_greeting(old_bet_amt, thrown_in)
    begin
      puts "\n#{self[@current_player].name}, Would you like to call(c), raise(r), or fold(f)?"
    
      case gets.chomp
      when "c"
        self.players[current_player].place_bet(self.current_bet + old_bet_amt - thrown_in)
        self.pot += self.current_bet + old_bet_amt - thrown_in
        self.current_player += 1
      when "r"
        raise_bet
      when "f"
        self.players.delete_at(self.current_player)
      end
    
      if self.current_player == self.players.length
        self.current_player = 0 
        self.cycle += 1
      end
    rescue RuntimeError
      puts "Invalid action, please try again."
      retry
    end    
  end
  
  def betting_round_greeting(old_bet_amt, thrown_in)
    show_hand(self.current_player)
    puts "To call: #{@current_bet + old_bet_amt - thrown_in}"
    puts "Current pot: #{@pot}"
    puts "Current bankroll: #{@players[current_player].bankroll}"
    puts "How much you've bet so far: #{@players[current_player].thrown_in}"
  end
  
  def raise_bet
    puts "How much would you like to raise by?"
    raise_amt = gets.chomp.to_i
    self.players[current_player].place_bet(self.current_bet + raise_amt)
    self.current_bet += raise_amt
    self.pot += self.current_bet
    self.current_player += 1
  end
  
  def swapping_round
    show_hand(self.current_player)
    puts "#{self[self.current_player].name}, Give me the indices of the cards you would like to exchange (up to 3)."
    swaps = gets.chomp.split("").map(&:to_i)
    self.players[self.current_player].hand.discard_and_draw(swaps)
    self.current_player += 1
  end
  
  def determine_winner
    tally = []
    self.players.each do |player|
      tally << player.hand.points
    end
    winner_idx = tally.find_index(tally.max)
    show_hand(winner_idx)
    self.players[winner_idx].add_to_bankroll(self.pot)
    
    puts "#{self.players[winner_idx].name}, you are the winner!"
    puts "New Bankroll: #{self.players[winner_idx].bankroll}"
  end
  
  def show_hand(player)
    system("clear")
    show_hand = self.players[player].hand.cards.map { |card| [card.value, SUIT_UNI[card.suit]] }
    cards_pretty = show_hand.map {|card| card.join("-")}
    p cards_pretty
  end
  
  def get_players
    puts "How many players this round?"
    num_players = gets.chomp.to_i
    init_players(num_players)
  end
  
  def init_players(num)
    num.times do |i|
      puts "Player #{i}: "
      name = gets.chomp
      puts "How much money you got?"
      bankroll = gets.chomp.to_i
      
      self.players << Player.new(name, bankroll, @deck)
    end
  end
  
  def shuffle_deck
    self.deck.cards.shuffle!
  end
  
  def round_over?
    self.players.length == 0
  end
  
  def [](n)
    self.players[n]
  end
  
end

class GameOver < RuntimeError
end

game = Game.new
game.play_round