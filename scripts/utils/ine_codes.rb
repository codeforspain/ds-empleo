
module CodeForSpain
  class INECodes

    include Singleton
    include Utils

    AUTONOMOUS_COMMUNITY_CODES_URL = 'https://raw.githubusercontent.com/codeforspain/ds-organizacion-administrativa/master/data/autonomias.json'
    PROVINCE_CODES_URL = 'https://raw.githubusercontent.com/codeforspain/ds-organizacion-administrativa/master/data/provincias.json'

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

    def self.code_for_province(province)
      instance.province_codes[province]
    end

    def province_codes
      @province_codes_cache ||= -> do
        json_file = File.read download PROVINCE_CODES_URL
        json = JSON::parse json_file, symbolize_names: true
        Hash[*json.map { |item| [item[:nombre], item[:provincia_id].to_i]}.flatten]
      end.call
    end
  end
end
