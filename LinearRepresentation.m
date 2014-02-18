function [out] = LinearRepresentation(values,vectorwidth,lo, hi, inverseFlag, binaryFlag)
%
% wrapper function  around scalar2icecubetray that provides binary version
% function instead of  [1 1 1 1 1 1 .21 0 0 0]         
% with binaryflag      [1 1 1 1 1 1  1  0 0 0]
%
% what happens when you invert this.. (ah now you're asking)
%  we pick the maximum column over a threshold and use that.
% 

if nargin < 6, binaryFlag = false; end
    
out = Scalar2ThermometerCode(values,vectorwidth,lo,hi,inverseFlag);

if ~inverseFlag && binaryFlag
    out = ceil(out);
end

