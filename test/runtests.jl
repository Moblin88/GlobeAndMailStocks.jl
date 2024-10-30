using Test, GlobeAndMailStocks, CSV, Dates, Tables

@testset "queryeod tests" begin
    @testset "default parameters" begin
        result = queryeod("AAPL")
        @test result isa CSV.File
        # Add more tests here based on what you expect the default output to be
    end

    @testset "custom parameters" begin
        result = queryeod(:AAPL, Date(2023, 9):Date(2023, 9)+Month(1), order = Base.Order.Reverse, dividends = false, splits = false)
        @test result isa CSV.File
        close = [189.46, 189.7, 182.91, 177.56, 178.18, 179.36, 176.3, 174.21,
        175.74, 175.01, 177.97, 179.07, 175.49, 173.93, 174.79, 176.08,
        171.96, 170.43, 170.69, 171.21]
        @test result.CLOSE == reverse(close)
    end

    @testset "futures" begin
        result = queryeod("ESH09", Date(2008, 12, 8):Week(1):Date(2009, 1, 5), recordtype=:nearest, aggregatevolume=:total, futuresvolume=:total)
        @test result isa CSV.File
        expected =
        [
            "ESZ08" Date(2008,12,08)  872.25  919.25  829     886     3269325 3301806
            "ESZ08" Date(2008,12,15)  883.5   919.25  857.25  881.25  2670205 3198151
            "ESH09" Date(2008,12,22)  884.25  891.5   852.75  869     654226  2287816
            "ESH09" Date(2008,12,29)  869     932.75  853.25  925.5   853185  2344054
        ]
        @test Tables.matrix(result)[begin:end-1, :] == expected
    end
end