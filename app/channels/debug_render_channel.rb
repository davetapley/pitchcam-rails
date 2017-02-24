class DebugRenderChannel < ApplicationCable::Channel
  def subscribed
    stream_for uuid
  end
end
