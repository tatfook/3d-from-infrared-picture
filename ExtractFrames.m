clc;
clear;
%% 读取视频
video_file='videoShort.mp4';
video=VideoReader(video_file);
frame_number=floor(video.Duration * video.FrameRate);
%% 分离图片
for i=1:frame_number
    image_name=strcat('videoShort_',num2str(floor(i/100)),'_',num2str(floor(mode(i/10))),'_',num2str(mod(i,10)));
    image_name=strcat(image_name,'.jpg');
    I=read(video,i);                               %读出图片
    imwrite(I,image_name,'jpg');                   %写图片
    I=[];
end
