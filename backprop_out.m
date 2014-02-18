function OUTPUTS = backprop_out(IN, Wt1, Wt2,hidnoise, beta)
% usage  OUT = backprop_out(IN, Wt1, Wt2)
%
% nnet with one hidden layer 
% 
% generates expected output sequence for given input  

% do we have forgettingrate?
if nargin < 4, hidnoise = 0.0; end
if nargin < 5, beta = 1.0; end

% get the dimensions of our data sets
[datarows, inelem]=size(IN); 

[wt1r,wt1c] = size(Wt1);
nhidnodes = wt1r;


OUTPUTS = [];

for p = 1:datarows
    % get appropriate input & target rows
    % though we will represent them as col vectors
    A = IN(p,1:inelem)';  
%     A = IN(p,1:inelem)';    
    
    % feedforward
    % layer 1
    B1 = Wt1*[A;1];  % input & bias
    O1 = activation(B1,beta,0);
    
    if hidnoise > 0 
        % is there any noise in transmission? 
        % add it to the outputs of the hidden layer
        O1 = O1 + sqrt(hidnoise)*randn(nhidnodes,1);
    end
    
    % layer 2
    B2 = Wt2*[O1;1]; %output and a bias node
    O2 = activation(B2,beta,0);

    OUTPUTS = [OUTPUTS; O2']; 
end


