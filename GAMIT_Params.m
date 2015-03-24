function params = GAMIT_Params(matfile)
%
% helper function to return standard GAMIT spreading activation parameters
% if matfile parameter is passed we load params from corresponding .mat
% file

if nargin == 1
    temp = load(matfile);
    params = temp.params;
else    
    %curve evolution parameters
    params.initialActivation = 1;
    params.nColumns = 200;
    params.nIterations = 2000;      % number of timesteps we evolve curve for

    params.alpha = 0.7;             % self activation 
    params.beta = 0.14952;          % spreading activation
    params.noiseFactor = 0.00025;  % noise

    params.GaussianFit = 0;      %is gamit score the stddev of the best fit gaussian 
                                     %or is it SummedActivation + MaxActivation?

    %curve sampling params
    params.bias = 0.87;              %single parameter to account for fact that humans always underestimate/overproduce intervals.
    params.sampleErrorSize = .05;    % margin of error on an sample from curve
    params.MemoryUncertainty = 0; %is there any additional uncertainty when we read off from the lifetime Curve?

    %prospective model parameters
    params.WorkingMemoryDelta = 1; %Do we just a subset of sampling deltas or all of them?
    params.RandomAccessMemory = 1; %If WMD=true, is the subset random or just the most recent deltas
    params.nSampleDeltas = 6;       % how many samples can we keep in memory?

    params.sampleFrequency = 100;    % base rate of one sample every fifty ticks
    params.PoissonSampling = 1;  % are time points samples according to a Poisson process or uniform random variable

    params.NeuralNetwork = 1;       %Do we use a neural net model of lifetime learning?
    params.RecurrentNetwork = 1;    %0 backprop, 1 simple recurrent network (SRN)
    params.ProbProspective = 0.2;   %what proportion of learning examples are prospective timing?
    
end