using Replication_Monge_et_al_2019
using Test
using DataFrames
using StatFiles

@testset "Data_work.jl" begin
    
    # Testing the filter_function! function :    
    @test ismissing(Replication_Monge_et_al_2019.filter_function!(missing))
    @test Replication_Monge_et_al_2019.filter_function!(200) == 200
    @test Replication_Monge_et_al_2019.filter_function!(0) == 0
    @test ismissing(Replication_Monge_et_al_2019.filter_function!(-100))
    @test ismissing(Replication_Monge_et_al_2019.filter_function!("this is a string"))

    # Testing the daa obtained in the first part : 
    
    # This is the intermediate result gotten from the do file of the authors :
    # true_pwt_data_1 = DataFrame(load("src/data/true_pwt_data_1.dta"))
    # We sort it to have it in the same order as them : 
    # sort!(true_pwt_data_1, [:country, :year])
    # This is our data : 
    # Replication_Monge_et_al_2019.pwt_data_1
    
    # We first compare the names of the columns, 
    # and we find that the 61th is different :
    # findall(names(true_pwt_data_1) .!== names(Replication_Monge_et_al_2019.pwt_data_1)) # 61
    # findall(names(Replication_Monge_et_al_2019.pwt_data_1) .!== names(true_pwt_data_1)) # 61
    # 
    # names(true_pwt_data_1)[61]
    # names(Replication_Monge_et_al_2019.pwt_data_1)[61]
    
    # When testing for perfect equality, we get a 'false' result :
    # print(isequal(true_pwt_data_1[:,1:end .!= 61], Replication_Monge_et_al_2019.pwt_data_1[:,1:end .!= 61]))
    # 
    # # The columns which are different are : 
    # identical = []
    # for col in 1:size(true_pwt_data_1)[2]
    #     tmp = isequal(true_pwt_data_1[:,col], Replication_Monge_et_al_2019.pwt_data_1[:,col])
    #     push!(identical, tmp)
    # end
    # 
    # different_columns = findall(==(false), identical)
    # 
    # # We could at least compare only numerical columns, with the isapprox function :
    # approximately = []
    # for col in 1:size(true_pwt_data_1)[2]
    #     if true_pwt_data_1[:,col] isa Number
    #         tmp2 = isapprox(true_pwt_data_1[:,col], Replication_Monge_et_al_2019.pwt_data_1[:,col])
    #     end
    #     push!(approximately, tmp2)
    # end
    # 
    # # approximately = []
    # # for col in 1:size(true_pwt_data_1)[2]
    # #     true_pwt_data_1[:,col] isa Number
    # # end

end