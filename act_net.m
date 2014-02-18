function [act, dact] = act_net(A,temp,theta)
% calculates an activation for each element of A
% using logistic equation with appropriate temp & theta & translation of
% the origin.

% defaults for if we haven't been given vals for temp & theta
if nargin < 2, temp = 1.0; end
if nargin < 3, theta = 0.0; end

if temp == 1.0 && theta == 0.0
    act = 1./(1 + exp(-1*A));
    dact = act.*(1.-act);
else
    b= exp ( - temp * A + theta);
    act = 1./(1 + b);
    c= (1+ b).*(1+b);
    dact = (temp * b ) ./ c;
end

