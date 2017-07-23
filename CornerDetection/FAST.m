function [ x,y ] = FAST( img,k,bool )
%Find corner point detection using FAST-9 algorithm, threshold is 50
%  I为输入图像
threshold=50;  %阈值
nth = 9; %FAST-9
pic = img;
[H W D]=size(pic);
if D==3
    %     pic = toGray(pic);
    pic=rgb2gray(pic);
end

%%
S = [-3,0;-3,1;-2,2;-1,3;0,3;1,3;2,2;3,1;3,0;3,-1;2,-2;1,-3;0,-3;-1,-3;-2,-2;-3,-1]+[4,4]; %16个点的相对位置
figure(3);imshow(img);title('FAST角点检测');hold on;
pic = double(pic);
tic;
% points = zeros(M,N);
s = zeros(H,W);
for px=4:H-3
    for py=4:W-3%若I1、I9与中心I0的差均小于阈值，则不是候选点
%         delta(1)=Sxp(pic(px-3,py)-pic(px,py),threshold)==0; %x1
%         delta(2)=Sxp(pic(px+3,py)-pic(px,py),threshold)==0;  %x9
%         delta(3)=Sxp(pic(px,py+3)-pic(px,py),threshold)==0;  %x5
%         delta(4)=Sxp(pic(px,py-3)-pic(px,py),threshold)==0;  %x13
        delta(1) = abs(pic(px-3,py)-pic(px,py))<threshold;
        delta(2) = abs(pic(px+3,py)-pic(px,py))<threshold;
        delta(3) = abs(pic(px,py+3)-pic(px,py))<threshold;
        delta(4) = abs(pic(px,py-3)-pic(px,py))<threshold;
        if sum(delta) <3 
            %length(find(delta==0))<3
            IS =[];
            block=pic(px-3:px+3,py-3:py+3);
            for i = 1:16
                IS = [IS,block(S(i,1),S(i,2))];  %圆周上16个点依次的亮度 Intensity set
            end
            d = IS - pic(px,py);
            lv = d>threshold;
            if nConti(lv,nth) == 1
                s(px,py) = sum(lv.*d);
            else 
%                 d = pic(px,py)-IS;
%                 lv = d>threshold;
                lv = -d>threshold;
                if nConti(lv,nth)==1
                    s(px,py) = -sum(lv.*(d));
%                     s(px,py) = sum(lv.*d);
                end
            end
        end
%         if length(find(delta==1))>=3 %p is darker possible
%             IS =[];
%             block=pic(px-3:px+3,py-3:py+3);
%             for i = 1:16
%                 IS = [IS,block(S(i,1),S(i,2))];  %圆周上16个点依次的亮度 Intensity set
%             end
%             d = IS - pic(px,py);
%             lv = d>threshold;
%             if nConti(lv,nth) == 1
%                 s(px,py) = sum(lv.*d);
%             end
%         else
%             if length(find(delta==-1))>=3 %P is brighter possible
%                 IS =[];
%                 block=pic(px-3:px+3,py-3:py+3);
%                 for i = 1:16
%                     IS = [IS,block(S(i,1),S(i,2))];  %圆周上16个点依次的亮度 Intensity set
%                 end
%                 d = pic(px,py)-IS;
%                 lv = d>threshold;
%                 if nConti(lv,nth) == 1
%                     s(px,py) = sum(lv.*d);
%                 end
%                 
%             end
%             
%         end
    end
end



%% Non Maximal Suppression 非极大值抑制 5x5
[x,y] = find(s~=0);

for m = 1:length(x)
    area = s(x(m)-2:x(m)+2,y(m)-2:y(m)+2);
    %     if x(m) == 347
    %         a = 1;
    %     end
    if s(x(m),y(m)) ~= 0
        if length(find(area)) ~= 1
            %             sum(sum(area)) == 1
            mask = zeros(5,5);
            %             ms = s(x(m)-2:x(m)+2,y(m)-2:y(m)+2);
            [mx,my] = find(area == max(max(area)));
            mask(mx(1),my(1)) = 1;
            %             points(x(m)-2:x(m)+2,y(m)-2:y(m)+2) = mask.*area;
            s(x(m)-2:x(m)+2,y(m)-2:y(m)+2) = mask.*area;
        end
    end
    
end


%% select Strongest point 选择最强点
if bool == true
[m,n] = size(s);
[val,index] = sort(s(:),'descend');
b=zeros(m*n,1);
b(index(1:k))=val(1:k);
s = reshape(b,[m,n]);
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

