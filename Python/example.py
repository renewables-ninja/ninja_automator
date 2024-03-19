import time
from ninja_automator import ninja_download_wind_csv

#####
## ##  DOWNLOAD RENEWABLE TIME SERIES DATA FOR MULTIPLE LOCATIONS
#####

# downloading data for a single loaction would be the same, but with calling either of wind or solar functions for a single location
# location_df in this example would be like:
# locations_df = pd.DataFrame({'lat': [-37.23, -37.23, -37.23, -37.23, -37.23],
#                              'lon': [143.05, 143.05, 143.05, 143.05, 143.05]})
#                           'name': ['location1', 'location2', 'location3', 'location4', 'location5']})

i = 0
for index, row in locations_df.iterrows():
    if i < 50:
        ninja_download_wind_csv(lat = row['lat'], lon = row['lon'], out_dir = 'ninja_wind', out_naming = row['name'], token = 'your_token_here')
        time.sleep(10)
        i += 1
    else:
        print('Sleeping for an hour')
        time.sleep(3600)
        i = 0