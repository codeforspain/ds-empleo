
Bundler.setup
Bundler.require

require 'open-uri'
require 'csv'

URL = 'http://www.ine.es/jaxiT3/files/t/es/px/3975.px?nocab=1'
FILENAME = 'autonomous_communities'
YEAR_KEY = 'Año'
QUARTER_KEY = 'Trimestre'
AUTONOMOUS_COMMUNITY_KEY = 'Comunidad Autónoma'

def download(url)
  file = Tempfile.new('px')
  open(file.path, 'wb') do |file|
    file << open(url).read.encode!('utf-8', 'iso-8859-15')
  end
end

def write_json_file(data)
  File.open(File.join(File.dirname(__FILE__), '..', 'data', "#{FILENAME}.json"), 'w') do |f|
    f.write JSON.pretty_generate data
  end
end

def write_csv_file(headers, data)
  CSV.open(File.join(File.dirname(__FILE__), '..', 'data', "#{FILENAME}.csv"), 'w') do |csv|
    csv << headers
    data.each do |dp|
      csv << headers.map { |k| dp[k] }
    end
  end
end

def update_datapackage
  File.open(File.join(File.dirname(__FILE__), '..', 'datapackage.json'), 'a+') do |f|
    f.rewind
    dp = JSON.parse f.read, symbolize_names: true
    dp[:last_updated] = Date.today
    f.truncate 0
    f.write JSON.pretty_generate dp
  end
end

file_path = download URL

dataset = PCAxis::Dataset.new file_path

periods = dataset.dimension('Periodo')
cas = dataset.dimension('Comunidades y Ciudades Autónomas')
statuses = dataset.dimension('Relación con la actividad económica')

datapoints = cas.reject{|ca| ca == 'Nacional'}.map do |ca|
  periods.map do |period|
    year, quarter = period.split('T')
    curr_period = { YEAR_KEY => year, QUARTER_KEY => quarter, AUTONOMOUS_COMMUNITY_KEY => ca }
    values = dataset.data('Sexo' => 'Ambos sexos', 'Edad' => 'Total', 'Periodo' => period, 'Comunidades y Ciudades Autónomas' => ca)
    statuses.zip(values).each do |status, value|
      curr_period[status] = (value.to_f * 1000).round
    end
    curr_period
  end
end.flatten
data = { data: datapoints }

write_json_file data
write_csv_file ([YEAR_KEY, QUARTER_KEY, AUTONOMOUS_COMMUNITY_KEY] + statuses), datapoints
update_datapackage

puts 'DONE!'
