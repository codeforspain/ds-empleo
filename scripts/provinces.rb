
Bundler.setup
Bundler.require

require 'open-uri'
require 'csv'

URL = 'http://www.ine.es/jaxiT3/files/t/es/px/3988.px?nocab=1'
FILENAME = 'provinces'

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
    csv << ["Provincia", "Periodo", "Estadística", "Valor"]
    data.each do |province, periods|
      next if province == :created_at
      periods.each do |period, stats|
        stats.each do |stat, value|
          csv << [province, period, stat, value]
        end
      end
    end
  end
end

file_path = download URL

dataset = PCAxis::Dataset.new file_path

periods = dataset.dimension('Periodo')
provinces = dataset.dimension('Provincias')
statuses = dataset.dimension('Relación con la actividad económica')

data = { created_at: Time.now }
provinces[1..-1].each do |province|
  curr_province = {}
  periods.each do |period|
    curr_period = {}
    values = dataset.data('Sexo' => 'Ambos sexos', 'Periodo' => period, 'Provincias' => province)
    statuses.zip(values).each do |status, value|
      curr_period[status] = (value.to_f * 1000).round
    end
    curr_province[period] = curr_period
  end
  data[province.split(' ')[1]] = curr_province
end

write_json_file data
write_csv_file data

puts 'DONE!'
