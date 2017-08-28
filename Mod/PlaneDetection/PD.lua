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

local s_g = {
	{0.0039,0.0156,0.0234,0.0156,0.0039},
	{0.0156,0.0625,0.0938,0.0625,0.0156},
	{0.0234,0.0938,0.1406,0.0938,0.0234},
	{0.0156,0.0625,0.0938,0.0625,0.0156},
	{0.0039,0.0156,0.0234,0.0156,0.0039},
};
local function PD.gfilter( I,h,w )
	local Io_ = matrix.copy(I);
	for i = 3,h-2 do
		for j = 3,w-2 do
			Io_[i][j] = imP.round(imP.ArraySum(imP.DotProduct(imP.submatrix(I,i-2,i+2,j-2,j+2),s_g)));
		end
	end
	return Io_;
end

--downsample 2
local function PD.ds2( I,h,w )
	local Io_ = {}
	
	for i = 1,math.floor(h/2) do
		Io_[i] = {}
		for j = 1,math.floor(w/2) do
			Io_[i][j] = I[i*2][j*2]
		end
	end
	return Io_;	
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

local function onlydoforA( _A )
	local A = {}
	local indexA = {1,2,4,5,6,11,8,12,10,14,7,15,17,9,16,18,3,13,19,20}
	for i = 1, #_A do
		A[i] = {}
		for j = 1,#indexA do 
			A[i][j] = _A[i][indexA[j]]
		end
	end
	return A;
end


--add 3 matrix
local function add3( m1,m2,m3 )
	local mtx = {}
	for i = 1,#m1 do
		mtx[i] = {}
		for j = 1,#m1[1] do
			mtx[i][j] = m1[i][j] + m2[i][j] + m3[i][j]
		end
	end
	return mtx
end

--add 3 matrix
local function add3v( v1,v2,v3 )
	local v_ = {}
	for i = 1,#v1 do
		v_[i] = v1[i] + v2[i] + v3[i]
	end
	return v_
end

local function p1p1( p1,p2 )
	return {p1[1]*p2[1],p1[2]*p2[2],p1[3]*p2[3],
			p1[1]*p2[2]+p1[2]*p2[1],p1[1]*p2[3]+p1[3]*p2[1],
			p1[2]*p2[3]+p1[3]*p2[2],p1[1]*p2[4]+p1[4]*p2[1],
			p1[2]*p2[4]+p1[4]*p2[2],p1[3]*p2[4]+p1[4]*p2[3],p1[4]*p2[4]}
	-- return pout;

end

local function p2p1( p1,p2 )
	return {p1[1]*p2[1],p1[2]*p2[2],p1[3]*p2[3],
			p1[1]*p2[2]+p1[4]*p2[1],p1[2]*p2[1]+p1[4]*p2[2],
			p1[1]*p2[3]+p1[5]*p2[1],p1[3]*p2[1]+p1[5]*p2[3],
			p1[2]*p2[3]+p1[6]*p2[2],p1[3]*p2[2]+p1[6]*p2[3],
			p1[4]*p2[3]+p1[5]*p2[2]+p1[6]*p2[1],
			p1[1]*p2[4]+p1[7]*p2[1],p1[2]*p2[4]+p1[8]*p2[2],p1[3]*p2[4]+p1[9]*p2[3],
			p1[4]*p2[4]+p1[7]*p2[2]+p1[8]*p2[1],
			p1[5]*p2[4]+p1[7]*p2[3]+p1[9]*p2[1],
			p1[6]*p2[4]+p1[8]*p2[3]+p1[9]*p2[2],
			p1[7]*p2[4]+p1[10]*p2[1],p1[8]*p2[4]+p1[10]*p2[2],p1[9]*p2[4]+p1[10]*p2[3],p1[10]*p2[4]}
	-- return pout;
end

