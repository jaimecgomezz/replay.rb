require 'httparty'

module HTTParty
  class Parser
    protected

    def json
      JSON.parse(body, quirks_mode: true, allow_nan: true, symbolize_names: true)
    end
  end
end

module Replay
  class Context
    module Requester
      def http(method, uri, options = {})
        raise(ArgumentError, "Invalid HTTP method: #{method}") unless HTTParty.respond_to?(method)

        response = HTTParty.send(method, uri, options)

        return response unless block_given?

        yield(response)
      end
    end
  end
end
