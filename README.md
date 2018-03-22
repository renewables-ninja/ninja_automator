# The Ninja Automator

This is a multi-langugage tool to scrape data from the [Renewables.ninja](https://www.renewables.ninja/) website.  It allows you to download wind and solar output data for multiple locations more easily.  

Currently there are implementations in Excel and R, with a Python version under development.


## Ninja Automator Excel VBA

This provides a VBA routine to run simulations via the Renewables.ninja API and deliver results into a spreadsheet.  Usage should be self explanatory, read the INFO worksheet to begin.

The Excel worksheet provides an example implementation, which allows the user to choose model parameters, and download data as either hourly values, daily averages or monthly averages.

Tested on [Excel](https://products.office.com/en-gb/excel) 2010, 2013 and 2016 on Windows 7 and 10. 

Requires VBA Macros to be enabled.

<br>


## Ninja Automator R

This provides a set of worked examples that contact the renewables.ninja API, perform your simulation and return the results as a data.frame.  Multiple simulations can be performed by either supplying vectors of input parameters or by reading them in from a CSV file.


### REQUIREMENTS & SETUP

[R](https://www.r-project.org/) or [MRO](https://mran.revolutionanalytics.com/open/) version 3+, with the `curl` library.

Download the files from the /R subfolder and you are ready to go.

Inside `example.r` edit the path names and your API token.


### USAGE INSTRUCTIONS

`ninja_automator.r` provides the background functions for communicating with the Renewables.ninja API.   Each function requires the latitude and longitude, and optionally takes other parameters that you can pass to the API such as wind turbine model or solar panel orientation.

`example.r` provides a set of five ready-made examples that walk you through running a single simulation, aggregating many simulations together, and reading inputs/output files to fully automate the ninja.

The functions `ninja_get_wind(lat, lon, ...)` and `ninja_get_solar(lat, lon, ...)` run a simulation for a single wind or solar farm by passing input parameters.  They will yield a 2-column dataframe containing timestamp and output.  You can expect each to take around 5-10 seconds to complete, due to the time needed to contact the server, the simulation to run, etc.

The functions `ninja_aggregate_wind(lat, lon, ...)` and `ninja_aggregate_solar(lat, lon, ...)` run simulations for multiple wind or solar farms by passing vectors of input data.  These will yield a multi-column dataframe containing timestamp and the output of each farm as a sepearate column.  You can expect the function to take around 10 seconds per farm being simulated.  

All the functions keep track of the number of simulations you have run, and will pause when necessary to prevent you from exceeding the hourly API limits.  If you'd like it to be faster, contact us via the Renewables.ninja [forum](https://community.renewables.ninja/) or [email](https://www.renewables.ninja/about).

`renewables.ninja.solar.farms.csv` and `renewables.ninja.wind.farms.csv` are example input files that can be fed into the automator to download a group of farms.  `renewables.ninja.wind.output.csv` is an example of the data that will be returned by `ninja_aggregate_wind`.

<br>


## LICENSE
BSD 3-Clause License

Copyright (C) 2016-2018 Iain Staffell

All rights reserved.

See `LICENSE` for more detail.



## CREDITS & CONTACT

The R automator is developed by Iain Staffell.  You can try emailing me at contact@renewables.ninja. 

This is part of the [Renewables.ninja](https://renewables.ninja) project, developed by Stefan Pfenninger and Iain Staffell.  Use the [contacts page](https://www.renewables.ninja/about) there.


### Citation

I Staffell and S Pfenninger, 2016.  Using bias-corrected reanalysis to simulate current and future wind power output.  *Energy*, 114, 1224–1239. [doi: 10.1016/j.energy.2016.08.068](https://dx.doi.org/10.1016/j.energy.2016.08.068)

S Pfenninger and I Staffell, 2016. Long-term patterns of European PV output using 30 years of validated hourly reanalysis and satellite data. Energy, 114, 1251-1265.  [doi: 10.1016/j.energy.2016.08.060](https://dx.doi.org/10.1016/j.energy.2016.08.060)
