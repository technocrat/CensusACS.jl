using Test
using CensusACS

@testset "CensusACS.jl Package Tests" begin
    
    @testset "Basic Package Loading" begin
        @test isa(CensusACS, Module)
        @test isdefined(CensusACS, :get_acs)
        @test isdefined(CensusACS, :get_acs_moe)
        @test isdefined(CensusACS, :get_acs1)
        @test isdefined(CensusACS, :get_acs3)
        @test isdefined(CensusACS, :get_acs5)
        @test isdefined(CensusACS, :get_acs_moe1)
        @test isdefined(CensusACS, :get_acs_moe3)
        @test isdefined(CensusACS, :get_acs_moe5)
    end
    
    @testset "Main Function Availability" begin
        # Test that main functions exist and are callable
        @test isa(get_acs, Function)
        @test isa(get_acs_moe, Function)
        @test isa(get_acs1, Function)
        @test isa(get_acs3, Function)
        @test isa(get_acs5, Function)
        @test isa(get_acs_moe1, Function)
        @test isa(get_acs_moe3, Function)
        @test isa(get_acs_moe5, Function)
    end
end
