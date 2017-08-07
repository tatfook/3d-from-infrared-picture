function [ T ] = getT( X,Y,patch,gX,gY,p )
%T 此处显示有关此函数的摘要
% [gX gY] = gradient(patch);
[r,c] = size(patch);
T = zeros(2,2);

for i = 1:r
%     x = X(i);
    for j = 1:c
%         y = Y(j); 
        gx = gX(i,j);
        gy = gY(i,j);
%         Tij = [x^2*gx^2, x^2*gx*gy, x*y*gx^2, x*y*gx*gy, x*gx^2, x*gx*gy; ...
%             x^2*gx*gy, x^2*gy^2, x*y*gx*gy, x*y*gy^2, x*gx*gy, x*gy^2; ...
%             x*y*gx^2, x*y*gx*gy, y^2*gx^2, y^2*gx*gy, y*gx^2, y*gx*gy; ...
%             x*y*gx*gy, x*y*gy^2, y^2*gx*gy, y^2*gy^2, y*gx*gy, y*gy^2; ...
%             x*gx^2,    x*gx*gy,   y*gx^2,   y*gx*gy,   gx^2,   gx*gy; ...
%             x*gx*gy,   x*gy^2,   y*gx*gy,   y*gy^2,   gx*gy,    gy^2];
        Tij = [ gx^2,   gx*gy; ...
                gx*gy,    gy^2];
        
        Tij = Tij*p(i,j);
        T = T+Tij;
    end
end

end

