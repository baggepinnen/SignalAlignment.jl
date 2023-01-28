# SignalAlignment

[![Build Status](https://github.com/baggepinnen/SignalAlignment.jl/workflows/CI/badge.svg)](https://github.com/baggepinnen/SignalAlignment.jl/actions)
[![Coverage](https://codecov.io/gh/baggepinnen/SignalAlignment.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/baggepinnen/SignalAlignment.jl)


This package takes a vector of signals and tries to align them.

One use case for this is when two different instruments are used to record something that is going on, but they may record at different sample rates, have no synchronization, or have different time offsets. Before analyzing such experiments, it may be helpful to align the signals to each other. 

# Function reference
- `align_signals(signals, method; master, by, output)`: Main entrypoint for signal alignment
- `syncplot`: takes the same arguments as `align_signals` (except `output`) and plots the aligned signals

## Method reference
The method indicates how alignment is computed. The method is specified by passing a `method` argument to `align_signals`. The following methods are available:

- `Delay(; delay_method)`: Align signals by shifting them with respect to each other
    - `delay_method = DTWDelay()`: Align signals by computing the optimal delay using Dynamic-Time Warping. This can be computationally expensive for very long signals, but is more robust than `XcorrDelay`.
    - `delay_method = XcorrDelay()`: Align signals by computing the optimal delay using cross-correlation
- `Warp`: Align signals by warping them with respect to each other
    - `warp_method = DTW()`: Align signals by computing the optimal warp using Dynamic-Time Warping. See [DynamicAxisWarping.jl](https://github.com/baggepinnen/DynamicAxisWarping.jl) for options to `DTW`.
    - `warp_method = GDTW()`: Align signals by computing the optimal warp using Generalized Dynamic-Time Warping. See [DynamicAxisWarping.jl](https://github.com/baggepinnen/DynamicAxisWarping.jl) for options to `GDTW`.

## Master reference
The master indicates which signal is used as the reference signal to which the other signals are aligned. The master is specified by passing a `master` argument to `align_signals`. The following masters are available:

- `Index`: Align all signals to a particular signal. The default is `Index(1)` which aligns all signals to the first signal.
- `Longest`: Align all signals to the longest signal
- `Shortest`: Align all signals to the shortest signal
- `Centroid`: Align all signals to the computed centroid (generalized median) of all signals. The metric used to compute the centroid is specified by, e.g., `Centroid(SqEuclidean())`.
- `Barycenter`: Align all signals to the computed barycenter (generalized mean) of all signals. The metric used to compute the barycenter is specified by, e.g., `Barycenter(SqEuclidean())`.

## Output reference
The output indicates what is returned by `align_signals`. The output is specified by passing an `output` argument to `align_signals`. The following output options are available:

- `Indices()`: Return the indices that align the signals.
- `Signals()`: Return the aligned signals.

The map from indices to aligned signals is
```julia
aligned_signals = [signals[i][inds[i]] for i in eachindex(signals)]
```

# Examples

## Align shifted signals to one particular signal
We can indicate that we want to align a vector of signals to a particular signal by passing the index of the signal we want to align to as the `master` argument to `align_signals`. The default master if none is provided is `Index(1)` like we use below.
```julia
using SignalAlignment
s0 = sin.((0:0.05:2pi)) # A noisy signal
s1 = s0[1:end-10]       # A second signal, misaligned with the first
s2 = s0[20:end]         # A third signal
signals = [s0, s1, s2]  # A vector of signals we want to align
signals = [s .+ 0.02 .* randn(length(s)) for s in signals] # Add some noise to the signals

master = Index(1)       # Indicate which signal is the master to which the others are aligned
method = Delay(delay_method=DTWDelay()) # Indicate that we want to align the signals by shifting them, and the delay between them is computed using DTW
output = Indices() # Indicate that we want the aligning indices as output
inds = align_signals(signals, method; master, output)
```
```
3-element Vector{UnitRange{Int64}}:
 2:1884
 2:1884
 1:1883
 ```

The indices returned by `align_signals` can be used to align the signals to the master signal.
```julia
aligned_signals = [signals[i][inds[i]] for i in eachindex(signals)]
plot(signals, label=["s0" "s1" "s2"], l=(:dash, ))
plot!(aligned_signals, label=["s0 aligned" "s1 aligned" "s2 aligned"], c=(1:3)', size=(600, 400))
```
![image](https://user-images.githubusercontent.com/3797491/215254940-f8ced414-cbf3-4818-b31b-19199485de52.png)

The example above used Dynamic-Time Warping (DTW) to find the optimal delay with which to shift the signals to the master. Rather than DTW, we can compute the delay using cross-correlation as well
```julia
method = Delay(delay_method = XcorrDelay())
```

If we want to obtain the aligned signals directly as output rather than the aligning indices, we pass `output = Signals()`.

## Align signals with different sample rates
In this example, the second signal has a sample rate that is 2x lower than the first signal. We can align the signals by warping them using Dynamic-Time Warping (DTW) to fit the first signal. DTW is handled by the [DynamicAxisWarping.jl](https://github.com/baggepinnen/DynamicAxisWarping.jl) package.
```julia
using SignalAlignment
s0 = sin.((0:0.05:2pi)) # A noisy signal
s1 = s0[1:2:end-10]     # A second signal with 2x lower sample rate
s2 = s0[20:end]         # A third signal
signals = [s0, s1, s2]  # A vector of signals we want to align
signals = [s .+ 0.02 .* randn(length(s)) for s in signals] # Add some noise to the signals

master = Index(1)       # Indicate which signal is the master to which the others are aligned
method = Warp(warp_method=DTW(radius=20))
output = Signals() # Indicate that we want the aligned signals as output
# syncplot(signals, method; master) # Call this if you only want to plot the aligned signals

aligned_signals = align_signals(signals, method; master, output)
plot(signals, label=["s0" "s1" "s2"], l=(:dash, ))
plot!(aligned_signals, label=["s0 aligned" "s1 aligned" "s2 aligned"], c=(1:3)', size=(600, 400))
```
![image](https://user-images.githubusercontent.com/3797491/215255054-afedf97c-4913-4bed-923d-d5ac6b52c5a6.png)

Notice how the signal that was sampled slowly has been stretched to fit the first signal. This introduces some artifacts, where some samples have been repeated. If the signals are instead aligned to the shortest signal, the longer signals are subsampled:
```julia
master = Shortest() 
aligned_signals = align_signals(signals, method; master, output)
plot(signals, label=["s0" "s1" "s2"], l=(:dash, ))
plot!(aligned_signals, label=["s0 aligned" "s1 aligned" "s2 aligned"], c=(1:3)', size=(600, 400))
```
![image](https://user-images.githubusercontent.com/3797491/215255616-f924449c-edb2-4431-b6d2-ccfc58636d90.png)

To get a smoother result, use generalized DTW (GDTW) instead of DTW. 
```julia
master = Shortest()
method = Warp(warp_method=GDTW(symmetric=false))
aligned_signals = align_signals(signals, method; master, output)
plot(signals, label=["s0" "s1" "s2"], l=(:dash, ))
plot!(aligned_signals, label=["s0 aligned" "s1 aligned" "s2 aligned"], c=(1:3)', size=(600, 400))
```
![image](https://user-images.githubusercontent.com/3797491/215255887-3cdeafae-ff39-4de2-85cf-d8849302c938.png)