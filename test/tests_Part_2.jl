# This file is dedicated to test the function of the submodule Part_2.jl

using Replication_Monge_et_al_2019
using Test
using DataFrames

@testset "isin function" begin
    # Testing the function isin :
    @test Replication_Monge_et_al_2019.isin([1,2], [1,2,3]) == [true, true]
    @test Replication_Monge_et_al_2019.isin([1,2,3], [1,2,3]) == [true, true, true]
end

@testset "Results Part 2" begin
    @test 1 == 1
    # Testing that we get the same Table 1 : (in progress)
    # The values obtained by the authors are : 
    # true_variables = ["Natural resources", "Timber", "Subsoil", "Oil", "Gas", "Other", "Cropland", "Pasterland", "Natural resources with urban land", "Observations"]
    # true_means = [8.19, 0.13, 5.44, 4.03, 1.21, 0.28, 2.26, 0.36, 17.7, 79]
    # true_medians = [4.01, 0.00, 0.73, 0.06, 0.1, 0.00, 1.06, 0.17, 14.7, 79]
    # true_cvs = [1.44, 3.76, 2.1, 2.42, 2.44, 2.79, 1.47, 1.53, 0.62, 79]
    # true_correlations = [-0.07, -0.29, 0.17, 0.15, 0.19, -0.21, -0.55, -0.27, -0.1, 79]
    # true_table_1 = DataFrame(   "Variables"                           => true_variables,
    #                             "Mean"                                => true_means,
    #                             "Median"                              => true_medians,
    #                             "Coefficient of Variation"            =>true_cvs,
    #                             "Correlation with per capita output"  => true_correlations)
    
    # Ideally, the test would look like : 
    # @test isequal(true_table_1, Replication_Monge_et_al_2019.table_1)
end
