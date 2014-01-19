function GAMIT_Retro_Pro_Interaction(targetTime,nSamples,lowCognitiveLoad,highCognitiveLoad,showGraphics,exportRawData)
%
% Demonstrate how the retrospective and prospective time estimates are
% calculated in the GAMIT model.

if nargin < 1
    targetTime = 600;
end
if nargin<2
    nSamples = 20;
end
if nargin<3
    lowCognitiveLoad = 0.95;
    highCognitiveLoad = 1.05;
end 
if nargin<5 
    showGraphics = true;
end
if nargin<6
    exportRawData = true;
end
relativeEstimates = true; % divide through by targetTime

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

if exportRawData
    t = table(retrospectiveLow,retrospectiveHigh,prospectiveLow,prospectiveHigh);
    writetable(t,'GAMIT_Retro_Pro_Interaction.csv','Delimiter',',');
    save('GAMIT_Retro_Pro_Params.mat','params');
end

if showGraphics
    %Graphics code shows interaction plot like Block, Hancock & Zakay 2010
    figure(1);
    clf(1);
    %load coordinates 
    xC = [lowCognitiveLoad, highCognitiveLoad];
    %get retrospective 'coordinates'
    yR = [mean(retrospectiveLow),mean(retrospectiveHigh)];
    yeR = [std(retrospectiveLow),std(retrospectiveHigh)];
    yeR = yeR /sqrt(length(retrospectiveLow));
    %get retrospective 'coordinates'
    yP = [mean(prospectiveLow),mean(prospectiveHigh)];
    yeP = [std(prospectiveLow),std(prospectiveHigh)];
    yeP = yeP /sqrt(length(prospectiveLow));
    if relativeEstimates
        yR = yR/targetTime;
        yeR = yeR/targetTime;
        yP = yP/targetTime;
        yeP = yeP/targetTime;
    end
    
    hold on;
    %plot lines
    %offset second set of xcoords slightly for ease of view
    xCprime = xC+diff(xC)*.02;
%     line(xC, yR,'Color','k','LineStyle','--','Marker','o');
%     line(xCprime, yP,  'Color','k','Marker','o');
    %plot error bars
    errorbar(xC,yR,yeR,'Color','k','LineStyle','--','Marker','o');
    errorbar(xCprime,yP,yeP,'Color','k','Marker','o');
    legend('Retrospective','Prospective');
 
    hold off;
    xlabel('Relative Cognitve Load (Normal load = 1.0)');
    if relativeEstimates
        ylabel('Mean Duration Judgement Ratio');
    else
        ylabel('Mean Time Estimates');
    end
    title('Interaction of retrospective & prospective time estimates with cognitive load');
end

