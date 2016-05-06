
Bundler.setup
Bundler.require
$:.unshift File.dirname __FILE__

require 'utils/utils'
require 'utils/ine_codes'

URL = 'http://www.ine.es/jaxiT3/files/t/es/px/3988.px?nocab=1'
FILENAME = 'provinces'
YEAR_KEY = 'Año'
QUARTER_KEY = 'Trimestre'
PROVINCE_KEY = 'Provincia'
PROV_INE_CODE_KEY = 'ID Provincia'
INPUT_ENCODING = 'iso-8859-15'

include CodeForSpain::Utils

file_path = download URL, INPUT_ENCODING

dataset = PCAxis::Dataset.new file_path

periods = dataset.dimension('Periodo')
provinces = dataset.dimension('Provincias')
statuses = dataset.dimension('Relación con la actividad económica')

datapoints = provinces.reject{|pr| pr == 'Nacional'}.map do |province|
  prov_name = province.split(' ')[1]
  periods.map do |period|
    year, quarter = period.split('T')
    curr_period = {
      YEAR_KEY => year, QUARTER_KEY => quarter,
      PROVINCE_KEY => prov_name, PROV_INE_CODE_KEY => CodeForSpain::INECodes.code_for_province(prov_name)
    }
    values = dataset.data('Sexo' => 'Ambos sexos', 'Periodo' => period, 'Provincias' => province)
    statuses.zip(values).each do |status, value|
      curr_period[status] = (value.to_f * 1000).round
    end
    curr_period
  end
end.flatten

data = { data: datapoints }

write_json_file data, FILENAME
write_csv_file ([YEAR_KEY, QUARTER_KEY, PROVINCE_KEY, PROV_INE_CODE_KEY] + statuses), datapoints, FILENAME
update_datapackage

puts 'DONE!'
