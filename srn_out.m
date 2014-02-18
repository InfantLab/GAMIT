function OUTPUTS = local_srn_out(IN, Wt1, Wt2,forgettingrate,hidnoise, beta)
% usage  OUT = local_srn_out(IN, Wt1, Wt2)
%
% nnet with one hidden layer and Elman type recurrence
% 
% generates expected output sequence for given input  

% do we have forgettingrate?
if nargin < 4, forgettingrate = 0.0; end
if nargin < 5, hidnoise = 0.0; end
if nargin < 6, beta = 1.0; end

% get the dimensions of our data sets
[datarows, inelem]=size(IN); 

[wt1r,wt1c] = size(Wt1);
nhidnodes = wt1r;

LastHiddenActivation =zeros(wt1r,1);

OUTPUTS = [];

for p = 1:datarows
    % get appropriate input & target rows
    % though we will represent them as col vectors
    A = IN(p,1:inelem)';    
    A = [A;LastHiddenActivation];
    
    % feedforward
    % layer 1
    B1 = Wt1*[A;1];  % input & bias
    [O1,~] = act_net(B1,beta,0);
    
    % is there any noise in transmission? 
    % add it to the outputs of the hidden layer
    O1 = O1 + sqrt(hidnoise)*randn(nhidnodes,1);
    % store internal state for next loop
    % but mulitplied by forgettingrate
    LastHiddenActivation = (1-forgettingrate)*O1;
    
    % layer 2
    B2 = Wt2*[O1;1]; %output and a bias node
    [O2,~] = act_net(B2,beta,0);

    OUTPUTS = [OUTPUTS; O2']; 
end


