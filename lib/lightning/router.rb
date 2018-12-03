# frozen_string_literal: true

module Lightning
  module Router
    autoload :Announcements, 'lightning/router/announcements'
    autoload :Events, 'lightning/router/events'
    autoload :Messages, 'lightning/router/messages'
    autoload :RouteFinder, 'lightning/router/route_finder'
    autoload :Router, 'lightning/router/router'
    autoload :RouterState, 'lightning/router/router_state'
  end
end
