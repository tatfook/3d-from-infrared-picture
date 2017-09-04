--[[
Title: 
Author(s): BerryZSZ
Date: 2017/7/19
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/ImagesTo3Dmodel/imP.lua");
------------------------------------------------------------
------------------------------------------------------------
local zeros = imP.tensor.zeros;
local ones = imP.tensor.ones;
local zeros3 = imP.tensor.zeros3;
local Round = imP.Round;
local imread = imP.imread;
local rgb2gray = imP.rgb2gray;
local CreatTXT = imP.CreatTXT;
local DotProduct = imP.tensor.DotProduct;
local ArraySum = imP.tensor.ArraySum;
local ArrayShowE = imP.tensor.ArrayShowE;
local ArrayShow = imP.tensor.ArrayShow;
local ArrayShow3 = imP.tensor.ArrayShow3;
local ArrayMult = imP.tensor.ArrayMult;
local ArrayAdd = imP.tensor.ArrayAdd;
local ArraySize = imP.tensor.ArraySize;
local bool2num = imP.tensor.bool2num;
local ArrayAddArray = imP.tensor.ArrayAddArray;
local FindMax2 = imP.tensor.FindMax2;
local FindMin2 = imP.tensor.FindMin2;
local FindMax3 = imP.tensor.FindMax3;
local FindMin3 = imP.tensor.FindMin3;
local diff = imP.tensor.diff;
local GetGaussian = imP.GetGaussian;
local GaussianF = imP.GaussianF;
local DoG = imP.DoG;
local meshgrid = imP.tensor.meshgrid;
local conv2 = imP.tensor.conv2;
local Det2 = imP.tensor.Det2;
local Trace2 = imP.tensor.Trace2;
local HarrisCD = imP.HarrisCD;
local GetColumn = imP.tensor.GetColumn;
local MatrixMultiple = imP.tensor.MatrixMultiple;
local det = imP.tensor.det;
local SubMatrix = imP.tensor.SubMatrix;
local inv = imP.tensor.inv;
local find = imP.tensor.find;
local subvector = imP.tensor.subvector;
local submatrix = imP.tensor.submatrix;
local connect = imP.tensor.connect;
local reshape = imP.tensor.reshape;
local transposition = imP.tensor.transposition;
local norm = imP.tensor.norm;
local dot = imP.tensor.dot;
local mod = imP.tensor.mod;
local gradient = imP.tensor.gradient;
local Spline = imP.tensor.Spline;
local imresize = imP.tensor.imresize;
local mean = imP.tensor.mean;
local diag = imP.tensor.diag;
local eye = imP.tensor.eye;
local sign = imP.tensor.sign;
local triu = imP.tensor.triu;

------------------------------------------------------------
]]

local imP = commonlib.gettable("imP");
local tensor = commonlib.inherit(nil, commonlib.gettable("imP.tensor"));

-- Creat the zeros matrix.
function imP.tensor.zeros(height, width)
	local array = {};
	for h = 1, height do
		array[h] = {};
		for w = 1, width do
			array[h][w] = 0;
		end
	end
	return array;	
end
local zeros = imP.tensor.zeros;
-- a=zeros(2,2);

function imP.tensor.ones(height, width)
	-- Creat the ones matrix.
	local array = {};
	for h = 1, height do
		array[h] = {};
		for w = 1, width do
			array[h][w] = 1;
		end
	end
	return array;	
end
local ones = imP.tensor.ones;

-- Creat the 3D zeros matrix.
function imP.tensor.zeros3(h, w, d)
	local self = {};
	for i = 1, h do
		self[i] = {};
		for j = 1, w do
			self[i][j] = {};
			for k = 1, d do
				self[i][j][k] = 0;
			end
		end
	end
	return self;
end
local zeros3 = imP.tensor.zeros3;


-- Find the nearest integer.
function imP.Round(n)
	local self;
	if type(n) == "number" then
		self = math.floor(n + 0.5);
	elseif type(n) == "table" and type(n[1]) =="number" then
		self = {};
		for i, v in ipairs(n) do
			table.insert(self, 1, math.floor(v + 0.5));
		end
	elseif type(n) == "table" and type(n[1]) == "table" then
		self = {};
		for i, v in ipairs(n) do
			table.insert(self, i, {});
			for j, m in ipairs(v) do 
				table.insert(self[i], j, math.floor(n[i][j]));
			end
		end
	end
	return self;
