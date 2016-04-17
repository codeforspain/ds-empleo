
Bundler.setup
Bundler.require

require 'open-uri'
require 'csv'

URL = 'http://www.ine.es/jaxiT3/files/t/es/px/3975.px?nocab=1'
FILENAME = 'autonomous_communities'

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
    csv << ["Comunidad Autónoma", "Periodo", "Estadística", "Valor"]
    data.each do |ca, periods|
      next if ca == :created_at
      periods.each do |period, stats|
        stats.each do |stat, value|
          csv << [ca, period, stat, value]
        end
      end
    end
  end
end

file_path = download URL

dataset = PCAxis::Dataset.new file_path

periods = dataset.dimension('Periodo')
cas = dataset.dimension('Comunidades y Ciudades Autónomas')
statuses = dataset.dimension('Relación con la actividad económica')

data = { created_at: Time.now }
cas[0..-2].each do |ca|
  curr_ca = {}
  periods.each do |period|
    curr_period = {}
    values = dataset.data('Sexo' => 'Ambos sexos', 'Edad' => 'Total', 'Periodo' => period, 'Comunidades y Ciudades Autónomas' => ca)
    statuses.zip(values).each do |status, value|
      curr_period[status] = (value.to_f * 1000).round
    end
    curr_ca[period] = curr_period
  end
  data[ca] = curr_ca
end

write_json_file data
write_csv_file data

puts 'DONE!'
