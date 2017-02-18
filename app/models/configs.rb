class Configs
  include Singleton

  def initialize
    @configs = Hash.new {|h, k| h[k] = Config.new }
  end

  def get(uuid)
    @configs[uuid]
  end
end
