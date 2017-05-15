%% Quentin Leitz
% Koffas Lab Research
% Updated January 21, 2017
% CRISPR Planner Driving File
% Accompanying Excel Workbook_BACKUP.xlsx
function output = DesignReactionFromSpreadsheet(workbook)
close all
%clear
clc
%workbook = 'Accompanying Excel Workbook_BACKUP.xlsx';

%% Read Inputs from Accompanying Excel Workbook
tic %Begin timer.

[Parameters,~,~] = xlsread(workbook,'Example','H5:I26');
%Read in parameters and strings from the Excel sheet.

[~, Repeatdropoutrepeat, ~] = xlsread(workbook,'Example','D5:I5')
Repeatdropoutrepeat = Capitalize(char(Repeatdropoutrepeat)); %<Repeat>[Dropout]<Repeat>
% Repeattocheck = Capitalize(char(Strings(3,5)));%Repeat region specified by the user - test this for validity.
[~,Repeattocheck,~] = xlsread(workbook,'Example','H7:I7');
Repeattocheck = Capitalize(char(Repeattocheck));
% Repeattocheck = xlsread(workbook,'Example','H7');%Repeat region specified by the user - test this for validity.
% Repeattocheck = Capitalize(char(Strings(3,1)));%Repeat region specified by the user - test this for validity.
Spacernum = Parameters(1); %A                  %Desired number of spacers in the final array.
Overhangsize = 4;                              %Bp for the desired overhang size.
Spacerlength = Parameters(3); %C               %Bp for the desired spacers.
Repeatlength = length(Repeattocheck);          %Length of the repeat region. 
Minmismatchnum = Parameters(4); %C.2           %Acceptable number of mismatches. 2 by default, 1 is another option.
Overhangnum = (2*Spacernum)+2;                 %Number of overhangs to be defined.
% Desiredenz = char(xlsread(workbook,'Example','H14')); %D           % for specifying the assembly enzyme.
[~,Desiredenz,~] = xlsread(workbook,'Example','H14:I14');
Desiredenz = Capitalize(char(Desiredenz));% Desiredenz = char(Strings(10,1)); %D           %Binary for specifying the assembly enzyme.
Desiredseq_bin = Parameters(8); %E             %Binary for specifying sequence of CRISPR spacers, in order.
Desiredspacerorder_bin = Parameters(11); %F    %Binary for specifying multiple spacer options for each array location.
Orderoligos = Parameters(15); %G               %Binary for specifying whether to order oligos or primers.
Naming_bin = Parameters(18); %H                %Binary for specifying the prefix of names in the output.

Repeatstring = Repeatdropoutrepeat(1:Repeatlength); %5'->3' repeat region sequence. 
Dropoutlength = length(Repeatdropoutrepeat)-2*Repeatlength; %Length of dropout sequence.
Dropoutseq = Repeatdropoutrepeat(Repeatlength+1:Repeatlength+Dropoutlength); %Dropout sequence.

Reversedropoutseq = InvertNucs(Dropoutseq); %Create reverse sequence.
%% Test Parameters for Validity
if isempty(Repeatstring) || isnan(Spacernum) || isnan(Overhangsize) || isnan(Spacerlength) ...
        || isnan(Desiredseq_bin) || isnan(Desiredspacerorder_bin) || isempty(Desiredenz) ...
        || isnan(Orderoligos) || isnan(Naming_bin)

    %If the user hasn't provided any of the critical parameters in Inputs.
    fprintf('ERROR: You have not provided sufficient parameters in the Inputs section.\n');
    return
else
end

if strcmp(Repeattocheck, Repeatstring)
else
    fprintf('ERROR: The natural repeat sequence provided does not match those within <Repeat>[Spacer]<Repeat>.\n');
    fprintf('Make sure that the base pairs flanking the dropout sequence have not been altered from their natural state.\n');
    return
end

if Desiredseq_bin == 1 && Desiredspacerorder_bin == 1 %Make sure E and F are not both selected.
    fprintf('ERROR: You may not set both E and F equal to 1 at the same time. They are mutually exclusive options.\n');
    return
else
end

if Desiredseq_bin == 1 %(D) If we are trying to specify the insert sequences, in order.
    [~,Spacerseq,~] = xlsread(workbook,'Example','E32:E47'); %Read in insert sequences.
    Spacerseq = Capitalize(char(Spacerseq));         %Convert to char.
    [rows, columns] = size(Spacerseq);
    if rows ~= Spacernum %If the user specified too many/too few spacer sequences.
        fprintf('ERROR: The number of spacers specified in A must match the number of spacer sequences provided.\n');
        return
    else
    end
    
    for i = 1:rows %If the user's spacer sequences are the wrong length.
        TestChar = char(cellstr(Spacerseq(i,:)));
        if length(Spacerseq(i,:)) ~= Spacerlength || length(TestChar) ~= Spacerlength
            fprintf('ERROR: The length of spacers specified in C must match the length of spacer sequences provided.\n');
            return
        else
        end
    end
else

end

if Desiredspacerorder_bin == 1 %(E) If the user wants multiple spacer options for each location
    [~,Spaceroptionseq,~] = xlsread(workbook,'Example','E52:T67'); %Read in spacer options
    [rows, columns] = size(Spaceroptionseq);
    if columns < Spacernum %If the user didn't provide enough spacer options
        fprintf('ERROR: There must be the same number of spacer options as specified in A\n');
        return
    elseif columns > Spacernum %If the user provided too many spacer options, trim to the first ones)
        Spaceroptionseq = Spaceroptionseq(:,1:Spacernum);
    end
    
    Spaceroptioncount = zeros(1,Spacernum); %Counts how many options for each spacer location
    
    for i = 1:Spacernum %Step through spacer locations A,B,C...
        for j = 1:rows %Step through options for each location 1,2,3...
            charSpaceroptionseq = char(Spaceroptionseq(j,i));
            if length(charSpaceroptionseq) ~= Spacerlength %Test that the spacer options are the correct length
                if j == 1 %If there is a bad spacer
                    fprintf('ERROR: There must be at least one spacer specified for each option.\n');
                    fprintf('Make sure your spacer options start at row 1 (Excel row 15) and proceed downwards.\n');
                    fprintf('Make sure your spacers are the length specified in C.\n');
                    return
                else
                    fprintf('ERROR: Make sure that your spacers are the length specified in C.\n');
                    return
                end
                
            else
                Spaceroptioncount(i) = Spaceroptioncount(i) + 1;
            end
            
        end
    end
    
else
    
end

%Test the validity of the specified assembly enzyme.
if strcmp(Desiredenz,'BsaI') 
    Enzymename = 'BsaI';
    Enzymepull = 1;
    Enzseq = '5''-GGCCGGTCTC';
    Enzseqmatch = Enzseq(end-5:end);
elseif strcmp(Desiredenz, 'BsmBI');
    Enzymename = 'BsmBI';
    Enzymepull = 1;
    Enzseq = '5''-GGCCCGTCTC';
    Enzseqmatch = Enzseq(end-5:end);
elseif strcmp(Desiredenz, 'BbsI');
    Enzymename = 'BbsI';
    Enzymepull = 2;
    Enzseq = '5''-GGCCGAAGAC';
    Enzseqmatch = Enzseq(end-5:end);    
else
    fprintf('ERROR: The specified enzyme is not recognized by this script.\n');
    fprintf('Supported enzymes are BsaI, BsmBI, and BbsI.\n');
    return
end
Enzymetocheck = InvertNucs(Enzseq(end-5:end)); %3'->5' sequences for the specified assembly enzyme
fprintf('The enzyme selected for the assembly is:  %s.\n', Enzymename);

%Check validity of the dropout cut sites.
Dropoutcutlocs = [0 0]; %Initialize Dropoutcutlocs.
%If we're specifying the dropout sequence and the assembly enzyme, define Dropoutcutlocs.
for j = 1:length(Dropoutseq)-5
    if Enzseqmatch == Dropoutseq(j:j+5);
        %5'->3' case passed, store location.
        Dropoutcutlocs(2) = j;
    elseif InvertNucs(fliplr(Enzseqmatch)) == Dropoutseq(j:j+5);
        %3'->5' case passed, store location.
        Dropoutcutlocs(1) = j+5;
    else
    end
