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
minActivation = 0.1*params.noiseFactor;

Activations = zeros(1,params.nColumns);
%start with activation in middle column
Activations(floor(params.nColumns/2)) = params.initialActivation;

%arrays for recording evolution of curve
AllCurves = zeros(params.nIterations,params.nColumns);
%initialise some noise 
AllNoise = randn(params.nIterations,params.nColumns);

for i = 1:params.nIterations
  % Convolve current activation curve with BAB kernel.
  Activations =  conv(Activations, BAB, 'same');
  %now add noise
  Activations = Activations + params.noiseFactor*AllNoise(i,:);
%   %apply thresholds
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

if ~showGraphics
else
    %Graphics code producing the monotonically decreasing activation curve
    %first generate window for the figure
    scrsz = get(0,'ScreenSize');
    figure('Position',[1 0.5*scrsz(4) 0.75*scrsz(3), 0.5*scrsz(4)]);

    snapshots = [];
    %get a nice set of colors for all the lines
    cc=hsv(13);
    for step = 10:10:1610
        %spreading activation
        if showGraphics == 2
            subplot(1,2,1);
        end
        plot(41:160, AllCurves(step,41:160)); 
        axis([61,140,0,0.15]);
        xlabel('Column activations');
        ylabel('Activation');
        title(['GAMIT Spreading activation t = ' num2str(step)]);
        if (mod(step,150) == 10)
            snapshots = [snapshots;step];
        end
        hold on
            for i=1:length(snapshots)
                line(41:160,AllCurves(snapshots(i), 41:160),'Color',cc(i,:),'LineWidth',1);
            end            
        hold off
        if showGraphics == 2
            subplot(1,2,2);
            plot(1:step, GamitScore(1:step)); 
            ymax = 1.05* max(GamitScore);
            axis([0,params.nIterations, 0, ymax]);
            
            xlabel('Time steps');
            ylabel('GAMIT Score');
            title(['GAMIT Total Score t = ' num2str(step)]);
        end
        %Total Activation
        drawnow;
        if step <460
            pause(0.05);
        elseif step < 900
            pause(0.02);
        else
            pause(0.01);
        end
    end
    colorbar('location','EastOutside','YTick',5*[1:length(snapshots)],'YTickLabel',snapshots(end:-1:1));
end