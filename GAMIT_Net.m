function timeEstimates = GAMIT_Net(targetTimes,cognitiveLoad,prospectiveFlag,reproduceFlag,params,wt1,wt2)
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
% wt1
% wt2

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
    %Generate the neural network 
    [wt1, wt2] = GAMIT_Learning(params);
end

%%%%%%%%%%%%%%%%
%How does cognitive load effect things?
%
%RETROSPECTIVE & PROSPECTIVE
%beta determines the rate of curve decay.
%higher load causes faster decay
params.beta = params.beta - (cognitiveLoad-1)* 0.0008;  

%PROSPECTIVE ONLY
%How often do we sample from the curve?
if prospectiveFlag
    %under higher cognitive load we sample at wider intervals 
    params.sampleFrequency = params.sampleFrequency * (1+ 2*(cognitiveLoad-1));
else
    %in retrospective case, we don't use this parameter
end

%OK, now we actually make some estimates
n = length(targetTimes);
timeEstimates = zeros(n,1);
for i = 1:n
    %first get a spreading activation curve for these settings
    [~, thisCurve] = GAMIT_Spreading_Activation(params);

    %always start with initial value
    INS = thisCurve(1,:);
    if prospectiveFlag
       %random samples
       if params.PoissonSampling
           sampleTimes = PoissonSequence(targetTimes(i), params.sampleFrequency);
       else %uniform sampling
           %how often are we sampling?
           nProspectiveSamples = floor(targetTimes(i) / params.sampleFrequency);
           sampleTimes = sort(ceil(targetTimes(i)*rand(1, nProspectiveSamples)));
       end
       INS = [INS; thisCurve(sampleTimes,:)];
    end        
    %end on targetTime
    INS = [INS;thisCurve(round(targetTimes(i)),:)];
    %  INS = thisCurve(round(targetTimes(i)),:);    
    OUTPUTS = srn_out(INS, wt1, wt2);
    [r,~]=size(OUTPUTS);
    timeEstimates(i) = LinearRepresentation(OUTPUTS(r,:),20,1,params.nIterations,true);  
end

    

