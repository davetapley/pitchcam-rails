class RaceChannel < ApplicationCable::Channel
  def start
    puts Time.current
  end
end
