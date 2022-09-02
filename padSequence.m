function sequence = padSequence(data,sequenceLength)

sequence = data.data;
[C,S] = size(sequence{1,1});

if S < sequenceLength
    padding = zeros(C,sequenceLength-S);
    sequence = [sequence padding];
else
    sequence = sequence{1,1}(:,1:sequenceLength);
end

sequence = {sequence};

end