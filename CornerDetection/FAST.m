function [ x,y ] = FAST( img )
%Find corner point detection using FAST-9 algorithm, threshold is 50
%  I为输入图像
pic = img;
[M N D]=size(pic);
if D==3
%     pic = toGray(pic);
    pic=rgb2gray(pic);
end
%%
S = [-3,0;-3,1;-2,2;-1,3;0,3;1,3;2,2;3,1;3,0;3,-1;2,-2;1,-3;0,-3;-1,-3;-2,-2;-3,-1]+[4,4]; %16个点的相对位置
threshold=50;  %阈值
nth = 9; %FAST-9
figure(3);imshow(img);title('FAST角点检测');hold on;
tic;
% points = zeros(M,N);
s = zeros(M,N);
for px=4:M-3
    for py=4:N-3%若I1、I9与中心I0的差均小于阈值，则不是候选点
        delta1=abs(pic(px-3,py)-pic(px,py))>threshold;
        delta9=abs(pic(px+3,py)-pic(px,py))>threshold;
            delta5=abs(pic(px,py+3)-pic(px,py))>threshold;
            delta13=abs(pic(px,py-3)-pic(px,py))>threshold;
            if sum([delta1 delta9 delta5 delta13])<3
                continue;
            else
                IS =[];
                block=pic(px-3:px+3,py-3:py+3);
                for i = 1:16
                    IS = [IS,block(S(i,1),S(i,2))];  %圆周上16个点依次的亮度 Intensity set
                end
                d = abs(IS-pic(px,py)); %16个点的亮度与中心点的距离
                lv = d > threshold; %logic value
                if nConti(lv,nth) == 1
                    s(px,py) = sum(d);
%                     points(px,py) = 1;  %储存特征点坐标
                end
            end
        end
    end


%% Non Maximal Suppression 非极大值抑制 5x5
[x,y] = find(s~=0);

for m = 1:length(x)
    area = s(x(m)-2:x(m)+2,y(m)-2:y(m)+2);
    if x(m) == 347
        a = 1;
    end
    if s(x(m),y(m)) == 0
        continue;
    else if length(find(area)) == 1
%             sum(sum(area)) == 1
            continue;
        else
            mask = zeros(5,5);
            ms = s(x(m)-2:x(m)+2,y(m)-2:y(m)+2);
            [mx,my] = find(ms == max(max(ms)));
            mask(mx(1),my(1)) = 1;
%             points(x(m)-2:x(m)+2,y(m)-2:y(m)+2) = mask.*area;
            s(x(m)-2:x(m)+2,y(m)-2:y(m)+2) = mask.*ms;
        end
    end
    
end

%%
[y,x] = find(s~=0);  %最终特征点的坐标

for n = 1:length(x)
    plot(x(n),y(n),'g+'); hold on;
end
hold off;

toc;
%%

end

