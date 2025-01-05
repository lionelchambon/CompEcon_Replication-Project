using Replication_Monge_et_al_2019
using Test

@testset "Data_work.jl" begin
    
    # Testing the filter_function! function :    
    @test ismissing(Replication_Monge_et_al_2019.filter_function!(missing))
    @test Replication_Monge_et_al_2019.filter_function!(200) == 200
    @test Replication_Monge_et_al_2019.filter_function!(0) == 0
    @test ismissing(Replication_Monge_et_al_2019.filter_function!(-100))
    @test ismissing(Replication_Monge_et_al_2019.filter_function!("this is a string"))

    # At the end, we would have something like : 
    # @test isequal(our_data, their_data)

end