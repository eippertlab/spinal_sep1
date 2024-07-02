function [EVec, Eload, EVal, pca_info] = mypca_calc(vecs)
%
%  PCA_CALC   Principal Component Analysis
%
%   [EVEC, ELOAD, EVAL] = PCA_CALC(X) takes a column-wise de-meaned
%       data matrix X of size n-by-m and calculates the n
%       Eigenvectors (EVEC of size n-by-n) of the data covariance
%       matrix, the factor loadings (ELOAD of size n-by-m) and the
%       corresponding Eigenvalues (EVAL of size n-by-1).
%
%
% Author: Rami K. Niazy, FMRIB Centre, University of Oxford
%
% Copyright (c) 2004 University of Oxford.
%

[m, n] = size(vecs); % vecs: [m(time) x n(epochs)]
[Us, S, EVec] = svd(vecs, 0); % Us: [n x n]
                              % S: [n x m]
                              % EVec: [m x m]

pca_info.U = Us;
pca_info.S = S;
pca_info.EVec = EVec;


% calc factor loadings 
if m == 1
    S = S(1);
else
    S = diag(S);
end
Eload = Us .* repmat(S',m,1); % factor loading

% clac Eigenvalues
S = S ./ sqrt(m-1);   
% if m <= n
%     S(m:n,1) = 0;
%     S(:,m:n) = 0;
% end
EVal = S.^2;

% calc explained variance
explained = (EVal / sum(EVal)) * 100; % variances of all individual principal components



pca_info.factorLoadings = Eload;
pca_info.eigenValues = EVal;
pca_info.explVar = explained;
