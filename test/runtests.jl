using Replication_Monge_et_al_2019
using Test

@testset "Replication_Monge_et_al_2019" begin
    @testset "Data replication" begin 
        # include("tests_Data_1.jl")
        # include("tests_Data_2.jl")
        # include("tests_Data_3.jl")
        include("tests_Data_final.jl")
    end
    @testset "Figures and Tables replication" begin 
        include("tests_Part_2.jl")
        include("tests_Part_3.jl")
    end
end