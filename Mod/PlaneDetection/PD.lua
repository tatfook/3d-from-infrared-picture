--[[
Title: 
Author(s): Mofafa
Date: 2017/7/20
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/PlaneDetection/PD.lua");
------------------------------------------------------------
]]

local PD = commonlib.gettable("PD");
NPL.load("(gl)Mod/PlaneDetection/imP.lua");
NPL.load("(gl)script/ide/math/matrix.lua");
local matrix = mathlib.matrix;



function PD:new( o )
	o = o or {}
	setmetatable(o,self)
	self.__index = self
	return o;
end


--判断A中是否有至少n个循环连续的1,A是行向量
function PD.nConti( A,n )
	local m = imP.find(A);
	local mid,result,B;
	if #m == 0 then
	    mid = true;
	else
	    if m[1] > n then
	        mid = true;
	    else
	    	mid = imP.connect(imP.subvector(A,m[1]+1),imP.subvector(A,_,m[1]));
	    	table.insert(mid,1,0);
	    	B = imP.diff(imP.find(mid));
	    	result = math.max(unpack(B))-1 >= n;
	    end
	end
	return result;
end
local nConti = PD.nConti;

--1D array add a number
function PD.array1Dadd(A,n)
	local array_o = {}
	for i = 1, #A do
		array_o[i] = A[i] + n;
	end
	return array_o;
end

function PD.ArrayDotProduct(a1,a2)
	-- Array dot product.	
	local array_o = {};
	for i = 1, #a1 do
		array_o[i] = a1[i]*a2[i];
	end
	return array_o;
end
local ArrayDotProduct = PD.ArrayDotProduct;

