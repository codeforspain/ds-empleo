
require 'open-uri'
require 'csv'

module CodeForSpain
  module Utils

    def download(url)
      file = Tempfile.new('px')
      open(file.path, 'wb') do |file|
        file << open(url).read.encode!('utf-8', 'iso-8859-15')
      end
    end

    def write_json_file(data, filename)
      File.open(File.join(File.dirname(__FILE__), '..', '..', 'data', "#{filename}.json"), 'w') do |f|
        f.write JSON.pretty_generate data
      end
    end

    def write_csv_file(headers, data, filename)
      CSV.open(File.join(File.dirname(__FILE__), '..', '..', 'data', "#{filename}.csv"), 'w') do |csv|
        csv << headers
        data.each do |dp|
          csv << headers.map { |k| dp[k] }
        end
      end
    end

    def update_datapackage
      File.open(File.join(File.dirname(__FILE__), '..', '..', 'datapackage.json'), 'a+') do |f|
        f.rewind
        dp = JSON.parse f.read, symbolize_names: true
        dp[:last_updated] = Date.today
        f.truncate 0
        f.write JSON.pretty_generate dp
      end
    end
  end
end