end

if  strcmp(Enzymename, 'BsaI')
    Dropoutcutlocs(1) = Dropoutcutlocs(1)-7;
    Dropoutcutlocs(2) = Dropoutcutlocs(2)+7;
elseif  strcmp(Enzymename, 'BsmBI')
    Dropoutcutlocs(1) = Dropoutcutlocs(1)-7;
    Dropoutcutlocs(2) = Dropoutcutlocs(2)+7;    
elseif  strcmp(Enzymename, 'BbsI')
    Dropoutcutlocs(1) = Dropoutcutlocs(1)-8;
    Dropoutcutlocs(2) = Dropoutcutlocs(2)+8;
end

% Check dropoutcutlocs for validity. 
if Dropoutcutlocs(1) > 0 || Dropoutcutlocs(2) <= length(Dropoutseq)
    fprintf('ERROR: The dropout cut locations specified are outside of their possible bounds.\n');
    fprintf('Make sure that your dropout cut site choices do not leave dropout behind.\n');
    return
else
end

if Orderoligos == 1 %If the user wants to order primers, read in primer overlap length.
    %If they don't want to order primers, then just use the default value.
    %(8) for coloring purposes in the Procedure sections.
    Primeroverlap = 8; %Bp into the desired spacer our primers should overlap (Default value).
else
    Primeroverlap = xlsread(workbook,'Example','J69');
    if rem(Primeroverlap,1) == 0 && Primeroverlap > 0
    else
        fprintf('ERROR: The degree of primer overlap must be a positive integer (1,2,3...)\n');
        fprintf('We recommend using the default value of 8 base pairs\n');
        return
    end
end

if Naming_bin == 1 %If the user wants to specify a naming prefix for the outputs.
    [~,Prefix,~] = xlsread(workbook,'Example','J71'); %Read in oligo/PCR product prefix.
    Prefix = [char(Prefix) '_'];
else
    Prefix = 'X_'; %If no naming prefix specified, use the generic option.
end

%% Check for Enzyme Sequences in the Repeats, the Spacers, and the Interfaces
[rows, columns] = size(Enzymetocheck);

if Desiredspacerorder_bin == 1 %F == 1, many possible CRISPRSystems - test one at a time.
    for i = 1:length(Spaceroptioncount) %Step through spacer locations
        for j = 1:Spaceroptioncount(i) %Step through options for that spacer location
            %For each option, build <Repeat>[Spacer]<Repeat> and check that for validity
            CRISPRSystem = [Repeatstring Capitalize(char(Spaceroptionseq(j,i))) Repeatstring];
            for z = 1:length(CRISPRSystem)-columns+1 %Step through CRISPRSystem 1bp at a time
                if CRISPRSystem(z:z+columns-1) == Enzymetocheck %If the area of CRISPRSystem matches our current enzyme
                    cprintf('Text', CRISPRSystem(1:z-1));
                    cprintf('[1,0,0]', Enzymetocheck);
                    cprintf('Text', CRISPRSystem(z+length(Enzymetocheck):end)); fprintf('\n');
                    cprintf('Text', char(zeros(1,z-1)));
                    cprintf('[1,0,0]', '%s', '******'); fprintf('\n');
                    
                    fprintf('ERROR: There is a problem with the assembly enzyme choice. Enzyme will cut incorrectly.\n');
                    fprintf('This is caused by an enzyme cut site within the <Repeat>[Spacer]<Repeat>.\n');
                    if z < Repeatlength
                        fprintf('ERROR: The problem is with the repeat region.\n');
                    else
                        fprintf('ERROR: The problem is with spacer option %d in location %d.\n', j, i);
                    end
                    fprintf('ERROR: The problem is located at base pair: %d of this section in the CRISPR system.\n', z);
                    fprintf('The problem is with the enzyme: %s or %s\n\n', Enzymetocheck, Enzymename);
                    return
                else
                end
            end
        end
    end
else %E == 1 or (F == 2 && E == 2), only one possible CRISPRSystem
    CRISPRSystem = Repeatstring;
    if Desiredseq_bin == 2 %(E == 2) If we're using generic spacers, just scan repeat region for issues.
        for z = 1:length(CRISPRSystem)-columns+1 %Step through CRISPRSystem 1bp at a time
            if CRISPRSystem(z:z+columns-1) == Enzymetocheck %If the area of CRISPRSystem matches our current enzyme
                cprintf('Text', CRISPRSystem(1:z-1));
                cprintf('[1,0,0]', Enzymetocheck);
                cprintf('Text', CRISPRSystem(z+length(Enzymetocheck):end)); fprintf('\n');
                cprintf('Text', char(zeros(1,z-1)));
                cprintf('[1,0,0]', '%s', '******'); fprintf('\n');
                
                fprintf('ERROR: There is a problem with the assembly enzyme choice. Enzyme will cut incorrectly.\n');
                fprintf('This is caused by an enzyme cut site within the <Repeat>[Spacer]<Repeat>.\n');
                fprintf('The problem is with the repeat region.\n');
                fprintf('The problem is located at base pair: %d of the repeat.\n', z);
                fprintf('ERROR: The problem is with the enzyme: %s or %s\n\n', Enzymetocheck, Enzymename);
                return
            else
            end
        end
    else %(E == 1) We're specifying the spacers, but only one spacer per location.
        CRISPRSystem = Repeatstring;
        for i = 1:Spacernum
            CRISPRSystem = [Repeatstring Spacerseq(i,:) Repeatstring];
            for z = 1:length(CRISPRSystem)-columns+1 %Step through CRISPRSystem 1bp at a time
                if CRISPRSystem(z:z+columns-1) == Enzymetocheck %If the area of CRISPRSystem matches our current enzyme
                    cprintf('Text', CRISPRSystem(1:z-1));
                    cprintf('[1,0,0]', Enzymetocheck);
                    cprintf('Text', CRISPRSystem(z+length(Enzymetocheck):end)); fprintf('\n');
                    cprintf('Text', char(zeros(1,z-1)));
                    cprintf('[1,0,0]', '%s', '******'); fprintf('\n');
                    
                    fprintf('ERROR: There is a problem with the assembly enzyme choice. Enzyme will cut incorrectly.\n');
                    fprintf('This is caused by an enzyme cut site within the <Repeat>[Spacer]<Repeat>.\n');
                    if z < Repeatlength
                        fprintf('ERROR: The problem is with the repeat region.\n');
                    else
                        fprintf('ERROR: The problem is with spacer option %d.\n', i);
                    end
                    fprintf('ERROR: The problem is located at base pair: %d of this section in the CRISPR system.\n', z);
                    fprintf('The problem is with the enzyme: %s or %s\n\n', Enzymetocheck, Enzymename);
                    return
                else
                end
            end
        end
    end
end

%% Create the Reverse String
Repeatstringrev = InvertNucs(Repeatstring); %Complement for the repeat region.

fprintf('The repeat looks like: \n');          %Print 5'->3' and 3'->5'.
disp([Repeatstring;Repeatstringrev]);

Repeatstringrev = fliplr(Repeatstringrev);  %Flip RepeatStringRev for proper readibility.

%% Define Palindromic Sequences to Avoid
[Position, Length, Pal] = palindromes(Repeatstring,'Length',Overhangsize,'Complement', true);
count = 1;
%Searches through the repeatstring and finds all palindromic sequences.
%These sequences are the same in the reverse string, so two overhangs
%should be discarded for each palindromic sequence found here.

for i = 1:length(Position)
    if Length(i) == Overhangsize            %Note that Length here is not the length() command. 

        Palindromestorage(count) = Pal(i);      %Stores palindromic sequences.
        count = count+1;

    else
        
    end
end

if exist('Palindromestorage', 'var')
    %If we have a palindrome storage vector, we caught some palindromes.
    Palindromestorage = char(Palindromestorage); %Converts to char for printing.
    [Palrows,~] = size(Palindromestorage);
    
    fprintf('\nOverhangs removed due to palindromes: %d\n', 2*Palrows); %Print result.
    disp(Palindromestorage);
else %If we don't, print that we did not find any palindromes.
    Palrows = 0;
    fprintf('\nOverhangs removed due to palindromes: %d\n',Palrows);
    
