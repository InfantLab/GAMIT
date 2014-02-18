function [Wt1, Wt2 ] = backprop(IN, OUT, nhidnodes,nepochs, wt1, wt2, gamma,hidnoise,momentum, beta, trackdevelopment)
%
% feedforward nnet with one hidden layer 
% 
% learning with backpropagation 

% get the dimensions of our data sets
[datarows, inelem]=size(IN); 
[~, outelem]=size(OUT);

if nargin < 4, nepochs = 100; end
if nargin < 5
    % initialise random weight matrices
    Wt1 = 0.1* randn(nhidnodes,inelem + 1); % +1 for bias!
    Wt2 = 0.1* randn(outelem, nhidnodes + 1); 
else
    Wt1 = wt1;
    Wt2 = wt2;
end

% defaults for if we haven't been given vals for gamma & nepochs
if nargin < 7, gamma = 0.05; end
if nargin < 8, hidnoise = 0.0; end
if nargin < 9, momentum = 0.005; end
if nargin < 10, beta = 1.0; end
if nargin < 11, trackdevelopment = false; end %if true note the weights at end of each epoch



Thid = zeros(nhidnodes,1);
        
old_dWt1 = 0.0;
old_dWt2 = 0.0;

for n = 1:nepochs
%     disp(strcat('epoch ', n));
    %randomise order of training items
    rp = randperm(datarows);
    for p = 1:datarows
        q = rp(p);
        % get appropriate input & target rows
        % though we will represent them as col vectors
        A = IN(q,1:inelem)';    
        T = OUT(q,1:outelem)';
        % feedforward
        % layer 1 
        B1 = Wt1*[A;1];  % input & bias
        O1 = activation(B1,beta,0);
      
        % is there any noise in transmission? 
        % add it to the outputs of the hidden layer
        % note with the exp  this is lognormal 
%        O1 = O1 + sqrt(hidnoise)*exp(randn(nhidnodes,1));
        if hidnoise > 0
            O1 = O1 + sqrt(hidnoise)*randn(nhidnodes,1);
        end

        d_O1 = d_activation(B1,beta,0);
        
        % layer 2
        B2 = Wt2*[O1;1]; %output and a bias node
        O2 = activation(B2,beta,0);
        d_O2 = d_activation(B2,beta,0);
   
        % calculate & apply the delta adjustments to output layer
        dWt2 = ((T-O2) .* d_O2) * [O1;1]' ;
        
        % now back propogate the errors
        % construct nhidnodes x 1 vector for the interim targets         Thid = zeros(nhidnodes,1);
        for k = 1:nhidnodes
            Thid(k,1) = Wt2(:,k)'* dWt2(:,k); % dot product of kth cols of Wt2 & output error
        end
    
        % using this target find weight changes
        dWt1 = (Thid .* d_O1) * [A;1]' ;
        dWt1 = gamma * dWt1; % apply the learning rate scalar
        dWt2 = gamma * dWt2; % apply the learning rate scalar
        
        % shift weight by delta + bit of old delta
        Wt1 = Wt1 + dWt1 + momentum * old_dWt1;    
        Wt2 = Wt2 + dWt2 + momentum * old_dWt2;
        
        % note old error
        old_dWt1 = dWt1;
        old_dWt2 = dWt2;
    end
    DevWeights1{n} = Wt1;
    DevWeights2{n} = Wt2;
end

if trackdevelopment
    Wt1 = DevWeights1;
    Wt2 = DevWeights2;
end