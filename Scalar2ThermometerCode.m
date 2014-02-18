function out = Scalar2ThermometerCode(inputValues,traywidth,emptyvalue,fullvalue, inverseFlag)
%
% helper function to map (column of) single scalars between low and fullvalue from left to
% right with integer and decimal parts such that low = [0 0 ...] and fullvalue = [1 1 ...], 
% e.g 2.5 -> [1 1 0.5 0 0] 
% if inverseFlag is true then we go from vectors to numerical scalars.
% there's probably an easier way but i don't know it.
% note that it doesn't validate that input in correct formats.
% but what about going the other way?
% easy [1 1 0.5 0 0] -> 2.5
% hard [0.97 0.84 0.52 0.23 0.02] -> ????  
% two answers either apply a trheshold ignore terms to right
%      [0.97 0.84 0.52 0.23 0.02] -> [1 1 0.52 0.23 0] -> 2.52
% or use a simple sum.
%      [0.97 0.84 0.52 0.23 0.02] -> 2.58

if nargin < 5; inverseFlag = false; end;

range = fullvalue - emptyvalue;              

if inverseFlag 
    if true
        summedcols = sum(inputValues, 2);
        out = range .* (summedcols)/traywidth + emptyvalue;
    else        
        maxthreshold = 0.7;
        minthreshold = 0.1;
        [R C] = size(scalars);
        %int part is just sum of 1's per row
        filledcells = scalars > maxthreshold;
        intpart = sum(filledcells,2);
        for rw = 1:R
            if intpart(rw) == traywidth
                %decimal part is zero
                decpart(rw) = 0;
            else
                %decimal part found in next column along
                decpart(rw) = scalars(rw, intpart(rw)+1);
                %but round down small values
                if decpart(rw) < minthreshold
                    decpart(rw) = 0;
                end
            end
        end
        out = range .* (intpart+decpart')/traywidth + emptyvalue;
    end
else
    [Nrows Ncols] = size(inputValues);
    idx=1:traywidth;  
    allidx=repmat(idx,Nrows,1);
    scaledvalues = traywidth*(inputValues - emptyvalue)/range;
    intpart = floor(scaledvalues)';                  %integer part
    decpart = scaledvalues' - intpart;               %decimal part
    repscaledvalues = repmat(intpart',1,traywidth);
    out = allidx<=repscaledvalues; 
    out = 1.0 * out;                               %make sure it's array of reals
    %special cases where intpart = full array of ones to avoid subscript error
    decpart(intpart==traywidth) =1;
    intpart(intpart==traywidth) = traywidth -1;
    inds = sub2ind(size(out), (1:Nrows),intpart + 1); %find where to put dec vals
    out(inds) = decpart;
end







