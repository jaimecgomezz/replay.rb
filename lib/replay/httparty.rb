require 'httparty'

module HTTParty
  class Parser
    protected

    def json
      JSON.parse(body, quirks_mode: true, allow_nan: true, symbolize_names: true)
    end
  end
end
