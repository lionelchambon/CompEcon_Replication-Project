using Replication_Monge_et_al_2019
using Test

@testset "Part_3" begin 

    # tests here...

end 
@test num_countries == 76  # Expected number of unique countries
@test unique_years == valid_years  # Expected unique years (order matters)


@test "QMPK" in names(data_fig4) 
@test "VMPK" in names(data_fig4)

# Test for VarQMPK
@test isapprox(computed_varQMPK, manual_varQMPK; atol=1e-7) "Error: VarQMPK does not match the manual computation. Computed: $computed_varQMPK, Manual: $manual_varQMPK"

# Test for VarVMPK
@test isapprox(computed_varVMPK, manual_varVMPK; atol=1e-7) "Error: VarVMPK does not match the manual computation. Computed: $computed_varVMPK, Manual: $manual_varVMPK"
