
module CodeForSpain
  class INECodes

    include Singleton
    include Utils

    AUTONOMOUS_COMMUNITY_CODES_URL = 'https://raw.githubusercontent.com/codeforspain/ds-organizacion-administrativa/master/data/autonomias.json'

    def self.code_for_autonomous_community(autonomous_community)
      instance.autonomous_community_codes[autonomous_community]
    end

    def autonomous_community_codes
      @autonomous_community_codes_cache ||= -> do
        json_file = File.read download AUTONOMOUS_COMMUNITY_CODES_URL
        json = JSON::parse json_file, symbolize_names: true
        Hash[*json.map { |item| [item[:nombre], item[:autonomia_id].to_i]}.flatten]
      end.call
    end

  end
end
