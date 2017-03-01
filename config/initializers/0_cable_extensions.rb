module BroadcasterExtensions
  def broadcast(message)
    def message.inspect
      Hash[map do |k,v|
        [k, v.to_s.gsub(/['"]data:[^'"]*/, 'data: [SNIP]' )]
      end].inspect
    end
    super
  end
end

ActionCable::Server::Broadcasting::Broadcaster.prepend BroadcasterExtensions
