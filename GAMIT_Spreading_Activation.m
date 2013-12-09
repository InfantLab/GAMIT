
function [GamitScore, AllCurves] = GAMIT_Spreading_Activation(params,showGraphics)
%
% This function takes parameters for GAMIT spreading activation curve and
% returns the time-evolving activation score and the shapes of the corrsponding curves.

if nargin < 1
    params = GAMIT_Params();
end
if nargin < 2
    showGraphics = false;
end

BAB = [params.beta, params.alpha, params.beta];  % Kernel for the convolution

%some limits and other parameters
maxActivation = params.initialActivation;
minActivation = params.noiseFactor;

Activations = zeros(1,params.nColumns);
%start with activation in middle column
Activations(floor(params.nColumns/2)) = params.initialActivation;

%arrays for recording evolution of curve
AllCurves = zeros(params.nIterations,params.nColumns);

for i = 1:params.nIterations
  % Convolve current activation curve with BAB kernel.
  Activations =   conv(Activations, BAB, 'same');
  %now add noise
  Activations = Activations + params.noiseFactor*randn(1,params.nColumns);
  %apply thresholds
  Activations(Activations>maxActivation) = maxActivation;
  Activations(Activations<minActivation) = minActivation;
  %keep record of this activation curve
  AllCurves(i,:) = Activations;  
end;

%NOW WORK OUT THE GAMIT SCORES
if params.GaussianFit
    xs = 1:params.nColumns;
    for n=1:params.nIterations
        %activation value is best estimate for sigma of this curve
%            [sigma mu A] = mygaussfit(1:params.nColumns,AllCurves(n,:));
%            TotalActivation(n) = sigma;
        ys = AllCurves(n,:);
        meanx = sum(ys.*xs)/sum(ys);
        varx = sum(ys.*((xs-meanx).*(xs-meanx)))/sum(ys);
        GamitScore(n) = sqrt(varx);
    end
else
    %get total activation per iteration
    SummedActivation = sum(AllCurves,2);
    %get max for each row
    GreatestActivation = max(AllCurves,[],2);
    %current model based on combination of these two values
    GamitScore = SummedActivation + GreatestActivation;
end

if showGraphics
    %Graphics code producing the monotonically decreasing activation curve
    %first generate window for the figure
    scrsz = get(0,'ScreenSize');
    figure('Position',[1 0.5*scrsz(4) 0.75*scrsz(3), 0.5*scrsz(4)]);

    snapshots = [];
    for step = 10:10:params.nIterations
        %spreading activation
        subplot(1,2,1);
        plot(41:160, AllCurves(step,41:160)); 
        axis([61,140,0,0.3]);
        xlabel('Column activations');
        ylabel('Activation');
        title(['GAMIT Spreading activation t = ' num2str(step)]);
        if (mod(step,100) == 10)
            snapshots = [snapshots;step];
        end
        hold on
            for i=1:length(snapshots)
                line(41:160,AllCurves(snapshots(i), 41:160),'LineStyle',':');
            end
        hold off
        %Total Activation
        subplot(1,2,2);
        plot(1:step, GamitScore(1:step)); 
        ymax = 1.05* max(GamitScore);
        axis([0,params.nIterations, 0, ymax]);
        xlabel('Time steps');
        ylabel('GAMIT Score');
        title(['GAMIT Total Score t = ' num2str(step)]);
        drawnow;
        pause(0.01);
    end
end