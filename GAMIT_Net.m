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
if nargin < 4 %
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
    %first get a new spreading activation curve for these settings
    [~, thisCurve] = GAMIT_Spreading_Activation(params);
    %always start with initial value
    INS = thisCurve(1,:);
    if reproduceFlag
       if prospectiveFlag
           %interval reproduction task
           %basically our model check it's watch at random intervals until it's
           %estimate is greater than or equal to the target time. At which
           %point it stops. we then return the actual amount of elapsed time to
           %get to this point.
           % as a first step, generate far more saccades than we might actually
           % need 
           %(targetinterval * 3) should be big enough!
           sampleTimes = getRandomSampleTimes(3*targetTimes(i),params.PoissonSampling,params.sampleFrequency);

           INS = [INS; thisCurve(sampleTimes,:)]; %inputs to the neural network are curve values at these times
           OUTPUTS = srn_out(INS, wt1, wt2); %outputs are network estimates
           %now have to convert these outputs to actual numerical values
           allEstimates = LinearRepresentation(OUTPUTS,20,1,params.nIterations,true);  
           %Finally find the first estimate greater than the target
           ix = find(allEstimates>targetTimes(i),1);
           %the actual estimate is the 'real' time that produced this estimate
           timeEstimates(i) = sampleTimes(ix);  
       else
           error('Cannot have a retrospective reproduction task.');
       end
    else
       %standard recognition task.
       if prospectiveFlag
           %/ - estimating length of a presented interval
           %sample the curve at randomly selected points during the interval and
           %then give a final estimate when we reach the actual target time
           sampleTimes = getRandomSampleTimes(targetTimes(i),params.PoissonSampling,params.sampleFrequency);
           INS = [INS; thisCurve(sampleTimes,:)]; 
       end
        %end on targetTime
        INS = [INS;thisCurve(round(targetTimes(i)),:)];
        %  INS = thisCurve(round(targetTimes(i)),:);    
        OUTPUTS = srn_out(INS, wt1, wt2);
        [r,~]=size(OUTPUTS);
        timeEstimates(i) = LinearRepresentation(OUTPUTS(r,:),20,1,params.nIterations,true);  
    end
end

end

function sampleTimes = getRandomSampleTimes(targetTime,PoissonFlag,sampleFrequency)
% helper function to return the attentional saccades
    if PoissonFlag
       %get poisson distributed random samples
       sampleTimes = PoissonSequence(targetTime, sampleFrequency);
   else %uniformly random sampling
       %how often are we sampling?
       nProspectiveSamples = floor(targetTime / sampleFrequency);
       sampleTimes = sort(ceil(targetTime*rand(1, nProspectiveSamples)));
    end
end
