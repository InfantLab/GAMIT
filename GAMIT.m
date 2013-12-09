function timeEstimates = GAMIT(targetTimes,cognitiveLoad,prospectiveFlag,reproduceFlag,params,referenceCurve)
%
% Simple implementation of the GAMIT model, input some high level parameters 
%
% targetTime        = Actual length of interval as number of simulation steps
% cognitiveLoad     = 1.00 is 'normal load', >1.00 is high cognitive load
% prospectiveFlag   = 0,false [Retrospective], 1,true [Prospective]
% reproduceFlag     = 0,false this is recognition task, 1,true this is an
%                     interval reproduction task (ignored in retrospective case)
%                   NB this flag not implemented yet. ALWAYS recognition task
% params            = GAMIT curve parameters
% referenceCurve    = The lifetime average curve.
% referenceDeltas   = The lifetime average delta. (Used for prospective)

% default parameters
if nargin < 1
    error('Enter target interval');
end 
if nargin < 2
    cognitiveLoad = 1.00; % normal load
end
if nargin < 3
    prospectiveFlag = false; %retrospective 
end
if nargin < 4 %NOT IMPLEMENTED (YET)
    reproduceFlag = false; %recognition task
end 
if nargin < 5
    %get default curve evolution params 
    params = GAMIT_Params();
end
if nargin < 6
    %Generate the reference curves
    referenceCurve = GAMIT_Lifetime();
end

%%%%%%%%%%%%%%%%
%How does cognitive load effect things?
%
%RETROSPECTIVE & PROSPECTIVE
%beta determines the rate of curve decay.
%higher load causes faster decay
params.beta = params.beta + (1-cognitiveLoad)* 0.0006;  

%PROSPECTIVE ONLY
%How often do we sample from the curve?
if prospectiveFlag
    %under higher cognitive load we sample at wider intervals 
    params.sampleFrequency = params.sampleFrequency * cognitiveLoad;
else
    %in retrospective case, we don't use this parameter
end

%OK, now we actually make some estimates
n = length(targetTimes);
timeEstimates = zeros(n,1);
PHI = ones(n,1);
for i = 1:n
    %first get a spreading activation curve for these settings
    [thisCurve, ~] = GAMIT_Spreading_Activation(params);
    
    %what is value of this curve at target time?
    rawActivation = thisCurve(round(targetTimes(i)));
    %APPLY SAMPLING NOISING TO THIS VALUE
    if params.GaussianFit
        %adjust activation by proportional random error 
        distFromCurve = abs(referenceCurve.GamitScore-rawActivation);
        [~, id_min] = min(distFromCurve);
        associatedUncertainty = referenceCurve.GamitScoreUncertainty(id_min);
        estActivation = rawActivation + associatedUncertainty * params.sampleErrorSize * randn(1);
    else
        %adjust with a fixed size random estimation error
        estActivation = rawActivation + params.sampleErrorSize * randn(1);
    end
   
    if params.MemoryUncertainty
        %we may also assume that there is also an error our judgement of the estimate
        %based on the uncertainity of our memory curve
        distFromCurve = abs(referenceCurve.GamitScore-estActivation);
        [~, id_min] = min(distFromCurve);
        associatedUncertainty = referenceCurve.GamitScoreUncertainty(id_min);
        estActivation = estActivation + associatedUncertainty * params.sampleErrorSize * randn(1);
        %impose a minimum value
        estActivation = max(params.noiseFactor,estActivation);
    end
    distFromCurve = abs(referenceCurve.GamitScore-estActivation);
    [~, id_min] = min(distFromCurve);
    timeEstimates(i) = id_min;  
    
    if prospectiveFlag
       % estimate is a baseline need to adjust it by PHI factor for rate of change.
       %how often are we sampling?
       nProspectiveSamples = floor(targetTimes(i) / params.sampleFrequency);
       %random samples
       if params.PoissonSampling
          sampleTimes = PoissonSequence(targetTimes(i), params.sampleFrequency);
       else %uniform sampling
          sampleTimes = sort(ceil(targetTimes(i)*rand(1, nProspectiveSamples)));
       end
       %corresponding deltas 
       if params.GaussianFit
           sampleDeltas = diff(thisCurve([1 sampleTimes]));
       else
           sampleDeltas = -1*diff(thisCurve([1 sampleTimes]));
       end
       %don't allow negatives
       sampleDeltas(sampleDeltas<=0)=0;
       nDeltas = length(sampleDeltas);
       if params.WorkingMemoryDelta
           %we won't typically remember all of these so pick just some of them
           memDeltas = min(length(sampleDeltas),params.nSampleDeltas);
           if params.RandomAccessMemory
               %pick memDelta points randomly
               scrambledDeltaIndices = randperm(length(sampleDeltas));
               rememberedDeltaIndices = scrambledDeltaIndices(1:memDeltas);
           else
               %select most recent memDelta points found so far
               rememberedDeltaIndices = nDeltas:-1:(nDeltas+1-memDeltas);
           end 
           %deltaEstimate is the average of these
           deltaEstimate = mean(sampleDeltas(rememberedDeltaIndices));
       else %delta is simply mean of all these values
          deltaEstimate =mean(sampleDeltas);
       end
       %so now we adjust our original estimate based on the relative delta
       deltaTypical = referenceCurve.Delta(min(timeEstimates(i),params.nIterations));
       if deltaEstimate <= 0 
            PHI(i) = 1;
       else
            PHI(i) = deltaTypical / deltaEstimate;
       end
       timeEstimates(i) = timeEstimates(i) * PHI(i);
    end
    %finally apply the global bias.
    timeEstimates(i) = timeEstimates(i) * params.bias;
end

    

