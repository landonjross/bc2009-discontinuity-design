% 2 1/2. Testing Code
% Run `runtests` in the matlab interpreter
% https://www.mathworks.com/help/matlab/matlab-unit-test-framework.html
%% Test epanechnikov
kernels.epanechnikov = @(x) (3 ./ 4) .* (1 - power(x, 2)) .* (abs(x) <= 1);
assert(kernels.epanechnikov(1) == 0)

%% Test zero is one
assert(0 == 1)
