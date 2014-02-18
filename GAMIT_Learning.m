function [wt1, wt2] = GAMIT_Learning(params, NCurves,NSamples, wt1,wt2, exportRawData)
%
% uses a neural network to time exstimate outputs for a decaying memory trace. 

if nargin < 1   
    params = GAMIT_Params();
end
if nargin < 2
    NCurves = 100; %default
end
if nargin < 3
    NSamples = 2000;
end
if nargin < 4
    wt1 = [];
end
if nargin < 5
    wt2 = [];
end
if nargin < 6
    exportRawData = false;
end

nOutputNodes = 20;
nHidNodes = 20;
InputValues = 1:params.nIterations;
OUT = LinearRepresentation(InputValues',nOutputNodes,1,params.nIterations,false); 


% train a simple recurrent net using backprop on
% points from many different curves, sampled as if experiencing
% a mixture of retrospective and prospective learning cases. 
if isempty(wt1) || isempty(wt2)
    %first initalise weights
    [wt1, wt2] = srn(zeros(1,200),OUT(1,:),nHidNodes,1);
end
%generate set of random targetTimes
targetTimes = randi(params.nIterations,NCurves,NSamples);
for curve = 1:NCurves
    %build a decay curve
    [temp INPUT_CURVES] = GAMIT_Spreading_Activation(params);
    %building a seperate decaying curve for each training instance is
    %possible but computationally demanding so instead we reuse each
    %one a number of times someties prospective and sometimes
    %retrospective
    for example = 1:NSamples          
        %%always start with the starting curve
        INS = INPUT_CURVES(1,:);
        OUTS = OUT(1,:);
        if rand(1)>params.ProbProspective
            %retrospective case, need just  end points
        else
            %prospective case need random points in between
            %corresponding to attentional saccades
            %NOTE THAT AT PRESENT ATTENTION PARAMETERS HELD CONSTANT
            %DURING TRAINING                
            if params.PoissonSampling 
                sampleTimes = PoissonSequence(targetTimes(curve,example), params.sampleFrequency);
            else %uniform sampling
                nProspectiveSamples = floor(targetTimes(curve,example) / params.sampleFrequency);
                sampleTimes = sort(ceil(targetTime*rand(1, nProspectiveSamples)));
            end
            INS = [INPUT_CURVES(sampleTimes,:)];
            OUTS = [OUT(sampleTimes,:)];          
        end 
        %always end with the end value
        INS = [INS;INPUT_CURVES(targetTimes(curve,example),:)];
        OUTS = [OUTS;OUT(targetTimes(curve,example),:)];

        %train the network with this example
        %keep track of evolving weights
        [wt1, wt2] = srn(INS,OUTS,nHidNodes,1,wt1, wt2);
    end
end 

if exportRawData
    t = table(wt1);
    writetable(t,'wt1.csv','Delimiter',',');
    t = table(wt2);
    writetable(t,'wt2.csv','Delimiter',',');        
end


