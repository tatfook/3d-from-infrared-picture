function [ A ] = getA( X,Y,dpatch,gX,gY,p )
%GETA 此处显示有关此函数的摘要
%   此处显示详细说明
[r,c] = size(dpatch);
A = zeros(6,1);
for i = 1:r
%     x = X(i);
    for j = 1:c
        gx = gX(i,j);
%         y = Y(j); 
        gy = gY(i,j);
%         m = [x*gx; x*gy; y*gx; y*gy; gx; gy];
        m = [0;0;0;0; gx; gy];
        Aij = dpatch(i,j)*m*p(i,j);
        A = A + Aij;
    end
end

end

