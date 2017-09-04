--[[
Title: 
Author(s): Mofafa
Date: 2017/7/20
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/PlaneDetection/array1D.lua");
------------------------------------------------------------
]]
local array1D =  commonlib.gettable("array1D");


-- simple copy, one can write other functions oneself
function array1D.copy( _a )
	local a_ = {}
	for i = 1,#_a do
		a_[i] = _a[i]
	end
	return a_
end

--1D array add a 1D array
function array1D.add(A1,A2)
	local array_o = {}
	for i = 1, #A1 do
		array_o[i] = A1[i] + A2[i];
	end
	return array_o;
end

--1D array sub a 1D array
function array1D.sub(A1,A2)
	local array_o = {}
	for i = 1, #A1 do
		array_o[i] = A1[i] - A2[i];
	end
	return array_o;
end

function array1D.DotProduct(a1,a2)
	-- 1D Array dot product.
	local a = {};
	for i = 1, #a1 do
		a[i] = a1[i]*a2[i]
	end
	return a;
end

-- local A = {1,2,3}
-- local B = {4,5,6}
-- print(array1D.mul(A,B))  --ans is 32
function array1D.mul( v1,v2 )
	-- multiply rows with columns
	local v_ = 0
	for i = 1, #v1 do
		v_ = v_ + v1[i]*v2[i]
	end
	return v_
end

function array1D.mulnum(_a,n)
	-- 1D Array multiply a number 
	local a_ = {};
	for i = 1, #_a do
		a_[i] = _a[i]*n
	end
	return a_;
end

-- find maximum value in 1D array _a
function array1D.max( _a )
	local maxa = _a[1];
	for k, v in ipairs(_a) do
		if v>maxa then
			maxa = v;
		end
	end 
	return maxa;
end
