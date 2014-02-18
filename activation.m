function a = activation(A,temp,theta,translation)
% calculates an activation for each element of A
% using logistic equation with appropriate temp & theta & translation of
% the origin.

% defaults for if we haven't been given vals for temp & theta
if nargin < 2, temp = 1.0; end
if nargin < 3, theta = 0.0; end
if nargin < 4, translation = 0.0; end

b = - temp .* (A - translation); 
b = b + theta;
a =  1./(1 + exp(b));

