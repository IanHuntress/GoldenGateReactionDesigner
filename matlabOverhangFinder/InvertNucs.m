function [ OutputSeq ] = InvertNucs( InputSeq )
% This function takes in a sequence of nucleotides, and returns a sequence
% of equal length, with the nucleotides inverted.
% A<-->T and C<-->G.

% This function is called within Experimental_Driver_Jan2017.

[rows, columns] = size(InputSeq);

OutputSeq = zeros(rows,columns);

if InputSeq/InputSeq(1,1) == ones(rows,columns);
    OutputSeq = InputSeq;
    return
else
end

for i = 1:rows
    for j = 1:columns
        if InputSeq(i,j) == 'A'       %Replace A with T
            OutputSeq(i,j) = 'T';
        elseif InputSeq(i,j) == 'T'   %Replace T with A
            OutputSeq(i,j) = 'A';
        elseif InputSeq(i,j) == 'C'   %Replace C with G
            OutputSeq(i,j) = 'G';
        elseif InputSeq(i,j) == 'G'   %Replace G with C
            OutputSeq(i,j) = 'C';
        else
            OutputSeq(i,j) = InputSeq(i,j); %Don't change if not ATCG
        end
    end
end

OutputSeq = char(OutputSeq);

end

