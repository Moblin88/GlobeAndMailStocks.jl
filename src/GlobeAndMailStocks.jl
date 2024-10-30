module GlobeAndMailStocks

import HTTP, CSV

using Dates

export queryeod

const api_date_format = dateformat"yyyymmdd"
format_date(date::Date) = Dates.format(date, api_date_format)
format_date(date::Any) = date
format_date(date::AbstractString) = Dates.format(Date(date),api_date_format)

const frequency_periods = Base.ImmutableDict(
    Base.ImmutableDict{DatePeriod, String}(),
    Day(1) => "daily",
    Week(1) => "weekly",
    Month(1) => "monthly",
    Quarter(1) => "quarterly",
    Year(1) => "yearly"
)


format_data(::Nothing, ::Nothing) = nothing
format_data(::Nothing, recordtype) = string("daily",recordtype)
format_data(frequency, ::Nothing) = format_data(frequency, "")
format_data(frequency, recordtype) = string(get(frequency_periods, frequency, frequency),recordtype)

const order_directions = Base.ImmutableDict(
    Base.ImmutableDict{Base.Order.Ordering, String}(),
    Base.Order.Forward => "asc",
    Base.Order.Reverse => "desc"
)
format_order(order) = get(order_directions, order, order)

format_volume(::Nothing, ::Nothing) = nothing
format_volume(::Nothing, futuresvolume) = futuresvolume
format_volume(aggregatevolume, ::Nothing) = format_volume(aggregatevolume,"")
format_volume(aggregatevolume, futuresvolume) = string(string(aggregatevolume) == "mean" ? nothing : aggregatevolume, futuresvolume)

"""
    queryeod(symbol[, daterange]; <keyword arguments>)

Query end-of-day (EOD) data for a given stock symbol from the Globe and Mail Stocks API.

# Arguments
- `symbol`: The stock symbol to query.
- `daterange`: A range of dates to query. Defaults to `nothing`. If provided, the `startdate`, `enddate`, and `frequency` parameters will default to the first date, last date, and step size of the range, respectively. Use `typemin(Date)` and `typemax(Date)` to query all available data.
- `startdate`: The start date of the range to query. Defaults to the first date in `daterange`.
- `enddate`: The end date of the range to query. Defaults to the last date in `daterange`.
- `frequency`: The frequency of the data to query. Defaults to the step size of `daterange`. Can be one of the following: `nothing`, `Day(1)`, `Week(1)`, `Month(1)`, `Quarter(1)`, `Year(1)`, `:daily`, `:weekly`, `:monthly`, `:quarterly`, `:yearly`.
- `maxrecords`: The maximum number of records to return. Defaults to `nothing`.
- `order`: The order in which to return the records. Defaults to `Base.Order.Forward`. Can be one of the following: `nothing`, `:asc`, `:desc`, `Base.Order.Forward`, `Base.Order.Reverse`.
- `recordtype`: The type of records to return. Defaults to `nothing`. Can be one of the following: `nothing`, `:continue`, `:nearest`.
- `contractroll`: The contract roll method to use. Defaults to `:expiration`. Can be one of the following: `:expiration`, `:combined`, `nothing`.
- `volume`: The volume calculation method to use. Defaults to `:sum`. Can be one of the following: `:contract`, `:total`, `:sumcontact`, `:sumtotal`, `:sum`, `nothing`.
- `dividends`: Whether to adjust for dividends. Defaults to `true`. Can be `true` or `false`.
- `splits`: Whether to adjust for splits. Defaults to `true`. Can be `true` or `false`.
- `nearby`: The number of nearby contracts to include. Defaults to `1`. Can be any positive integer.
- `daystoexpiration`: The number of days to expiration to include. Defaults to `1`. Can be any positive integer.
- `backadjust`: Whether to back-adjust the data. Defaults to `false`. Can be `true` or `false`.

# Returns
Returns a `CSV.File` object with the queried EOD data from [CSV.jl](https://github.com/JuliaData/CSV.jl)

# Examples
```julia
csv_file = queryeod("AAPL", Date(2020, 1, 1):Day(1):Date(2020, 12, 31))  # daily data
csv_file = queryeod("AAPL", Date(2020, 1, 1):Month(1):Date(2020, 12, 31))  # monthly data
```
# Reference
For more information about the underlying API, please refer to the [Barchart OnDemand API documentation](https://www.barchart.com/solutions/client/web-services/historical/eod).
"""
function queryeod( 
    symbol,
    daterange = nothing;
    startdate = isnothing(daterange) ? nothing : first(daterange), 
    enddate = isnothing(daterange) ? nothing : last(daterange),
    frequency = isnothing(daterange) ? nothing : step(daterange),
    maxrecords = nothing, 
    order = Base.Order.Forward, 
    recordtype = nothing, 
    contractroll = :expiration,
    futuresvolume = nothing,
    aggregatevolume = :sum, 
    dividends = true, 
    splits = true, 
    nearby = 1, 
    daystoexpiration=1, 
    backadjust=false)
    
    url = "https://globeandmail.pl.barchart.com/proxies/timeseries/queryeod.ashx"
    q = (
        "symbol" => symbol,
        "start" => format_date(startdate),
        "end" => format_date(enddate),
        "maxrecords" => maxrecords,
        "order" => format_order(order),
        "data" => format_data(frequency, recordtype),
        "contractroll" => contractroll,
        "volume" => format_volume(aggregatevolume, futuresvolume),
        "dividends" => dividends,
        "splits" => splits,
        "nearby" => nearby,
        "daystoexpiration" => daystoexpiration,
        "backadjust" => backadjust
    )
    resp = HTTP.get(url, query=(k => string(v) for (k, v) in q if !isnothing(v)))
    headers = ["SYMBOL","YYYY-MM-DD","OPEN","HIGH","LOW","CLOSE","VOLUME", "OPENINTEREST"]
    # warnings are silenced since OPENINTEREST is optional
    return CSV.File(resp.body, header=headers, silencewarnings=true)
end

end