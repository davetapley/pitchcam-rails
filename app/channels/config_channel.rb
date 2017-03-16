class ConfigChannel < ApplicationCable::Channel
  def subscribed
    stream_for uuid
  end

  def get
    config = Configs.instance.get uuid
    ConfigChannel.broadcast_to uuid, config: config
  end

  def update(data)
    config = Configs.instance.get uuid
    config.attributes = data['new_config']
    ConfigChannel.broadcast_to uuid, config: config
  end

  def save
    config = Configs.instance.get uuid
    config.to_disk
  end
end
