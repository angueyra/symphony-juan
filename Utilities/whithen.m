function lightercolor=whithen(color,factor)
% function lightercolor=whithen(color,factor)
% Give anf RGB color vector or matrix to produce a more desaturated color
% factor belongs to [0 1]

if size(color,2)~=3
    error('input argument 1 is not a color vector or matrix');
end
if factor<0 || factor>1
    error('input argument 2 must be a single number bigger between 0 and 1');
end

lightercolor=(color)+((1-color).*factor);