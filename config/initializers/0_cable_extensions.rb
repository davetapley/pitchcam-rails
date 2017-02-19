module BroadcasterExtensions
  def broadcast(message)
    puts 'broadcast'
    def message.inspect
      Hash[map { |k,v| [k, v.to_s.starts_with?('data:') ? 'data: [SNIP]' : v] }].inspect
    end
    super
  end
end

ActionCable::Server::Broadcasting::Broadcaster.prepend BroadcasterExtensions
