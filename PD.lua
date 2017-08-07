--[[
Title: 
Author(s): Mofafa
Date: 2017/7/20
Desc: 
use the lib:
------------------------------------------------------------

------------------------------------------------------------
]]
PD = {};  --Plane Detection
require("models");

--判断A中是否有至少n个循环连续的1,A是行向量
function PD.nConti( A,n )
local m = models.find(A);
local output,result,B;
if #m == 0 then
    output = true;
else
    if m[1] > n then
        output = true;
    else
    	output = models.connect(models.subvector(A,m[1]+1),models.subvector(A,_,m[1]));
    	table.insert(output,1,0);
    	local B = models.diff(models.find(output));
    	result = math.max(table.unpack(B))-1 >= n;
    end
end
return result;
end

--FAST corner point detection algorithm
-- img is a gray image,k is the number of strongest points
function PD.FAST( img,k )
	local x,y;
	local threshold = 45;
	local n = 10;
	local S = {};
	S[1] = {1,1,2,3,4,5,6,7,7,7,6,5,4,3,2,1}; --x
	S[2] = {4,5,6,7,7,7,6,5,4,3,2,1,1,1,2,3}; --y
	local H = #img;
	local W = #img[1];
	local s = models.zeros(H,W);

	for px = 4,H-3 do
		for py = 4,W-3 do
			local dt1 = models.bool2num(math.abs(img[px-3][py]-img[px][py])<threshold);
			local dt9 = models.bool2num(math.abs(img[px+3][py]-img[px][py])<threshold);
			local dt5 = models.bool2num(math.abs(img[px][py+3]-img[px][py])<threshold);
			local dt13 = models.bool2num(math.abs(img[px][py-3]-img[px][py])<threshold);
			    if dt5 + dt9 + dt1 + dt13 < 3 then
			    	local IS = {};
			    	local block = models.submatrix(img,px-3,px+3,py-3,py+3);
			    	
			    	for i = 1,16 do
			    		IS[#IS+1] = block[S[1][i]][S[2][i]];
			    	end
			    	
			    	--确定亮度差是否大于阈值
			    	d = models.ArrayAdd(IS,-img[px][py]);
			    	local lv = {};
			    	for i = 1,16 do
			    		lv[i] = models.bool2num(d[i]>threshold);
			    	end

			    	if PD.nConti(lv.n) == true then
			    		s[px][py] = models.ArraySum(models.DotProduct(lv,d));
			    	else
			    		for i = 1,16 do

						
						lv[i] = models.bool2num(-d[i]>threshold);
			    		end
			    		if PD.nConti(lv,n) == true then
			    			s[px][py] = -models.ArraySum(models.DotProduct(lv,d));
			    		end
			    	end
			    end
			
		end
	end

	--Non Maximal Suppression 非极大值抑制 5x5
	local x,y = find(s,0,false);
	for m = 1,#x do
		local area = models.submatrix(s,x[m]-2,x[m]+2,y[m]-2,y[m]+2);
		if s[x[m]][y[m]] ~= 0 then
			if #models.find(area,0,false) ~= 1 then
				local mask = models.zeros(5,5);
				local mx,my = models.find(area,models.Array2Max(area));
				mask[mx[1]][my[1]] = 1;
				local ma = models.DotProduct(mask,area);
				for i = x[m]-2,x[m]+2 do
					for j = y[m]-2,y[m]+2 do
						s[i][j] = ma[i-x[m]+3][j-y[m]+3];
					end
				end
				mask = models.zeros(5,5);
			end
		end
	end

	--Select Strongest point 选择最强点
	if k ~= nil then
		local m,n = models.ArraySize(s);
		local sv = models.reshape(s,1,m*n);
		local sortFunc = function(a, b) return b < a end
		table.sort( sv, sortFunc );
		local line = sv[k];
		for i = 1,m do
			for j = 1,n do
				if s[i][j]<line then
					s[i][j] = 0;
				end
			end
		end
	end

	x,y = models.find(s,0,false);
	return x,y;
end


function PD.getT(patch,gx,gy)
	local d = #patch
	local T = imP.zeros(2,2)
	local Tij;
	for i = 1,d do
		for j = 1,d do
			Tij = {{gx[i][j]^2,gx[i][j]*gy[i][j]},{gx[i][j]*gy[i][j],gy[i][j]^2}}
			T = imP.add(T,Tij);
		end
	end
	return T;
end

function PD.getA(dpatch,gx,gy)
	local d = #dpatch
	local A = imP.zeros(6,1)
	local Aij;
	local m;
	for i = 1,d do
		for j = 1,d do
			m = {{0},{0},{0},{0},{gx[i][j]},{gy[i][j]}}
			Aij = imP.ArrayMutl(m,dpatch[i][j]);
			local A = imP.add(A,Aij);
		end
	end
	return A;  --6x1 matrix
end



--KLT tracker
--List is the list of images
--corners is x and y from FAST
-- local len = #x
-- local corners = {};
-- for i = 1,len do
-- 	corners[i] = {x[i],y[i]}
-- end
function PD.KLT( List,corners )
	local windowSize = 15;
	local rows = #img;
	local cols = #img[1];
	local l = #corners;
	local Counter = imP.ones(1,300)
	local newCorners = imP.zeros(5,l)
	newCorners[1] = corners;
	for j = 2,5 do
		local I = List[j-1];
		local J = List[j];
		for corner_i =1,l do
			local a1 = corners[corner_i][1]-windowSize
			local a2 = corners[corner_i][1]+windowSize
			local b1 = corners[corner_i][2]-windowSize
			local b2 = corners[corner_i][2]+windowSize
			if a1 > 0 and a2 <= rows and b1 > 0 and b2 <= cols then				
				local patch = submatrix(I,a1,a2,b1,b2)
				local gx,gy = gradient(patch)
				-- local x = {a1,a2}
				-- local y = {b1,b2}
				local T = getT(patch,gx,gy)
				local dpatch = submatrix(I-J,a1,a2,b1,b2)
				local A = getA(dpatch,gx,gy)
				local e = {{A[5]},{A[6]}}  --horizontal
				local z = matrix.mul(matrix.invert(T),e)
				newCorners[j][corner_i] = imP.round(corners[corner_i]+matrix.transpose(z))
			end
		end
	end
end

