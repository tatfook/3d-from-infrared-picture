--[[
Title: Singular value decomposition
Author(s): BerryZSZ
Date: 2017/8/17
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/PlaneDetection/SVD.lua");
------------------------------------------------------------
------------------------------------------------------------
local QRDecompositionSch = SVD.QRDecompositionSch;
local QRDecompositionHouse = SVD.QRDecompositionHouse;
local DO_SVD = SVD.DO_SVD;
------------------------------------------------------------
]]
NPL.load("(gl)Mod/PlaneDetection/imP.lua");

local SVD = commonlib.gettable("SVD");

------------------------------------------------------------
local zeros = imP.tensor.zeros;
local norm = imP.tensor.norm;
local transposition = imP.tensor.transposition;
local MatrixMultiple = imP.tensor.MatrixMultiple;
local ArraySum = imP.tensor.ArraySum;
local DotProduct = imP.tensor.DotProduct;
local eye = imP.tensor.eye;
local sign = imP.tensor.sign;
local submatrix = imP.tensor.submatrix;
local ArrayMult = imP.tensor.ArrayMult;
local ArrayAddArray = imP.tensor.ArrayAddArray;
local triu = imP.tensor.triu;
local diag = imP.tensor.diag;
local FindMax2 = imP.tensor.FindMax2;

------------------------------------------------------------
--@para: QR decomposition algorithm by Gram-Schmidt method
function SVD.QRDecompositionSch(A)
	local row = #A;
	local col = #A[1];
	if row > col then
		for i = 1, row do
			for j = col + 1, row do
				A[i][j] = 0;
			end
		end
		m = #A;
		n = #A[1];
	elseif col > row then
		for i = row + 1, col do
			A[i] = {};
			for j = 1, col do
				A[i][j] = 0;
			end
		end
		m = #A;
		n = #A[1];
	end
	local Q = zeros(m, n);
	local R = zeros(n, n);
	local Qk = {};
	local transA = zeros(n, m);
	for k = 1, n do
		transA = transposition(A);
		R[k][k] = norm(transA[k]);
		if R[k][k] ~= 0 then
			for i = 1, m do
				Q[i][k] = A[i][k] / R[k][k];
				Qk[i] = Q[i][k];
			end
			for j = k + 1, n do
				R[k][j] = ArraySum(DotProduct(Qk, transA[j]));
				for i = 1, m do 
					A[i][j] = A[i][j] - R[k][j] * Q[i][k];
				end
			end
		end
	end
	Q = submatrix(Q, 1, row, 1, row);
	R = submatrix(R, 1, row, 1, col);
	return Q, R;
end
local QRDecompositionSch = SVD.QRDecompositionSch;

--@para: QR decomposition algorithm by Householder method
function SVD.QRDecompositionHouse(A, input)
	local row = #A;
	local col = #A[1];
	local m, n;
	if row > col then
		for i = 1, row do
			for j = col + 1, row do
				A[i][j] = 0;
			end
		end
		m = #A;
		n = #A[1];
	elseif col > row then
		for i = row + 1, col do
			A[i] = {};
			for j = 1, col do
				A[i][j] = 0;
			end
		end
		m = #A;
		n = #A[1];
	else
		m = row;
		n = col;
	end
	local E = eye(n);
	local R = input or zeros(n, n);
	local P1 = eye(n);
	local s, w, P;
	for k = 1, n-1 do 
		s = -sign(A[k][k]) * norm(submatrix(A, k, n, k, k));
		R[k][k] = -s;
		if k == 1 then
			w = transposition(submatrix(A, 2, n, k, k));
			table.insert(w[1], 1, A[1][1] + s);
		else
			w = transposition(submatrix(A, k + 1, n, k, k));
			table.insert(w[1], 1, A[k][k] + s);
			for i = 1, k-1 do
				table.insert(w[1], 1, 0);
				R[i][k] = A[i][k]
			end
		end
		if norm(w) ~= 0 then
			w = ArrayMult(w, 1 / norm(w));
		end
		P = ArrayAddArray(E, ArrayMult(MatrixMultiple(transposition(w), w), -2));
		A = MatrixMultiple(P, A);
		P1 = MatrixMultiple(P, P1);
		for j = 1, n do
			R[j][n] = A[j][n];
		end
	end
	Q = transposition(P1);
	Q = submatrix(Q, 1, row, 1, row);
	R = submatrix(R, 1, row, 1, col);
	return Q, R;
end
local QRDecompositionHouse = SVD.QRDecompositionHouse;

function SVD.DO_SVD(A)
	local loopmax = math.max(#A, #A[1]);
	local loopcount = 0;
	local U = eye(#A);
	local S = transposition(A);
	local V = eye(#A[1]);
	local Q, e, E, F;
	local input_QR = zeros(loopmax, loopmax);
	local input_U = zeros(#U, loopmax);
	local input_S = zeros(1, loopmax);
	local input_V = zeros(#V, loopmax);
	while loopcount < loopmax do
		Q, S = QRDecompositionHouse(transposition(S), input_QR);
		U = MatrixMultiple(U, Q);
		Q, S = QRDecompositionHouse(transposition(S), input_QR);
		V = MatrixMultiple(V, Q);
		e = triu(A);
		E = math.sqrt(ArraySum(DotProduct(e, e)));
		F = math.sqrt(ArraySum(DotProduct(diag(S), diag(S))));
		if F == 0 then
			F = 1;
		end
		loopcount = loopcount + 1;
	end
	local ss = diag(S);
	local ssn;
	S = zeros(#A, #A[1]);
	for n = 1, #ss do
		ssn = ss[n];
		S[n][n] = math.abs(ssn);
		if ssn < 0 then
			for i = 1, #A do
				U[i][n] = -U[i][n];
			end
		end
	end
	return U, S, V,E,e;
end
local DO_SVD = SVD.DO_SVD;

