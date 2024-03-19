import csv
import pandas as pd
from pathlib import Path
import requests


#####
## ##  FUNCTIONS TO BUILD THE URL FOR API REQUESTS 
#####
	
# example wind url: https://www.renewables.ninja/api/data/wind?&lat=-37.23&lon=143.05&date_from=2014-01-01&date_to=2014-02-28&capacity=240&dataset=merra2&height=83&turbine=Vestas+V80+2000&format=csv
def ninja_build_wind_url(lat, lon, start_date='2019-01-01', end_date='2019-12-31', dataset='merra2', 
                         capacity=1, height=60, turbine='Vestas+V80+2000', raw='false', format='csv'):
		return f'https://www.renewables.ninja/api/data/wind?&lat={lat}&lon={lon}&date_from={start_date}\
            &date_to={end_date}&capacity={capacity}&dataset={dataset}&height={height}&turbine={turbine}&raw={raw}&format={format}'.replace(" ", "")

# example solar url: https://www.renewables.ninja/api/data/pv?lat=45&lon=22&date_from=2014-01-01&date_to=2014-01-31&dataset=merra2&capacity=1&system_loss=0.1&tracking=0&tilt=35&azim=180&raw=false&format=csv
def ninja_build_solar_url(lat, lon, start_date='2019-01-01', end_date='2019-12-31', dataset='merra2', 
                          capacity=1, system_loss=0.1, tracking=0, tilt=35, azim=180, raw='false', format='csv'):
		return f'https://www.renewables.ninja/api/data/pv?&lat={lat}&lon={lon}&date_from={start_date}\
            &date_to={end_date}&capacity={capacity}&dataset={dataset}&system_loss={system_loss}&tracking={tracking}&raw={raw}&tilt={tilt}&azim={azim}&format={format}'.replace(" ", "")

#####
## ##  FUNCTIONS TO DOWNLOAD A SINGLE REQUEST FROM THE API 
#####

# download wind or solar power output for a given location
#
# pass 'lat' and 'lon', and optionally other api variables
#
# pass naming, and directory for output file(s)
#
# returns a data frame with timestamp and power output
#

def ninja_download_wind_csv(lat, lon, output_dir, output_naming, token, start_date='2019-01-01', end_date='2019-12-31'):
    with requests.Session() as s:
        headers = {'Authorization': 'Token ' + token}
        download = s.get(ninja_build_wind_url(lat, lon, start_date, end_date), headers=headers)
        decoded_content = download.content.decode('utf-8')
        cr = csv.reader(decoded_content.splitlines(), delimiter=',')
        ninja_wind_df = pd.DataFrame(list(cr))
        ninja_wind_df.to_csv(Path(output_dir) / f"ninja_wind_{output_naming}.csv", index=False)

        return ninja_wind_df
            
def ninja_download_solar_csv(lat, lon, output_dir, output_naming, token, start_date='2019-01-01', end_date='2019-12-31'):
    with requests.Session() as s:
        headers = {'Authorization': 'Token ' + token}
        download = s.get(ninja_build_solar_url(lat, lon, start_date, end_date), headers=headers)
        decoded_content = download.content.decode('utf-8')
        cr = csv.reader(decoded_content.splitlines(), delimiter=',')
        ninja_solar_df = pd.DataFrame(list(cr))
        ninja_solar_df.to_csv(Path(output_dir) / f"ninja_solar_{output_naming}.csv", index=False)

        return ninja_solar_df