function PD.sum1Darray( a )
	local num = 0;
	for k,v in pairs(a) do
		num = num + v
	end
	return num
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
	local s = imP.zeros(H,W);
	local dt1,dt9,dt5,dt13;
	local block,IS,lv = {};

	for px = 4,H-3 do
		for py = 4,W-3 do
			dt1 = imP.bool2num(math.abs(img[px-3][py]-img[px][py])<threshold);
			dt9 = imP.bool2num(math.abs(img[px+3][py]-img[px][py])<threshold);
			dt5 = imP.bool2num(math.abs(img[px][py+3]-img[px][py])<threshold);
			dt13 = imP.bool2num(math.abs(img[px][py-3]-img[px][py])<threshold);
			    if dt5 + dt9 + dt1 + dt13 < 3 then
			    	IS = {};
			    	block = imP.submatrix(img,px-3,px+3,py-3,py+3);
			    	
			    	for i = 1,16 do
			    		IS[#IS+1] = block[S[1][i]][S[2][i]];
			    	end
			    	
			    	--确定亮度差是否大于阈值
			    	d = PD.array1Dadd(IS,-img[px][py]);
			    	lv = {};
			    	for i = 1,16 do
			    		lv[i] = imP.bool2num(d[i]>threshold);
			    	end

			    	if PD.nConti(lv,n) == true then
			    		s[px][py] = PD.sum1Darray(ArrayDotProduct(lv,d));
			    	else
			    		for i = 1,16 do
			    			lv[i] = imP.bool2num(-d[i]>threshold);
			    		end
			    		if PD.nConti(lv,n) == true then
			    			s[px][py] = -PD.sum1Darray(ArrayDotProduct(lv,d));
			    		end
			    	end
			    end
			
		end
	end

	--Non Maximal Suppression 非极大值抑制 5x5
	x,y = imP.find(s,0,false);
	local area,mask,ma = {}
	local mask = imP.zeros(5,5);
	local mx,my;
	for m = 1,#x do
		area = imP.submatrix(s,x[m]-2,x[m]+2,y[m]-2,y[m]+2);
		if s[x[m]][y[m]] ~= 0 then
			if #imP.find(area,0,false) ~= 1 then
				-- mask = imP.zeros(5,5);
				mx,my = imP.find(area,imP.Array2Max(area));
				mask[mx[1]][my[1]] = 1;
				ma = imP.DotProduct(mask,area);
				for i = x[m]-2,x[m]+2 do
					for j = y[m]-2,y[m]+2 do
						s[i][j] = ma[i-x[m]+3][j-y[m]+3];
					end
				end
				mask = imP.zeros(5,5);
			end
		end
	end

	--Select Strongest point 选择最强点
	if k ~= nil then
		local m,n = imP.ArraySize(s);
		local sv = imP.reshape(s,1,m*n);
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

	x,y = imP.find(s,0,false);
	return x,y;
end
local FAST = PD.FAST;


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
			A = imP.add(A,Aij);
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
    --corners = [rows,cols]

	local windowSize = 15;
	local rows = #List[1];
	local cols = #List[1][1];
	local l = #corners;
	local newCorners = {}
	local I,J,a1,a2,b1,b2,gx,gy,patch,T,dpatch,A,z,numj;
	local e = {};
	if #List > 5 then
	numj = 5
	else
	numj = #List
	end
	newCorners[1] = corners;
	for j = 2,numj do
		I = List[j-1];
		J = List[j];
		newCorners[j]={}
		for corner_i =1,l do
			a1 = corners[corner_i][1]-windowSize
			a2 = corners[corner_i][1]+windowSize
			b1 = corners[corner_i][2]-windowSize
			b2 = corners[corner_i][2]+windowSize
			if a1 > 0 and a2 <= rows and b1 > 0 and b2 <= cols then				
				patch = imP.submatrix(I,a1,a2,b1,b2)
				gx,gy = imP.gradient(patch)
				-- local x = {a1,a2}
				-- local y = {b1,b2}
				T = PD.getT(patch,gx,gy)
				dpatch = imP.submatrix(matrix.sub(I,J),a1,a2,b1,b2)
				A = PD.getA(dpatch,gx,gy)
				e = {{A[5][1]},{A[6][1]}}  --2x1 matrix
				z = matrix.mul(matrix.invert(T),e)
				for i = 1,2 do
				    newCorners[j][corner_i] = {}
				    newCorners[j][corner_i][i]=imP.round(corners[corner_i][i]+z[i][1])
			    end
			end
		end
	end
	return newCorners;
end

local function PD.gfilter( I,h,w )
	local g = {};
	g[1] = {0.0039,0.0156,0.0234,0.0156,0.0039}
	g[2] = {0.0156,0.0625,0.0938,0.0625,0.0156}
	g[3] = {0.0234,0.0938,0.1406,0.0938,0.0234}
	g[4] = {0.0156,0.0625,0.0938,0.0625,0.0156}
	g[5] = {0.0039,0.0156,0.0234,0.0156,0.0039}
	local m;
	local Io = matrix.copy(I);
	for i = 3,h-2 do
		for j = 3,w-2 do
			Io[i][j] = imP.round(imP.ArraySum(imP.DotProduct(imP.submatrix(I,i-2,i+2,j-2,j+2),g)));
		end
	end
	return Io;
end

--downsample 2
local function PD.ds2( I,h,w )
	local Io = {}
	for i = 1,math.floor(h/2) do
		Io[i] = {}
		for j = 1,math.floor(w/2) do
			Io[i][j] = I[i*2][j*2]
		end
	end
	return Io;	
end

function PD.gPyramid( I,n )
	local h,w = imP.ArraySize(I)
	local G = {};
	G[1] = I;
	local Gg = {};
	for L = 2,n do
		Gg = PD.gfilter(G[L-1],h,w)
		G[L] = PD.ds2(Gg,h,w)
	end
	return G

end

-- TODO
-- function null
--function lu

local function p1p1( p1,p2 )
	local pout = {p1[1]*p2[1],p1[2]*p2[2],p1[3]*p2[3],
			p1[1]*p2[2]+p1[2]*p2[1],p1[1]*p2[3]+p1[3]*p2[1],
			p1[2]*p2[3]+p1[3]*p2[2],p1[1]*p2[4]+p1[4]*p2[1],
			p1[2]*p2[4]+p1[4]*p2[2],p1[3]*p2[4]+p1[4]*p2[3],p1[4]*p2[4]}
	return pout;

end

local function p2p1( p1,p2 )
	local pout = {p1[1]*p2[1],p1[2]*p2[2],p1[3]*p2[3],
			p1[1]*p2[2]+p1[4]*p2[1],p1[2]*p2[1]+p1[4]*p2[2],
			p1[1]*p2[3]+p1[5]*p2[1],p1[3]*p2[1]+p1[5]*p2[3],
			p1[2]*p2[3]+p1[6]*p2[2],p1[3]*p2[2]+p1[6]*p2[3],
			p1[4]*p2[3]+p1[5]*p2[2]+p1[6]*p2[1],
			p1[1]*p2[4]+p1[7]*p2[1],p1[2]*p2[4]+p1[8]*p2[2],p1[3]*p2[4]+p1[9]*p2[3]
			p1[4]*p2[4]+p1[7]*p2[2]+p1[8]*p2[1],
			p1[5]*p2[4]+p1[7]*p2[3]+p1[9]*p2[1],
			p1[6]*p2[4]+p1[8]*p2[3]+p1[9]*p2[2],
			p1[7]*p2[4]+p1[10]*p2[1],p1[8]*p2[4]+p1[10]*p2[2],p1[9]*p2[4]+p1[10]*p2[3],p1[10]*p2[4]}
	return pout;
end

local function gj_elim_pp( A )
	local V,U = lu(A)  
	local B = imP.zeros(10,20)
	B[1] = U[1]
	B[2] = U[2]
	B[3] = U[3] 
	B[4] = U[4]
	B[10] = array1D.mulnum(U[10],1/U[10][10])
	B[9] = array1D.mulnum(array1D.sub(U[9],array1D.mulnum(B[10],U[9][10])),1/U[9][9])
	B[8] = array1D.mulnum(array1D,sub(array1D.sub(U[8],array1D.mulnum(B[9],U[8][9])),array1D.mulnum(B[10],U[8][10])),1/U[8][8])
	B[8] = array1D.mulnum(array1D,sub(array1D,sub(array1D.sub(U[7],array1D.mulnum(B[8],U[7][8])),
		array1D.mulnum(B[9],U[7][9])),array1D.mulnum(B[10],U[7][10])),1/U[7][7])
	B[6] = array1D.mulnum(array1D,sub(array1D,sub(array1D,sub(array1D.sub(U[6],array1D.mulnum(B[7],U[6][7])),
		array1D.mulnum(B[8],U[6][8])),array1D.mulnum(B[9],U[6][9])),array1D.mulnum(B[10],U[6][10])),1/U[6][6])
	B[5] = array1D.mulnum(array1D,sub(array1D,sub(array1D,sub(array1D,sub(array1D.sub(U[5],array1D.mulnum(B[6],U[5][6])),
		array1D.mulnum(B[7],U[5][7])),array1D.mulnum(B[8],U[5][8])),array1D.mulnum(B[9],U[5][9])),array1D.mulnum(B[10],U[5][10])),1/U[5][5])
	return B

end

-- FIVE_POINT_ALGORITHM Given five points matches between two images, and the
-- intrinsic parameters of each camera. Estimate the essential matrix E, the 
-- rotation matrix R and translation vector t, between both images.
-- returns E_all, R_all, t_all, Eo_all
-- R_all and t_all are the rotation matrices and translation
-- vectors of camera 2 for the different essential matrices, such that a 3D
-- point in camera 1 reference frame can be transformed into the camera 2
-- reference frame through p_2 = R{n}*p_1 + t{n}. 
-- Eo_all is the essential matrix before the imposing the structure U*diag([1 1 0])*V'. 
-- It should help get a better feeling on the accuracy of the solution. All these
-- return values a nx1 cell arrays. 

-- Arguments:
-- pts1, pts2 - assumed to have dimension 2x5 and of equal size. 
-- K1, K2 - 3x3 intrinsic parameters of cameras 1 and 2 respectively
function fivePoint( pts1,pts2,K1,K2 )
	local N = 5
	local oneN = imP.ones(1,N)	
	local m = matrix.copy(pts1)
	m[3] = oneN;
	local q1 = matrix.div(K1,m);
	m[1] = pts2[1]
	m[2] = pts2[2]
	local q2 = matrix.div(K2,m);
	local q = {array1D.DotProduct(q1[1],q2[1]),array1D.DotProduct(q1[2],q2[1]),array1D.DotProduct(q1[3],q2[1]),
	          array1D.DotProduct(q1[1],q2[2]),array1D.DotProduct(q1[2],q2[2]),array1D.DotProduct(q1[3],q2[2]),
	          array1D.DotProduct(q1[1],q2[3]),array1D.DotProduct(q1[2],q2[3]),array1D.DotProduct(q1[3],q2[3])}
    q = matrix.transpose(q)
    local mask = {}
    mask[1] = {1,2,3};
    mask[2] = {4,5,6};
    mask[3] = {7,8,9};
    local nullSpace = fivePoint.null(q)  --9x4
    nullSpace = matrix.transpose(nullSpace)
    local Xmat = imP.reshape(nullSpace[1],3,3)
    local Ymat = imP.reshape(nullSpace[2],3,3)
    local Zmat = imP.reshape(nullSpace[3],3,3)
    local Wmat = imP.reshape(nullSpace[4],3,3)
    local X_ = matrix.div(matrix.mul(matrix.invert(matrix.transpose(K2)),Xmat),K1);
    local Y_ = matrix.div(matrix.mul(matrix.invert(matrix.transpose(K2)),Ymat),K1);
    local Z_ = matrix.div(matrix.mul(matrix.invert(matrix.transpose(K2)),Zmat),K1);
    local X_ = matrix.div(matrix.mul(matrix.invert(matrix.transpose(K2)),Wmat),K1);
    --det(F)
    local detF = matrix.add(p2p1(matrix.sub(p1p1({X_[1][2],Y_[1][2],Z_[1][2],W_[1][2]},
                           {X_[2][3],Y_[2][3],Z_[2][3],W_[2][3]}),
						    p1p1({X_[1][3],Y_[1][3],Z_[1][3],W_[1][3]},
                           {X_[2][2],Y_[2][2],Z_[2][2],W_[2][2]})),
						    {X_[3][1],Y_[3][1],Z_[3][1],W_[3][1]}),
			     matrix.add(p2p1(matrix.sub(p1p1({X_[1][3],Y_[1][3],Z_[1][3],W_[1][3]},
                           {X_[2][1],Y_[2][1],Z_[2][1],W_[2][1]}),
						    p1p1({X_[1][1],Y_[1][1],Z_[1][1],W_[1][1]},
                           {X_[2][3],Y_[2][3],Z_[2][3],W_[2][3]})),
						    {X_[3][1],Y_[3][1],Z_[3][1],W_[3][1]}),
						   p2p1(matrix.sub(p1p1({X_[1][1],Y_[1][1],Z_[1][1],W_[1][1]},
                           {X_[2][2],Y_[2][2],Z_[2][2],W_[2][2]}),
						    p1p1({X_[1][2],Y_[1][2],Z_[1][2],W_[1][2]},
                           {X_[2][1],Y_[2][1],Z_[2][1],W_[2][1]})),
						    {X_[3][3],Y_[3][3],Z_[3][3],W_[3][3]})))
    --FlippedV
    local EE_tll = p1p1


end
