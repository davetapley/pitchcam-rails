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
  end

  def save
    config = Configs.instance.get uuid
    config.to_disk
  end

  def start_line(data)
    left =  CvPoint.new data['left']['x'], data['left']['y']
    right = CvPoint.new data['right']['x'], data['right']['y']
    frame_width = data['frameWidth']
    frame_height = data['frameHeight']

    config = Configs.instance.get uuid
    config.set_start_line left, right, frame_width, frame_height
    ConfigChannel.broadcast_to uuid, config: config, roi: config.frame_roi
  end
end
