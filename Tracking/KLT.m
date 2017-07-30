clear all;close all;clc;
%% %%%%%%%%%% find Corners  %%%%%%%%%%%
orgI = imread('smoothFrames/smooth_0_0_1.jpg');
[c,r] = FAST(orgI,150,false);
%saveas(gcf,'mainCornersSeq1.jpg');
saveas(gcf,'mainCornersSmooth.jpg');
%Save Corners
[l ~ ]=size(c);
corners = cell(1,l);
%save corners positions
% % tempI = 1;
corners{1} = [r(75) c(75)];
corners{2} = [r(72) c(72)];

%% %%%%%%%%% KLT Tracker %%%%%%%%%%%%%
%windowSize = 30;
windowSize = 20;
[rows cols chan] = size(orgI);
for corner_i = 1:2
    if (corners{corner_i}(1)-windowSize > 0 && corners{corner_i}(1)+windowSize <= rows && corners{corner_i}(2)-windowSize > 0 && corners{corner_i}(2)+windowSize < cols)
        %No rotation with initial postion
        p = [0 0 0 0 corners{corner_i}(1) corners{corner_i}(2)];
        cornerCounter = 0;
        newCornerCounter = 1;
        T = orgI(corners{corner_i}(1)-windowSize:corners{corner_i}(1)+windowSize,corners{corner_i}(2)-windowSize:corners{corner_i}(2)+windowSize);
        T= double(T);
        %Make all x,y indices
        [x,y]=ndgrid(0:size(T,1)-1,0:size(T,2)-1);
        %Calculate center of the template image
        TemplateCenter=size(T)/2;
        %Make center of the template image coordinates 0,0
        x=x-TemplateCenter(1); y=y-TemplateCenter(2);
        
        addpath('C:\Users\86450\Documents\MATLAB\PlaneDetection\Total\smoothFrames');
        ListName=dir('C:\Users\86450\Documents\MATLAB\PlaneDetection\Total\smoothFrames\*.jpg');
%         [Pm,Pn]=size(ListName);        
        %loop through frames
        for j = 2:50
            NextFrame=imread(ListName(j).name);    %readImg

            NextFrameCopy = NextFrame;
            [H W D]=size(NextFrame);
            if D==3
                NextFrame = rgb2gray(NextFrame);
            end
            copy_p = p;
            I_nextFrame= double(NextFrame); 
            delta_p = 7;
            sigma = 3;
            %Make derivatives kernels
            [xder,yder]=ndgrid(floor(-3*sigma):ceil(3*sigma),floor(-3*sigma):ceil(3*sigma));
            DGaussx=-(xder./(2*pi*sigma^4)).*exp(-(xder.^2+yder.^2)/(2*sigma^2));
            DGaussy=-(yder./(2*pi*sigma^4)).*exp(-(xder.^2+yder.^2)/(2*sigma^2));
            % Filter the images to get the derivatives
            Ix_grad = imfilter(I_nextFrame,DGaussx,'conv');
            Iy_grad = imfilter(I_nextFrame,DGaussy,'conv');
            counter = 0;
            %Threshold
            Threshold = 0.01;
            while ( norm(delta_p) > Threshold)
                counter= counter + 1;
                %Break if it is not convergence for more than 80 loop, and consider it as convergence
                if(counter > 80)
                    break;
                end
                %norm(delta_p)
                %The affine matrix for template rotation and translation
                W_p = [ 1+p(1) p(3) p(5); p(2) 1+p(4) p(6)];
                %1 Warp I with w
                I_warped = warpping(I_nextFrame,x,y,W_p);
                %2 Subtract I from T
                I_error= T - I_warped;
                % Break if outside image
                if((p(5)>(size(I_nextFrame,1))-1)||(p(6)>(size(I_nextFrame,2)-1))||(p(5)<0)||(p(6)<0)), break; end
                %3 Warp the gradient
                Ix =  warpping(Ix_grad,x,y,W_p);   
                Iy = warpping(Iy_grad,x,y,W_p); 
                %4 Evaluate the Jacobian
                W_Jacobian_x=[x(:) zeros(size(x(:))) y(:) zeros(size(x(:))) ones(size(x(:))) zeros(size(x(:)))];
                W_Jacobian_y=[zeros(size(x(:))) x(:) zeros(size(x(:))) y(:) zeros(size(x(:))) ones(size(x(:)))];
                %5 Compute steepest descent
                I_steepest=zeros(numel(x),6);
                for j1=1:numel(x),
                    W_Jacobian=[W_Jacobian_x(j1,:); W_Jacobian_y(j1,:)];
                    Gradient=[Ix(j1) Iy(j1)];
                    I_steepest(j1,1:6)=Gradient*W_Jacobian;
                end
                %6 Compute Hessian
                H=zeros(6,6);
                for j2=1:numel(x), H=H+ I_steepest(j2,:)'*I_steepest(j2,:); end
                %7 Multiply steepest descend with error
                total=zeros(6,1);
                for j3=1:numel(x), total=total+I_steepest(j3,:)'*I_error(j3); end
                %8 Computer delta_p
                delta_p=H\total;
                %9 Update the parameters p <- p + delta_p
                 p = p + delta_p';  
            end
            
            cornerCounter = cornerCounter+1;
            if (cornerCounter == 15)
                T = NextFrameCopy(p(5)-windowSize:p(5)+windowSize,p(6)-windowSize:p(6)+windowSize);
                p = [0 0 0 0 p(5) p(6)];
                T= double(T);
                %Make all x,y indices
                [x,y]=ndgrid(0:size(T,1)-1,0:size(T,2)-1);
                %Calculate center of the template image
                TemplateCenter=size(T)/2;
                %Make center of the template image coordinates 0,0
                x=x-TemplateCenter(1); y=y-TemplateCenter(2);
                cornerCounter = 0;
            end
            if (corner_i == 1)
                newCorners2{newCornerCounter} = [p(6) p(5)];
            else
                newCorners1{newCornerCounter} = [p(6) p(5)];
            end
            newCornerCounter = newCornerCounter+1;
        end      
    end
end

%% Draw and Save all output frames (tracked frames)
newCornerCounter = 1;
%loop through frames
for j = 2:50
    NextFrame=imread(ListName(j).name);    %readImg    
    figure;imshow(uint8(NextFrame));hold on;
    for m=1:newCornerCounter
        if (m==newCornerCounter)
            plot(newCorners1{m}(1),newCorners1{m}(2),'s');
            plot(newCorners2{m}(1),newCorners2{m}(2),'rs');
        else
            plot(newCorners1{m}(1),newCorners1{m}(2),'*');
            plot(newCorners2{m}(1),newCorners2{m}(2),'r*');
        end
    end
    hold off;
    %saveas(gcf,strcat('output1/',num2str(j-33),'.jpg'));
    saveas(gcf,strcat(num2str(j-1),'.jpg'));
    close all;
    newCornerCounter = newCornerCounter + 1;
end
%%%%%%%%%%% End KLT Tracker %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
 
