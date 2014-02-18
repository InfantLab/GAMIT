function GAMIT_Net_Retro_Pro_Interaction(targetTime,nTrials,lowCognitiveLoad,highCognitiveLoad,showGraphics,exportRawData,wt1,wt2)
%
% Demonstrate how the retrospective and prospective time estimates are
% calculated in the GAMIT model.

if nargin < 1
    targetTime = 650;
end
if nargin<2
    nTrials = 20;
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
params = GAMIT_Params();
if nargin <8
    %step 1: Get default params & generate a reference curve
    nCurves = 100;
    nSamples = 500;
    [wt1, wt2] = GAMIT_Learning(params,nCurves,nSamples);
else
    %already generated weights;
end

testTimes = targetTime * ones(1,nTrials);

%%% RETROSPECTIVE %%%
retrospectiveLow = GAMIT_Net(testTimes,lowCognitiveLoad,false,false,params,wt1, wt2);
retrospectiveHigh = GAMIT_Net(testTimes,highCognitiveLoad,false,false,params,wt1, wt2);

%%% PROSPECTIVE %%%
prospectiveLow = GAMIT_Net(testTimes,lowCognitiveLoad,true,false,params,wt1, wt2);
prospectiveHigh = GAMIT_Net(testTimes,highCognitiveLoad,true,false,params,wt1, wt2);

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
    legend('Retrospective','Prospective','Location','best');
 
    hold off;
    xlabel('Relative Cognitve Load (Normal load = 1.0)');
    if relativeEstimates
        ylabel('Mean Duration Judgement Ratio');
    else
        ylabel('Mean Time Estimates');
    end
%     title('Interaction of retrospective & prospective time estimates with cognitive load');
    figureHandle = gcf;
    %# make all text in the figure to size 14 and bold
    set(findall(figureHandle,'type','text'),'fontSize',14,'fontWeight','bold')
end

