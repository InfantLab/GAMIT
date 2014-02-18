function [out] = LogRepresentation(values,vectorwidth,lo, hi, inverseFlag)
%
% helper function to map single values to a log scale ice cube tray
% equivalent to the Vincent Walsh (2003) ATOM representation
%
% such that values between log(low) and log(hi) from left to
% right with integer and decimal parts such that log(low) = [0 0 ...] and log(hi) = [1 1 ...], 
% e.g log(10) ->  2.5 -> [1 1 0.5 0 0] 
% if inverseFlag is true then we go from ATOM vectors to numerical scalars.
%
% there's probably an easier way but i don't know it.
%
% note - this function does not validate that vectorized inputs have
% correct form.

if nargin < 5; inverseFlag = false; end;

if lo <= 0 
    error('lower bound lo must be greater than zero');
end
        
if inverseFlag
    out = exp(Scalar2ThermometerCode(values,vectorwidth,log(lo),log(hi), inverseFlag));
else
    out = Scalar2ThermometerCode(log(values),vectorwidth,log(lo), log(hi), inverseFlag);
end





