%% pure translation case
% A is constrained to be the identical matrix, only d to be considered
%Zd = e
%Z = [gx^2, gx*gy; gx*gy, gy^2];
function [ newCorners ] = klt( corners,ListName )
orgI = imread(ListName(1).name);
l = length(corners);
%% %%%%%%%%% KLT Tracker %%%%%%%%%%%%%
windowSize = 20; %half
[rows cols chan] = size(orgI);
X = 1:rows;
Y = 1:cols;
tic;
% newCorner1Counter = 1;
% newCorner2Counter = 1;
Counter = ones(1,300);
% p = gaussN(windowSize);
p = ones(2*windowSize+1,2*windowSize+1);
% x = -windowSize:windowSize;
% y = x;
for j = 2:5
    I = imread(ListName(j-1).name);
    J = imread(ListName(j).name);    %read NextFrame
%     JCopy = J;
    [H W D]=size(J);
    if D==3
        J = rgb2gray(J);
        I = rgb2gray(I);
    end
    I = double(I);
    J = double(J);
    
    for corner_i = 1:l
        if (corners{corner_i}(1)-windowSize > 0 && corners{corner_i}(1)+windowSize <= rows && corners{corner_i}(2)-windowSize > 0 && corners{corner_i}(2)+windowSize <= cols)
            a = corners{corner_i}(1)-windowSize:corners{corner_i}(1)+windowSize;
            b = corners{corner_i}(2)-windowSize:corners{corner_i}(2)+windowSize;
            patch = I(a,b); %pixels in chosen feature window
            x = X(a);
            y = Y(b);%coordinate in chosen feature window
            [gx gy] = gradient(patch);
            T = getT(x,y,patch,gx,gy,p);
            dpatch = I(a,b)-J(a,b);
            a = getA(x,y,dpatch,gx,gy,p);
            e = [a(5);a(6)];
            z = inv(T)*e; %[dxx;dyx;dxy;dyy;dx;dy]
%             pTrack(corner_i,j,:) = z;
            corners{corner_i} = round(corners{corner_i}+z');
%             corners{corner_i} = round(corners{corner_i}+[z(5),z(6)]);
            newCorners{corner_i,Counter(corner_i)} = corners{corner_i};
            Counter(corner_i) = Counter(corner_i)+1;
            
        end
        
    end
end
toc;
%%%%%%%%%%% End KLT Tracker %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
end
