##################################################################
#                                                                #
#  BSD 3-Clause License                                          #
#  Copyright (C) 2012-2019  Iain Staffell  <staffell@gmail.com>  #
#  All rights reserved.                                          #
#                                                                #
##################################################################
####  ###
####  ###
##   ##      RENEWABLES.NINJA
#####       WEBSITE AUTOMATOR
##
#
#
#  MAIN USER FUNCTIONS:
#
#    these contact the renewables.ninja API, perform your simulation
#    and then return the results as a dataframe.  each function 
#    requires the latitude and longitude, and optionally takes other
#    parameters that you can pass to the API such as wind turbine model
#    of solar panel orientation.
#    
#
#    run a simulation for a single wind or solar farm
#    returns a dataframe of timestamps and output values
#       ninja_get_wind = function(lat, lon, ...)
#       ninja_get_solar = function(lat, lon, ...)
#
#    run simulations for a set of wind or solar farms
#    returns a dataframe of timestamps and output values for each farm
#       ninja_aggregate_wind = function(lat, lon, ...)
#       ninja_aggregate_solar = function(lat, lon, ...)
#
#
#
#  OTHER BACKGROUND FUNCTIONS:
#
#    a list holding data about your api requests
#    used to keep track of your usage limits
#       apilog$...
#
#    background functions to build URLs to access the API
#       ninja_build_wind_url = function(lat, lon, ...)
#       ninja_build_solar_url = function(lat, lon, ...)
#
#    background functions to download and process ninja simulations 
#       ninja_get_url = function(url)
#       ninja_aggregate_urls = function(urls)
#
#    background functions that do other stuff
#       cat_flush(...)
#       format_date(...)
#
#



#####
## ##  PRE-REQUISITES
#####

	library(curl)





#####
## ##  FUNCTIONS TO BUILD THE URL FOR API REQUESTS 
#####
	
	# example wind url: https://www.renewables.ninja/api/data/wind?&lat=-37.23&lon=143.05&date_from=2014-01-01&date_to=2014-02-28&capacity=240&dataset=merra2&height=83&turbine=Vestas+V80+2000&format=csv
	ninja_build_wind_url = function(lat, lon, from='2014-01-01', to='2014-12-31', dataset='merra2', capacity=1, height=60, turbine='Vestas+V80+2000', raw='false', format='csv')
	{
		from = format_date(from)
		to = format_date(to)
		paste0('https://www.renewables.ninja/api/data/wind?&lat=', lat, '&lon=', lon, '&date_from=', from, '&date_to=', to, '&capacity=', capacity, '&dataset=', dataset, '&height=', height, '&turbine=', turbine, '&raw=', raw, '&format=', format)
	}


	# example solar url: https://www.renewables.ninja/api/data/pv?lat=45&lon=22&date_from=2014-01-01&date_to=2014-01-31&dataset=merra2&capacity=1&system_loss=0.1&tracking=0&tilt=35&azim=180&raw=false&format=csv
	ninja_build_solar_url = function(lat, lon, from='2014-01-01', to='2014-12-31', dataset='merra2', capacity=1, system_loss=0.1, tracking=0, tilt=35, azim=180, raw='false', format='csv')
	{
		from = format_date(from)
		to = format_date(to)
		paste0('https://www.renewables.ninja/api/data/pv?lat=', lat, '&lon=', lon, '&date_from=', from, '&date_to=', to, '&capacity=', capacity, '&dataset=', dataset, '&system_loss=', system_loss, '&tracking=', tracking, '&tilt=', tilt, '&azim=', azim, '&raw=', raw, '&format=', format)
	}