end


%% Step Through and Record all Potential Overhang Choices
Overhangstorage = zeros(2*(Repeatlength-Overhangsize+1),Overhangsize);
Overhangdesc = zeros(2*(Repeatlength-Overhangsize+1),2);
Loc = 1;
Palfailed = 0;
Palfailcounter = 0;

for i = 1:2 %i=1: 5'->3'; i=2: 3'->5'
    for j = 1:Repeatlength-Overhangsize+1
        if Palrows ~= 0
            for k = 1:Palrows       %Test whether overhang equals any of our palindromes.
                if i == 1
                    if Repeatstring(j:j+Overhangsize-1) == Palindromestorage(k,:)
                        Palfailed = 1;  %If it does, Failed = 1 and don't add to storage.
                    else
                    end
                else
                    if Repeatstringrev(j:j+Overhangsize-1) == Palindromestorage(k,:)
                        Palfailed = 1;  %If it does, Failed = 1 and don't add to storage.
                    else
                    end
                end
            end
        else
        end
        
        if Palfailed == 1;      %Track number of palindromic overhangs caught.
            Palfailcounter = Palfailcounter+1;
        else
        end
        
        if i == 1 && Palfailed == 0; %5'->3' and not a palindrome.
            Overhangdesc(Loc,1) = i; %Whether we're 5'->3' or 3'-> 5'.
            Overhangdesc(Loc,2) = j; %Start location in the repeat.
            Overhangstorage(Loc,1:Overhangsize) = Repeatstring(j:j+Overhangsize-1); %Overhang BPs.
            Loc = Loc+1;             %Step forward with the counter variable.
            
        elseif i == 2 && Palfailed == 0; %3'->5' and not a palindrome.
            Overhangdesc(Loc,1) = i; %Whether we're 5'->3' or 3'-> 5'.
            Overhangdesc(Loc,2) = j+Repeatlength; %Start location in the repeat.
            Overhangstorage(Loc,1:Overhangsize) = fliplr(Repeatstringrev(j:j+Overhangsize-1)); %Overhang BPs.
            Loc = Loc+1;             %Step forward with the counter variable.
            
        else
        end
        
        Palfailed = 0; %Reset palindrome fail variable for next overhang.
        %To test if all palindromes were caught, ensure that
        %Palfailcounter = 2*Palrows.
    end
    
end

[rows, ~] = size(Overhangstorage);

%Trim Overhangstorage to remove rows initialized but never filled
%due to palindromic sequences.
Overhangstorage = Overhangstorage(1:rows-Palfailcounter,:);
Overhangdesc = Overhangdesc(1:rows-Palfailcounter,:);

Overhangstorage = char(Overhangstorage); %Convert to character array.

%% Catalog Overhangs Already Specified by the Dropout Insert/Repeat Region
Backboneoverhanglocs = [Repeatlength-abs(Dropoutcutlocs(1))-Overhangsize+1 Repeatlength-abs(Dropoutcutlocs(1)); ...
    Dropoutcutlocs(2)-Dropoutlength Dropoutcutlocs(2)-Dropoutlength+Overhangsize-1];
    %Within <Repeat1>[Spacer]<Repeat2>, Backboneoverhanglocs row 1 specifies the
    %boundary locations of the overhang in Repeat1. Row 2 specifies the
    %boundary locations of the overhang in Repeat2.
    
Backboneoverhangs = [InvertNucs(Repeatstring(Backboneoverhanglocs(1,1):Backboneoverhanglocs(1,2))) ; ...
    Repeatstring(Backboneoverhanglocs(2,1):Backboneoverhanglocs(2,2))];
    %Stores the actual sequence of the overhangs specified by the backbone.
    
Specifiedoverhangs = [Backboneoverhangs ; InvertNucs(Backboneoverhangs)];
    %Stores both the Backboneoverhangs and their complements.

Specifiedoverhanginfo = [Repeatlength+Enzymepull ; Backboneoverhanglocs(2,1) ; ...
    Backboneoverhanglocs(1,1) ; Repeatlength+Backboneoverhanglocs(1,1)];
    %Store the locations of those backbone overhangs
    
[rows, ~] = size(Specifiedoverhangs);
Numspecoverhangs = rows;

%% Perform Deterministic Walk to Find an Acceptable Solution
Progress = 0;                               %The number of choices we have made.
Progresstarget = Spacernum-1;               %Target number of choices to make for Progress.

Choiceinfomid1 = (1+Repeatlength)/2;        %Middle of repeat bp in the 5'->3' direction.
Choiceinfomid2 = (3*Repeatlength+2)/2;      %Middle of repeat bp in the 3'->5' direction.

Compilspecoverhangs = Specifiedoverhangs;       %Initial compiled specified overhangs equals those set by the backbone.
Compilnumspecoverhangs = Numspecoverhangs;      %Initial number of specified overhangs equals number specified by the backbone.
Compilspecoverhanginfo = Specifiedoverhanginfo; %Initial compiled locations are those specified by the backbone.

badchoice = false;                          %Whether or not we have made a bad choice on this while loop.
badchoicecount = 1;                         %How many bad choices we have made.
badchoicedetails = -1;                      %Stores our degree of Progress when we realize our choice was bad.

Failed = 0;                                 %Whether or not we failed (ran out of options to test). This breaks while loop.

[rowsOverhangstorage,~] = size(Overhangstorage); %Store size of overhangstorage for looping.