end
local Round = imP.Round;
--print(Round(9.3));


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
					array[h][j][i] = pixel[h];
				end
			end
		end
		return array;
	else
		LOG.std(nil, "warn", "imP", "The file %s not found", filename);
	end
end
local imread = imP.imread;

function imP.rgb2gray(array)
	if(#array == 3 and type(array[1]) == "table" and type(array[1][1]) == "table") then
		local row = #array[1];
		local column = #array[1][1];
		local self = zeros(row, column);
		for i = 1, row do
			for j = 1, column do
				self[i][j] =(299 * array[1][i][j] + 587 * array[2][i][j] + 114 * array[3][i][j]) / 1000;
				self[i][j] = math.floor(self[i][j] + 0.5);
			end
		end
		return self;
	end
end
local rgb2gray = imP.rgb2gray;

-- Creat the txt file of the array.
function imP.CreatTXT(array, filename)	
	ParaIO.CreateDirectory(filename);
    local file = ParaIO.open(filename, "w");
	if(file:IsValid()) then
		local h = #(array);
		for j = 1, h do
			local w = #(array[j]);
			if w ~= nil then
				for i = 1, w do
					file:WriteString(array[j][i].."\t");
				end
			end
			file:WriteString("\r");
		end
		LOG.std(nil, "debug", "imP", "succesfullly written to %s with length %d", filename, h);
		file:close();
	else
		LOG.std(nil, "warn", "imP", "unable to open file %s for writing", filename);
	end
end
local CreatTXT = imP.CreatTXT;



-- Array dot product.
-- @param output: inout result of a1*a2. if nil, a new array is created
function imP.tensor.DotProduct(array1, array2, output)
	if type(array1[1]) == "number" then
		local output = output or {};
		for i = 1, #array1 do
			output[i] = array1[i] * array2[i];
		end
		return output;
	elseif type(array1[1]) == "table" and type(array1[1][1]) == "number" then	
		local h = #(array1);
		local w = #(array1[1]);
		local output = output or zeros(h, w);
		for i = 1, h do
			for j = 1, w do
				output[i][j] = array1[i][j] * array2[i][j];
			end
		end
		return output;
	else
		LOG.std(nil, "warn", "imP", "imP.tensor.DotProduct: unexpected array type");
	end
end
local DotProduct = imP.tensor.DotProduct;

function imP.tensor.ArraySize( arr )
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
local ArraySize = imP.tensor.ArraySize;


-- Here the array is matrix. Sum each elements of the array.
function imP.tensor.ArraySum(array)
	local sum = 0;
	if type(array[1]) == "number" then
		for i = 1, #array do
			sum = sum + array[i];
		end
	elseif(type(array[1]) == "table" and type(array[1][1]) == "number") then
		for i = 1, #array do
			for j = 1, #array[1] do 
				sum = sum + array[i][j];
			end
		end
	else
		LOG.std(nil, "warn", "imP", "imP.tensor.ArraySum: unexpected array type");
	end
	return sum;
end
local ArraySum = imP.tensor.ArraySum;

-- Show the each element of the array.
function imP.tensor.ArrayShowE(array)
	for i, v in pairs(array) do
		for j, m in pairs(array[i]) do
			print(i, j, m);
		end
	end
end
local ArrayShowE = imP.tensor.ArrayShowE;

-- Show the array.
function imP.tensor.ArrayShow(array)
	for i, v in pairs(array) do
		if type(v) == "table" then
			print(table.concat(v, " "));
		else
			print(v, "");
		end
	end
end
local ArrayShow = imP.tensor.ArrayShow;

-- Show the 3D array.
function imP.tensor.ArrayShow3(array)
	for i, v in pairs(array) do
		for j, w in pairs(v) do
			print(table.concat(w, " "));
		end
	end
end
local ArrayShow3 = imP.tensor.ArrayShow3;

-- Array mutliplies number.
function imP.tensor.ArrayMult(array, n, output)
	if type(array[1]) == "table" then
		local h = #(array);
		local w = #(array[1]);
		local array2_o = output or zeros(h, w);
		for i = 1, h do
			for j = 1, w do
				array2_o[i][j] = array[i][j] * n;
			end
		end
		return array2_o;
	else 
		local array1_o = output or {};
		for i = 1, #array do
			array1_o[i] = array[i] * n;
		end
		return array1_o;
	end
end
local ArrayMult = imP.tensor.ArrayMult;
--ArrayShow(ArrayMult(array,3))


-- Array addes number.
function imP.tensor.ArrayAdd(array, n)
	local h = #(array);
	local w = #(array[1]);
	local array_o = zeros(h, w);
	for i = 1, h do
		for j = 1, w do
			array_o[i][j] = array[i][j] + n;
		end
	end
	return array_o;
end
local ArrayAdd = imP.tensor.ArrayAdd;
--ArrayShow(ArrayAdd(array,3))


-- Two having same heigth and width array add
function imP.tensor.ArrayAddArray(array1, array2, output)
	if(type(array1[1]) == "number" and type(array2[1]) == "number") then
		local output = output or {}
		for i = 1, #(array1) do
			output[i] = array1[i] + array2[i];
		end
		return output;
	elseif(type(array1[1]) == "table" and type(array2[1]) == "table" and type(array1[1][1]) == "number" and type(array2[1][1]) == "number") then
		local h1 = #(array1);
		local w1 = #(array1[1]);
		local h2 = #(array2);
		local w2 = #(array2[1]);
		if(h1==h2 and w1==w2) then
			local output = output or zeros(h1, w1);
			for i = 1, h1 do
				for j = 1, w1 do
					output[i][j] = array1[i][j] + array2[i][j];
				end
			end
			return output;
		end
	else
		LOG.std(nil, "warn", "imP", "imP.tensor.ArrayAddArray: unexpected array type");

	end
end
local ArrayAddArray = imP.tensor.ArrayAddArray;
-- a={{1,2,3},{1,2,3}};
-- b={{4,5,6},{4,5,6}};
-- ArrayShow(ArrayAddArray(a,b))

-- Find the Max Value of the 2D Array
function imP.tensor.FindMax2(array)
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
local FindMax2 = imP.tensor.FindMax2;


-- Find the Min Value of the 2D Array
function imP.tensor.FindMin2(array)
	local min = array[1][1];
	for i, v in ipairs(array) do
		for j, m in ipairs(array[i]) do
			if m<min then
				min = m;
			end
		end
	end 
	return min;
end
local FindMin2 = imP.tensor.FindMin2;


-- Find the Max Value of the 3D Array
function imP.tensor.FindMax3(array)
	local max = array[1][1][1];
	for i, v in ipairs(array) do
		for j, m in ipairs(array[i]) do
			for p, q in ipairs(array[i][j]) do
				if q>max then
					max = q;
				end
			end
		end
	end 
	return max;
end
local FindMax3 = imP.tensor.FindMax3;


-- Find the Min Value of the 3D Array
function imP.tensor.FindMin3(array)
	local min = array[1][1][1];
	for i, v in ipairs(array) do
		for j, m in ipairs(array[i]) do
			for p, q in ipairs(array[i][j]) do
				if q<min then
					min = q;
				end
			end
		end
	end 
	return min;
end
local FindMin3 = imP.tensor.FindMin3;

-- 1th difference
function imP.tensor.diff( vector )
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
local diff = imP.tensor.diff;

-- Get the Gaussian nucleus from the window size(wsize) and the sigma(sig).
function imP.GetGaussian(sig)
	if sig==nil then
		sig = 1;
	end
	local wsize = 2 * math.ceil(2 * sig) + 1;
	local w = math.ceil(wsize / 2);
	--local n=math.pow(10,math.ceil(-math.log10(1/sig^2*math.exp(-(w-1)^2/sig^2))));
	local g = zeros(wsize, wsize);
	for i = 1, wsize do
		for j = 1, wsize do
			g[i][j] = (1 / sig^2) * math.exp(-((i-w)^2+(j - w)^2) / 2 / sig^2);
		end
	end
	local sum = ArraySum(g)
	g = ArrayMult(g, 1 / sum);
	return g;
end
local GetGaussian = imP.GetGaussian;
-- a=GetGaussian(5);
-- ArrayShow(a);
-- print(ArraySum(a))


-- Gaussian Filter
function imP.GaussianF(array, sig)
	local h = #(array);
	local w = #(array[1]);
	local G = zeros(h, w);
	if sig==nil then
		sig = 1;
	end
	local wsize = 2 * math.ceil(2 * sig) + 1;
	local d = math.floor(wsize / 2);
	local u = math.ceil(wsize / 2);
	local g = GetGaussian(sig);
	--ArrayShow(g);
	local A = zeros(wsize, wsize);
	local tempResult = zeros(wsize, wsize);
	for i = 1 + d, h - d do
		for j = 1 + d, w - d do
			for a = 1, wsize do
				for b = 1, wsize do
					A[a][b] = array[i + a-u][j + b-u];
				end
			end
			G[i][j] = ArraySum(DotProduct(A, g, tempResult));
		end
	end
	return G;
end
local GaussianF = imP.GaussianF;
-- arrayG={{1,2,3,4,5},{1,2,3,4,5},{1,2,3,4,5},{1,2,3,4,5},{1,2,3,4,5}};
-- G=GaussianF(arrayG);
-- ArrayShow(G);

-- Difference of Gaussian
function imP.DoG(array, sig, n)
	if n==nil then
		n = 4;
	end
	if sig==nil then
		sig = 1;
	end
	local k = math.pow(2, 1 / n);
	local d = math.ceil(2 * sig * math.pow(k, n-1)) + 1;
	local h = #(array);
	local w = #(array[1]);
	local G = {};
	for i = 1, n do
		G[i] = GaussianF(array, sig * math.pow(k, i-1));
	end
	local DoG = {};
	for i = 1, n-1 do
		DoG[i] = ArrayAddArray(G[i + 1], ArrayMult(G[i], -1));
	end
	local A = {};
	for i = 1, 3 do
		A[i] = zeros(3, 3);
	end
	local F = zeros(h, w);
	for q = 2, n-2 do
		for i = 1 + d, h - d do 
			for j = 1 + d, w - d do
				for x = 1, 3 do
					for m = 1, 3 do
						for n = 1, 3 do
							A[x][m][n] = DoG[q + x-2][i + m-2][j + n-2];
						end
					end
				end
				if DoG[q][i][j]==FindMax3(A) then
					F[i][j] = q + F[i][j];
				elseif DoG[q][i][j]==FindMin3(A) then
					F[i][j] = q + n + F[i][j];
				else
					F[i][j] = 0;
				end
			end
		end
	end
	return F;
end
local DoG = imP.DoG;


-- Generate a meshgrid. 
-- Horizontal:mode=0, vertical: mode=1
function imP.tensor.meshgrid(a, b, mode)
	if(mode~=0 and mode~=1) then
		mode = 0;
	end
	local d = math.abs(a-b) + 1;
	local array = zeros(d, d);
	if mode==0 then
		for i = 1, d do
			for j = 1, d do
				array[i][j] = i;
			end
		end
	else
		for i = 1, d do
			for j = 1, d do
				array[i][j] = j;
			end
		end
	end
	array = ArrayAdd(array, a-1);
	return array;
end
local meshgrid = imP.tensor.meshgrid;
-- a=meshgrid(-1,6,1);
-- ArrayShow(a)


-- Computer the convolation of 2D array.
-- Where A is origanal array, B is the kenel.
function imP.tensor.conv2(A, B, output)
	local h = #(A);
	local w = #(A[1]);
	local hsize = #(B);
	local wsize = #(B[1])
	local d = math.floor(hsize / 2);
	local u = math.floor(wsize / 2);
	local N = output or zeros(h, w);
	local M = zeros(hsize, wsize);
	for i = 1 + d, h - d do
		for j = 1 + u, w - u do
			for p = 1, hsize do
				for q = 1, wsize do
					M[p][q] = A[i + p-d-1][j + q-u-1];
				end
			end
			N[i][j] = ArraySum(DotProduct(M, B));
		end
	end
	return N;
end
local conv2 = imP.tensor.conv2;

-- Comput 2 Dimension matrix determinant.
function imP.tensor.Det2(array)
	local D = array[1][1] * array[2][2]-array[1][2] * array[2][1];
	return D;
end
local Det2 = imP.tensor.Det2;


-- Comput 2 Dimension matrix trace.
function imP.tensor.Trace2(array)
	local T = array[1][1] + array[2][2];
	return T;
end
local Trace2 = imP.tensor.Trace2;


-- Herris Corner Detector
function imP.HarrisCD(array)
	local sig = 1;
	local wsize = 7;
	local h = #(array);
	local w = #(array[1]);
	local xx = meshgrid(-3, 3, 1);
	local yy = meshgrid(-3, 3, 0);
	local M = ArrayAddArray(DotProduct(xx, xx), DotProduct(yy, yy));
	local Gxy = zeros(wsize, wsize);
	for i = 1, wsize do
		for j = 1, wsize do
			Gxy[i][j] = math.exp(-(M[i][j] / 2 / sig^2));
		end
	end
	local Gx = DotProduct(xx, Gxy);
	local Gy = DotProduct(yy, Gxy);
	local Ix = conv2(array, Gx);
	local Iy = conv2(array, Gy);
	local Ix2 = DotProduct(Ix, Ix);
	local Iy2 = DotProduct(Iy, Iy);
	local Ixy = DotProduct(Ix, Iy);
	Ix2 = GaussianF(Ix2, 1);
	Iy2 = GaussianF(Iy2, 1);
	Ixy = GaussianF(Ixy, 1);
	local R = zeros(h, w);
	local Rmax = 0;
	local M = zeros(2, 2);
	for i = 1, h do
		for j = 1, w do
			M = {{Ix2[i][j], Ixy[i][j]}, {Ixy[i][j], Iy2[i][j]}};
			R[i][j] = Det2(M)-0.06 * Trace2(M);
			if R[i][j]>Rmax then
				Rmax = R[i][j];
			end
		end
	end
	-- local count=0;
	local result = zeros(h, w);
	for i = 1, h do
		for j = 1, w do
			if R[i][j]>0.01 * Rmax then
				result[i][j] = 1;
				-- count=count+1;
			end
		end
	end
	return result;
end
local HarrisCD = imP.HarrisCD;


--Get a column in a Matrix
function imP.tensor.GetColumn(M, column, output)
	local output = output or zeros(1, #M);
	for i = 1, #M do
		output[1][i] = M[i][column];
	end
	return output;
end
local GetColumn = imP.tensor.GetColumn;

-- Matrix multiple
--[[a={{1, 2},{4, 5}};
b={{1, 2},{1, 5}};
c=MatrixMultiple(a,b);
ArrayShow(c)]]
function imP.tensor.MatrixMultiple(M1, M2, output1, output2)
	local row1 = #M1;
	local column1 = #M1[1];
	local row2 = #M2;
	local column2 = #M2[1];
	if column1 == row2 then
		local output1 = output1 or zeros(row1, column2);
		for i = 1, row1 do
			for j = 1, column2 do	
				output1[i][j] = ArraySum(DotProduct(M1[i], GetColumn(M2, j, output2)[1]));
			end
		end
		return output1;
	end
end
local MatrixMultiple = imP.tensor.MatrixMultiple;

-- Determine of 2 or 3 dimensions Matrix
--[[
a={{1, 2},{4, 5}};
b={{1, 2, 3},{4, 5, 6},{7, 8, 9}};
print(det(a),det(b))]]
function imP.tensor.det(M)
	local row = #M;
	local column = #M[1];
	if(row == column) and(row == 2) then
		local det2 = M[1][1] * M[2][2]-M[1][2] * M[2][1];
		return det2;
	elseif(row == column) and(row == 3) then
		local det3 = (M[1][1] * M[2][2] * M[3][3] + M[1][2] * M[2][3] * M[3][1]
		+ M[1][3] * M[2][1] * M[3][2]-M[1][1] * M[2][3] * M[3][2]
		-M[1][2] * M[2][1] * M[3][3]-M[1][3] * M[2][2] * M[3][1]);
		return det3;
	end	
end
local det = imP.tensor.det;


-- The Sub Matrix which remove the i-th row and j-th column
--[[
b={{1, 2, 3},{4, 5, 6},{7, 8, 9}};
ArrayShow(b)
ArrayShow(SubMatrix(b,1,0))
ArrayShow(SubMatrix(b,2,2))]]
function imP.tensor.SubMatrix(M, i, j)
	local row = #M;
	local column = #M[1];
	local self = zeros(row, column);
	for m = 1, row do
		for n = 1, column do
			self[m][n] = M[m][n];
		end
	end
	if(i <= row) and(j <= column) and(i > 0) and(j >0 ) then
		table.remove(self, i);
		for i = 1, row-1 do
			table.remove(self[i], j);
		end
	elseif(i <= row) and(j == 0) then
		table.remove(self, i);
	elseif(i == 0) and(j <= column) then
		for i = 1, row do
			table.remove(self[i], j);
		end
	end
	return self;
end
local SubMatrix = imP.tensor.SubMatrix;


-- Inverse Matrix of 2 or 3 dimensions Matrix
--[[
a={{1, 2},{4, 5}};
b={{1, 2, 3},{4, 5, 6},{7, 8, 10}};
ArrayShow(inv(a))
ArrayShow(inv(b))]]
function imP.tensor.inv(M, invM)
	local row = #M;
	local column = #M[1];
	if(row == column) and(row == 2) then
		local inv2 = ArrayMult({{M[2][2], -M[1][2]}, {-M[2][1], M[1][1]}}, 1 / det(M));
		return inv2;
	elseif(row == column) and(row == 3) then
		local inv3 = zeros(3, 3) or invM;
		local det3 = det(M);
		for i = 1, 3 do
			for j = 1, 3 do	
				inv3[j][i] = (-1)^(i + j) * det(SubMatrix(M, i, j)) / det3;
				--print(inv3[i][j], det(SubMatrix(M,i,j)),det3)
			end
		end
		return inv3;
	end	
end
local inv = imP.tensor.inv;

function imP.tensor.bool2num( bool )
	local num;
	if bool == true then
		num = 1;
	else
		num = 0;
	end
	return num;
end
local bool2num = imP.tensor.bool2num;

--return the key of specified value
--@param value: double or integer
--@param bool: 如果bool为true，返回value索引，否则返回不等于value的索引
--@return x,y:  ...  默认返回0元素真索引
--如果tab为1维，返回的y为nil88
function imP.tensor.find(tab, value, bool)
	if value==nil then
		value = 0;
	end
	if bool==nil then
		bool = true;
	end	
	local x = {};
	local y = {};
	if bool == true then
		for k, v in pairs(tab) do 
			if type(tab[k]) == "table" then
				for j, i in pairs(tab[k]) do
					if i==value then 
						x[#x + 1] = k;
						y[#y + 1] = j;
					end
				end
			else
				if v==value then
					x[#x + 1] = k;
					y[#y + 1] = nil;
				end
			end
		end 
	else
		for k, v in pairs(tab) do 
			if type(tab[k]) == "table" then
				for j, i in pairs(tab[k]) do
					if i~=value then 
						x[#x + 1] = k;
						y[#y + 1] = j;
					end
				end
			else
				if v~=value then
					x[#x + 1] = k;
					y[#y + 1] = nil;
				end
			end
		end 
	end
	return x, y
end
local find = imP.tensor.find;

--截取vector中n到m的一部分
function imP.tensor.subvector( vector,n,m )
    if n==nil then
		n = 1;
	end	
	if m==nil then
		m = #vector;
	end	
	local subv = {};
	for i = n,m do
		subv[#subv + 1] = vector[i]; --type is table
    end
	return subv;
end
local subvector = imP.tensor.subvector;

--截取matrix中一部分
function imP.tensor.submatrix(matrix, a, b, c, d)
	local a = a or 1;
	local b = b or #matrix;
	local c = c or 1;
	local d = d or #matrix[1];
	local subm = output or zeros(b-a + 1, d-c + 1);
	for i = 1, b-a + 1 do
		for j = 1, d-c + 1 do 
			subm[i][j] = matrix[i-1 + a][j - 1 + c];
		end
	end
	return subm;
end
local submatrix = imP.tensor.submatrix;

--connect 2 vector
function imP.tensor.connect(A, B, mod)
	local row1 = #A;
	local column1 = #A[1];
	local row2 = #B;
	local column2 = #B[1];
	local mod = mod or 0
	if row1 == row2 and mod == 0 then
		local self = zeros(row1, column1 + column2);
		for j = 1, column1 + column2 do
			for i = 1, row1 do
				if j <= column1 then
					self[i][j] = A[i][j];
				elseif j > column1 then
					self[i][j] = B[i][j-column1];
				end
			end
		end
		return self;
	elseif column1 == column2 and mod == 1 then
		local self = zeros(row1 + row2, column1);
		for i = 1, row1 + row2 do
			for j = 1, column1 do
				if i <= row1 then
					self[i][j] = A[i][j];
				elseif i > row1 then
					self[i][j] = B[i-row1][j];
				end
			end
		end
		return self;
	end
end
local connect = imP.tensor.connect;

--connect 2 vector
function imP.connectAB( A,B )
	local result = {};
	for k,v in pairs(A) do
		result[#result + 1] = v;
	end
	for k,v in pairs(B) do
		result[#result + 1] = v;
	end
	return result;
end

--turn the size of A to m * n
--return type is table
function imP.tensor.reshape(A, m, n)
	local a = #A;
	local b = #A[1];
	local V = {};
	local result = {};
	if b ~= nil then --A is a matrix
		for k, v in pairs(A) do
			V = connect(V, A[k]);
		end
		if m == 1 then
			result = V;
		else
			for i = 1, m do
				result[i] = subvector(V, 1 + n *(i - 1), n * i);
			end
		end
	else --A is a vector, m usually will not be 1
		for i = 1, m do 
			result[i] = subvector(A, 1 + n *(i - 1), n * i);
		end		
	end
	return result;
end
local reshape = imP.tensor.reshape;

-- Matrix transposition
function imP.tensor.transposition(M)
	local row = #M;
	local column = #M[1];
	local self = zeros(column, row);
	for i = 1, row do
		for j = 1, column do
			self[j][i] = M[i][j];
		end
	end
	return self;
end
local transposition = imP.tensor.transposition;

function imP.tensor.norm(array)
	local self = 0;
	if type(array[1]) == "table" and #array == 1 then
		for i = 1, #array[1] do
			self = self +(array[1][i])^2;
		end
	elseif type(array[1]) == "table" and #array[1] == 1 then
		for i = 1, #array do
			self = self +(array[i][1])^2;
		end
	elseif type(array[1]) == "number" then
		for j = 1, #array do
			self = self +(array[j])^2;
		end
	end
	self = math.sqrt(self);
	return self;
end
local norm = imP.tensor.norm;

function imP.tensor.dot(array1, array2)
	local self = 0;
	if #array1 == #array2 then
		for i = 1, #array1 do
			self = self + array1[i] * array2[i];
		end
	end
	return self;
end
local dot = imP.tensor.dot;

function imP.tensor.mod(number1, number2)
	local self = math.mod(number1, number2);
	if self < 0 then
		self = self + number2;
	end
	return self;
end
local mod = imP.tensor.mod;

--get gradient gx and gy of matrix m
function imP.tensor.gradient(m)
	local rows = #m;
	local cols = #m[1];
	local gx = zeros(rows, cols);
	local gy = zeros(rows, cols);
	for i = 1, rows do 
		gy[i][1] = m[i][2]-m[i][1]
		gy[i][cols] = m[i][cols]-m[i][cols-1]
		for j = 2, cols-1 do
			gy[i][j] = 0.5 * (m[i][j + 1]-m[i][j-1])
		end
	end
	for j = 1, cols do 
		gx[1][j] = m[2][j]-m[1][j]
		gx[rows][j] = m[rows][j]-m[rows-1][j]
		for i = 2, rows-1 do
			gx[i][j] = 0.5 * (m[i + 1][j]-m[i-1][j])
		end
	end
	return gx, gy
end
local gradient = imP.tensor.gradient;

function imP.tensor.Spline(w, a)
	local S;
	local n = -0.5 or a;
	local num = math.abs(w);
	if num < 1 then
		S = 1 -(n + 3) * num^2 +(n + 2) * num^3;
	elseif num >=1 and num <=2 then
		S = -4 * n + 8 * n * num - 5 * n * num^2 - n * num^3;
	else
		S = 0
	end
	return S;
end
local Spline = imP.tensor.Spline;

--@Para: resize an image by bicubic method
function imP.tensor.imresize(Image, outputsize)
	local rows = #Image;
	local cols = #Image[1];
	local outputRows = math.floor(rows * outputsize + 0.5);
	local outputCols = math.floor(cols * outputsize + 0.5);
	local self = zeros(outputRows, outputCols);
	local rowNew, colNew, u, v, m, n;
	local A, B, C;
	local output1 = zeros(1, 4);
	local output2 = zeros(1, 1);
	local output3 = zeros(1, 4);
	local output4 = zeros(1, 4);

	-- Extend the image
	local Image0 = zeros(rows + 6, cols + 6);
	for i = 4, rows + 3 do	
		Image0[i][1] = Image[i-3][1];
		Image0[i][2] = Image[i-3][2];
		Image0[i][3] = Image[i-3][3];
		Image0[i][cols + 4] = Image[i-3][cols-2];
		Image0[i][cols + 5] = Image[i-3][cols-1];
		Image0[i][cols + 6] = Image[i-3][cols];
		for j = 4, cols + 3 do
			Image0[i][j] = Image[i-3][j-3];
		end
	end
	for i = 4, cols + 3 do
		Image0[1][i] = Image[1][i-3];
		Image0[2][i] = Image[2][i-3];
		Image0[3][i] = Image[3][i-3];
		Image0[rows + 4][i] = Image[rows-2][i-3];
		Image0[rows + 5][i] = Image[rows-1][i-3];
		Image0[rows + 6][i] = Image[rows][i-3];
	end
	for i = 1, 3 do
		for j = 1, 3 do
			Image0[i][j] = Image[i][j];
			Image0[rows + 3 + i][j] = Image[rows + i - 3][j];
			Image0[i][cols + 3 + j] = Image[i][cols + j - 3];
			Image0[rows + 3 + i][cols + 3 + j] = Image[rows + i - 3][cols + j-3];
		end
	end


	for i = 1, outputRows do
		for j = 1, outputCols do
			rowNew = i * rows / outputRows;
			colNew = j * cols / outputCols;
			
			m = math.floor(rowNew) + 3;
			n = math.floor(colNew) + 3;
			if m >= 2 and m <= rows + 6 and n >= 3 and n <= cols + 7 then
--				u = rowNew - m + 2;
--				v = colNew - n + 2;
				--A = {{Spline(1+u), Spline(u), Spline(1-u), Spline(2-u)}};
				A = {{1, 1, 1, 8}};
				B = {{Image0[m-1][n-2], Image0[m][n-2], Image0[m + 1][n-2], Image0[m + 2][n-2]},
				{Image0[m-1][n-1], Image0[m][n-1], Image0[m + 1][n-1], Image0[m + 2][n-1]},
				{Image0[m-1][n], Image0[m][n], Image0[m + 1][n], Image0[m + 2][n]},
				{Image0[m-1][n + 1], Image0[m][n + 1], Image0[m + 1][n + 1], Image0[m + 2][n + 1]}}
				--C = {{Spline(1+v)}, {Spline(v)}, {Spline(1-v)}, {Spline(2-v)}};
				C = {{1}, {1}, {1}, {8}};
				local f = MatrixMultiple(MatrixMultiple(A, B, output1, output3), C, output2, output4);
				self[i][j] = f[1][1];
			end
		end
	end
	local ImageMax = FindMax2(Image);
	local ImageMin = FindMin2(Image);
	local SelfMax = FindMax2(self);
	local SelfMin = FindMin2(self);
	self = ArrayMult(self,(ImageMax - ImageMin) / (SelfMax - SelfMin));
	self = ArrayAdd(self, ImageMax - FindMax2(self));
	self = Round(self);
	return self;
end
local imresize = imP.tensor.imresize;

function imP.tensor.mean(array)
	local self;
	if type(array[1]) == "number" then
		self = ArraySum(array) / #array;
	elseif type(array[1]) == "table" and type(array[1][1]) == "number" then
		self = {};
		for i = 1, #array do
			self[i] = ArraySum({array[i]}) / #array[i];
		end
	else 
		LOG.std(nil, "warn", "imP", "imP.tensor.mean: unexpected array type")
	end
	return self;
end
local mean = imP.tensor.mean;

function imP.tensor.diag(array)
	if type(array) == "table" and type(array[1]) == "number" then
		local self = zeros(#array, #array);
		for i = 1, #array do
			self[i][i] = array[i];
		end
		return self;
	elseif type(array) == "table" and type(array[1]) == "table" then
		local self = {};
		for i = 1, math.min(#array, #array[1]) do
			self[i] = array[i][i];
		end
		return self;
	else
		LOG.std(nil, "warn", "imP", "imP.tensor.diag: unexpected array type");
	end
end
local diag = imP.tensor.diag;

--Creat a unit Matrix which size is n
function imP.tensor.eye(n, output)
	local output = output or zeros(n, n);
	for i = 1, n do
		output[i][i] = 1;
	end
	return output;
end
local eye = imP.tensor.eye;

--sign function
function imP.tensor.sign(x)
	if x > 0 then
		return 1;
	elseif x < 0 then
		return -1;
	else
		return 0;
	end
end
local sign = imP.tensor.sign;

--Upper triangular part of matrix
function imP.tensor.triu(Array, n, output)
	local n = n or 0;
	local output = output or zeros(#Array, #Array[1]);
	local count = 1 + n;
	local t;
	for i = 1, #Array do
		if count >= 1 then
			t = count;
		else
			t = 1;
		end
		for j = t, #Array[1] do
			output[i][j] = Array[i][j];
		end
		count = count + 1;
	end
	return output;
end
local triu = imP.tensor.triu;
