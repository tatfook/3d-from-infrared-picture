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


