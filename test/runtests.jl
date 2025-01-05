using Replication_Monge_et_al_2019
using Test

@testset "Replication_Monge_et_al_2019" begin
    @testset "Data replication" begin 
        include("tests_Data_1.jl")
        include("tests_Data_2.jl")
    end
    @testset "Figure and Tables replication" begin 
        include("tests_Part_2.jl")
        include("tests_Part_3.jl")
    end
end