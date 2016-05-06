
Bundler.setup
Bundler.require
$:.unshift File.dirname __FILE__

require 'utils/utils'

URL = 'http://www.ine.es/jaxiT3/files/t/es/px/3975.px?nocab=1'
FILENAME = 'autonomous_communities'
YEAR_KEY = 'Año'
QUARTER_KEY = 'Trimestre'
AUTONOMOUS_COMMUNITY_KEY = 'Comunidad Autónoma'

include CodeForSpain::Utils

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

write_json_file data, FILENAME
write_csv_file ([YEAR_KEY, QUARTER_KEY, AUTONOMOUS_COMMUNITY_KEY] + statuses), datapoints, FILENAME
update_datapackage

puts 'DONE!'
