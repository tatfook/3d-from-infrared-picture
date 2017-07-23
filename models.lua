
models = {};

--return size of 1D or 2D array 
function models.ArraySize( arr )
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
local ArraySize = models.ArraySize;

--return the key of specified value
--如果bool为true，返回value索引，否则返回不等于value的索引
--默认返回0元素真索引
--如果tab为1维，返回的y为nil88
function models.find(tab,value,bool)
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


-- 1th difference
function models.diff( vector )
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

--截取vector中n到m的一部分
function models.subvector( vector,n,m )
    if n==nil then
		n = 1;
	end	
	if m==nil then
		m = #vector;
	end	
	local subv = {};
	if n ~= m then
		for i = n,m do
			subv[#subv + 1] = vector[i]; --type is table
	    end
	else
		subv = vector[m];  --type is number
	end
	return subv;
end

--截取matrix中一部分
function models.submatrix( matrix,a,b,c,d )
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

--connect 2 vector
function models.connect( A,B )
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
function models.reshape( A, m,n )
	local a, b = models.ArraySize(A);
	local V = {};
	local result = {};
	if b ~= nil then --A is a matrix
		for k,v in pairs(A) do
			V = models.connect(V,A[k]);
		end
		if m == 1 then
			result = V;
		else
		for i = 1,m do
			result[i] = models.subvector(V,1+n*(i-1),n*i);
		end
	    end
	else --A is a vector, m usually will not be 1
		for i = 1,m do 
			result[i] = models.subvector(A,1+n*(i-1),n*i);
		end		
	end
	return result;
end

function models.bool2num( bool )
	local num;
	if bool == true then
		num = 1;
	else
		num = 0;
	end
	return num;
end



function models.ArrayAdd(array, n)
	-- Array addes number.
	local h = #array;
	local w = #array[1];
	local array_o = models.zeros(h, w);
	for i = 1, h do
		for j = 1, w do
			array_o[i][j] = array[i][j] + n;
		end
	end
	return array_o;
end

function models.ArraySum(array)
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

function models.DotProduct(array1, array2)
	-- Array dot product.
	local h = table.getn(array1);
	local w = table.getn(array1[1]);
	local array = zeros(h, w);
	for i = 1, h do
		for j = 1, w do
			array[i][j] = array1[i][j] * array2[i][j];
		end
	end
	return array;
end

--Read the image and creat the Grey image.
function models.imread2Grey(filename)
	local file = ParaIO.open(filename, "image");
	if(file:IsValid()) then
		local ver = file:ReadInt();
		local width = file:ReadInt();
		local height = file:ReadInt();
		-- how many bytes per pixel, usually 1, 3 or 4
		local bytesPerPixel = file:ReadInt();
		-- echo({ver, width = width, height = height, bytesPerPixel = bytesPerPixel})
		local pixel = {};
		local array = zeros(height, width);
		for j = 1, height do
			for i = 1, width do
				pixel = file:ReadBytes(bytesPerPixel, pixel);
				array[j][i] = pixel[1];
				for h = 2, bytesPerPixel do				    
					array[j][i] = array[j][i] + pixel[h];
				end
				array[j][i] = Round(array[j][i] / bytesPerPixel);
				--echo({i, j,array[j][i]});
			end
		end
		return array;
	else
		print("The file is not valid");
	end
end

--
function models.zeros(height, width)
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

function models.Array2Max(array)
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