#####
## ##  FUNCTIONS TO DOWNLOAD A SINGLE REQUEST FROM THE API 
#####

	# download wind or solar power output for a given location
	#
	# pass 'lat' and 'lon', and optionally other api variables
	#
	# returns a data frame with timestamp and power output
	# zero error checking :(
	#
	ninja_get_wind = function(lat, lon, from='2014-01-01', to='2014-12-31', dataset='merra2', capacity=1, height=60, turbine='Vestas+V80+2000', raw='false')
	{
		url = ninja_build_wind_url(lat, lon, from, to, dataset, capacity, height, turbine, raw, 'csv')
		ninja_get_url(url)
	}


	ninja_get_solar = function(lat, lon, from='2014-01-01', to='2014-12-31', dataset='merra2', capacity=1, system_loss=0.1, tracking=0, tilt=35, azim=180, raw='false')
	{
		url = ninja_build_solar_url(lat, lon, from, to, dataset, capacity, system_loss, tracking, tilt, azim, raw, 'csv')
		ninja_get_url(url)
	}



	# behind the scenes - this function contacts the ninja API
	# converts the CSV returned by the ninja into a data.frame
	#
	# it also trackes when you made previous server requests
	# to ensure you don't exceed your API rate limits
	#
	ninja_get_url = function(url)
	{
		# first - check we aren't exceeding our rate limits
		apilog$enforce_rate_limits()

		# make a note of when we made this request
		apilog$request_time <<- c(Sys.time(), apilog$request_time)

		# grab the data as csv
		req = curl(url, handle=h)
		csv = read.csv(req, skip=3, stringsAsFactors=FALSE)

		# convert the time column to POSIX
		csv[ , 1] = as.POSIXct(csv[ , 1], format="%Y-%m-%d %H:%M")

		# return
		csv
	}


	# here's the global object we use to track api requests
	apilog = list()

	# burst speed - how many seconds between individual requests
	apilog$burst_speed = 10

	# hourly_limit - how many requests can be made per hour
	apilog$hourly_limit = 50

	# a function to ensure we stick within these limits
	apilog$enforce_rate_limits = function()
	{
		# first - check we aren't exceeding our rate limit
		if (length(apilog$request_time) >= apilog$hourly_limit)
		{
			repeat
			{
				# get the time since our 50th request
				elapsed = difftime(Sys.time(), apilog$request_time[apilog$hourly_limit], units='secs')

				# we are safe to continue
				if (elapsed > 3600) break

				# approach iain with money to buy a bigger server if you want this rate increasing :)
				cat_flush('The ninja API is limited to', apilog$hourly_limit, 'requests per hour: waiting', 5 * ceiling((3600-elapsed)/5), 'seconds to proceed...')
				Sys.sleep(5)
			}

			cat_flush()

		}

		# second - check we aren't exceeding the burst limit
		elapsed = difftime(Sys.time(), apilog$request_time[1], units='secs')
		if (elapsed < apilog$burst_speed)
		{
			Sys.sleep( apilog$burst_speed - elapsed )
		}
	}

	# a vector saying when we made requests
	apilog$request_time = Sys.time()







#####
## ##  FUNCTIONS TO DOWNLOAD AND AGGREGATE MULTIPLE REQUESTS FROM THE API 
#####

	# download wind or solar power output for multiple locations
	#
	# pass 'lat' and 'lon' as vectors, optionally 'from' and 'to' as single strings, optionally other api variables either as single strings or vectors
	# optionally pass the 'name' to assign each output time series (column names in the returned data)
	#
	# returns a data frame with timestamp and power output
	# limited error checking :|
	#
	ninja_aggregate_wind = function(lat, lon, from='2014-01-01', to='2014-12-31', dataset='merra2', capacity=1, height=60, turbine='Vestas+V80+2000', name=NULL)
	{
		# check our coordinates are of the same length
		if (length(lat) != length(lon))
			stop("Error in ninja_aggregate_wind: lat and lon should be vectors of the same length!\n")

		# check we only want one time span
		if (length(from) != 1 | length(to) != 1)
			stop("Error in ninja_aggregate_wind: from and to should be a single date only!\n")

		# check our other parameters are either single values or one value per coordinate
		length_parms = c(length(dataset), length(capacity), length(height), length(turbine))
		if (!all( length_parms %in% c(1, length(lat)) ))
			stop("Error in ninja_aggregate_wind: farm parameters should either be single values or vectors of the same length as lat and lon!\n")

		# convert all our parameters to api request urls
		urls = ninja_build_wind_url(lat, lon, from, to, dataset, capacity, height, turbine)

		# do the magic
		ninja_aggregate_urls(urls, name)
	}


	ninja_aggregate_solar = function(lat, lon, from='2014-01-01', to='2014-12-31', dataset='merra2', capacity=1, system_loss=10, tracking=0, tilt=35, azim=180, name=NULL)
	{
		# check our coordinates are of the same length
		if (length(lat) != length(lon))
			stop("Error in ninja_aggregate_solar: lat and lon should be vectors of the same length!\n")

		# check we only want one time span
		if (length(from) != 1 | length(to) != 1)
			stop("Error in ninja_aggregate_solar: from and to should be a single date only!\n")

		# check our other parameters are either single values or one value per coordinate
		length_parms = c(length(dataset), length(capacity), length(system_loss), length(tracking), length(tilt), length(azim))
		if (!all( length_parms %in% c(1, length(lat)) ))
			stop("Error in ninja_aggregate_solar: farm parameters should either be single values or vectors of the same length as lat and lon!\n")

		# convert all our parameters to api request urls
		urls = ninja_build_solar_url(lat, lon, from, to, dataset, capacity, system_loss, tracking, tilt, azim)

		# do the magic
		ninja_aggregate_urls(urls, name)
	}


	ninja_aggregate_urls = function(urls, name=NULL)
	{
		n = length(urls)

		# if we are passing names for our farms - check there's the right number of them
		if (!is.null(name))
			if (length(name) != n)
				stop("Error in ninja_aggregate_urls: name should be a vector the same length as urls / lat and lon!\n")


		# run through each farm
		for (i in 1:n)
		{
			# i call this UX
			cat_flush("Downloading farm", i, "of", n)

			# grab the data for this farm
			this_farm = ninja_get_url(urls[i])

			# aggregate our data together
			if (i == 1)
				all_farms = data.frame(V1=this_farm[ , 2])

			if (i > 1)
				all_farms[ , i] = this_farm[ , 2]

		}

		# bind the timestamps onto the aggregated data
		all_farms = cbind(this_farm[ , 1], all_farms, stringsAsFactors=FALSE)
		colnames(all_farms)[1] = colnames(this_farm)[1]

		# assign names to the output columns
		if (!is.null(name))
		{
			colnames(all_farms)[-1] = make.names(name)
		} else {
			colnames(all_farms)[-1] = paste0('output', colnames(all_farms)[-1])
		}

		# more UX!
		cat_flush("Downloaded", n, "farms...\n")

		# return
		all_farms
	}







