# Script to download and parse national (un)employment statistics
# Output will be a JSON file.

Bundler.setup
Bundler.require

require 'open-uri'
require 'csv'

URL_ACTIVOS = 'http://www.ine.es/jaxiT3/files/t/es/px/4204.px?nocab=1'
URL_OCUPADOS = 'http://www.ine.es/jaxiT3/files/t/es/px/4211.px?nocab=1'
URL_PARADOS = 'http://www.ine.es/jaxiT3/files/t/es/px/4245.px?nocab=1'
URL_INACTIVOS = 'http://www.ine.es/jaxiT3/files/t/es/px/4255.px?nocab=1'
FILENAME = 'ca_latest'

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
    csv << ["Comunidad Autónoma", "Estadística", "Valor"]
    data.each do |ca, stats|
      next if ca == :created_at
      stats.each do |stat, value|
        csv << [ca, stat, value]
      end
    end
  end
end

def parse(url)
  file_path = download url

  dataset = PCAxis::Dataset.new file_path

  period = dataset.dimension('Periodo').first
  cas = dataset.dimension("Comunidades y Ciudades Autónomas")
  values = dataset.data('Edad' => 'Total', 'Sexo' => 'Ambos sexos', 'Periodo' => period)
  data = []
  cas.zip(values).each do |c, v|
    data << c
    data << v.to_f
  end
  Hash[*data]
end

data = { created_at: Time.now }
{ 'activos' => URL_ACTIVOS,
  'ocupados' => URL_OCUPADOS,
  'parados' => URL_PARADOS,
  'inactivos' => URL_INACTIVOS }.each do |label, url|
  parse(url).each do |cas, value|
    (data[cas] ||= {})[label] = value
  end
end

write_json_file data
write_csv_file data

puts 'DONE!'
