function r = poissrnd(lambda,m,n,state,method)
%POISSRND Random matrices from Poisson distribution.
%	R = POISSRND(LAMBDA) returns a matrix of random numbers chosen   
%	from the Poisson distribution with parameter LAMBDA.
%
%	The size of R is the size of LAMBDA. Alternatively, 
%	R = POISSRND(LAMBDA,M,N) returns an M by N matrix. 
%
%	Use R = POISSRND(LAMBDA,M,N,STATE) to initialise the random
%	number generator with STATE. Use R = POISSRND(LAMBDA,[],[],STATE)
%	when M and N are not given and POISSRND([],[],[],STATE) when
%	only the random number generator needs to be initialised.
%	POISSRND([],[],[],0) resets the generator to its initial state.
%	POISSRND([],[],[],J), for integer J, resets the generator to its J-th state.
%	POISSRND([],[],[],sum(100*clock)) resets it to a different state each time.
%	Note: POISSRND actually initialises RAND and RANDN.
%
%	Use R = POISSRND(LAMBDA,M,N,STATE,METHOD) to determine the method.
%	METHOD='normal' (default) uses a waiting time method.
%	METHOD='fast' uses a waiting time method at lambda<1000 and
%			normal distribution with mean and variance equal to lambda
%			at labda>=1000.
%	METHOD=value equal to 'fast' but with the border set at value
%  		instead of 1000.
%	Use R = POISSRND(LAMBDA,[],[],[],METHOD) when M, N and STATE are
%	not given.
%
%	For more information see the M-file.

%  Addition 1 (12-3-1999):  
%	This version of POISSRND has been improved in performance
%	by Mischa Tolsma, MMR-TN TU Delft. It removes elements of
%   which the result already has been found from the search matrix.
%	It's major speedup occurs when lambda contains a lot of 
%	small elements with just a few large ones.
%	
%	Speed up factors:
%	0.1 % large elements: 10
%	100 % large elements: 1.3 both at an array of 1000
%
%  Addition 2 (14-7-2000):
%  This version of POISSRND allows the use of normal distribution as an
%  approximation of the Poisson distribution at large values of lambda.
%  The Poisson distribution resembles a normal distribution with mean
%  lambda and variance lambda when lambda is large. But the standard 
%  version of POISSRND needs a large amount of time for large values
%  of lambda.
%  Indication of speed up factor: 80 at lambda=10,000 and array of 100.

%  Addition 3 (7-12-2000):
%  The new version of POISSRND of release has been improved in speed
%  and has become faster starting from lambda = 15. These improvements
%  are therefore incorporated into this version.
%  For large lambda (between 15 and 1000), use the method of Ahrens 
%  and Dieter as described in Knuth, Volume 2, 1998 edition.
%  note: this version calls the GAMRND and the BINORND functions.

%	References:
%	   [1]  L. Devroye, "Non-Uniform Random Variate Generation", 
%	   Springer-Verlag, 1986 page 504.


%   Based on poissrnd.
%   M.F.P. Tolsma, Signals, Systems and Control Group, Applied Physics, TU Delft
%   http://www.tn.tudelft.nl/mmr
%   copyright remains with author

%   $Revision: 1.2 $  $Date: 2000/12/07 11:45:00 $


%------------------------------Input argument verification
if nargin <  1, 
    error('Requires at least one input argument.'); 
end

if nargin > 3
    %random seed
    if ~isempty(state)
        rand('state',state)
        randn('state',state)
        if isempty(lambda)
            return;
        end
    end
end

[rows columns] = size(lambda);

if nargin==2
    if ~isempty(m)
        if rows*columns>1
            error('Lambda should be a scalar.');
        else
            rows=m;
        end
    end
end

if nargin>2
    if ~isempty(n)
        if rows*columns>1
            error('Lambda should be a scalar.');
        else
            if ~isempty(m)
                rows=m;
            end
            columns=n;
        end
    end
end

if prod(size(lambda))==1
    lambda=lambda*ones(rows,columns);
end

if nargin==5
    if ~isempty(findstr(method,'normal'))
        method=0;
    elseif ~isempty(findstr(method,'fast'))
        method=1000;
    elseif isempty(method)
        method=0;
    end
else
    method=0;
end


%Initialize r to zero.

r = zeros(rows, columns);
index = [1:rows]'*ones(1,columns)+rows*ones(rows,1)*[0:columns-1];

% Return NaN if LAMBDA is not positive.
if any(any(lambda <= 0));
    if prod(size(lambda) == 1)
        r = NaN * ones(rows,columns);
        lambda=[];
    else
        k = find(lambda <= 0);
        r(k) = NaN * ones(size(k));
        
        k = find(lambda > 0);
        lambda=lambda(k);			 % Remove elements for which a result has been calculated.
        index=index(k);
    end
end

%values larger then 'method' are randomised using a discrete normal distribution.
%This is approximatly equal to the poisson distribution.
if method>0
    k = find(lambda>=method);         % The lambda's larger than method
    if ~isempty(k)
        r(index(k))=round(lambda(k)+sqrt(lambda(k)).*randn(size(lambda(k))));
        
        k = find(lambda<method);		    % The lambda's smaller than method
        lambda=lambda(k);			        % Remove elements for which a result has been calculated.
        index=index(k);
    end
end

%values larger (or equal to 15 are randomised using the method of Ahrens and Dieter
k = find(lambda >= 15);
if ~isempty(k)
    alpha = 7/8;
    lk=lambda(k);
    m = floor(alpha * lk);
    
    % Generate m waiting times, all at once
    x = gamrnd(m,1);
    k2= find(x <= lk);
    
    if ~isempty(k2)
        % If we did not overshoot, then the number of additional times
        % has a Poisson distribution with a smaller mean.
        r(index(k(k2))) = m(k2) + poissrnd(lk(k2)-x(k2));
    end
    
    k2= find(x > lk);
    if ~isempty(k2)
        % If we did overshoot, then the times up to m-1 are uniformly
        % distributed on the interval to x, so the count of times less
        % than lambda has a binomial distribution.
        r(index(k(k2))) = binornd(m(k2)-1, lk(k2)./x(k2));
    end
    
    k = find(lambda<15);
    lambda=lambda(k);
    index=index(k);
end

kt=0;
p=zeros(size(index));
while ~isempty(index)
    p = p - log(rand(size(p)));
    k = find(p >= lambda);      % The r's larger than border
    r(index(k))=kt;
    
    k = find(p < lambda); 		% The r's for which the border hasn't been reached.
    lambda=lambda(k);			% Remove elements for which a result has been calculated.
    p=p(k);
    index=index(k);
    
    kt=kt+1;    
end

