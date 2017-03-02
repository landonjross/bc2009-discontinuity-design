function [dd] = DDEstimator(kernel, varnames, d, s, h, varargin)
% Replication of discontinuity design estimator from Blundell and Dias
% 2009.

% 1. Reassemble the table.
data = table(varargin{1}{1, :});
data.Properties.VariableNames = varnames;
data.MCrep(1);

% 2. Define eligibility variable
% Matlab syntax feature:
% examplestruct.('examplefield') is a dynamic field reference on a struct
% Ever copy and paste something like?
% example.elig_1 = example.s_eS >= 1;
% example.elig_2 = example.s_eS >= 2;
% ...
% With dynamic field references you can do the same with less bugs:
% example = readtable(data_path);
% for x = 1:5
%     example.(['elig_' int2str(x)]) = example.(s) >= x;
% end
elig = 'elig';
elig_min_score = 4;
data.(elig) = data.(s) >= elig_min_score;


% 3. Center score variable at eligibility discontinuity
cs = [s '_centered'];
data.(cs) = (data.(s) - elig_min_score) ./ h;


% 4. Compute kernel weights at eligibility discontinuity
k = 'kernel_weight';
data.(k) = kernel(data.(cs));


% 5. Estimate CEF around discontinuity
beta_est = @(X, D, y) inv(X' * D * X) * (X' * D * y);


% Ineligible
inel = data(data.(elig) == 0, :);
inel_N = height(inel);
inel_X = [inel.(cs) ones(inel_N, 1)];
inel_D = diag(inel.(k));

% CEF
inel_cef = beta_est(inel_X, inel_D, inel.y);
y0hat = inel_cef(2, 1);

% Participation
inel_part = beta_est(inel_X, inel_D, inel.highed_indicator);
p0hat = inel_part(2, 1);


% Eligible
el = data(data.(elig) == 1, :);
el_N = height(el);
el_X = [el.(cs) ones(el_N, 1)];
el_D = diag(el.(k));

% CEF
el_cef = beta_est(el_X, el_D, el.y);
y1hat = el_cef(2, 1);

% Participation
el_part = beta_est(el_X, el_D, el.highed_indicator);
p1hat = el_part(2, 1);

% Treatment effect, Equation (55) pg. 620 of B&C
dd = (y1hat - y0hat) / (p1hat - p0hat);
end
