module ApplicationCable
  class Channel < ActionCable::Channel::Base
    def action_signature(action, data)
      "#{self.class.name}##{action}".tap do |signature|
        if (arguments = data.except('action')).any?
          signature << "(#{arguments.keys})"
        end
      end
    end
  end
end
