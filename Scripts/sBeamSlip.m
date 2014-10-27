
iStart = 0;
iEnd   = 110;

for k=iStart:iEnd
    
    aRaw = od.Data(k, 'RAW', '', 'ElectronBeam');
    dEne = mean(aRaw(:,7));
    
    fprintf('Time %03d :: Energy = %.3f\n', k, dEne);
    
end % for

clear iStart;
clear iEnd;
