function [ p ] = gaussN( windowSize )
%GAUSSN 此处显示有关此函数的摘要
%   norm gaussian distribution

for i = 1:2*windowSize+1
    for j = 1:2*windowSize+1
        x = i-windowSize-1;
        y = j-windowSize-1;
        d = 1/(2*pi*3);
        p(i,j) = d*exp(-0.5/3*(x^2+y^2));
    end
end
p = p/sum(sum(p));
end

