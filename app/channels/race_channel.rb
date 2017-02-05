class RaceChannel < ApplicationCable::Channel
  def subscribed
    stream_for uuid
  end

  def start
    RaceChannel.broadcast_to uuid, 'Starting race'
  end
end
