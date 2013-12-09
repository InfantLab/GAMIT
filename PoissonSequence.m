function [seq] = PoissonSequence(MaxN,lambda)
%
% generates a cumulatitve sequence of intervals
% where points obey a Poisson distribution upto
% total sum of MaxN

seq = cumsum(poissrnd(lambda,1,floor(5*MaxN/lambda)));
seq(seq>MaxN)= [];