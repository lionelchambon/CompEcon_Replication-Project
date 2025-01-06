using Replication_Monge_et_al_2019
using Test

@testset "Results Part 3" begin 

    @test Replication_Monge_et_al_2019.num_countries == 76  # Expected number of unique countries
    # What do you mean with "valid_years" ? This variable does not seem to be defined.
    @test Replication_Monge_et_al_2019.unique_years == valid_years  # Expected unique years (order matters)
    
    @test "QMPK" in names(Replication_Monge_et_al_2019.data_fig4) 
    @test "VMPK" in names(Replication_Monge_et_al_2019.data_fig4)
    
    # Test for VarQMPK
    @test isapprox(Replication_Monge_et_al_2019.computed_varQMPK, Replication_Monge_et_al_2019.manual_varQMPK)
    
    # Test for VarVMPK
    @test isapprox(Replication_Monge_et_al_2019.computed_varVMPK, Replication_Monge_et_al_2019.manual_varVMPK) 
end 

# Controlling that all tests run by adding a last test
# (not displayed in the REPL if something goes wrong).
@testset "Last test" begin 
    @test 1 == 1
end