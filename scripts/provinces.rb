
Bundler.setup
Bundler.require

require 'open-uri'
require 'csv'

URL = 'http://www.ine.es/jaxiT3/files/t/es/px/3988.px?nocab=1'
FILENAME = 'provinces'
YEAR_KEY = 'Año'
QUARTER_KEY = 'Trimestre'
PROVINCE_KEY = 'Provincia'

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

file_path = download URL

dataset = PCAxis::Dataset.new file_path

periods = dataset.dimension('Periodo')
provinces = dataset.dimension('Provincias')
statuses = dataset.dimension('Relación con la actividad económica')

datapoints = provinces.reject{|pr| pr == 'Nacional'}.map do |province|
  periods.map do |period|
    year, quarter = period.split('T')
    curr_period = { YEAR_KEY => year, QUARTER_KEY => quarter, PROVINCE_KEY => province.split(' ')[1] }
    values = dataset.data('Sexo' => 'Ambos sexos', 'Periodo' => period, 'Provincias' => province)
    statuses.zip(values).each do |status, value|
      curr_period[status] = (value.to_f * 1000).round
    end
    curr_period
  end
end.flatten

data = { created_at: Time.now, data: datapoints }

write_json_file data
write_csv_file ([YEAR_KEY, QUARTER_KEY, PROVINCE_KEY] + statuses), datapoints

puts 'DONE!'
