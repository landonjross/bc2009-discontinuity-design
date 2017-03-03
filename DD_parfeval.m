clear

% 1. Data
% Matlab feature:
% readtable('example.csv') creates a type table object.
% Browse `help table`. Most every way you'll want to access tabular data is
% already coded up for table objects. You'll never again need to remember
% what variable is in column 19 of a matrix again you saved a year ago.
corr_path = '../csv/MCdta-corr.csv';
nocorr_path = '../csv/MCdta-nocorr.csv';
data = readtable(corr_path);
d = 'd_eS';
s = 's_eS';
data.(d) = categorical(data.(d));
data.highed_indicator = data.(d) == 'high education';

% 2. Specify observed outcome
Z = @(dcol, y1, y0) dcol .* log(y1) + (1 - dcol) .* log(y0);
data.y = Z(data.highed_indicator, data.y1, data.y0);


% 2. Kernel
% Matlab feature:
% example_func = @(x) x + 1 is an anonymous function.
% Would you rather figure out what A or B means six months from now?
% A. (abs(data.(cs)) <= 1) .* 3 .* (1 - power(data.(cs), 2)) ./ 4;
% B. epanecnikov(data.(cs))
% Downside: debugging can be more difficult.
kernels.epanechnikov = @(x) (3 ./ 4) .* (1 - power(x, 2)) .* (abs(x) <= 1);
kernels.gauss = @(x) (1 ./ sqrt(2 .* pi)) .* exp( -1 .* (1 ./ 2) .* power(x, 2));
kernels.ross_zhang = @(x) max(kernels.gauss(x-2), kernels.gauss(x+2));

% Beware, I have not carefully validated these kernel functions!
kernels.uniform = @(x) (1 ./ 2) .* (abs(x) <= 1);
kernels.triangular = @(x) (1 - abs(x)) .* (abs(x) <= 1);
kernels.cosine = @(x) (pi ./ 4) .* cos(pi ./ 2 .* x) .* (abs(x) <= 1);
kernels.sigmoid = @(x) (2 ./ pi) .* (1 ./ (exp(x) + exp(-x)));

% 4. Fix variable names
varnames = data.Properties.VariableNames;

% 5. Results
bandwidths = [0.1 0.5 1.0 1.5 2];
xlsxsheet_num = 2;
numout = 1;
p = gcp();
for h = bandwidths;
    results = table();
    for kernel_name = fieldnames(kernels)'
        kernel_name{1}
        kernel = kernels.(kernel_name{1});
        % estimator = @(varargin) DDEstimator(kernel, varnames, d, s, h, varargin);
        estimator = @(varargin) parfeval(p, @DDEstimator, numout, kernel, varnames, d, s, h, varargin);
        futures = splitapply(estimator, data, findgroups(data.MCrep));
        results.([kernel_name{1} '_h_' num2str(h .* 10)]) = fetchOutputs(futures);
    end
    writetable(results, 'results_parallel.xlsx', 'sheet', xlsxsheet_num);
    xlsxsheet_num = xlsxsheet_num + 1;
end