while length(Compilspecoverhangs) < Overhangnum
    %Loop until we have the final number of overhangs required.
    clear Potentialchoice Choiceinfo Choicemismatchinfo     %Clear these vectors which are built on each iteration.
    clear Consolpotentialchoice Consolchoiceinfo Consolchoicemismatchinfo
    Mismatchvec = zeros(Compilnumspecoverhangs,1);  %Initialize mismatchvec size based on # of specified overhangs.
    
    if badchoice == true %If we went down a path that ran out of options.
        Progress = 0;                               %Reset progress.
        Compilspecoverhangs = Specifiedoverhangs;   %Reset specified overhangs.
        Compilnumspecoverhangs = Numspecoverhangs;  %Reset number of specified overhangs.
        Compilspecoverhanginfo = Specifiedoverhanginfo; %Reset locations of specified overhangs.
        clear Choicestorage                         %Reset previous choices.
        clear Choiceinfostorage                     %Reset previous choice locations.
        
        badchoice = false;                          %Reset badchoice binary.
        
    else
    end
    
    Loc = 1;
    %Set location counter, which is used to specify the storage of
    %potential overhang choices and their information.
    
    for i = 1:rowsOverhangstorage   %Scan through all overhangs.
        
        for j = 1:Compilnumspecoverhangs      %Compare overhang to specified overhangs.
            Mismatchvec(j) = sum(Overhangstorage(i,:) ~= Compilspecoverhangs(j,:));
            %Count the number of mismatches between the overhang being
            %tested and each of the already specified overhangs.
            
        end
        
        Triedandfailed = false;
        
        if exist('Choicestorage', 'var') %If this not our first choice
            for j = 1:length(badchoicedetails) %Scan through previous bad choices
                if badchoicedetails(j) == Progress+1 ...
                        && all(all((badchoicestorage(1:Progress,4*j-3:4*j) == Choicestorage) == 1)) ...
                        && all((badchoicestorage(Progress+1,4*j-3:4*j) == Overhangstorage(i,:)) == 1)
                    %Conditions:
                    %1. If we have failed at i before and are searching for i.
                    %2. If our choices to this point have been the same as
                    %       those where we failed.
                    %3. If the overhang we're considering is the same as the
                    %       one we have previously chosen and failed with.
                    Triedandfailed = true;
                    
                else
                end
            end
            
        else %If this is our first choice (Can't use Choicestorage in if statement below).
            for j = 1:length(badchoicedetails) %Scan through previous bad choices.
                if badchoicedetails(j) == Progress+1 ...
                        && all((badchoicestorage(Progress+1,4*j-3:4*j) == Overhangstorage(i,:)) == 1)
                    %Conditions:
                    %1. If we have failed at i before and are searching for i
                    %2. If the overhang we're considering is the same as the
                    %       one we have previously chosen and failed with.
                    Triedandfailed = true;
                    
                else
                end
            end
        end
        
        if any(Mismatchvec <= Minmismatchnum-1) || Triedandfailed == true
            %Conditions:
            %1. When there is 1 or less mismatch, that means 3-4 bps are
            %   the same between the selected overhang and overhangs
            %   already specified. Too similar.
            %2. Trash options we have already tried and failed with.
            
            %If this is the case, Potentialchoice is never created and the
            %next if statement fails. This triggers badchoice protocol.
            
            
        else %Store options which are at least 2 bp different.
            Potentialchoice(Loc,1:Overhangsize) = Overhangstorage(i,:);
            %Store overhang info.
            Choiceinfo(Loc,1) = Overhangdesc(i,2);          %Store choice location index.
            Choicemismatchinfo(Loc,1) = sum(Mismatchvec);   %Store mismatch information.
            Loc = Loc+1; %Counter for building choice vectors.
            
        end
        Mismatchvec = zeros(length(Compilspecoverhangs),1); %Reset mismatchvec.
        
    end
    
    if exist('Potentialchoice', 'var')
        %If we have at least one potential choice.
        [rows, ~] = size(Potentialchoice);    %Check size of potential choice vector.
        if rows >= Progresstarget-Progress
            %If there are more potential choices than the number of
            %decisions we have left to make, this path could be viable.
            Sufficientsolutions = true;
            
        else    %If there are not enough potential choices, we failed.
            Sufficientsolutions = false;
        end
    else        %If there are no potential choices, we failed.
        Sufficientsolutions = false;
    end
    
    if exist('Potentialchoice', 'var') && Sufficientsolutions == true
        %Conditions:
        %1. Make sure we found a solution, at least one solution.
        %2. Ensure we have enough choices available to possibly succeed
        %   along this path.
        [rows, ~] = size(Choicemismatchinfo);
        maxmismatch = max(Choicemismatchinfo);
        %The potential choice with the fewest matches to already specified
        %overhangs.
        Loc = 1;
        
        for i = 1:rows %Consolidate potential choices based on max mismatch #.
            if Choicemismatchinfo(i) >= maxmismatch-2
                %Consolidate based on proximity to overhang with the
                %highest degree of mismatch.
                Consolpotentialchoice(Loc,1:Overhangsize) = Potentialchoice(i,:);   %Overhang.
                Consolchoiceinfo(Loc,1) = Choiceinfo(i);                 %Location index.
                Consolchoicemismatchinfo(Loc,1) = Choicemismatchinfo(i); %Mismatch info.
                Loc = Loc+1;
                
            else
            end
        end
        
        %Choose from the consolidated choices the one which is closest to
        %the center of the repeat region.
        Degreeofmid = abs([(Consolchoiceinfo - Choiceinfomid1) ...
            (Consolchoiceinfo - Choiceinfomid2)]);
        [value, loc] = min([Degreeofmid ;[1000 1000]]); %Choose value which is closest to the middle by row.
        [value2, loc2] = min(min([Degreeofmid ; [1000 1000]])); %Value closest to the middle by column.
        
        %Store choice, add to specified overhangs, repeat.
        Choicestorage(Progress+1,1:Overhangsize) = Consolpotentialchoice(loc(loc2),:); %Store overhang choices.
        Choiceinfostorage(Progress+1,1) = Consolchoiceinfo(loc(loc2),1);               %Store overhang choice locations.
        Choicemismatchstorage(Progress+1,1) = Consolchoicemismatchinfo(loc(loc2),1);   %Store degree of mismatch for choices.
        Compilspecoverhangs = [Compilspecoverhangs ; Choicestorage(Progress+1,:) ; ... %Add choices to compiled specified overhangs.
            InvertNucs(Choicestorage(Progress+1,:))];
        Compilspecoverhanginfo = [Compilspecoverhanginfo ; Choiceinfostorage(Progress+1,1) ... %Add overhang choice location info to compiled.
            ; (2*Repeatlength - Choiceinfostorage(Progress+1,1) - 2)];
        
        [rows, ~] = size(Compilspecoverhangs);
        Compilnumspecoverhangs = rows;
        Progress = Progress+1;
        
    else                        %What to do if we found no solution.
        if Progress ~= 0        %If this is not our first choice.
            badchoice = true;   %Set badchoice to true -> next while loop resets everything.
            
            if badchoicecount == 1 %If this is the first badchoice we've made.
                badchoicestorage(1:Progress,1:Overhangsize) = Choicestorage(:,:);
                
            else %If this is not the first badchoice we've made, tack onto the end.
                badchoicestorage(1:Progress,end+1:end+Overhangsize) = Choicestorage(:,:);
                %Store the path to ensure we don't take it again.
                
            end
            badchoicedetails(1,badchoicecount) = Progress;
            badchoicecount = badchoicecount+1;
            
        else
            %Handles case where we run out of options for choice 1 and must
            %terminate without returning a solution.
            Failed = 1;
            break
            
        end
        
    end
    
    if toc > 20 %If we haven't found a solution in 20 seconds, we are unlikely to find one. Terminate.
        fprintf('\nThe solver could not find a solution in the given time frame.\n');
        fprintf('ERROR: Try reducing the number of spacers required in the final array.\n');
        return
    else
    end  
    
end

%% Display Overhang Selection
if Failed == 1          %If we reached no solution
    fprintf('\n ERROR: A solution could not be determined with the parameters given.\n');
    return
    
else                    %If we reached a solution
    fprintf('\nSpecified overhangs: %d\n',length(Compilspecoverhangs));
    disp(Compilspecoverhangs)
%     fprintf('\nOverhang choices: %d\n', length(Choicestorage));
%     disp(char(Choicestorage));
end

%% Perform Comparisons Between all Overhang Choices and Create Match Index
% [rows, ~] = size(Choicestorage);
% 
% Comparisonstorage = zeros(rows,4*rows);
% Matchindexstorage = zeros(rows,rows);
% Loc = 1;
% 
% for i = 1:rows %Building rows of Comparison matrix
%     Comparisontarget = Choicestorage(i,1:Overhangsize);
%     
%     for j = Loc:rows %Building columns of Comparison matrix
%         Compareresult = Comparisontarget == Choicestorage(j,1:Overhangsize);
%         Matchindexstorage(j,i) = sum(Compareresult);
%         
%     end
%     
%     Loc = Loc+1;
% end
% 
% f = figure('units','normalized','position',[.05 0.05 0.9 0.8]);
% t = uitable(f, 'Data', Matchindexstorage, 'ColumnName', Choicestorage, 'RowName', Choicestorage, 'Position', [20 20 1800 680]);
% 
% fprintf('\nMatrix of overhang match indices (0 -> perfect mismatch; 4 -> perfect match):\n');
% disp(Matchindexstorage);

%% Make Choices about the Order of Overhangs in the Final Assembly
% clearvars -except Choicestorage Choiceinfostorage Backboneoverhangs Repeatstring ...
%     Repeatstringrev Overhangsize Spacernum Repeatlength Matchindexstorage ...
%     Compilspecoverhangs Overhangstorage Backboneoverhanginfo Spacerlength ...
%     Compilspecoverhanginfo Overhangnum Desiredseq_bin Desiredenz ...
%     Desireddumseq_bin Desiredseqs Primeroverlap Orderoligos Dropoutseq ...
%     Reversedropoutseq Spacerseq Spaceroptionseq Desiredspacerorder_bin ...
%     Spaceroptioncount Enzseq Prefix Enzymestocheck Dropoutcutlocs ...
%     Repeatdropoutrepeat Dropoutlength Backboneoverhanglocs Enzymename ...
%     Enzymepull Specifiedoverhangs
%Clear all of the temporary junk.

[rowsspecoverhangs, ~] = size(Compilspecoverhangs);
Potentialsegmentlength = zeros(rowsspecoverhangs,1);
Progress = 0;
Overhangorder = char(zeros(1,Overhangsize));
Overhanglocation = 0;
Segmentlength = 0;

while Progress < Overhangnum - 4
    
    Potentialsegmentlength = zeros(rowsspecoverhangs,1);
    
    for i = 5:rowsspecoverhangs
        if any(Overhanglocation == Compilspecoverhanginfo(i))
            %Test whether we have used this overhang before. If yes, do not
            %consider it and move on to the next overhang choice.
            
        else
            if Progress == 0 %We are on the first spacer
                if Compilspecoverhanginfo(i) > Repeatlength
                    %We are on the reverse string going 3'->5'
                    Potentialsegmentlength(i) = Repeatlength - Backboneoverhanglocs(1,1) + ...
                        1 + Spacerlength + 2*Repeatlength - Compilspecoverhanginfo(i) + 1;
                    
                else    %We are on the forward string going 5'->3'
                    Potentialsegmentlength(i) = 0;
                    %Set in excess; can't use a 5'->3' overhang for this
                    %choice.
                    
                end
                
            elseif Progress > 0 && Progress < Overhangnum - 6  %We are on a middle spacer
                if Compilspecoverhanginfo(i) > Repeatlength ...
                        %We are on the reverse string going 3'->5'
                    Potentialsegmentlength(i) = Repeatlength - Overhanglocation(Progress+1) ...
                        + 1 + Spacerlength + 2*Repeatlength - Compilspecoverhanginfo(i) + 1;
                    
                else    %We are on the forward string going 5'->3'
                    Potentialsegmentlength(i) = 0;
                    
                end
                
            else %We are on the final spacer.
                if Compilspecoverhanginfo(i) > Repeatlength ...
                        %We are on the reverse string going 3'->5'
                    Potentialsegmentlength(i) = Repeatlength - Overhanglocation(Progress+1) ...
                        + 1 + Spacerlength + Backboneoverhanglocs(2,2);
                    
                else    %We are on the forward string going 5'->3'
                    Potentialsegmentlength(i) = 0;
                    
                end
                
            end
        end
        
    end

    %Select the choice which results in the segment length closest to but
    %under 60bp.
    [maxlength,maxloc] = max(Potentialsegmentlength);
    
    if maxlength > 60
        if any((0 < Potentialsegmentlength).*(Potentialsegmentlength < 60))
            %Check if there are any nonzero segment lengths less than 60.
            for i = 1:length(Potentialsegmentlength)
                if Potentialsegmentlength(i) >= 60 %Replace above 60 with 0
                    Potentialsegmentlength(i) = 0;
                else
                end
                
            end
            
            %Choose the segment which is closest to but less than 60.
            [minlength, minloc] = min(60 - Potentialsegmentlength);
            Overhangorder = [Overhangorder ; Compilspecoverhangs(minloc,:) ; ...
                InvertNucs(Compilspecoverhangs(minloc,:))];
            
            Overhanglocation = [Overhanglocation ; Compilspecoverhanginfo(minloc,:) ; ...
                Loc2ComplementLoc(Compilspecoverhanginfo, Compilspecoverhanginfo(minloc,:), Repeatlength)];
            
            Segmentlength = [Segmentlength ; Potentialsegmentlength(minloc)];
            
        else
            %If the max length is greater than 60 and there are no
            %potential segments available that are less than 60, choose the
            %largest length segment available (going to have to PCR it).
            Overhangorder = [Overhangorder ; Compilspecoverhangs(maxloc,:) ; ...
                InvertNucs(Compilspecoverhangs(maxloc,:))];
            
            Overhanglocation = [Overhanglocation ; Compilspecoverhanginfo(maxloc) ; ...
                Loc2ComplementLoc(Compilspecoverhanginfo, Compilspecoverhanginfo(maxloc), Repeatlength)];
            
            Segmentlength = [Segmentlength ; Potentialsegmentlength(maxloc)];
            
        end
        
    else
        %If maxlength is less than or equal to 60, Illumina seq. will work
        %with high fidelity. Use the overhang choice resulting in a seq.
        %length closest to 60bp.
        Overhangorder = [Overhangorder ; Compilspecoverhangs(maxloc,:) ; ...
            InvertNucs(Compilspecoverhangs(maxloc,:))];
        
        Overhanglocation = [Overhanglocation ; Compilspecoverhanginfo(maxloc) ; ...
            Loc2ComplementLoc(Compilspecoverhanginfo, Compilspecoverhanginfo(maxloc), Repeatlength)];
        
        Segmentlength = [Segmentlength ; Potentialsegmentlength(maxloc)];
        
    end
    
    Progress = Progress + 2;
    
end

Overhangorder = [Compilspecoverhangs(3,:); Overhangorder(2:end,:) ; Compilspecoverhangs(4,:)]; %Trim storage matrices of initial 0's
Overhanglocation = [Compilspecoverhanginfo(3) ; Overhanglocation(2:end,:) ; Compilspecoverhanginfo(4)];
Segmentlength = Segmentlength(2:end,1);

fprintf('Overhang order:\n');
disp(Overhangorder);

%% Print the Assembly with Instructions
Repeatstringrev = fliplr(Repeatstringrev);
Enzseqlength = length(Enzseq);
Reverseenzseq = [fliplr(Enzseq(1,4:end)) '-5'''];

Colorvec = {'[0.96 0.24 0.02]' '[0.98 0.71 0.08]' '[0.35 0.91 0.07]' ...
    '[0.08 0.38 0.1]' '[0.07 0.58 0.88]' '[0.09 0.41 0.4]'  ...
    '[0.09 0.09 0.87]' '[0.36 0.1 0.89]' '[0.68 0.13 0.87]' '[0.97 0.22 0.56]'...
    '[0.5 1 1]' '[0.25 0 0]' '[0.5 0 0.5]' '[0.25 0.5 0.5]' ...
    '[0.55 0.58 0.14]' '[1 0.5 0.5]'};
%Vector with various color options.
Colorveccounter = 1; %Counter for cycling through Colorvec.

for i = 1:length(Overhanglocation)
    if Overhanglocation(i) > Repeatlength
        Overhanglocation(i) = Loc2ComplementLoc(Compilspecoverhanginfo, ...
            Overhanglocation(i), Repeatlength);
    else
    end
    
end

%Print the starting form of the DNA
fprintf('\nDNA Prior to any cutting:\n');
cprintf('Text', Repeatstring);
cprintf('Strings',Dropoutseq);
cprintf('Text', Repeatstring);
fprintf('\n');

cprintf('Text', Repeatstringrev);
cprintf('Strings', Reversedropoutseq);
cprintf('Text', Repeatstringrev);

%Print the DNA after cutting out the dropout
fprintf('\n\nDNA backbone after cutting out the dropout:\n');
cprintf('Text', [Repeatstring(1:Backboneoverhanglocs(1,1)-1) char(zeros(1, length(Backboneoverhanglocs(1,1):Repeatlength)))]);
cprintf('Text', char(zeros(1,Dropoutlength+Backboneoverhanglocs(2,1)-1)));
cprintf(Colorvec{1+Spacernum}, [Repeatstring(Backboneoverhanglocs(2,1):Backboneoverhanglocs(2,2)) ' ']); fprintf('\b');
cprintf('Text', Repeatstring(Backboneoverhanglocs(2,2)+1:Repeatlength));

fprintf('\n');
cprintf('Text', Repeatstringrev(1:Backboneoverhanglocs(1,1)-1));
cprintf(Colorvec{1}, [Repeatstringrev(Backboneoverhanglocs(1,1):Backboneoverhanglocs(1,2)) ' ']); fprintf('\b');
cprintf('Text', [char(zeros(1,length(Backboneoverhanglocs(1,2):Repeatlength)-1)) '  ']); fprintf('\b\b');
cprintf('Text', char(zeros(1,Dropoutlength+length(Repeatstringrev(1:Backboneoverhanglocs(2,2))))));
cprintf('Text', Repeatstringrev(Backboneoverhanglocs(2,2)+1:Repeatlength));
fprintf('\n\n');

cprintf('Text', '%s', char(8722*ones(1,2*Repeatlength+Spacerlength)));
fprintf('\n');

% Initialize parameters for printing out each successive spacer procedure.
Progress = 0;
Seqnum = 0;
Loc = 1;
Storagecounter = 1;
Oligolengthstorage = zeros(Spacernum*2,1);

if Desiredseq_bin == 1
    Spaceroption = '%s';
else
    Spaceroption = '%d';
end

while Progress < Spacernum
    fprintf('Procedure for Spacer:  %d\n',Progress+1);
    fprintf('Primer Orientation:\n');
    Pushforward = false;
    Degreeofpush1 = 0;
    
    if Desiredseq_bin == 1 %If spacer sequences have been specified.
        Spacerseqcurrent = Spacerseq(Progress+1,:);       
    else %If spacer sequences have not been specified, use generic.
        Spacerseqcurrent = (Seqnum+1)*ones(1,Spacerlength);   
    end
    
    %Primer overlap
    if Overhanglocation(Loc)-Enzseqlength-Enzymepull-1 > 0 %Have to push forward the primer.
        cprintf('Text', char(zeros(1,Overhanglocation(Loc)-Enzseqlength-Enzymepull-1)));
        cprintf('[1,0,0]', Enzseq);
        fprintf('\n');
        
    else %Have to push forward everything else
        Pushforward = true;
        if Overhanglocation(Loc)-Enzseqlength-Enzymepull-1 < 0 %If we need to make room for more than 3
            %Degreeofpush1 is the amount to push the lines 2 and 3 in the
            %procedure. This is the forward and reverse string before the primers do anything.
            Degreeofpush1 = abs(Overhanglocation(Loc)-(Enzseqlength+Enzymepull))+1;    
            
            %Degreeofpush2 is the amount to push lines 6 and 7 in the
            %procedure. This is the forward and reverse string of the PCR product.
%             Degreeofpush2 = abs(Overhanglocation(Loc)-(Enzseqlength+Enzymepull))+1;
            Degreeofpush2 = 3;            
        else %If we only need to push to make room for "5'-", Degreeofpush2 = 3.
            Degreeofpush1 = 0;
            Degreeofpush2 = 0;
        end
        cprintf('[1,0,0]', Enzseq);
        fprintf('\n');
    end
    
    %Forward string
    if Pushforward == true
        cprintf('Text', char(zeros(1,Degreeofpush1)));
    else
    end
    
    if Orderoligos == 1 %Store oligos for printing later
        Vec2store = [Repeatstring(Overhanglocation(Loc): ...
            Overhanglocation(Loc)+Overhangsize-1) ...
            Repeatstring(Overhanglocation(Loc)+Overhangsize:Repeatlength) ...
            num2str(Spacerseqcurrent,'%u') Repeatstring(1:Overhanglocation(Loc+1)-1)];
        Oligostorage(Storagecounter,1:length(Vec2store)) = Vec2store;
        Oligolengthstorage(Storagecounter) = length(Vec2store);
        Oligospacerstorage(Storagecounter) = length(Repeatstring(Overhanglocation(Loc):...
            Overhanglocation(Loc)+Overhangsize-1)) + ...
            length(Repeatstring(Overhanglocation(Loc)+Overhangsize:Repeatlength)) + 1;
        Storagecounter = Storagecounter+1;
        
    else %Store primers for printing later
        Vec2store = [Enzseq ...
            Repeatstring(Overhanglocation(Loc)-Enzymepull:Repeatlength)...
            num2str(Spacerseqcurrent(1,1:Primeroverlap),'%u')];
        Primerstorage(Storagecounter,1:length(Vec2store)) = Vec2store;
        Primerspacerstorage(Storagecounter) = Enzseqlength + ...
            length(Repeatstring(Overhanglocation(Loc)-Enzymepull:Repeatlength)) + 1;
        Storagecounter = Storagecounter+1;
        
    end
    
    cprintf('Text', Repeatstring(1:Overhanglocation(Loc)-Enzymepull-1));
    cprintf('[1,0,0]', Repeatstring(Overhanglocation(Loc)-Enzymepull:Repeatlength));
    
    cprintf('[1,0,0]', Spaceroption, Spacerseqcurrent(1,1:Primeroverlap)); 
    cprintf('Strings', Spaceroption, Spacerseqcurrent(1,Primeroverlap+1:Spacerlength));
    
    cprintf('Text', Repeatstring);
    fprintf('\n');
    Loc = Loc+1;
    
    %Reverse string
    if Pushforward == true
        cprintf('Text', char(zeros(1,Degreeofpush1)));
    else
    end
    
    if Orderoligos == 1 %Store the oligos for printing later
        Vec2store = [Repeatstringrev(Overhanglocation(Loc-1)+Overhangsize:Repeatlength) ...
            num2str(InvertNucs(Spacerseqcurrent),'%u') Repeatstringrev(1:Overhanglocation(Loc)-1) ...
            Repeatstringrev(Overhanglocation(Loc): ...
            Overhanglocation(Loc)+Overhangsize-1)];
        Oligostorage(Storagecounter,1:length(Vec2store)) = Vec2store;
        Oligolengthstorage(Storagecounter) = length(Vec2store);
        Oligospacerstorage(Storagecounter) = length(Repeatstringrev(Overhanglocation(Loc-1) ...
            +Overhangsize:Repeatlength)) + 1;
        Storagecounter = Storagecounter+1;
        
    else %Store the Primers for printing later
        Vec2store = [num2str(InvertNucs(Spacerseqcurrent(1,end-Primeroverlap+1:end)),'%u') Repeatstringrev(1:Overhanglocation(Loc)+Overhangsize+Enzymepull-1) ...
            Reverseenzseq(1:end-3) '-''5'];
        
        Primerstorage(Storagecounter,1:length(Vec2store)) = fliplr(Vec2store);
        Primerspacerstorage(Storagecounter) = length(Reverseenzseq) + ...
            length(Repeatstringrev(1:Overhanglocation(Loc)+Overhangsize+Enzymepull-1)) + 1;
        Storagecounter = Storagecounter+1;
        
    end
    
    cprintf('Text', Repeatstringrev);
    
    cprintf('Strings', Spaceroption, InvertNucs(Spacerseqcurrent(1,1:Spacerlength-Primeroverlap)));
    cprintf('[1,0,0]', Spaceroption, InvertNucs(Spacerseqcurrent(1,Spacerlength-Primeroverlap+1:Spacerlength)));
    
    cprintf('[1,0,0]', Repeatstringrev(1:Overhanglocation(Loc)+Overhangsize+Enzymepull-1));
    cprintf('Text', Repeatstringrev(Overhanglocation(Loc)+Overhangsize+Enzymepull:Repeatlength));
    fprintf('\n');
    
    %Reverse primer
    if Pushforward == true
        cprintf('Text', char(zeros(1,Degreeofpush1+Repeatlength+Spacerlength+...
            Overhanglocation(Loc)+Overhangsize+Enzymepull-1)));
    else
        cprintf('Text', char(zeros(1,Repeatlength+Spacerlength+...
            Overhanglocation(Loc)+Overhangsize+Enzymepull-1)));
    end
    cprintf('[1,0,0]', Reverseenzseq);
    fprintf('\n\n');
    
    Loc = Loc-1;

    %PCR Product Forward string
    fprintf('PCR Amplicon:\n');    
    if Pushforward == true
        cprintf('Text', char(zeros(1,Degreeofpush2)));
    else
    end
    cprintf('Text', '%s', char(zeros(1,Overhanglocation(Loc)-Enzseqlength-Enzymepull+2)));
    cprintf('Text',Enzseq(4:7));
    cprintf('[1,0,0]',Enzseq(end-5:end));
    cprintf('Text', Repeatstring(Overhanglocation(Loc)-Enzymepull:Repeatlength)); 
    cprintf('Strings', Spaceroption, Spacerseqcurrent); 
    cprintf('Text', Repeatstring(1:Overhanglocation(Loc+1)+Overhangsize+Enzymepull-1));
    cprintf('Text', InvertNucs(Reverseenzseq(1:end-3))); 
    fprintf('\n');
    Loc = Loc+1;
    
    %PCR product reverse string
    if Pushforward == true
        cprintf('Text', char(zeros(1,Degreeofpush2)));
    else
    end
    cprintf('Text', '%s', char(zeros(1,Overhanglocation(Loc-1)-Enzseqlength-Enzymepull+2)));
    cprintf('Text', InvertNucs(Enzseq(4:end)));
    cprintf('Text', Repeatstringrev(Overhanglocation(Loc-1)-Enzymepull:Repeatlength));
    cprintf('Strings', Spaceroption, InvertNucs(Spacerseqcurrent));
    cprintf('Text', Repeatstringrev(1:Overhanglocation(Loc)+Overhangsize+Enzymepull-1));
    cprintf('[1,0,0]', Reverseenzseq(1:6));
    cprintf('Text', Reverseenzseq(7:end-3));
    fprintf('\n\n');
    Loc = Loc-1;
    
    %Enzyme-digested forward string
    fprintf('Digested Amplicon:\n')    
    if Pushforward == true
        cprintf('Text', '%s', char(zeros(1,Degreeofpush1+Overhanglocation(Loc)-1)));
    else
        cprintf('Text', '%s', char(zeros(1,Overhanglocation(Loc)-1)));
    end
    cprintf(Colorvec{Colorveccounter}, [Repeatstring(Overhanglocation(Loc): ...
        Overhanglocation(Loc)+Overhangsize-1) ' ']); fprintf('\b');
    cprintf('Text', [Repeatstring(Overhanglocation(Loc)+Overhangsize:Repeatlength) '  ']); fprintf('\b\b'); 
    cprintf('Strings', Spaceroption, Spacerseqcurrent);
    cprintf('Text', [Repeatstring(1:Overhanglocation(Loc+1)-1) ' ']); fprintf('\b');
    fprintf('\n');
    Colorveccounter = Colorveccounter+1;
    Loc = Loc+1;
    
    %Enzyme-digested reverse string
    if Pushforward == true
        cprintf('Text', '%s', char(zeros(1,Degreeofpush1+Overhanglocation(Loc-1)+Overhangsize-1)));
    else
        cprintf('Text', '%s', char(zeros(1,Overhanglocation(Loc-1)+Overhangsize-1)));
    end
    cprintf('Text', Repeatstringrev(Overhanglocation(Loc-1)+Overhangsize:Repeatlength));
    cprintf('Strings', Spaceroption, InvertNucs(Spacerseqcurrent));
    cprintf('Text', [Repeatstringrev(1:Overhanglocation(Loc)-1) ' ']); fprintf('\b');
    cprintf(Colorvec{Colorveccounter}, [Repeatstringrev(Overhanglocation(Loc): ...
        Overhanglocation(Loc)+Overhangsize-1) ' ']); fprintf('\b');
    fprintf('\n\n');
    Loc = Loc+1;
    
    %Add lines
    Sequencesize = Overhanglocation(Loc-1)+Spacerlength+Repeatlength-Overhanglocation(Loc-2);
    fprintf('Sequence size:  %d\n', Sequencesize);
    
    cprintf('Text', '%s', char(8722*ones(1,2*Repeatlength+Spacerlength)));
    fprintf('\n');
    
    Seqnum = Seqnum + 1;
    
    if Seqnum >= 9
        Seqnum = -1;
    else
    end
    
    Progress = Progress + 1;
    
end

%% Display the Final Results
if Orderoligos == 1 %If the user wants to order oligos
    fprintf('The oligos to order are:  \n');
    [rows, ~] = size(Oligostorage);
    Spacercount = 1;
    Abovecutoff = false;
    
    for i = 1:rows
        if mod(i,2) == 0 %If we are on an even number row (AKA reverse direction)
            fprintf('Spacer %d, Reverse:  ', floor(Spacercount));
            fprintf('5''-');
            cprintf('[0.98 0.71 0.08]', '%s', fliplr(Oligostorage(i,Oligolengthstorage(i)-Overhangsize+1:Oligolengthstorage(i))));
            cprintf('Text', '%s', [fliplr(Oligostorage(i,Oligospacerstorage(i)+Spacerlength:Oligolengthstorage(i)-Overhangsize)) ' ']); fprintf('\b');
            cprintf('Strings', '%s', fliplr(Oligostorage(i,Oligospacerstorage(i):Oligospacerstorage(i)+Spacerlength-1)));     
            cprintf('Text', '%s', [fliplr(Oligostorage(i,1:Oligospacerstorage(i)-1)) ' ']); fprintf('\b');          

            if Oligolengthstorage(i) > 60
                cprintf('[1,0,0]', '%s', ' *');
                Abovecutoff = true;
            else
            end
            
        else %If we are on an odd number row (AKA forward direction)
            fprintf('Spacer %d, Forward:  ', floor(Spacercount));
            fprintf('5''-');
            cprintf('[0.98 0.71 0.08]', '%s', [Oligostorage(i,1:Overhangsize) ' ']); fprintf('\b'); 
            
            if Overhangsize+1 == Oligospacerstorage(i)
            else
                cprintf('Text', '%s', [Oligostorage(i,Overhangsize+1:Oligospacerstorage(i)-1) ' ']); fprintf('\b');
     
            end
            cprintf('Strings', '%s', [Oligostorage(i,Oligospacerstorage(i):Oligospacerstorage(i)+Spacerlength-1) ' ']); fprintf('\b');
            cprintf('Text', '%s', [Oligostorage(i,Oligospacerstorage(i)+Spacerlength:end) ' ']); fprintf('\b');
            if Oligolengthstorage(i) > 60
                cprintf('[1,0,0]', '%s', [char(zeros(1,Overhangsize)) ' *']);
                Abovecutoff = true;
            else
            end
        end
        
        fprintf('\n');
        Spacercount = Spacercount+0.5;
        
    end
    
    if Abovecutoff == true;
        cprintf('[1,0,0]', '%s', 'WARNING, * Indicates that the specified oligo is larger than 60 bp. Mutations are likely.');
        fprintf('\n\n');
    else
        fprintf('\n');
    end
    
else %If the user wants to order primers
    fprintf('The primers to order are:  \n');
    [rows, ~] = size(Primerstorage);
    Spacercount = 1;
    
    for i = 1:rows
        if mod(i,2) == 0 %If we are on an even number row
            fprintf('Spacer %d, Reverse:  ', floor(Spacercount));
        else %If we are on an odd number row
            fprintf('Spacer %d, Forward:  ', floor(Spacercount));
        end
        Spacercount = Spacercount+0.5;
        
        cprintf('[1,0,0]', '%s', Primerstorage(i,1:Enzseqlength));
        cprintf('Text', '%s', Primerstorage(i,14:Primerspacerstorage(i)-1));
        cprintf('Strings','%s', Primerstorage(i,Primerspacerstorage(i):Primerspacerstorage(i)+Primeroverlap-1));
        fprintf('\n');
        
    end
    cprintf('Text', '%s', char(8722*ones(1,2*Repeatlength+Spacerlength)));
    
%% Describe Oligos for Single-Spacer Arrays
    fprintf('\nThe primers described require you to have already created minimal, single-spacer arrays.\n');
    fprintf('The oligos needed in order to create those single-spacer arrays are shown below.\n');
    fprintf('Duplicated single-spacer arrays are not shown multiple times. They only appear once.\n\n');
    
    if Desiredspacerorder_bin == 1
        Spacernumcurrent = sum(Spaceroptioncount);
        %Have to build a single vector of the spacers
        Spacervec = char(ones(1,Spacerlength));
        for i = 1:Spacernum
            for j = 1:Spaceroptioncount(i)
                Spacervec(end+1,:) = Capitalize(char(Spaceroptionseq(j,i)));
            end
        end
        Spacervec = Spacervec(2:end,:);
    else
        Spacernumcurrent = Spacernum;
    end
   
    count = 1;
    numthatfailed = 0;
    for i = 1:Spacernumcurrent
        
        if Desiredseq_bin == 1 %If spacer sequences have been specified.
            Spacerseqcurrent = Spacerseq(i,:);
        elseif Desiredspacerorder_bin == 1 %If many options for each spacer location, step through the grid.
            Spacerseqcurrent = Spacervec(i,:);
        else %If spacer sequences have not been specified, use generic.    
            Spacerseqcurrent = char(48*ones(1,Repeatlength)+i);
        end
        
        arrayvec1 = [Repeatstring(Backboneoverhanglocs(1,1):end) Spacerseqcurrent Repeatstring(1:Backboneoverhanglocs(2,1)-1)];
        arrayvec2 = fliplr([Repeatstringrev(Backboneoverhanglocs(1,2)+1:Repeatlength) InvertNucs(Spacerseqcurrent) Repeatstringrev(1:Backboneoverhanglocs(2,2))]);
        
        Alreadyprinted = false;
        count = count+1;        
        
        if count > 2
            for j = 1:2:count-2-numthatfailed
                if [arrayvec1 ; arrayvec2] == arrayvecstorage(j:j+1,:)
                    %We already have this oligo set printed, don't print or save it again.
                    Alreadyprinted = true;
                else                     
                    
                end
                
            end
        else
        end
        
        if Alreadyprinted == false
            arrayvecstorage(count-1-numthatfailed:count-numthatfailed,1:length(arrayvec1)) = [arrayvec1 ; arrayvec2];
            fprintf('Single-spacer array #%d oligos:\n',i);
            fprintf('5''-');
            cprintf('Text','%s', arrayvecstorage(count-1-numthatfailed,1:length(arrayvec1))); fprintf('\n');
            
            fprintf('5''-');
            cprintf('Text','%s', arrayvecstorage(count-numthatfailed,1:length(arrayvec1))); fprintf('\n\n');
            
        else
            fprintf('Single-spacer array #%d was a duplicate and is not shown.\n\n',i);
            numthatfailed = numthatfailed+2;
        end
        count = count+1;
        
    end
    
end
fprintf('\b');
cprintf('Text', '%s', char(8722*ones(1,2*Repeatlength+Spacerlength)));
fprintf('\n');

%% Export output to Excel
Descriptoralphabet = ['A'; 'B'; 'C'; 'D'; 'E'; 'F'; 'G'; 'H'; 'I'; 'J'; 'K'; 'L'; 'M'; 'N'; 'O'; 'P'];

if Orderoligos == 1                 %If the user wants to order oligos
    Descloc = 1;                %Keeps track of the excel output location (Increases by 1 each inner loop only)
    Printoption = 'C6';                 %Determines where final array will output in Excel
    
    if Desiredspacerorder_bin == 1  %If there are multiple spacer options for each location
        [rows, ~] = size(Oligostorage);
        Exceldescriptor = char(zeros(1,length(Prefix)+4)); %Storage for Oligo names ('X_A1_F')
        
        Loc = 1;                    %Keeps track of the row in Oligostorage we're looking at
        
        for i = 1:Spacernum %Number of spacers
            for j = 1:Spaceroptioncount(i) %Number of options for each spacer
                for k = 1:2 %Forward and reverse
                    if k == 1 %Forward
                        Exceldescriptor(Descloc,:) = [Prefix Descriptoralphabet(i) num2str(j) '_F'];
                        
                        Output = [Oligostorage(Loc,1:Oligospacerstorage(Loc)-1)  Capitalize(char(Spaceroptionseq(j,i))) Oligostorage(Loc,Oligospacerstorage(Loc)+Spacerlength:Oligolengthstorage(Loc))];
                        Exceloutput(Descloc,1:length(Output)) = Output;
                        
                    elseif k == 2 %Reverse
                        Exceldescriptor(Descloc,:) = [Prefix Descriptoralphabet(i) num2str(j) '_R'];
                        
                        if isempty(Oligostorage(Loc,1:Oligospacerstorage(Loc)-1)) == 1
                            Output = fliplr([InvertNucs(Capitalize(char(Spaceroptionseq(j,i)))) Oligostorage(Loc,Oligospacerstorage(Loc)+Spacerlength:Oligolengthstorage(Loc))]);
                            
                        else
                            Output = fliplr([Oligostorage(Loc,1:Oligospacerstorage(Loc)-1)  InvertNucs(Capitalize(char(Spaceroptionseq(j,i)))) Oligostorage(Loc,Oligospacerstorage(Loc)+Spacerlength:Oligolengthstorage(Loc))]);
                            
                        end
                        
                        Exceloutput(Descloc,1:length(Output)) = Output;
                    end
                    
                    Loc = Loc+1;
                    Descloc = Descloc+1;
                end
                Loc = Loc-2;
            end
            Loc = Loc+2;
        end
        
    else %If there is a specified order for the spacers
        Exceldescriptor = char(zeros(1,length(Prefix)+3));
        
        for i = 1:Spacernum
            Exceldescriptor(Descloc,:) = [Prefix Descriptoralphabet(i) '_F'];
            Output = Oligostorage(Descloc,1:Oligolengthstorage(Descloc));
            Exceloutput(Descloc,1:length(Output)) = Output;
            Descloc = Descloc+1;
            
            Exceldescriptor(Descloc,:) = [Prefix Descriptoralphabet(i) '_R'];
            Output = fliplr(Oligostorage(Descloc,1:Oligolengthstorage(Descloc)));
            Exceloutput(Descloc,1:length(Output)) = Output;
            Descloc = Descloc+1;
        end
        
    end
    
else %If the user wants to order primers
    Descloc = 1;                        %Keeps track of the excel output location (Increases by 1 each inner loop only)
    Printoption = 'F6';                 %Determines where final array will output in Excel
    
    if Desiredspacerorder_bin == 1          %If there are multiple spacer options for each location
        [rows, ~] = size(Primerstorage);
        Exceldescriptor = char(zeros(1,length(Prefix)+4)); %Storage for primer names ('X_A1_F')
        Loc = 1;                            %Keeps track of the row in Primerstorage we're looking at
        
        for i = 1:Spacernum %Number of spacers
            for j = 1:Spaceroptioncount(i) %Number of options for each spacer
                for k = 1:2 %Forward and reverse
                    if k == 1
                        Exceldescriptor(Descloc,:) = [Prefix Descriptoralphabet(i) num2str(j) '_F'];
                        Currentspaceroption = Capitalize(char(Spaceroptionseq(j,i)));
                        Output = [Primerstorage(Loc,4:Primerspacerstorage(Loc)-1) Currentspaceroption(1:Primeroverlap)];
                        Exceloutput(Descloc,1:length(Output)) = Output;
                        
                    elseif k == 2
                        Exceldescriptor(Descloc,:) = [Prefix Descriptoralphabet(i) num2str(j) '_R'];
                        Currentspaceroption = Capitalize(char(Spaceroptionseq(j,i)));
                        Currentspaceroption = fliplr(InvertNucs(Currentspaceroption));
                        Output = [Primerstorage(Loc,4:Primerspacerstorage(Loc)-1) Currentspaceroption(1:Primeroverlap)];
                        
                        Exceloutput(Descloc,1:length(Output)) = Output;
                    end
                    
                    Loc = Loc+1;
                    Descloc = Descloc+1;
                end
                Loc = Loc-2;
            end
            Loc = Loc+2;
        end
        
    else %If there is a specified order for the spacers
        Exceldescriptor = char(zeros(1,length(Prefix)+3));
        
        for i = 1:Spacernum
            Exceldescriptor(Descloc,:) = [Prefix Descriptoralphabet(i) '_F'];
            Output = Primerstorage(Descloc,4:Primerspacerstorage(Descloc)+Primeroverlap-1);
            Exceloutput(Descloc,1:length(Output)) = Output;
            Descloc = Descloc+1;
            
            Exceldescriptor(Descloc,:) = [Prefix Descriptoralphabet(i) '_R'];
            Output = Primerstorage(Descloc,4:Primerspacerstorage(Descloc)+Primeroverlap-1);
            Exceloutput(Descloc,1:length(Output)) = Output;
            Descloc = Descloc+1;
        end
        
    end
    
end

if Orderoligos == 1
    fprintf('Label         Oligo Sequence (5''->3'')\n');
else
    fprintf('Label         Primer Sequence (5''->3'')\n');
end

for i = 1:Descloc-1 %Convert the matrix of strings to a cell array for faster printing in Excel.
    Exceloutputcell(i,1) = {Exceldescriptor(i,:)};
    fprintf('%s', [char(Exceloutputcell(i,1)) '   ']);
    Exceloutputcell(i,2) = {Exceloutput(i,:)};
    fprintf('%s\n', char(Exceloutputcell(i,2)));
    
end

% Print the final array.
% xlswrite(workbook, Exceloutputcell, 'Example_Output', Printoption);

%% Final Completion Statement and Time Elapsed
toc
fprintf('Script completed!');

end