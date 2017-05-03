function [ Loc2 ] = Loc2ComplementLoc( Compilspecoverhanginfo, Loc1, Repeatlength )

[rows, ~] = size(Compilspecoverhanginfo);

for i = 1:rows
    if Compilspecoverhanginfo(i) == Loc1 && Loc1 > Repeatlength
        Loc2 = 2*Repeatlength - Loc1 - 2;
    elseif Compilspecoverhanginfo(i) == Loc1 && Loc1 < Repeatlength
        Loc2 = 2*Repeatlength - Loc1 - 2;
    else
        
    end
    
end

end

