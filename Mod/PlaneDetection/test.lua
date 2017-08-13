-- --[[
-- Title: 
-- Author(s): Mofafa
-- Date: 2017/7/20
-- Desc: 
-- use the lib:
-- ------------------------------------------------------------

-- ------------------------------------------------------------
-- ]]

NPL.load("(gl)Mod/PlaneDetection/imP.lua");
NPL.load("(gl)Mod/PlaneDetection/PD.lua");
NPL.load("(gl)script/ide/math/matrix.lua");
local matrix = mathlib.matrix;

local Iname ={}
Iname[1] = "Mod/PlaneDetection/smooth1.jpg";
Iname[2] = "Mod/PlaneDetection/smooth2.jpg";
Iname[3] = "Mod/PlaneDetection/smooth3.jpg";
local Im
local List = {}
for i = 1,3 do
    List[i] = {}
    Im = imP.imread(Iname[i])
    List[i] = imP.rgb2gray(Im)
end

local x, y = PD.FAST(List[1]);
local len = #x
local corners = {};
for i = 1, len do
	corners[i] = {x[i], y[i]}
end

local newcorners = PD.KLT(List,corners)


