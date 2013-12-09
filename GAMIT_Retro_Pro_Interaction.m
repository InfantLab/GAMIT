function GAMIT_Retro_Pro_Interaction(targetTime,nSamples,lowCognitiveLoad,highCognitiveLoad,showGraphics)
%
% Demonstrate how the retrospective and prospective time estimates are
% calculated in the GAMIT model.

if nargin < 1
    targetTime = 600;
end
if nargin<2
    nSamples = 50;
end
if nargin<3
    lowCognitiveLoad = 0.95;
    highCognitiveLoad = 1.1;
end 
if nargin<4 
    showGraphics = true;
end
relativeEstimates = true;

%step 1: Get default params & generate a reference curve
params = GAMIT_Params();
lifetimeCurve = GAMIT_Lifetime(params);


testTimes = targetTime * ones(1,nSamples);

%%% RETROSPECTIVE %%%
retrospectiveLow = GAMIT(testTimes,lowCognitiveLoad,false,false,params,lifetimeCurve);
retrospectiveHigh = GAMIT(testTimes,highCognitiveLoad,false,false,params,lifetimeCurve);

%%% PROSPECTIVE %%%
prospectiveLow = GAMIT(testTimes,lowCognitiveLoad,true,false,params,lifetimeCurve);
prospectiveHigh = GAMIT(testTimes,highCognitiveLoad,true,false,params,lifetimeCurve);


if showGraphics
    %Graphics code shows interaction plot like Block, Hancock & Zakay 2010
    figure(1);
    clf(1);
    %load coordinates 
    xC = [lowCognitiveLoad, highCognitiveLoad];
    %get retrospective 'coordinates'
    yR = [mean(retrospectiveLow),mean(retrospectiveHigh)];
    yeR = [std(retrospectiveLow),std(retrospectiveHigh)];
    %get retrospective 'coordinates'
    yP = [mean(prospectiveLow),mean(prospectiveHigh)];
    yeP = [std(prospectiveLow),std(prospectiveHigh)];
    
    if relativeEstimates
        yR = yR/targetTime;
        yeR = yeR/targetTime;
        yP = yP/targetTime;
        yeP = yeP/targetTime;
    end
    
    hold on;
    %plot lines
    line(xC, yR,'Color','b');
    %offset this xcoord slightly for ease of view
    xCprime = xC+diff(xC)*.02;
    line(xCprime, yP,  'Color','r');
    legend('Retrospective','Prospective');
    %plot error bars
    errorbar(xC,yR,yeR,'Color','b');
    errorbar(xCprime,yP,yeP,'Color','r');
    hold off;
    xlabel('Relative Cognitve Load (Normal load = 1.0)');
    if relativeEstimates
        ylabel('Mean Duration Judgement Ratio');
    else
        ylabel('Mean Time Estimates');
    end
    title('Interaction of retrospective & prospective time estimates with cognitive load');
end

