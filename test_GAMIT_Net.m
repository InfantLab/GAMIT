function [AllRet, AllPro] = test_GAMIT_Net(seed)
%testing the Simple Recurrent Network version of GAMIT
%this script generates the figures found in 
%Addyman & Mareschal (2014) seed = 2014;

if nargin < 1
    rng('shuffle');
else
    % fix a random seed for replication
    rng(seed);
end

params = GAMIT_Params();
testCases = 20:20:1800;
nLearners = 20;
nAges = 20;
nCurves = 50;   
nSamples = 50;
   
%%%%%%%% SIMULATION 1 %%%%%%%%%%
%first lets look at learning..
%initialize storage variables
AllRet = zeros(nLearners,nAges,length(testCases));
AllPro = AllRet;
for learner = 1:nLearners
    learner
    %initialize weights
    wt1 = []; wt2 = [];
    for age = 1:nAges 
        age
        %train the network
        [wt1, wt2] = GAMIT_Learning(params,nCurves,nSamples,wt1,wt2);
        %see what it outputs & store results
        AllRet(learner,age,:) = GAMIT_Net(testCases,1,0,0,params,wt1,wt2);
        AllPro(learner,age,:) = GAMIT_Net(testCases,1,1,0,params,wt1,wt2);
    end
end

epochs = 1:nAges;
TotalTrainingItems = nCurves*nSamples*1:nAges;
%find average 
RetByAge = squeeze(mean(AllRet,1));
ProByAge = squeeze(mean(AllPro,1));
plotGraphs(testCases,RetByAge,ProByAge,'Retrospective SRN Learning','Prospective SRN Learning','Time Estimate',true,true,epochs);

%%%%%%%%%% SIMULATION 2 %%%%%%%%%%%%%%%
% %now lets look at error in a single trained network
% %can use last network trained in sim 1.
 %or train a new one
 nCurves = 500;
 nSamples = 100;
 [wt1, wt2] = GAMIT_Learning(params,nCurves,nSamples);
nTrials = 20; 
AllRet = zeros(nTrials,length(testCases));
AllPro = AllRet;
for i = 1:nTrials 
    AllRet(i,:) = GAMIT_Net(testCases,1,0,0,params,wt1,wt2);
    AllPro(i,:) = GAMIT_Net(testCases,1,1,0,params,wt1,wt2);
end
ErrRet = std(AllRet,1);
ErrPro = std(AllPro,1);
plotGraphs(testCases,ErrRet,ErrPro,'Retrospective SD','Prospective SD','Estimates Standard Deviation',false, false,0);

RelErrRet = ErrRet ./ mean(AllRet,1);
RelErrPro = ErrPro ./ mean(AllPro,1);
%least squares linear regression
p = polyfit(testCases,RelErrRet,1);
fittedRet = polyval(p,testCases);
p = polyfit(testCases,RelErrPro,1);
fittedPro = polyval(p,testCases);
plotGraphs(testCases,[RelErrRet;fittedRet],[RelErrPro;fittedPro],'Retrospective Relative Error','Prospective Relative Error','Error / Interval Length',false, false,0);

%%%%%%%%%% SIMULATION 3 %%%%%%%%%%%%%%%
% % %now lets look at cognitive load 

%first plot the comparison graph to Block, Hancock and Zakay 2010
GAMIT_Net_Retro_Pro_Interaction(600,20,0.95,1.05,true,false,wt1,wt2);

% then plot lo,med,hi across full range
AllRet = zeros(3,nTrials,length(testCases));
AllPro = AllRet;
for i = 1:nTrials
    %retrospective low, normal high
    AllRet(1,i,:) = GAMIT_Net(testCases,0.9,0,0,params,wt1,wt2);
    AllRet(2,i,:) = GAMIT_Net(testCases,1.0,0,0,params,wt1,wt2);
    AllRet(3,i,:) = GAMIT_Net(testCases,1.1,0,0,params,wt1,wt2);
    %retrospective low, normal high
    AllPro(1,i,:) = GAMIT_Net(testCases,0.9,1,0,params,wt1,wt2);
    AllPro(2,i,:) = GAMIT_Net(testCases,1.0,1,0,params,wt1,wt2);
    AllPro(3,i,:) = GAMIT_Net(testCases,1.1,1,0,params,wt1,wt2);
end
 
Ret = squeeze(mean(AllRet,2));
Pro = squeeze(mean(AllPro,2));

plotGraphs(testCases,Ret,Pro,'Retrospective Low vs Normal vs High Cog Load','Prospective Low vs Normal vs High Cog Load','Time Estimates',true,false, 0);
end

function plotGraphs(testCases, retroResults, prospResults, retroTitle, prospTitle,ylab,includeDiagonal,showcolorbar,epochs)
    
    figure;
    [r,~] = size(retroResults);
    cc=hsv(r);
    colormap(cc);
    if showcolorbar
        ticks = 2:2:length(epochs);
    end 

    subplot(2,1,1);
    hold on;
    for i=1:r
        plot(testCases,retroResults(i,:),'Color',cc(i,:));
    end
    if includeDiagonal
         plot(testCases,testCases,':k');
    end
    xlabel('Target Time');
    ylabel(ylab);
    title(retroTitle);
    if showcolorbar
        hd=colorbar('location','EastOutside','YTick',ticks,'YTickLabel',epochs(ticks));
        set(get(hd,'title'),'String','Epochs');
    end

    hold off;
    subplot(2,1,2);
    hold on;
    for i=1:r
        plot(testCases,prospResults(i,:),'Color',cc(i,:));
    end
    if includeDiagonal
        plot(testCases,testCases,':k');
    end
    xlabel('Target Time');
    ylabel(ylab);
    title(prospTitle);
    hold off;
    if showcolorbar
        hd= colorbar('location','EastOutside','YTick',ticks,'YTickLabel',epochs(ticks));
        set(get(hd,'title'),'String','Epochs');
    end
    figureHandle = gcf;
    %# make all text in the figure to size 14 and bold
    set(findall(figureHandle,'type','text'),'fontSize',14,'fontWeight','bold')
end
    