#####
## ##  GENERICS
#####

	# console - clear line and flush line
	cat_flush = function(...)
	{
		cat("\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b")
		cat("\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b")
		cat("\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b")
		cat("\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b")
		cat(...)
		flush.console()
	}

	# convert unknown date formats into standard posix
	# this is overkill, but it allows us to handle 2014-12-31 format
	# that the ninja expects plus 31/12/2014 that Excel defaults to
	#
	# @x - a vector of character dates/datetimes 
	#
	# derived from Cole Beck's "Handling date-times in R" http://biostat.mc.vanderbilt.edu/wiki/pub/Main/ColeBeck/datestimes.pdf
	#
	format_date = function(x)
	{
		x1 = x

		# replace blanks with NA and remove
		x1[x1 == ""] = NA
		x1 = x1[!is.na(x1)]
		if (length(x1) == 0)
		return(NA)

		# if it's already a time variable, set it to character
		if ("POSIXt" %in% class(x1[1]))
			x1 = as.character(x1)

		dateTimes = do.call(rbind, strsplit(x1, " "))
		
		for (i in ncol(dateTimes))
			dateTimes[dateTimes[, i] == "NA"] = NA

		# assume the time part can be found with a colon
		timePart = which(apply(dateTimes, MARGIN=2, FUN=function(i) { any(grepl(":", i)) } ))

		# everything not in the timePart should be in the datePart
		datePart = setdiff(seq(ncol(dateTimes)), timePart)

		# should have 0 or 1 timeParts and exactly one dateParts
		if (length(timePart) > 1 || length(datePart) != 1)
			stop("Error in format_date: cannot parse your time variable")

		timeFormat = NA

		if (length(timePart))
		{
			# find maximum number of colons in the timePart column
			ncolons = max(nchar(gsub("[^:]", "", na.omit(dateTimes[, timePart]))))

			if (ncolons == 1) {
				timeFormat = "%H:%M"
			} else if (ncolons == 2) {
				timeFormat = "%H:%M:%S"
			} else stop("Error in format_date: timePart should have 1 or 2 colons")
		}

		# remove all non-numeric values
		dates = gsub("[^0-9]", "", na.omit(dateTimes[, datePart]))
		
		# sep is any non-numeric value found, hopefully / or -
		sep = unique(na.omit(substr(gsub("[0-9]", "", dateTimes[, datePart]), 1, 1)))
		if (length(sep) > 1)
			stop("Error in format_date: too many seperators in datePart")
		
		# maximum number of characters found in the date part
		dlen = max(nchar(dates))
		dateFormat = NA
		
		# when six, expect the century to be omitted
		if (dlen == 6)
		{
			if (sum(is.na(as.Date(dates, format = "%y%m%d"))) == 0) {
				dateFormat = paste("%y", "%m", "%d", sep = sep)
			} else if (sum(is.na(as.Date(dates, format = "%d%m%y"))) == 0) {
				dateFormat = paste("%d", "%m", "%y", sep = sep)
			} else stop("Error in format_date: datePart format [six characters] is inconsistent")

		} else if (dlen == 8) {

			if (sum(is.na(as.Date(dates, format = "%Y%m%d"))) == 0) {
				dateFormat = paste("%Y", "%m", "%d", sep = sep)
			} else if (sum(is.na(as.Date(dates, format = "%d%m%Y"))) == 0) {
				dateFormat = paste("%d", "%m", "%Y", sep = sep)
			} else stop("Error in format_date: datePart format [eight characters] is inconsistent")

		} else {

			stop(sprintf("Error in format_date: datePart has unusual length: %s", dlen))
		}

		if (is.na(timeFormat)) 
		{
			format = dateFormat
		} else if (timePart == 1) {
			format = paste(timeFormat, dateFormat)
		} else if (timePart == 2) {
			format = paste(dateFormat, timeFormat)
		} else stop("Error in format_date: cannot parse your time variable")

		x = as.POSIXlt(x, format=format)
		return(format(x))
	}

