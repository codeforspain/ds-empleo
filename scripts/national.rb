
Bundler.setup
Bundler.require

require 'open-uri'
require 'csv'

URL = 'http://www.ine.es/jaxiT3/files/t/es/px/4048.px?nocab=1'
FILENAME = 'national'

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
    csv << ["Periodo", "Estadística", "Valor"]
    data.each do |period, stats|
      next if period == :created_at
      stats.each do |stat, value|
        csv << [period, stat, value]
      end
    end
  end
end

file_path = download URL

dataset = PCAxis::Dataset.new file_path

periods = dataset.dimension('Periodo')
statuses = dataset.dimension('Relación con la actividad económica')

data = { created_at: Time.now }
periods.each do |period|
  curr_period = {}
  values = dataset.data('Sexo' => 'Ambos sexos', 'Edad' => 'Total', 'Periodo' => period)
  statuses.zip(values).each do |status, value|
    curr_period[status] = (value.to_f * 1000).round
  end
  data[period] = curr_period
end

write_json_file data
write_csv_file data

puts 'DONE!'