-- PZ4PZ3 Function responsible for multiplying a 4th order z polynomial p1
--   by a 3rd order z polynomial p2
--   p1 - Is a row vector arranged like: z4 | z3 | z2 | z | 1
--   p2 - Is a row vector arranged like: z3 | z2 | z | 1
--   po - Is a row vector arranged like: z7 | z6 | z5 | z4 | z3 | z2 | z | 1
local function pz4pz3( p1,p2 )
	return {p1[1]*p2[1],
		        p1[2]*p2[1] + p1[1]*p2[2],
		        p1[3]*p2[1] + p1[2]*p2[2] + p1[1]*p2[3],
		        p1[4]*p2[1] + p1[3]*p2[2] + p1[2]*p2[3] + p1[1]*p2[4],
		        p1[5]*p2[1] + p1[4]*p2[2] + p1[3]*p2[3] + p1[2]*p2[4],
		        p1[5]*p2[2] + p1[4]*p2[3] + p1[3]*p2[4],
		        p1[5]*p2[3] + p1[4]*p2[4],
		        p1[5]*p2[4]};  
    -- return po;
end

-- compute the cross product of two 3D column vectors.
local function cross_vec3( u,v ) --u,v size is 1x3
	return {{u[1][2]*v[1][3] - u[1][3]*v[1][2]},
		        u[1][3]*v[1][1] - u[1][1]*v[1][3],
		        u[1][1]*v[1][2] - u[1][2]*v[1][1]}};
    -- return out
end

-- PZ4PZ3 Function responsible for multiplying a 6th order z polynomial p1
--   by a 4th order z polynomial p2
--   p1 - Is a row vector arranged like: z6 | z5 | z4 | z3 | z2 | z | 1
--   p2 - Is a row vector arranged like: z4 | z3 | z2 | z | 1
--   po - Is a row vector arranged like: 
--       z10 | z9 | z8 | z7 | z6 | z5 | z4 | z3 | z2 | z | 1
local function pz6pz4( p1,p2 )
	return  {p1[1]*p2[1],
		        p1[2]*p2[1] + p1[1]*p2[2],
		        p1[3]*p2[1] + p1[2]*p2[2] + p1[1]*p2[3], 
		        p1[4]*p2[1] + p1[3]*p2[2] + p1[2]*p2[3] + p1[1]*p2[4],
		        p1[5]*p2[1] + p1[4]*p2[2] + p1[3]*p2[3] + p1[2]*p2[4] + p1[1]*p2[5],
		        p1[6]*p2[1] + p1[5]*p2[2] + p1[4]*p2[3] + p1[3]*p2[4] + p1[2]*p2[5],
		        p1[7]*p2[1] + p1[6]*p2[2] + p1[5]*p2[3] + p1[4]*p2[4] + p1[3]*p2[5],
		        p1[7]*p2[2] + p1[6]*p2[3] + p1[5]*p2[4] + p1[4]*p2[5],
		        p1[7]*p2[3] + p1[6]*p2[4] + p1[5]*p2[5], 
		        p1[7]*p2[4] + p1[6]*p2[5], 
		        p1[7]*p2[5]};
    -- return po
end

-- PZ4PZ3 Function responsible for multiplying a 7th order z polynomial p1
--   by a 3rd order z polynomial p2
--   p1 - Is a row vector arranged like: z7 | z6 | z5 | z4 | z3 | z2 | z | 1
--   p2 - Is a row vector arranged like: z3 | z2 | z | 1
--   po - Is a row vector arranged like: 
--       z10 | z9 | z8 | z7 | z6 | z5 | z4 | z3 | z2 | z | 1
local function pz7pz3( p1,p2 )
	return {p1[1]*p2[1],
		        p1[2]*p2[1] + p1[1]*p2[2],
		        p1[3]*p2[1] + p1[2]*p2[2] + p1[1]*p2[3],
		        p1[4]*p2[1] + p1[3]*p2[2] + p1[2]*p2[3] + p1[1]*p2[4],
		        p1[5]*p2[1] + p1[4]*p2[2] + p1[3]*p2[3] + p1[2]*p2[4],
		        p1[6]*p2[1] + p1[5]*p2[2] + p1[4]*p2[3] + p1[3]*p2[4], 
		        p1[7]*p2[1] + p1[6]*p2[2] + p1[5]*p2[3] + p1[4]*p2[4], 
		        p1[8]*p2[1] + p1[7]*p2[2] + p1[6]*p2[3] + p1[5]*p2[4],
		        p1[8]*p2[1] + p1[7]*p2[3] + p1[6]*p2[4],
		        p1[8]*p2[3] + p1[7]*p2[4],
		        p1[8]*p2[4]}; 
    -- return po;
