
Bundler.setup
Bundler.require
$:.unshift File.dirname __FILE__

require 'utils/utils'

URL = 'http://www.ine.es/jaxiT3/files/t/es/px/4048.px?nocab=1'
FILENAME = 'national'
YEAR_KEY = 'Año'
QUARTER_KEY = 'Trimestre'
INPUT_ENCODING = 'iso-8859-15'

include CodeForSpain::Utils

file_path = download URL, INPUT_ENCODING

dataset = PCAxis::Dataset.new file_path

periods = dataset.dimension('Periodo')
statuses = dataset.dimension('Relación con la actividad económica')

datapoints = periods.map do |period|
  year, quarter = period.split('T')
  curr_period = { YEAR_KEY => year, QUARTER_KEY => quarter }
  values = dataset.data('Sexo' => 'Ambos sexos', 'Edad' => 'Total', 'Periodo' => period)
  statuses.zip(values).each do |status, value|
    curr_period[status] = (value.to_f * 1000).round
  end
  curr_period
end

data = { data: datapoints }

write_json_file data, FILENAME
write_csv_file ([YEAR_KEY, QUARTER_KEY] + statuses), datapoints, FILENAME
update_datapackage

puts 'DONE!'
