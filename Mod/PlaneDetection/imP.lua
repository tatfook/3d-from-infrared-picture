--[[
Title: 
Author(s): Mofafa
Date: 2017/7/20
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/PlaneDetection/imP.lua");
------------------------------------------------------------
]]


local imP = commonlib.gettable("imP");
--imP = {};

function imP:new( o )
	o = o or {}
	setmetatable(o,self)
	self.__index = self
	return o;
end


--return size of 1D or 2D array 
function imP.ArraySize( arr )
	local a = #arr;
	local b;
	if type(arr[1]) ~= "table" then
		b = 1;
		return a;
	else
		b = #arr[1];
		return a,b;
	end
end
local ArraySize = imP.ArraySize;

--return the key of specified value
--如果bool为true，返回value索引，否则返回不等于value的索引
--默认返回0元素真索引
--如果tab为1维，返回的y为nil
function imP.find(tab,value,bool)
    if value==nil then
		value = 0;
	end
    if bool==nil then
		bool = true;
	end	
	local x = {};
	local y = {};
	if bool == true then
		for k,v in pairs(tab) do 
			if type(tab[k]) == "table" then
				for j,i in pairs(tab[k]) do
					if i==value then 
						x[#x+1] = k;
						y[#y+1] = j;
					end
			    end
			else
				if v==value then
					x[#x+1] = k;
					y[#y+1] = nil;
				end
		    end
		end 
	else
		for k,v in pairs(tab) do 
			if type(tab[k]) == "table" then
				for j,i in pairs(tab[k]) do
					if i~=value then 
						x[#x+1] = k;
						y[#y+1] = j;
					end
			    end
			else
				if v~=value then
					x[#x+1] = k;
					y[#y+1] = nil;
				end
		    end
		end 
	end
	return x,y
end
local find = imP.find;

-- 1th difference
function imP.diff( vector )
    if nth==nil then
		nth = 1;
	end
	local result = {};
	local k;
	if #vector == 1 then
		result = {};
	else
		for j=2,#vector do
			k = vector[j]-vector[j-1];
			result[#result + 1] = k;
		end
	end
	return result;		
end
local diff = imP.diff;

--截取vector中n到m的一部分
function imP.subvector( vector,n,m )
    if n==nil then
		n = 1;
	end	
	if m==nil then
		m = #vector;
	end	
	local subv = {};
	for i = n, m do
		subv[#subv + 1] = vector[i]; --type is table
	end
--	if n ~= m then
--		for i = n,m do
--			subv[#subv + 1] = vector[i]; --type is table
--	    end
--	else
--		subv = vector[m];  --type is number
--	end
	return subv;
end
local subvector = imP.subvector;


--截取matrix中一部分,a,b为row索引，c,d为column索引
function imP.submatrix( matrix,a,b,c,d )
    if a==nil then
		a = 1;
	end	
	if b==nil then
		m = #matrix;
	end	
	if c==nil then
		c = 1;
	end	
	if d==nil then
		d = #matrix[1];
	end	
	local subm ={};
	for i = 1,b-a+1 do
		subm[i] = {}
		for j = 1,d-c+1 do 
			subm[i][j] = matrix[i-1+a][j-1+c];
		end
	end
	return subm;
end
local submatrix = imP.submatrix;

--connect 2 vector
function imP.connect( A,B )
	local result = {};
	for k,v in pairs(A) do
		result[#result + 1] = v;
	end
	for k,v in pairs(B) do
		result[#result + 1] = v;
	end
	return result;
end
local connect = imP.connect;

--turn the size of A to m * n
--return type is table
function imP.reshape( A, m,n )
	local a, b = imP.ArraySize(A);
	local V = {};
	local result = {};
	if b ~= nil then --A is a matrix
		for k,v in pairs(A) do
			V = imP.connect(V,A[k]);
		end
		if m == 1 then
			result = V;
		else
		for i = 1,m do
			result[i] = imP.subvector(V,1+n*(i-1),n*i);
		end
	    end
	else --A is a vector, m usually will not be 1
		for i = 1,m do 
			result[i] = imP.subvector(A,1+n*(i-1),n*i);
		end		
	end
	return result;
end
local connect = imP.connect;

function imP.bool2num( bool )
	local num;
	if bool == true then
		num = 1;
	else
		num = 0;
	end
	return num;
end
local bool2num = imP.bool2num;


function imP.ArrayAdd(array, n)
	-- Array addes number.
	local h = #array;
	local w = #array[1];
	local array_o = imP.zeros(h, w);
	for i = 1, h do
		for j = 1, w do
			array_o[i][j] = array[i][j] + n;
		end
	end
	return array_o;
end
local ArrayAdd = imP.ArrayAdd;


function imP.ArraySum(array)
	-- Here the array is matrix. Sum each elements of the array.
	local h = #array;
	local w = #array[1];
	local sum = 0;
	for i = 1, h do
		for j = 1, w do 
			sum = sum + array[i][j];
		end
	end
	return sum;
end
local ArraySum = imP.ArraySum;


function imP.DotProduct(array1, array2)
	-- Array dot product.
	local h = table.getn(array1);
	local w = table.getn(array1[1]);
	local array = imP.zeros(h, w);
	for i = 1, h do
		for j = 1, w do
			array[i][j] = array1[i][j] * array2[i][j];
		end
	end
	return array;
end
local DotProduct = imP.DotProduct;

--
function imP.zeros(height, width)
	-- Creat the zeros matrix.
	local array = {};
	for h = 1, height do
		array[h] = {};
		for w = 1, width do
			array[h][w] = 0;
		end
	end
	return array;	
end
local zeros = imP.zeros;

function imP.ones(height, width)
	-- Creat the zeros matrix.
	local array = {};
	for h = 1, height do
		array[h] = {};
		for w = 1, width do
			array[h][w] = 1;
		end
	end
	return array;	
end
local zeros = imP.ones;

function imP.Array2Max(array)
	-- Find the Max Value of the 2D Array
	local max = array[1][1];
	for i, v in ipairs(array) do
		for j, m in ipairs(array[i]) do	
			if m>max then
				max = m;
			end
		end
	end 
	return max;
end
local Array2Max = imP.Array2Max;


-------------------------
function imP.transpose( m )
	local mtx = {}
	for i = 1,#m[1] do
		mtx[i] = {}
		for j = 1,#m do
			mtx[i][j] = m[j][i]
		end
	end
	return mtx
end

function imP.add( m1, m2 )
	local mtx = {}
	for i = 1,#m1 do
		mtx[i] = {}
		for j = 1,#m1[1] do
			mtx[i][j] = m1[i][j] + m2[i][j]
		end
	end
	return mtx
end

function imP.aAdda(arr1, arr2)
	-- Array mutliplies number.
	local h = table.getn(arr1);
	local array_o = imP.zeros(h,1)
	for i = 1, h do
			array_o[i] = arr1[i] + arr2[i];
		
	end
	return array_o;
end


function imP.ArrayMutl(array, n)
	-- Array mutliplies number.
	local h = table.getn(array);
	local w = table.getn(array[1]);
	local array_o = zeros(h, w)
	for i = 1, h do
		for j = 1, w do
			array_o[i][j] = array[i][j] * n;
		end
	end
	return array_o;
end


--[[get gradient gx and gy of matrix m
e.g.
 local D = {}
 D[1] = {1,1,0,0,1};
 D[2] = {2,1,2,2,0};
 D[3] = {2,1,1,0,1};
 local gx,gy = imP.gradient(D)
gx and gy are matrixes]] 
function  imP.gradient( m )
	local rows = #m;
	local cols = #m[1];
	local gx = zeros(rows,cols);
	local gy = zeros(rows,cols);
	for i = 1,rows do 
		gy[i][1] = m[i][2]-m[i][1]
		gy[i][cols] = m[i][cols]-m[i][cols-1]
		for j = 2, cols-1 do
			gy[i][j] = 0.5*(m[i][j+1]-m[i][j-1])
		end
	end
	for j = 1, cols do 
		gx[1][j] = m[2][j]-m[1][j]
		gx[rows][j] = m[rows][j]-m[rows-1][j]
		for i = 2, rows-1 do
			gx[i][j] = 0.5*(m[i+1][j]-m[i-1][j])
		end
	end
	return gx,gy
end
local gradient = imP.gradient;

--
function imP.round(num)
    local rnum = math.floor(num+0.5)        
    return  rnum 
end
local round = imP.round;


--Read the image and creat the Gray image.
function imP.imread(filename)
	local file = ParaIO.open(filename, "image");
	if(file:IsValid()) then
		local ver = file:ReadInt();
		local width = file:ReadInt();
		local height = file:ReadInt();
		-- how many bytes per pixel, usually 1, 3 or 4
		local bytesPerPixel = file:ReadInt();
		-- echo({ver, width = width, height = height, bytesPerPixel = bytesPerPixel})
		local pixel = {};
		local array = {};
		for i = 1, bytesPerPixel do
			array[i] = zeros(height, width);
		end
		for j = 1, height do
			for i = 1, width do
				pixel = file:ReadBytes(bytesPerPixel, pixel);
				for h = 1, bytesPerPixel do				    
					array[h][j][i] = pixel[4-h];
				end
			end
		end
		return array;
	else
		print("The file is not valid");
	end
end
local imread = imP.imread;

function imP.rgb2gray(array)
	if (#array == 3 and type(array[1]) == "table" and type(array[1][1]) == "table") then
		local row = #array[1];
		local column = #array[1][1];
		local self = zeros(row, column);
		for i = 1, row do
			for j = 1, column do
				self[i][j] = (299*array[1][i][j] + 587*array[2][i][j] + 114*array[3][i][j])/1000;
				self[i][j] = math.floor(self[i][j] + 0.5);
			end
		end
		return self;
	end
end
local rgb2gray = imP.rgb2gray;

-- Creat the txt file of the array.
function imP.CreatTXT(array, filename)	
	local file = io.open(filename, "w");
	local h = #(array);
	if h ~= nil then
		for j = 1, h do
			local w = #(array[j]);
			if w ~= nil then
				for i = 1, w do
					file:write(array[j][i], "\t");
				end
			end
			file:write("\r");
		end
	end
	file:close();
end
local CreatTXT = imP.CreatTXT;
