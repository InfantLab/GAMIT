function ReferenceCurve = GAMIT_Lifetime(params, N, showGraphics)
%
% generates an average lifetime activation curve. Has default values but
% accepts overrides

if nargin < 1   
    params = GAMIT_Params();
end
if nargin < 2
    N = 50; %default
end
if nargin < 3
    showGraphics = false;
end 
%initialise storage
gamitScore =zeros(N,params.nIterations); 
scoreDelta =zeros(N,params.nIterations); 
nSamples = round(params.nIterations/params.sampleFrequency); 
%generate N curves
for i= 1:N
   [gamitScore(i,:), ~] = GAMIT_Spreading_Activation(params);
   
   % work out corresponding delta curves      
   % randomly sample from this activation curve
   if params.PoissonSampling
       sampleTimes = PoissonSequence(params.nIterations, params.sampleFrequency);
   else %uniform random sample
       sampleTimes = sort(ceil(params.nIterations*rand(1, nSamples)));
   end
   %include  end event for interpolation
   sampleTimes = [sampleTimes params.nIterations ];
   %remove duplicates
   sampleTimes = unique(sampleTimes);
   deltas =  diff(gamitScore(i,[1 sampleTimes]));
   if ~params.GaussianFit
      %deltas are negative 
      deltas = -1*deltas;
   end
%    %ignore negatives
%    deltas(deltas<0)=0;
   nD = length(deltas);
   meandeltas = zeros(1,nD);
   if params.WorkingMemoryDelta
       %delta estimates are constrained by working memory limitations
       for d = 1:nD
           nDeltas = min(d,params.nSampleDeltas);
           if params.RandomAccessMemory
                %randomly select from deltas found so far
               %simulate the random selection and averaging of deltas 
               %total of params.nSampleDeltas are held in Working memory at any time     
                scrambledDeltaIndices = randperm(d);
                rememberedDeltaIndices = scrambledDeltaIndices(1:nDeltas);
           else 
                %select most recent nDeltas found so far
                rememberedDeltaIndices = d:-1:(d+1-nDeltas);
           end
           %current deltaEstimate is the average of these
           meandeltas(d) = mean(deltas(rememberedDeltaIndices));
       end

   else
       %delta estimates are just a running mean of all deltas so far
       for d=1:nD
           meandeltas(d) = mean(deltas(1:d));
       end
   end
   %linearly interpolate across missing values
   scoreDelta(i,:) = interp1(sampleTimes, meandeltas,1:params.nIterations,'linear','extrap');

end

%average them together
ReferenceCurve.GamitScore = mean(gamitScore,1); 
ReferenceCurve.GamitScoreUncertainty = std(gamitScore, 1);
ReferenceCurve.Delta = mean(scoreDelta,1); 



if showGraphics
    %plot this average curve and the information that went into building it
    %calculated std deviation
    lifetimeUncertainity = std(gamitScore, 1);
    %calculate how this applies to the ref curve
    lifetimeUpper =  ReferenceCurve.GamitScore + lifetimeUncertainity;
    lifetimeLower =  ReferenceCurve.GamitScore - lifetimeUncertainity;
    
    %Plot the lifetime activation curve
    scrsz = get(0,'ScreenSize');
    hf=figure('Position',[0 0.5*scrsz(4) 0.5*scrsz(3), 0.5*scrsz(4)]);
    %shorthand
    nPts=params.nIterations;
    %group history lines
    histLines=plot(1:nPts,gamitScore','Color',[0.8,0.8,1]);
    hSGroup = hggroup;
    set(histLines,'Parent',hSGroup);
    % Include this hggroups in the legend:
    set(get(get(hSGroup,'Annotation'),'LegendInformation'),'IconDisplayStyle','on');
%     axis([1,nPts, 0.0, 1.6]);
    hold on;
       %finally plot 
       plot(1:nPts,ReferenceCurve.GamitScore,'b','LineWidth',2 );
       %plot a shaded error band
       patch([1:nPts (nPts:-1:1)], [lifetimeUpper lifetimeLower(nPts:-1:1)],[0.8,0.8,1], ...
             'FaceColor',[0.8,1,0.8],'EdgeColor',[0.9,0.9,0.9],'FaceAlpha',0.5);
       title('Average activation curve and associated uncertainty.');
       if params.GaussianFit
           %least squares linear regression
            p = polyfit(1:nPts,ReferenceCurve.GamitScore(1:nPts),1);
            fitted = polyval(p,1:nPts);
            plot(1:nPts,fitted, 'r');
            fitdescription = 'Best linear fit' ;
            legend('History of GamitScore','Lifetime Average','Uncertainty',fitdescription,'Location','SouthWest');

       else
           %fit a comparison exponential decay curve
           F = @(p,xdata) p(1)*exp(p(2)*(xdata));
           [p,resnorm] = lsqcurvefit(F,[1.6 .001],1:nPts,ReferenceCurve.GamitScore);
           plot(1:nPts, p(1)*exp((1:nPts) * p(2)),'r','LineWidth',2 );
           fitdescription = 'Best exponential fit' ;
           resnorm
           % or fit a logarithmic decay function
           F = @(p,xdata) p(1)*log(xdata) + p(2);
           [p,resnorm] = lsqcurvefit(F,[-.143 1.7],1:nPts,ReferenceCurve.GamitScore);
           
            legend('History of GamitScore','Lifetime Average','Uncertainty',fitdescription,'Location','SouthWest');    
%            %plot this on the same graph
%            plot(1:nPts, p(1)*log(1:nPts) + p(2),'m','LineWidth',2 );
%            fitdescription2 = 'Best logarithmic fit' ;
%            resnorm
%            legend('History of GamitScore','Lifetime Average','Uncertainty',fitdescription,fitdescription2,'Location','SouthWest');    
       end
    hold off;
    %picture in picture of growth in Std Dev.
    if params.GaussianFit
        hx2=axes('parent',hf,'position',[0.57 0.16 0.27 0.3]); % normalized units are used for position 
    else
        hx2=axes('parent',hf,'position',[0.55 0.55 0.3 0.3]); % normalized units are used for position 
    end
    plot(1:nPts,lifetimeUncertainity,'r');
    title('Uncertainty in average activation.');
    
    %Plot the lifetime delta curve
    hf2=figure('Position',[0.5*scrsz(3) 0.5*scrsz(4) 0.5*scrsz(3), 0.5*scrsz(4)]);
     %group history lines
    histDeltas=plot(1:nPts,scoreDelta','Color',[0.8,0.8,1]);
    hSGroup = hggroup;
    set(histDeltas,'Parent',hSGroup);
    % Include this hggroups in the legend:
    set(get(get(hSGroup,'Annotation'),'LegendInformation'),'IconDisplayStyle','on');
    hold on;
        plot(1:nPts,ReferenceCurve.Delta,'b','LineWidth',2 );
    hold off;
    title('Lifetime delta curve');
    legend('History of delta curves','Lifetime Average','Location','Best');
    
end
