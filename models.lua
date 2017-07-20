
models = {};

--return the key of specified value
--如果bool为true，返回value索引，否则返回不等于value的索引
--默认返回0元素索引
function models.find(tab,value,bool)
    if value==nil then
		value = 0;
	end
    if bool==nil then
		bool = true;
	end	
	local keys = {};
	if bool == true then
		for k,v in pairs(tab) do 
			if v==value then 
			table.insert(keys,k)
		    end
		end 
	else
		for k,v in pairs(tab) do 
			if v~=value then 
			table.insert(keys,k)
		    end
		end 
	end
	return keys
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
	for i = n,m do
		subv[#subv + 1] = vector[i];
	end
	return subv;
end

--
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

