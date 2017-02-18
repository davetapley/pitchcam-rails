class DebugRenderChannel < ApplicationCable::Channel
  def subscribed
    stream_for uuid

    config = Configs.instance.get uuid
    VideoChannel.broadcast_to uuid, action: 'ready', config_updated_at: config.updated_at
  end

  def config(data)
    config = Configs.instance.get uuid
    config.attributes = data['new_config']
  end
end