end

-- PZ3PZ3 Function responsible for multiplying two 3rd order z polynomial
--   p1, p2 - Are row vector arranged like: z3 | z2 | z | 1
--   po - Is a row vector arranged like: z6 | z5 | z4 | z3 | z2 | z | 1
local function pz3pz3( p1,p2 )
	return {p1[1]*p2[1],
		        p1[1]*p2[2] + p1[2]*p2[1],
		        p1[1]*p2[3] + p1[2]*p2[2] + p1[3]*p2[1],
		        p1[1]*p2[4] + p1[2]*p2[3] + p1[3]*p2[2] + p1[4]*p2[1],
		        p1[2]*p2[4] + p1[3]*p2[3] + p1[4]*p2[2],
		        p1[3]*p2[4] + p1[4]*p2[3],
		        p1[4]*p2[4]};
    -- return po
end

-- Given Matrix A we perform partial pivoting as per specified in
local function gj_elim_pp( A )
	local V,U = lu(A)  --TODO function lu
	local B = imP.zeros(10,20)
	B[1] = U[1]; B[2] = U[2]; B[3] = U[3]; B[4] = U[4];
	for i = 1,20 do
		B[10][i] = U[10][i]/U[10][10]
		B[9][i] = (U[9][i]-U[9][10]*B[10][i])/U[9][9]
		B[8][i] = (U[8][i]-U[8][9]*B[9][i]-U[8][10]*B[10][i])/U[8][8]
		B[7][i] = (U[7][i]-U[7][8]*B[8][i]-U[7][9]*B[9][i]-U[7][10]*B[10][i])/U[7][7]
		B[6][i] = (U[6][i]-U[6][7]*B[7][i]-U[6][8]*B[8][i]-U[6][9]*B[9][i]-U[6][10]*B[10][i])/U[6][6]
		B[5][i] = (U[5][i]-U[5][6]*B[6][i]-U[5][7]*B[7][i]-U[5][8]*B[8][i]-U[5][9]*B[9][i]-U[5][10]*B[10][i])/U[5][5]
	end
	return B;
end

local function partial_subtrc( p1,p2 )
	local po = {-p2[1],p1[1],-p2[2],p1[2],-p2[3],p1[3],
				 -p2[4], p1[4],-p2[5],p1[5],-p2[6],p1[6],
				 -p2[7], p1[7],-p2[8],p1[8],-p2[9],p1[9],-p2[10],p1[10]}
	return po; 
end


local e_val_inner = imP.zeros(10,10);
for i = 2,10 do 
	e_val_inner[i][i-1] = 1
end

