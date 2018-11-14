% Generates data for signal detection using windows, similar to comparison
% done in paper "On the Use of Windows for Harmonic Analysis with the
% Discrete Fourier Transform" by Harris.
% 2 signals are generated with amplitude difference as in dbarr.
% The program finds the minimal bin difference for which the
% signals are distinguishable.
% In this script, the first signal is fixed on the 10th bin.

outputdir = 'output_data';
filenameout = 'part4_onbin.csv';

wgen = WindowGenerator();

fs = 1;
N = 201;
A1 = 1;
dbarr = [0 , 5 ,10 , 20 , 30 , 40 , 50];
detect_threshold_db = 3;
w1 = 10;
w2arr = 11:0.1:40;

w2count = length(w2arr);
dftbin = fs/(N-1);

%% Signal Generation
signals = cell(7,w2count);
for i=1:7
    db = dbarr(i);
    A2 = A1*10^(-db/20);
    for j=1:w2count
        w2 = w2arr(j);
        signals{i,j} = Signal([2 , A1 , w1*dftbin]);
        signals{i,j}.addComp([2 , A2 , w2*dftbin]);
        signals{i,j}.generate(fs , N/fs);
    end
end


%% On the bin Table


minfreq_on_bin = nan(29 , length(dbarr));

for winnum = 1:29
    win = wgen.generate(winnum ,N , 'dfteven');
    if(isnan(win)) , continue , end
    for i=1:length(dbarr)
        db = dbarr(i);
        for j=1:w2count
            w2 = w2arr(j);
            x = signals{i,j}.xx;
            xwin = x(1:length(win)) .* win;

            xspect = abs(fft(xwin));
            xspect = xspect(1:length(xspect)/2);
            xspect(2:end-1) = 2*xspect(2:end-1);

            m1 = xspect(w1+1);
            spectdb = 20*log10(xspect/m1);

            [maxv , maxw] = extrema(spectdb , 1 , 0);
            [minv , minw] = extrema(spectdb , -1 , 0);


            
            if(ismember(w1+1 , maxw) && ismember(round(w2+1) , maxw))
                null = minw( minw>w1+1 & minw<round(w2+1) );
                if(length(null)>1) , break; end
                null = min(minv(find(minw==null,1)));
                peak2 = spectdb(round(w2+1));
                null = peak2 - null;
                if(null > detect_threshold_db)
                    minfreq_on_bin(winnum , i) = w2;
                    plot((0:length(xspect)-1)*dftbin*2, spectdb)
                    hold on
                    plot(round(w2)*dftbin*2 , peak2 , 'or')
                    hold off
                    thetitle = [num2str(db) , ' db.' , ' Freq ' , num2str(w2*2*dftbin) , ' ', '\pi' ,  '. Freq diff =' , num2str(w2arr(j)-10) , ' bins , ' , wgen.name , ' Window'];
                    title(thetitle);
                    ylim([-70,0]); 
                    disp(['Detected! ' , thetitle]);
                    break
                else
%                     disp(['Undetected! ' , num2str(db) , 'db. Freq diff =' , num2str(w2arr(j)-10)] )
                end
            else
%                 disp(['Undetected! ' , num2str(db) , 'db. Freq diff =' , num2str(w2arr(j)-10)] )
            end
        end
    end
end

minfreq_on_bin = minfreq_on_bin*dftbin*2;

filepathout = fullfile(outputdir , filenameout);

names = wgen.allWindowNames();
ids = (1:wgen.winCount)';
T = table(ids , names);
T = [T array2table(minfreq_on_bin)];
T.Properties.VariableNames = {'ID' , 'Window' , 'db0' , 'db5' , 'db10' , 'db20' , 'db30' , 'db40' , 'db50'};
writetable(T,filepathout,'Delimiter',',','QuoteStrings',true)