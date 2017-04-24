class CarTrackerChannel < ApplicationCable::Channel
  def subscribed
    stream_for uuid
    config = Configs.instance.get uuid
    cars = config.car_trackers.keys
    cars.each do |car|
      CarTrackerChannel.broadcast_to uuid, action: 'addCar', name: car.name
    end
  end

  def reset
    config = Configs.instance.get uuid
    config.reset_car_trackers!
  end
end
