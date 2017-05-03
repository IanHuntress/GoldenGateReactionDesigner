function [ Stringout ] = Capitalize( Stringin )
% This function takes in a string, and returns that same string with every
% individual letter capitalized. It only capitalizes A's, T's, C's, and G's
% as these represent the biological nucleotides. 

% This function is called within Experimental_Driver_Jan2017.

[rows, columns] = size(Stringin);
Stringout = char(zeros(rows,columns));

for i = 1:rows
    for j = 1:columns
        if Stringin(i,j) == 'a'
            Stringout(i,j) = 'A';
        elseif Stringin(i,j) == 't'
            Stringout(i,j) = 'T';
        elseif Stringin(i,j) == 'c'
            Stringout(i,j) = 'C';
        elseif Stringin(i,j) == 'g'
            Stringout(i,j) = 'G';
        else
            Stringout(i,j) = Stringin(i,j);
        end
    end


end

