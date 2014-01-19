function GAMIT_Weber_Demo(targetTime, nSamples, prospectiveFlag,method,exportRawData)
%
% Demonstrate that time estimates in the GAMIT model have the scalar
% property. 
%
%   targetTime      = Actual length of interval as number of simulation steps
%   nSamples        = number of times we try to estimate this target
%   prospectiveFlag = 0,false [Retrospective], 1,true [Prospective]
%   method          = 0,'hist' compare targetTime and 1.5*targetTime as histograms
%                     1,'bars' compare targetTime & 0.2:0.2:2 * targetTime as estimates & errorbars
%   exportRawData   = 0,1,true,false, save 

if nargin<1
    targetTime = 800;
end
if nargin<2
    nSamples = 100;
end
if nargin<3
    prospectiveFlag = false;
end 
if nargin<4 
    method = 0;
end
if nargin<5
    exportRawData = false;
end

if prospectiveFlag 
    pro_or_ret = 'Prospective';
else
    pro_or_ret = 'Retrospective';
end

%step 1: Get default params & generate a reference curve
params = GAMIT_Params();
lifetimeCurve = GAMIT_Lifetime(params);

%now generate window for the figure
scrsz = get(0,'ScreenSize');
figure('Position',[1 0.5*scrsz(4) 0.75*scrsz(3), 0.5*scrsz(4)]);

if method == 0 || strcmpi(method,'hist') %webers law as histograms. 
    %step 2 - generate lots of estimates
    targetArray = targetTime * ones(1,nSamples);
    intervalEstimates = GAMIT(targetArray,1.0,prospectiveFlag,false,params,lifetimeCurve);

    %step 3 - generate comparison of estimates
    targetArray2 = 1.5 * targetTime * ones(1,nSamples);
    intervalEstimates2 = GAMIT(targetArray2,1.0,prospectiveFlag,false,params,lifetimeCurve);


    %webers law as histograms. 
    subplot(1,2,1);
    hold on;
    hist(intervalEstimates,80);
    h = findobj(gca,'Type','patch');
    set(h,'FaceColor','r','EdgeColor','w')
    title([pro_or_ret ' Histograms of estimates for target interval (red) & 1.5 * target (blue)']);
    subplot(1,2,1);
    hist(intervalEstimates2,80);
    hold off

    %scale these histograms 
    x=0:40/targetTime:3;
    [n,xout]=hist(intervalEstimates/targetTime,x);
    [n2,xout2]=hist(intervalEstimates2/(1.5*targetTime),x);

    subplot(1,2,2);
    bar(x,[n' n2']);
    title(['Scaled histograms of estimates - ' pro_or_ret]);
    
    if exportRawData
        t = table(retrospectiveLow,retrospectiveHigh,prospectiveLow,prospectiveHigh);
        writetable(t,'GAMIT_Weber_Demo.csv','Delimiter',',');
        save('GAMIT_Weber_Params.mat','params');
    end
        
else %webers law as error bars. 
    multipliers = [0.2:0.2:2];
    nSteps = length(multipliers);
    targetArray = targetTime * ones(1,nSamples);
    for i = 1:nSteps
        intervalEstimates(i,:) = GAMIT(multipliers(i)*targetArray,1.0,prospectiveFlag,false,params,lifetimeCurve);
    end
    
    %left hand panel
    subplot(1,2,1);
    %webers law as error bars. 
    x=targetTime*multipliers;
    y=mean(intervalEstimates,2);
    y2=std(intervalEstimates,1,2);
    plot(x,y);
    ymax = max(max(intervalEstimates));
    axis([0 2.1*targetTime 0 ymax]);
    title([pro_or_ret ' GAMIT estimates for range of intervals with error bars']);
    xlabel('Target interval (number simulation steps)');
    ylabel('GAMIT Estimate');
    hold on;
        errorbar(x,y,y2);
    hold off;
    
    %right hand panel
    subplot(1,2,2);
    hold on;
    plot(x,y2);
    ymax = 1.1*max(y2);
    %fit Y = mX +c
    p = polyfit(x',y2,1);
    fitted = polyval(p,1:params.nIterations);
    plot(1:params.nIterations,fitted, 'r');
    %fit y= mX (method 1)
    m = x'\y2; % or m = pinv(X)*Y;
	plot(1:params.nIterations, m*[1:params.nIterations], 'g');
%     %fit y = mX (method 2)
%     F = @(p,xdata) p(1)*(xdata);
%     [p,resnorm] = lsqcurvefit(F,[0.05],x,y2');
%     plot(x,p(1)*x,'y');
    axis([0 2.1 * targetTime 0 ymax]);
    title([pro_or_ret ' Scaled errors']);
    xlabel('Target interval (number simulation steps)');
    ylabel('GAMIT Relative Error');
    legend('Relative Error','Best linear fit','Best scalar fit','Location','Best');
    hold off
   
end