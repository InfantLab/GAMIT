function [Wt1, Wt2 ] = srn(IN, OUT, nhidnodes,nepochs,wt1,wt2,gamma,forgettingrate,hidnoise,momentum, beta, trackdevelopment )
%
% nnet with one hidden layer and Elman type recurrence
% 
% learning with backpropagation 
% 
% get the dimensions of our data sets
[datarows, inelem]=size(IN); 
[~, outelem]=size(OUT);

if nargin < 4, nepochs = 1; end
if nargin < 5
    % initialise random weight matrices
    Wt1 = 0.1* randn(nhidnodes,inelem + nhidnodes + 1); % +1 for bias!
    Wt2 = 0.1* randn(outelem, nhidnodes + 1); 
else
    Wt1 = wt1;
    Wt2 = wt2;
end

% defaults for if we haven't been given vals for gamma & nepochs
if nargin < 7,  gamma = 0.05; end
if nargin < 8,  forgettingrate = 0.0; end
if nargin < 9,  hidnoise = 0.0; end
if nargin < 10, momentum = 0.005; end
if nargin < 11, beta = 1.0; end
if nargin < 12, trackdevelopment = false; end %if true note the weights at end of each epoch


LastHiddenActivation =zeros(nhidnodes,1);
        
old_dWt1 = 0.0;
old_dWt2 = 0.0;
if trackdevelopment
    DevWeights1 = cell(nepochs);
    DevWeights2 = cell(nepochs);
end 
for n = 1:nepochs
%     disp(strcat('epoch ', n));
    for q = 1:datarows
        % get appropriate input & target rows
        % though we will represent them as col vectors
         % input & context & bias unit
        Input = [IN(q,1:inelem)';LastHiddenActivation;1];    
        Target = OUT(q,1:outelem)';
        % feedforward
        % layer 1 
        B1 = Wt1*Input; 
        %get activation & its derivative
        [O1,d_O1] = act_net(B1,beta,0);
      
        % is there any noise in transmission? 
        % add it to the outputs of the hidden layer
        % note with the exp  this is lognormal 
%        O1 = O1 + sqrt(hidnoise)*exp(randn(nhidnodes,1));
        O1 = O1 + sqrt(hidnoise)*randn(nhidnodes,1);

        % store internal state for next loop
        % but multiply each value by (1-forgetting rate)
        LastHiddenActivation = (1-forgettingrate) * O1;
             
        % layer 2
        B2 = Wt2*[O1;1]; %output and a bias node
        [O2,d_O2] =act_net(B2,beta,0);
        
        % calculate & apply the delta adjustments to layer2
        Layer2Error = (Target-O2) .* d_O2;
        dWt2 = Layer2Error * [O1;1]';
        
        % now back propogate the errors
        Result1Error = Wt2' * Layer2Error;
        %Layer1 error removng the bias 
        Layer1Error = Result1Error(1:end-1,:) .* d_O1;
        
        % use this target find weight changes for layer2
        dWt1 = Layer1Error * Input';

        dWt1 = gamma * dWt1; % apply the learning rate scalar
        dWt2 = gamma * dWt2; % apply the learning rate scalar
        
        % shift weight by delta + bit of old delta
        Wt1 = Wt1 + dWt1 + momentum * old_dWt1;    
        Wt2 = Wt2 + dWt2 + momentum * old_dWt2;
        
        % note old error
        old_dWt1 = dWt1;
        old_dWt2 = dWt2;
    end
    if trackdevelopment
        DevWeights1{n} = Wt1;
        DevWeights2{n} = Wt2;
    end
end

if trackdevelopment
    Wt1 = DevWeights1;
    Wt2 = DevWeights2;
end