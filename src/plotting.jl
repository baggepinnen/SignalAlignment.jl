@userplot SyncPlot

@recipe function syncplot(p::SyncPlot; method = Warp(DTW(radius=2000, transportcost=1.00)), master = Longest())
    output = Signals()
    signals = make_wide.(p.args[1])
    aligned = SignalAlignment.align_signals(signals, method; master, output)
    aligned = make_tall.(aligned)
    delete!(plotattributes, :master)
    delete!(plotattributes, :method)
    for sig in aligned
        @series begin
            link --> :x
            sig
        end
    end
end

make_wide(x) = size(x,1) > size(x,2) ? x' : x
make_tall(x) = size(x,1) < size(x,2) ? x' : x