# This file is dedicated to test the function of the submodule Part_2.jl

using Replication_Monge_et_al_2019
using Test

@testset "Part_2.jl" begin
    
    # Testing the function isin :
    @testset "isin" begin
        @test isin([1,2], [1,2,3]) == [true, true]
        @test isin([1,2,3], [1,2,3]) == [true, true, true]
    end

    # Testing that we have all the selected countries for the samples of 76 and 79 countries : 
    @testset samples begin
        @test sum(isin(benchmark_76,data_2000[:,"country"])) == 76
        @test sum(isin(benchmark_79,data_2000[:,"country"])) == 79
    end

    # Testing that we get the same Table 1 : (in progress)
    @testset Table_1 begin
       # @test Table_1 == 
       @test 1 == 1
    end
end
