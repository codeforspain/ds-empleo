# Script to download and parse national (un)employment statistics
# Output will be a JSON file.

Bundler.setup
Bundler.require

require 'open-uri'
require 'csv'

URL_ACTIVOS = 'http://www.ine.es/jaxiT3/files/t/es/px/4049.px?nocab=1'
URL_OCUPADOS = 'http://www.ine.es/jaxiT3/files/t/es/px/4076.px?nocab=1'
URL_PARADOS = 'http://www.ine.es/jaxiT3/files/t/es/px/4084.px?nocab=1'
URL_INACTIVOS = 'http://www.ine.es/jaxiT3/files/t/es/px/4134.px?nocab=1'
FILENAME = 'latest'

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

def write_csv_file(data)
  CSV.open(File.join(File.dirname(__FILE__), '..', 'data', "#{FILENAME}.csv"), 'w') do |csv|
    csv << %w(statistic value)
    data.each do |k, v|
      csv << [k, v]
    end
  end
end

def parse(url)
  file_path = download url

  dataset = PCAxis::Dataset.new file_path

  period = dataset.dimension('Periodo').first
  dataset.data('Edad' => 'Total', 'Sexo' => 'Ambos sexos', 'Unidad' => 'Valor absoluto', 'Periodo' => period).to_f
end

data = { 'created_at' => Time.now }
{ 'activos' => URL_ACTIVOS,
  'ocupados' => URL_OCUPADOS,
  'parados' => URL_PARADOS,
  'inactivos' => URL_INACTIVOS }.each do |label, url|
  data[label] = parse url
end

write_json_file data
write_csv_file data

puts 'DONE!'
