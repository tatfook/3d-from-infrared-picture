# Plane-Detection-with-a-Single-Moving-Camera

[ARKit Introduction](https://www.youtube.com/watch?v=LLRweyZ1KpA)
ARKit，一款全面支持AR增强现实开发的SDK。 ARKit支持所有安装了ios 11的iphone与ipad

[ARCore Introduction](https://www.youtube.com/watch?v=ttdPqly4OF8)
ARCore，Google 推出的增强现实 SDK。软件开发者现在就可以下载它去开发 Android 平台上的增强现实应用，或者为他们的 App 增加增强现实功能。支持最新的Google Pixel，Galaxy S8手机

常用开源单目SLAM(Simultaneous localization and mapping)方案
[MonoSLAM](https://github.com/hanmekim/SceneLib2)   单目  第一个实时视觉SLAM系统
[PTAM](https://github.com/Oxford-PTAM/PTAM-GPL)   单目  提出mapping和tracking并行化双线程，第一次使用非线性优化
[ORB_SLAM](https://webdiis.unizar.es/~raulmur/orbslam/)   单目为主（支持单目，双目，RGB-D)   三个线程（Tracking，局部bundle adjustment优化，全局Pose Graph回环检测与优化）
[LSD-SLAM](https://vision.in.tum.de/research/vslam/lsdslam)  单目为主  使用直接法，半稠密重建，对相机内参和曝光敏感
[SVO](https://github.com/uzh-rpg/rpg_svo)  单目  使用疏密直接法，速度较快（开源的SVO程序适用于无人机的俯视相机，相机运动一般是水平和上下，如果用平视相机需要自己修改）
[ROVIO](https://github.com/ethz-asl/rovio)   单目+IMU（惯性传感器）
