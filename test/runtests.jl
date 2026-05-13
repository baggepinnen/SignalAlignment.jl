using SignalAlignment
using Distances
using Test
using Plots
using LinearAlgebra, Statistics

@testset "SignalAlignment.jl" begin
signals = [sin.((0:0.01:6pi) .+ rand()) for _ in 1:50]
signals_unequal = [sin.((0:0.01:(6pi + rand())) .+ rand()) for _ in 1:50]
signals_short = [sin.((0:0.01:(4pi + rand())) .+ rand()) for _ in 1:10]
signals_mv = [randn(2,10) for _ in 1:5]

@testset "Master methods" begin
    @info "Testing Master methods"

    @test get_master(Index(5), signals) == signals[5]
    @test get_master(5, signals) == signals[5]
    @test get_master(Longest(), signals_unequal) == signals_unequal[argmax(length.(signals_unequal))]
    @test get_master(Shortest(), signals_unequal) == signals_unequal[argmin(length.(signals_unequal))]
    @test get_master(Centroid(Euclidean()), signals) ∈ signals
    @test get_master(Barycenter(Euclidean()), signals) == mean(signals)
    bc = get_master(Barycenter(DTW(radius=5)), signals_short)
    @test typeof(bc) == eltype(signals_short)
    # plot(signals_short); plot!(bc, l=(5, :red))
end


@testset "outputs" begin
    @info "Testing outputs"

    output = Indices()
    inds = fill(1:10, length(signals))
    @test get_output(inds, signals, output) == inds

    output = Signals()
    sa = get_output(inds, signals, output)
    @test sa == [s[i] for (s,i) in zip(signals, inds)]

    sa = get_output(inds[1:length(signals_mv)], signals_mv, output)
    @test sa[1] == signals_mv[1][:,inds[1]]
end

@testset "by" begin
    @info "Testing by"
    @test get_alignment_signals(signals, nothing) == signals
    @test get_alignment_signals(signals, identity) == signals
    
end

@testset "Methods" begin
    @info "Testing Methods"

    master = Index(1)
    s0 = sin.((0:0.01:6pi))
    s1 = s0[1:end-1]
    s2 = s0[2:end]

    @testset "Delay" begin
        @info "Testing Delay"
        
        
        method = XcorrDelay()
        @test compute_delay(method, s1, s1) == 0
        @test compute_delay(method, s1, s2) == 1
        @test compute_delay(method, s2, s1) == -1
        
        method = DTWDelay()
        @test compute_delay(method, s1, s1) == 0
        @test compute_delay(method, s1, s2) == 1
        @test compute_delay(method, s2, s1) == -1
        
        method = Delay(delay_method = XcorrDelay())
        inds = compute_aligning_indices([s1,s2], method; master)
        @test inds == [2:length(s1), 1:length(s2)-1]

        method = Delay(delay_method = DTWDelay())
        inds = compute_aligning_indices([s1,s2], method; master)
        @test inds == [2:length(s1), 1:length(s2)-1]
    end


    @testset "Warp" begin
        @info "Testing Warp"
        method = Warp(warp_method=DTW(radius=3))
        inds = compute_aligning_indices([s1,s2], method; master)
        @test inds[1] == 1:length(s1)
        @test inds[2] == [1; 1:length(s2)-1]

        inds = compute_aligning_indices(signals, method; master)
        @test all(length.(inds) .>= length(inds[1])) # all should be at least as long as the master


        method = Warp(warp_method=GDTW(symmetric=false))
        asigs = align_signals([s1,s2], method; master)
        ==(length.(asigs)...)
        @test norm(asigs[1] - asigs[2]) < norm(s1 - s2)

    end
end


    @testset "align_signals" begin
        @info "Testing align_signals"
        method = Delay(delay_method=DTWDelay())
        for method ∈ [
                Delay(delay_method = DTWDelay())
                Delay(delay_method = XcorrDelay())
            ]
            @show method
            # test with same length
            inds = align_signals(signals, method)
            aligned = getindex.(signals, inds)
            @test all(length.(inds) .== length(inds[1]))
            @test all(norm.(aligned .- (aligned[1], )) .< (method.delay_method isa DTWDelay ? 0.5 : 2.5))
            
            # test with different lengths
            inds = align_signals(signals_unequal, method)
            aligned = getindex.(signals_unequal, inds)
            @test all(length.(inds) .== length(inds[1]))
            @test all(norm.(aligned .- (aligned[1], )) .< (method.delay_method isa DTWDelay ? 0.5 : 5))
            
            # plot(signals, layout=2, sp=1)
            # plot!(aligned, sp=2)
            # display(current())
        end
        
        method = Delay()
        inds = align_signals(signals_short, method; output=Indices())
        sa = getindex.(signals_short, inds)
        sa2 = align_signals(signals_short, method; output=Signals())
        @test all(s1 == s2 for (s1,s2) in zip(sa, sa2))
            
        inds = align_signals(signals_mv, method; output=Indices())
        @test all(reduce(vcat, inds) .<= 10)
        sa = align_signals(signals_mv, method; output=Signals())
        @test all(size.(sa) .== Ref((2, length(inds[1]))))
        
        @test all(length.(inds) .== length(inds[1]))

        @testset "plot" begin
            @info "Testing plot"
            syncplot(signals, method)
        end
    end

    @testset "Shortest master + Indices" begin
        @info "Testing Shortest master with Indices output"

        timelen(x) = size(x, ndims(x))

        # univariate sanity check
        for dm in (XcorrDelay(), DTWDelay())
            method = Delay(delay_method = dm)
            inds = align_signals(signals_short, method; master = Shortest(), output = Indices())
            @test all(length.(inds) .== length(inds[1]))
            aligned = [s[i] for (s, i) in zip(signals_short, inds)]
            ref = aligned[argmin(timelen.(signals_short))]
            @test all(norm(a - ref) < (dm isa DTWDelay ? 0.5 : 5.0) for a in aligned)
        end

        method = Warp(warp_method = DTW(radius = 5))
        inds = align_signals(signals_short, method; master = Shortest(), output = Indices())
        @test all(length.(inds) .== length(inds[1]))

        # multivariate signals of unequal length — this is what triggers the bug
        T  = 0:0.05:4pi
        base = vcat(sin.(T)', cos.(T)')
        shifts = [0, 4, 2, 6, 3]
        trims  = [20, 5, 15, 10, 25]
        sigs_mv = [base[:, 1+s : end-tr] for (s, tr) in zip(shifts, trims)]

        method = Delay(delay_method = DTWDelay())
        inds = align_signals(sigs_mv, method; master = Shortest(), output = Indices())
        @test all(length.(inds) .== length(inds[1]))
        @test all(maximum(i) <= timelen(s) for (s, i) in zip(sigs_mv, inds))
        aligned = [s[:, i] for (s, i) in zip(sigs_mv, inds)]
        ref = aligned[argmin(timelen.(sigs_mv))]
        @test all(norm(a - ref) < 1e-8 for a in aligned)
    end

end