-- FIVE_POINT_ALGORITHM Given five points matches between two images, and the
-- intrinsic parameters of each camera. Estimate the essential matrix E, the 
-- rotation matrix R and translation vector t, between both images. This 
-- algorithm is based on the method described by David Nister in "An 
-- Efficient Solution to the Five-Point Relative Pose Problem"
-- [E_all, R_all, t_all, Eo_all] = FIVE_POINT_ALGORITHM(pts1, pts2, K1, K2) 
-- returns in E all the valid Essential matrix solutions for the five point correspondence.
-- returns in R_all and t_all all the rotation matrices and translation
-- vectors of camera 2 for the different essential matrices, such that a 3D
-- point in camera 1 reference frame can be transformed into the camera 2
-- reference frame through p_2 = R{n}*p_1 + t{n}. Eo_all is the essential
-- matrix before the imposing the structure U*diag([1 1 0])*V'. It should
-- help get a better feeling on the accuracy of the solution. All these
-- return values a nx1 cell arrays. 
-- Arguments:
-- pts1, pts2 - assumed to have dimension 2x5 and of equal size. 
-- K1, K2 - 3x3 intrinsic parameters of cameras 1 and 2 respectively
local D = {{0,1,0},{-1,0,0},(0,0,1)};
local z,x,y
local p_z6,p_z7,Eo = {}
local U,V,E,R,t,a,b,c,d,P,C,Q,c_2= {}
local R_all,t_all,E_all,Eo_all = {}
function PD.fivePoint( pts1,pts2,K1,K2 )
	-- local N = 5
	-- local oneN = imP.ones(1,N)	
	-- local m = matrix.copy(pts1)
	-- m[3] = oneN;
	local q1 = matrix.div(K1,{{pts1},{imP.ones(1,5)}});
	-- m[1] = pts2[1]
	-- m[2] = pts2[2]
	local q2 = matrix.div(K2,{{pts2},{imP.ones(1,5)}});
	local q = {array1D.DotProduct(q1[1],q2[1]),array1D.DotProduct(q1[2],q2[1]),array1D.DotProduct(q1[3],q2[1]),
	          array1D.DotProduct(q1[1],q2[2]),array1D.DotProduct(q1[2],q2[2]),array1D.DotProduct(q1[3],q2[2]),
	          array1D.DotProduct(q1[1],q2[3]),array1D.DotProduct(q1[2],q2[3]),array1D.DotProduct(q1[3],q2[3])}
    q = matrix.transpose(q)
    -- local mask = {{1,2,3},{4,5,6},{7,8,9}}
    -- mask[1] = {1,2,3};
    -- mask[2] = {4,5,6};
    -- mask[3] = {7,8,9};
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
    local _A = {}
    --det(F)
    _A[1] = array1D.add(p2p1(array1D.sub(p1p1({X_[1][2],Y_[1][2],Z_[1][2],W_[1][2]},
           {X_[2][3],Y_[2][3],Z_[2][3],W_[2][3]}),
	    p1p1({X_[1][3],Y_[1][3],Z_[1][3],W_[1][3]},
           {X_[2][2],Y_[2][2],Z_[2][2],W_[2][2]})),
	    {X_[3][1],Y_[3][1],Z_[3][1],W_[3][1]}),
	 array1D.add(p2p1(array1D.sub(p1p1({X_[1][3],Y_[1][3],Z_[1][3],W_[1][3]},
           {X_[2][1],Y_[2][1],Z_[2][1],W_[2][1]}),
	    p1p1({X_[1][1],Y_[1][1],Z_[1][1],W_[1][1]},
           {X_[2][3],Y_[2][3],Z_[2][3],W_[2][3]})),
	    {X_[3][1],Y_[3][1],Z_[3][1],W_[3][1]}),
	   p2p1(array1D.sub(p1p1({X_[1][1],Y_[1][1],Z_[1][1],W_[1][1]},
           {X_[2][2],Y_[2][2],Z_[2][2],W_[2][2]}),
	    p1p1({X_[1][2],Y_[1][2],Z_[1][2],W_[1][2]},
           {X_[2][1],Y_[2][1],Z_[2][1],W_[2][1]})),
	    {X_[3][3],Y_[3][3],Z_[3][3],W_[3][3]})))
    --FlippedV
    local EE_t11 = add3(p1p1({Xmat[1][1],Ymat[1][1],Zmat[1][1],Wmat[1][1]},
			{Xmat[1][1],Ymat[1][1],Zmat[1][1],Wmat[1][1]}),
		    p1p1({Xmat[1][2],Ymat[1][2],Zmat[1][2],Wmat[1][2]},
			{Xmat[1][2],Ymat[1][2],Zmat[1][2],Wmat[1][2]}),
		    p1p1({Xmat[1][3],Ymat[1][3],Zmat[1][3],Wmat[1][3]},
			{Xmat[1][3],Ymat[1][3],Zmat[1][3],Wmat[1][3]}));
	-- EE_t12
    local A_12 = add3(p1p1({Xmat[1][1],Ymat[1][1],Zmat[1][1],Wmat[1][1]},
			{Xmat[2][1],Ymat[2][1],Zmat[2][1],Wmat[2][1]}),
		    p1p1({Xmat[1][2],Ymat[1][2],Zmat[1][2],Wmat[1][2]},
			{Xmat[2][2],Ymat[2][2],Zmat[2][2],Wmat[2][2]}),
		    p1p1({Xmat[1][3],Ymat[1][3],Zmat[1][3],Wmat[1][3]},
			{Xmat[2][3],Ymat[2][3],Zmat[2][3],Wmat[2][3]}));
	-- EE_t13
    local A_13 = add3(p1p1({Xmat[1][1],Ymat[1][1],Zmat[1][1],Wmat[1][1]},
			{Xmat[3][1],Ymat[3][1],Zmat[3][1],Wmat[3][1]}),
		    p1p1({Xmat[1][2],Ymat[1][2],Zmat[1][2],Wmat[1][2]},
			{Xmat[3][2],Ymat[3][2],Zmat[3][2],Wmat[3][2]}),
		    p1p1({Xmat[1][3],Ymat[1][3],Zmat[1][3],Wmat[1][3]},
			{Xmat[3][3],Ymat[3][3],Zmat[3][3],Wmat[3][3]}));

    local EE_t22 = add3(p1p1({Xmat[2][1],Ymat[2][1],Zmat[2][1],Wmat[2][1]},
			{Xmat[2][1],Ymat[2][1],Zmat[2][1],Wmat[2][1]}),
		    p1p1({Xmat[2][2],Ymat[2][2],Zmat[2][2],Wmat[2][2]},
			{Xmat[2][2],Ymat[2][2],Zmat[2][2],Wmat[2][2]}),
		    p1p1({Xmat[2][3],Ymat[2][3],Zmat[2][3],Wmat[2][3]},
			{Xmat[2][3],Ymat[2][3],Zmat[2][3],Wmat[2][3]}));
	-- EE_t23
    local A_23 = add3(p1p1({Xmat[2][1],Ymat[2][1],Zmat[2][1],Wmat[2][1]},
			{Xmat[3][1],Ymat[3][1],Zmat[3][1],Wmat[3][1]}),
		    p1p1({Xmat[2][2],Ymat[2][2],Zmat[2][2],Wmat[2][2]},
			{Xmat[3][2],Ymat[3][2],Zmat[3][2],Wmat[3][2]}),
		    p1p1({Xmat[2][3],Ymat[2][3],Zmat[2][3],Wmat[2][3]},
			{Xmat[3][3],Ymat[3][3],Zmat[3][3],Wmat[3][3]}));

    local EE_t33 = add3(p1p1({Xmat[3][1],Ymat[3][1],Zmat[3][1],Wmat[3][1]},
			{Xmat[3][1],Ymat[3][1],Zmat[3][1],Wmat[3][1]}),
		    p1p1({Xmat[3][2],Ymat[3][2],Zmat[3][2],Wmat[3][2]},
			{Xmat[3][2],Ymat[3][2],Zmat[3][2],Wmat[3][2]}),
		    p1p1({Xmat[3][3],Ymat[3][3],Zmat[3][3],Wmat[3][3]},
			{Xmat[3][3],Ymat[3][3],Zmat[3][3],Wmat[3][3]}));

 --    Not used
	-- EE_t21 = EE_t12;
	-- EE_t31 = EE_t13;
	-- EE_t32 = EE_t23;
	local subarr2 = array1D.mulnum(add3(EE_t11,EE_t22,EE_t33),0.5)
	local A_11 = array1D.sub(EE_t11,subarr2)
	-- local A_12 = array1D.copy(EE_t12)
	-- local A_13 = array1D.copy(EE_t13)
	local A_21 = A_12
	local A_22 = array1D.sub(EE_t22,subarr2)
	-- local A_23 = array1D.copy(EE_t23)
	local A_31 = A_13
	local A_32 = A_23
	local A_33 = array1D.sub(EE_t33,subarr2)

	-- AE_xx
	_A[2] = add3(p2p1(A_11, {Xmat[1][1],Ymat[1][1],Zmat[1][1],Wmat[1][1]}),
			p2p1(A_12,{Xmat[2][1],Ymat[2][1],Zmat[2][1],Wmat[2][1]}),
			p2p1(A_13,{Xmat[3][1],Ymat[3][1],Zmat[3][1],Wmat[3][1]}))

	_A[3] = add3(p2p1(A_11, {Xmat[1][2],Ymat[1][2],Zmat[1][2],Wmat[1][2]}),
			p2p1(A_12,{Xmat[2][2],Ymat[2][2],Zmat[2][2],Wmat[2][2]}),
			p2p1(A_13,{Xmat[3][2],Ymat[3][2],Zmat[3][2],Wmat[3][2]}))

	_A[4] = add3(p2p1(A_11, {Xmat[1][3],Ymat[1][3],Zmat[1][3],Wmat[1][3]}),
			p2p1(A_12,{Xmat[2][3],Ymat[2][3],Zmat[2][3],Wmat[2][3]}),
			p2p1(A_13,{Xmat[3][3],Ymat[3][3],Zmat[3][3],Wmat[3][3]}))

	_A[5] = add3(p2p1(A_21, {Xmat[1][1],Ymat[1][1],Zmat[1][1],Wmat[1][1]}),
			p2p1(A_22,{Xmat[2][1],Ymat[2][1],Zmat[2][1],Wmat[2][1]}),
			p2p1(A_23,{Xmat[3][1],Ymat[3][1],Zmat[3][1],Wmat[3][1]}))

	_A[6] = add3(p2p1(A_21, {Xmat[1][2],Ymat[1][2],Zmat[1][2],Wmat[1][2]}),
			p2p1(A_22,{Xmat[2][2],Ymat[2][2],Zmat[2][2],Wmat[2][2]}),
			p2p1(A_23,{Xmat[3][2],Ymat[3][2],Zmat[3][2],Wmat[3][2]}))

	_A[7] = add3(p2p1(A_21, {Xmat[1][3],Ymat[1][3],Zmat[1][3],Wmat[1][3]}),
			p2p1(A_22,{Xmat[2][3],Ymat[2][3],Zmat[2][3],Wmat[2][3]}),
			p2p1(A_23,{Xmat[3][3],Ymat[3][3],Zmat[3][3],Wmat[3][3]}))

	_A[8] = add3(p2p1(A_31, {Xmat[1][1],Ymat[1][1],Zmat[1][1],Wmat[1][1]}),
			p2p1(A_32,{Xmat[2][1],Ymat[2][1],Zmat[2][1],Wmat[2][1]}),
			p2p1(A_33,{Xmat[3][1],Ymat[3][1],Zmat[3][1],Wmat[3][1]}))

	_A[9] = add3(p2p1(A_31, {Xmat[1][2],Ymat[1][2],Zmat[1][2],Wmat[1][2]}),
			p2p1(A_32,{Xmat[2][2],Ymat[2][2],Zmat[2][2],Wmat[2][2]}),
			p2p1(A_33,{Xmat[3][2],Ymat[3][2],Zmat[3][2],Wmat[3][2]}))

	_A[10] = add3(p2p1(A_31, {Xmat[1][3],Ymat[1][3],Zmat[1][3],Wmat[1][3]}),
			p2p1(A_32,{Xmat[2][3],Ymat[2][3],Zmat[2][3],Wmat[2][3]}),
			p2p1(A_33,{Xmat[3][3],Ymat[3][3],Zmat[3][3],Wmat[3][3]}))

	-- local _A = {detF,AE_11,AE_12,AE_13,AE_21,AE_22,AE_23,AE_31,AE_32,AE_33}
	local A = onlydoforA(_A)
	-- Gauss Jordan elimination (partial pivoting after)
	local A_el = gj_elim_pp(A)
	-- Subtraction and forming matrix B
	local k_row = partial_subtrc(imP.submatrix(A_el,5,5,11,20),imP.submatrix(A_el,6,6,11,20))
	local l_row = partial_subtrc(imP.submatrix(A_el,7,7,11,20),imP.submatrix(A_el,8,8,11,20))
	local m_row = partial_subtrc(imP.submatrix(A_el,9,9,11,20),imP.submatrix(A_el,10,10,11,20))

	local B11 = imP.submatrix(k_row,1,1,1,4)
	local B12 = imP.submatrix(k_row,1,1,5,8)
	local B13 = imP.submatrix(k_row,1,1,9,13)
	local B21 = imP.submatrix(l_row,1,1,1,4)
	local B22 = imP.submatrix(l_row,1,1,5,8)
	local B23 = imP.submatrix(l_row,1,1,9,13)
	local B31 = imP.submatrix(m_row,1,1,1,4)
	local B32 = imP.submatrix(m_row,1,1,5,8)
	local B33 = imP.submatrix(m_row,1,1,9,13)

	local p_1 = array1D.sub(pz4pz3(B_23,B_12),pz4pz3(B_13,B_22));
	local p_2 = array1D.sub(pz4pz3(B_13,B_21),pz4pz3(B_23,B_11));
	local p_3 = array1D.sub(pz3pz3(B_11,B_22),pz3pz3(B_12,B_21));

	local n_row = add3v(pz7pz3(p_1,B_31),pz7pz3(p_2,B_32),pz6pz4(p_3,B_33))
	--Extracting roots from n_row using companion matrix eigen values
	n_row = array1D.mulnum(n_row,-1/n_row[1])
	e_val_inner[1] = imP.subvector(n_row,2,_)
	local e_val = eig(e_val_inner)  --TODO function eig

	local m = 0
	for n = 1,10 do
		if isreal(e_val(n)) = 1 then --TODO function isreal
			m = m+1
		end
	end

	-- local R_all,t_all,E_all,Eo_all = imP.zeros(m,1)
	m = 1
	-- local z,x,y
	-- local p_z6,p_z7,Eo = {}
	-- local U,V,E,R,t,a,b,c,d,P,C,Q,c_2= {}
	for n = 1,10 do 
		if isreal(e_val(n)) = 1 then --TODO function isreal
			z = e_val(n)

			--Backsubstition
			p_z6 = {z^6,z^5,z^4,z^3,z^2,z,1}
			p_z7 = {z^7,p_z6}
			x = array1D.mul(p_1,p_z7)/array1D(p_3,p_z6)
			y = array1D.mul(p_2,p_z7)/array1D(p_3,p_z6)

			Eo = matrix.add(Wmat,add3(matrix.mulnum(Xmat,x),matrix.mulnum(Ymat,y),matrix.mulnum(Zmat,z)));
			Eo_all[m] = Eo;
			U,V = svd(Eo);
			E = matrix.mul(matrix.mul(U,diag({1,1,0})),matrix.transpose(V))
			E_all[m] = E;

			-- lua nargout

			--check determinan signs
			if(matrix.det(U) < 0) then
				for i = 1,#U do
					U[i][3] = -U[i][3]
				end
			end

			if(matrix.det(V) < 0) then
				for i = 1,#V do
					V[i][3] = -V[i][3]
				end
			end

			-- Extracting R and t from E 
			local q_1,q_2 = {}
			q_1[1],q_2[1] = {}
			for i = 1,#q1 do
				q_1[1][i] = q1[i][1]
				q_2[1][i] = q2[i][1]
			end

			for n = 1,4 do
				t[1] = {}
				if (n%2 == 0) then
					for i = 1,#U do 
						t[1][i] = -U[i][3]
					end
				else
					for i = 1,#U do 
						t[1][i] = U[i][3]
					end
				end
				if (n<3) then
					R = matrix.mul(U,matrix.mul(D,matrix.transpose(V)))
				else
					R = matrix.mul(U,matrix.transpose(matrix.mul(V,D)))
				end
				-- Cheirality (points in front of the camera) constraint assuming perfect
				-- point correspondence	 
				--size 1x3
				a = matrix.mul(q_2,E)
				b = cross_vec3(q_1,{{a[1],a[2],0}})
				c = cross_vec3(q_2,matrix.mul(matrix.mul(q_1,matrix.transpose(E)),diag({1,1,0})))
				d = cross_vec3(a,b)

				P = matrix.concath(R,matrix.transpose(t)) --3x4
				C = matrix.mul(c,P) --1x4
				Q = matrix.concath(matrix.mulnum(d,C[1][4]), 
					matrix.mulnum(matrix.mul(d,{{C[1][1]},{C[1][2]},{C[1][3]}}),-1))  --1x4

				if (Q[1][3]*Q[1][4] >= 0) then
					c_2 = matrix.mul(P,matrix.transpose(Q)) --3x1
					if (c_2[3][1]*Q[1][4] >= 0) then
						R_all[m] = R
						t_all[m] = t
						break
					end
				end
			end
			m = m + 1
		end
	end
	return E_all,R_all,t_all,Eo_all

end
