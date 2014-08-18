clear
import mbed.*
comport = '/dev/tty.usbmodem642'
mybed = SerialRPC(comport, 9600);
% myled = DigitalOut(mymbed, LED1);
%tie to that object in MATLAB
%dout3 = DigitalOut(mymbed,'blueLED');
%Read and Write to a variable on mbed

mybed.reset;
pause(0.01);

pace_param.PAAB= 50;
pace_param.PAARP= 250;
pace_param.PAVB= 50;
pace_param.PVAB= 50;
pace_param.PVARP= 300;
pace_param.PVVB= 50;
pace_param.PVVRP = 200;
pace_param.VSP_thresh= 110;
pace_param.PVARP_def= 300;
pace_param.TAVI= 250; 
pace_param.TURI= 600;
pace_param.TLRI= 1000;
pace_param.setup = 0;

PAAB = RPCVariable(mybed, 'PAAB');
PAARP = RPCVariable(mybed, 'PAARP');
PAVB = RPCVariable(mybed, 'PAVB');
PVAB = RPCVariable(mybed, 'PVAB');
PVARP = RPCVariable(mybed, 'PVARP');
PVVB = RPCVariable(mybed, 'PVVB');
PVVRP = RPCVariable(mybed,'PVVRP');
VSP_thresh = RPCVariable(mybed, 'VSP_thresh');
PVARP_def = RPCVariable(mybed, 'PVARP_def');
TAVI = RPCVariable(mybed, 'TAVI');
TURI = RPCVariable(mybed, 'TURI');
TLRI = RPCVariable(mybed, 'TLRI');
setup = RPCVariable(mybed, 'setup');


%setup.write('1');
pause(0.05);

PAAB.write(num2str(pace_param.PAAB));
pause(0.05);

PAARP.write(num2str(pace_param.PAARP));
pause(0.05);

PAVB.write(num2str(pace_param.PAVB));
pause(0.05);

PVAB.write(num2str(pace_param.PVAB));
pause(0.05);

PVARP.write(num2str(pace_param.PVARP));
pause(0.05);

PVVB.write(num2str(pace_param.PVVB));
pause(0.05);

PVVRP.write(num2str(pace_param.PVVRP));
pause(0.05);

VSP_thresh.write(num2str(pace_param.VSP_thresh));
pause(0.05);

PVARP_def.write(num2str(pace_param.PVARP_def));
pause(0.05);

TAVI.write(num2str(pace_param.TAVI));
pause(0.05);

TURI.write(num2str(pace_param.TURI));
pause(0.05);

TLRI.write(num2str(pace_param.TLRI));
pause(0.05);

% double check
check_PAAB = str2double(PAAB.read());
if check_PAAB == pace_param.PAAB
    disp('PAAB good');
else
    fprintf(2,'PAAB bad\n')
end

check_PAARP = str2double(PAARP.read());
if check_PAARP == pace_param.PAARP
    disp('PAARP good');
else
    fprintf(2,'PAARP bad\n')
end

check_PAVB = str2double(PAVB.read());
if check_PAVB == pace_param.PAVB
    disp('PAVB good');
else
    fprintf(2,'PAVB bad\n')
end

check_PVAB = str2double(PVAB.read());
if check_PVAB == pace_param.PVAB
    disp('PVAB good');
else
    fprintf(2,'PVAB bad\n')
end

check_PVARP = str2double(PVARP.read());
if check_PVARP == pace_param.PVARP
    disp('PVARP good');
else
    fprintf(2,'PVARP bad\n')
end

check_PVVB = str2double(PVVB.read());
if check_PVAB == pace_param.PVAB
    disp('PVVB good');
else
    fprintf(2,'PVVB bad\n')
end

check_PVVRP = str2double(PVVRP.read());
if check_PVVRP == pace_param.PVVRP
    disp('PVVRP good');
else
    fprintf(2,'PVVRP bad\n')
end

check_VSP_thresh = str2double(VSP_thresh.read());
if check_VSP_thresh == pace_param.VSP_thresh
    disp('VSP_thresh good');
else
    fprintf(2,'VSP_thresh bad\n')
end

check_PVARP_def = str2double(PVARP_def.read());
if check_PVARP_def == pace_param.PVARP_def
    disp('PVARP good');
else
    fprintf(2,'PVARP bad\n')
end

check_TAVI = str2double(TAVI.read());
if check_TAVI == pace_param.TAVI
    disp('TAVI good');
else
    fprintf(2,'TAVI bad\n')
end

check_TURI = str2double(TURI.read());
if check_TURI == pace_param.TURI
    disp('TURI good');
else
    fprintf(2,'TURI bad\n')
end

check_TLRI = str2double(TLRI.read());
if check_TLRI == pace_param.TLRI
    disp('TLRI good');
else
    fprintf(2,'TLRI bad\n')
end

%check_

setup.write('1');