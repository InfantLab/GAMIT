function a = d_activation(A,temp,theta)
% the derivative of the logistic equation for each element of A
% note: inputs are original values of A not their activations
if nargin < 2, temp = 1.0; end
if nargin < 3, theta = 0.0; end
if temp == 1.0 && theta == 0.0
f = 1./(1 + exp(A));
a = f.*(1.-f);
else
b= exp ( - temp * A + theta);
c= (1+ b).*(1+b);
a = (temp * b ) ./ c;
end
