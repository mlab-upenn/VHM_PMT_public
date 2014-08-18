function VHM_SIM_init
% close all
% clear global node_pos
% clear global node_table
global node_pos
global Config
global node_table
global path_table
global probe_table
global probe_pos
global pace_para


Config.path_plot=[];
pace_panel_para=[];
probe_table=[];
probe_pos=[];
path_table=[];
node_table=[];
node_pos=[];
pace_para=[];
Config.pace_panel=Inf;
pos = get(0, 'screensize'); %get the screensize
W=pos(3);
H=pos(4);
WIDTH=1200;
HEIGHT=670;
Config.Handle=figure('Units', 'Pixels', 'Position', [20 H-740 WIDTH HEIGHT],...
	'Resize','off','Name','Penn Virtual Heart Model Simulator V2.0','NumberTitle','Off',...
    'WindowButtonDownFcn',@button_down);

% topology axes
Config.TOP_axe=axes('Units','Pixels','Position',[20,130,530,530],'Xlim',[0 530],'Ylim',[0 530],'NextPlot','add');
p=imread('EP.jpg');
Config.im=imagesc(p);

set(Config.TOP_axe,'XTick',[],'YTick',[],'ZTick',[]);
Config.node_pos=scatter([],[],'LineWidth',5);
Config.probe_pos=scatter([],[],'LineWidth',3,'Marker','square');

uicontrol('Style','pushbutton','Position',[20,50,80,30],'String','Save model','Callback',@save_model);
uicontrol('Style','pushbutton','Position',[120,50,80,30],'String','Load model','Callback',@load_model);
uicontrol('Style','pushbutton','Position',[220,50,80,30],'String','Show EGM','Callback',@mod_model);
uicontrol('Style','pushbutton','Position',[20,20,80,30],'String','Pace panel','Callback',@pace_panel);

Config.add_node=uicontrol('Style','togglebutton','Position',[320,50,60,30],'String','Add node');
Config.add_path=uicontrol('Style','pushbutton','Position',[400,50,60,30],'String','Add path','Callback',@add_path);
Config.add_probe=uicontrol('Style','togglebutton','Position',[480,50,60,30],'String','Add probe');
Config.disp=uicontrol('Style','checkbox','String','display image','Position',[20,100,100,20],'Value',1,'Callback',@disp_img);
Config.Run=uicontrol('Style','togglebutton','Position',[480,100,60,25],'String','Run');
Config.pace_freq=uicontrol('Style','edit','Position',[400,100,50,20],'BackgroundColor','white','String','500');
Config.slidebar=uicontrol('Style','slider','Position',[130,100,240,20],'Max',0.5,'Min',0.01,'Value',0.1,'SliderStep',[0.05,1],'Callback',@slidebar);

Config.update_fig=uicontrol('Style','checkbox','String','Update figure','Position',[1070,630,100,20],'Value',1);
Config.update_table=uicontrol('Style','checkbox','String','Update table','Position',[1070,610,100,20],'Value',0);
Config.show_unipolar=uicontrol('Style','checkbox','String','Show unipolar','Position',[1070,590,100,20],'Value',0);

uicontrol('Style','pushbutton','Position',[1070,550,80,30],'String','Save EGM','Callback',@save_EGM);

Config.Table_node=uitable('Position',[570,460,480,200],'BackgroundColor',[1,1,1],'CellEditCallback',@para_edit);
set(Config.Table_node,'ColumnName',{'Name','State','Terp_c','Terp_d','Trrp_c','Trrp_d','Trest_c','Trest_d','Act'},'RowName','numbered');
% set(Config.Table_node,'ColumnFormat',{[],node_ind,[],[],[],[],[]});
set(Config.Table_node,'ColumnWidth',{55,50,50,50,50,50,50,50,20});
set(Config.Table_node,'ColumnEditable',[true true true true true true true true true]);

% path_ind={'Idle','Ante','Retro','Double','Conflict'};
Config.Table_path=uitable('Position',[570,250,480,200],'BackgroundColor',[1,1,1],'CellEditCallback',@para_edit);
set(Config.Table_path,'ColumnName',{'Name','State','En','Ex','Amp','An_s','Re_s','An_c','An_d','Re_c','Re_d'},'RowName','numbered');
% set(Config.Table_path,'ColumnFormat',{[],path_ind,node_table(:,1)',node_table(:,1)',[],[],[]});
set(Config.Table_path,'ColumnWidth',{50,50,30,30,30,40,40,40,40,40,40,40});
set(Config.Table_path,'ColumnEditable',[true true true true true true true true true true true]);

Config.Table_pace=uitable('Position',[570,130,300,100],'BackgroundColor',[1,1,1],'CellEditCallback',@para_edit);
set(Config.Table_pace,'ColumnName',{'Name','State','Timer_cur','Timer_def','Act'},'RowName','numbered');
set(Config.Table_pace,'ColumnWidth',{50,50,60,60,30});

Config.pacemaker_on=uicontrol('Style','checkbox','String','Pacemaker ON','Position',[870,130,100,20],'Value',0);

Config.formal_flag=uicontrol('Style','checkbox','String','Formal model','Position',[120,20,100,20],'Value',0);
end

function disp_img(hObject,eventdata,handles)
global Config

if get(Config.disp,'Value')
    set(Config.im,'Visible','on');
else
    set(Config.im,'Visible','off');
end


end
function para_edit(hObject,eventdata,handles)
global node_table
global path_table
global probe_table
global Config

% path_ind={'Idle','Ante','Retro','Double','Conflict'};

switch hObject
    case Config.Table_node
        node_table{eventdata.Indices(1),eventdata.Indices(2)}=eventdata.NewData;
        switch eventdata.Indices(2)
            case 4
                if node_table{eventdata.Indices(1),3}>eventdata.NewData
                    node_table{eventdata.Indices(1),3}=eventdata.NewData;
                    node_table{eventdata.Indices(1),4}=eventdata.NewData;
                end
            case 6
                if node_table{eventdata.Indices(1),5}>eventdata.NewData
                    node_table{eventdata.Indices(1),5}=eventdata.NewData;
                    node_table{eventdata.Indices(1),6}=eventdata.NewData;
                end
            case 8
                if node_table{eventdata.Indices(1),7}>eventdata.NewData
                    node_table{eventdata.Indices(1),7}=eventdata.NewData;
                    node_table{eventdata.Indices(1),8}=eventdata.NewData;
                end
         
                
        end
        set(Config.Table_node,'Data',node_table);
        
    case Config.Table_path
        path_table{eventdata.Indices(1),eventdata.Indices(2)}=eventdata.NewData;
        switch eventdata.Indices(2)
            case 6
                
                path_table{eventdata.Indices(1),8}=round(path_table{eventdata.Indices(1),12}/eventdata.NewData);
                path_table{eventdata.Indices(1),9}=round(path_table{eventdata.Indices(1),12}/eventdata.NewData); 
            case 7
                
                path_table{eventdata.Indices(1),10}=round(path_table{eventdata.Indices(1),12}/eventdata.NewData);
                path_table{eventdata.Indices(1),11}=round(path_table{eventdata.Indices(1),12}/eventdata.NewData); 
            case 9
                path_table{eventdata.Indices(1),8}=eventdata.NewData;
                path_table{eventdata.Indices(1),6}=path_table{eventdata.Indices(1),12}/eventdata.NewData;
            case 11
                path_table{eventdata.Indices(1),10}=eventdata.NewData;
                path_table{eventdata.Indices(1),7}=path_table{eventdata.Indices(1),12}/eventdata.NewData;
        end
        set(Config.Table_path,'Data',path_table(:,1:11));
end


end

function mod_model(hObject,eventdata,handles)
global Config
global egm_table

Config.egm_axe=[];
Config.plot_egm=[];
Config.data_fig=figure('Units', 'Pixels', 'Position', [600 130 600 600],...
	'Resize','off','Name','Electrograms','NumberTitle','Off');
switch get(Config.show_unipolar,'Value')
    case 1
        for i=1:size(egm_table,1)
            Config.egm_axe(i)=subplot(ceil(size(egm_table,1)/2),2,i);
            Config.plot_egm(i)=plot(0,0);
            set(gca,'Xtick',[],'Ytick',[]);
            ylabel(egm_table{i,1},'Rotation',0);
           
        end
    case 0
        double_ind=find(ismember(egm_table(:,3),'d'));
        for i=1:length(double_ind)
            Config.egm_axe(i)=subplot(length(double_ind),1,i);
            Config.plot_egm(i)=plot(0,0);
            set(gca,'Xtick',[],'Ytick',[]);
            
            ylabel(egm_table{double_ind(i),1},'Rotation',0);
            
        end
end

end

function pace_panel(hObject,eventdata,handles)
global Config
global egm_table
global pace_panel_para

Config.pace_panel=figure('Units', 'Pixels', 'Position', [50 130 500 170],...
	'Resize','off','Name','Pace panel','NumberTitle','Off');
uicontrol('Style','text','Position',[20,140,70,20],'String','S1 period');
Config.s1=uicontrol('Style','edit','Position',[20,120,70,20],'BackgroundColor','white','String','600');
pace_panel_para.s1=sscanf(get(Config.s1,'String'),'%d');

uicontrol('Style','text','Position',[20,70,70,20],'String','S1 number');
Config.s1n=uicontrol('Style','edit','Position',[20,50,70,20],'BackgroundColor','white','String','7');
pace_panel_para.s1n=sscanf(get(Config.s1n,'String'),'%d');

uicontrol('Style','text','Position',[100,140,70,20],'String','S2 period');
Config.s2=uicontrol('Style','edit','Position',[100,120,70,20],'BackgroundColor','white','String','450');
pace_panel_para.s2=sscanf(get(Config.s2,'String'),'%d');

uicontrol('Style','text','Position',[100,70,70,20],'String','S2 number');
Config.s2n=uicontrol('Style','edit','Position',[100,50,70,20],'BackgroundColor','white','String','1');
pace_panel_para.s2n=sscanf(get(Config.s2n,'String'),'%d');

uicontrol('Style','text','Position',[180,140,70,20],'String','Pulse width');
Config.pulse_w=uicontrol('Style','edit','Position',[180,120,70,20],'BackgroundColor','white','String','4');
pace_panel_para.pulse_w=sscanf(get(Config.pulse_w,'String'),'%d');

uicontrol('Style','text','Position',[260,140,70,20],'String','Amplitude');
Config.pulse_a=uicontrol('Style','edit','Position',[260,120,70,20],'BackgroundColor','white','String','20');
pace_panel_para.pulse_a=sscanf(get(Config.pulse_a,'String'),'%d');

uicontrol('Style','text','Position',[180,70,70,20],'String','pace probe');
Config.pace_probe=uicontrol('Style','popupmenu','Position',[180,50,70,20],'BackgroundColor','white');
set(Config.pace_probe,'String',egm_table(:,1));
pace_panel_para.pace_probe=egm_table{get(Config.pace_probe,'Value'),2};

Config.pace_deliver=uicontrol('Style','togglebutton','Position',[400,40,80,30],'String','Deliver','Callback',@pace_deliver);
pace_panel_para.state=1;
pace_panel_para.pace_state=1;

end

function button_down(hObject,eventdata,handles)
global node_pos
global Config
global node_table
global path_table

Config.pos=get(Config.TOP_axe,'CurrentPoint');

if (Config.pos(1,1)>20 && Config.pos(1,1)<600 && Config.pos(1,2)>0 && Config.pos(1,2)<660) 
    if get(Config.add_node,'Value')
        Config.test=figure('Position',[300,500,500,200],'Units', 'Pixels','Resize','off','Name','Set parameters for node','NumberTitle','Off');
        uicontrol('Style','text','Position',[20,165,500,20],'String','Name        State                        ERP                                   RRP                                   Rest        ',...
            'BackgroundColor',[204/255,204/255,204/255]);

        Config.n=uicontrol('Style','edit','Position',[20,150,70,20],'BackgroundColor','white');
        Config.s=uicontrol('Style','popupmenu','String',{'Rest','ERP','RRP'},'Position',[90,150,50,20],'BackgroundColor','white');
        Config.erp_cur=uicontrol('Style','edit','Position',[160,150,50,20],'BackgroundColor','white','String','320');
        Config.erp_def=uicontrol('Style','edit','Position',[210,150,50,20],'BackgroundColor','white','String','320');
        Config.rrp_cur=uicontrol('Style','edit','Position',[280,150,50,20],'BackgroundColor','white','String','120');
        Config.rrp_def=uicontrol('Style','edit','Position',[330,150,50,20],'BackgroundColor','white','String','120');
        Config.rest_cur=uicontrol('Style','edit','Position',[400,150,50,20],'BackgroundColor','white','String','9999');
        Config.rest_def=uicontrol('Style','edit','Position',[450,150,50,20],'BackgroundColor','white','String','9999');
        uicontrol('Style','pushbutton','Position',[100,100,80,30],'String','Add','Callback',@node_add);
        uicontrol('Style','pushbutton','Position',[200,100,80,30],'String','Cancel','Callback',@close_fig);
    end
    if get(Config.add_probe,'Value')
        Config.test=figure('Position',[300,500,600,200],'Units', 'Pixels','Resize','off','Name','Add probe','NumberTitle','Off');
        
        Config.probe_name=uicontrol('Style','edit','Position',[20,150,70,20],'BackgroundColor','white');
        for i=1:size(path_table,1)
            Config.probe_path(i)=uicontrol('Style','checkbox','String',path_table{i,1},'Position',[100+floor(i/5)*80,150-mod(i,5)*20,80,20]);
    
        end
        uicontrol('Style','pushbutton','Position',[100,30,80,30],'String','Add','Callback',@probe_add);
        uicontrol('Style','pushbutton','Position',[200,30,80,30],'String','Cancel','Callback',@close_fig);
        
    end
    
end


end

function probe_add(hObject, eventdata, handles)
global probe_table
global Config
global probe_pos
probe_pos=[probe_pos;Config.pos(1,1:2)];
set(Config.probe_pos,'XData',probe_pos(:,1),'YData',probe_pos(:,2));

n=get(Config.probe_name,'String');
p=[];
% for i=1:length(Config.probe_path)
%    if get(Config.probe_path(i),'Value')
%        p=[p;i];
%    end
%     
% end
probe_table=[probe_table;{n}];
set(Config.add_probe,'Value',0);
close(Config.test);
end

function node_add(hObject, eventdata, handles)

global node_table
global node_pos
global Config

node_pos=[node_pos;Config.pos(1,1:2)];
set(Config.node_pos,'XData',node_pos(:,1),'YData',node_pos(:,2));

n=get(Config.n,'String');
s=get(Config.s,'Value');
erp_cur=sscanf(get(Config.erp_cur,'String'),'%d');
erp_def=sscanf(get(Config.erp_def,'String'),'%d');
rrp_cur=sscanf(get(Config.rrp_cur,'String'),'%d');
rrp_def=sscanf(get(Config.rrp_def,'String'),'%d');
rest_cur=sscanf(get(Config.rest_cur,'String'),'%d');
rest_def=sscanf(get(Config.rest_def,'String'),'%d');
a=[150,300];
node_table=[node_table;{n,s,erp_cur,erp_def,rrp_cur,rrp_def,rest_cur,rest_def,0,a,0,2}];
set(Config.add_node,'Value',0);
close(Config.test);

end

function close_fig(hObject, eventdata, handles)
global Config
close(Config.test);
end

function save_model(hObject, eventdata, handles)
global node_table
global node_pos
global probe_table
global probe_pos
global path_table
global pace_para
global egm_table
[fname,path] = uiputfile('*.mat', 'Save VHM Model');
dir=[path fname];

save(dir,'node_table','node_pos','probe_pos','probe_table','path_table','pace_para','egm_table');

end

function save_EGM(hObject, eventdata, handles)
global data
global node_path
[fname,path] = uiputfile('*.mat', 'Save VHM Model');
dir=[path fname];
save(dir,'data','node_path');


end
function load_model(hObject, eventdata, handles)
global node_table
global node_pos
global Config
global path_table
global probe_table
global probe_pos
global pace_para
global egm_table

[fname,path] = uigetfile('*.mat', 'Load VHM Model');

load([path fname]);
% imagesc(img);
Config.node_pos=scatter([],[],'LineWidth',5);
Config.probe_pos=scatter([],[],'LineWidth',2,'Marker','*');

set(Config.node_pos,'XData',node_pos(:,1),'YData',node_pos(:,2));
if ~isempty(probe_pos)
set(Config.probe_pos,'XData',probe_pos(:,1),'YData',probe_pos(:,2));
end
% set(Config.path_1,'String',node_table(:,1));
% set(Config.path_2,'String',node_table(:,1));

for i=1:size(path_table,1)
    Config.path_path_plot(i)=line([node_pos(path_table{i,3},1),node_pos(path_table{i,4},1)],[node_pos(path_table{i,3},2),node_pos(path_table{i,4},2)],'LineWidth',3);
end

set(Config.Table_node,'Data',node_table(:,1:9));
set(Config.Table_path,'Data',path_table(:,1:11));
set(Config.Table_pace,'Data',pace_para);
end


function add_path(hObject, eventdata, handles)
global node_table
global node_pos
global probe_table
global probe_pos
global path_table
global Config

 Config.test=figure('Position',[300,500,500,200],'Units', 'Pixels','Resize','off','Name','Add new path','NumberTitle','Off');
        
Config.path_name=uicontrol('Style','edit','Position',[20,120,70,20],'BackgroundColor','white');
Config.path_1=uicontrol('Style','popupmenu','String','Select','Position',[100,120,70,20],'BackgroundColor','white');
Config.path_2=uicontrol('Style','popupmenu','String','Select','Position',[180,120,70,20],'BackgroundColor','white');
Config.path_amp=uicontrol('Style','edit','Position',[260,120,70,20],'BackgroundColor','white','String','10');
Config.path_ante=uicontrol('Style','edit','Position',[340,120,70,20],'BackgroundColor','white','String','2');
Config.path_retro=uicontrol('Style','edit','Position',[420,120,70,20],'BackgroundColor','white','String','2');
Config.add_path_yes=uicontrol('Style','pushbutton','Position',[50,80,80,30],'String','Add path','Callback',@add_path_yes);
Config.add_path_no=uicontrol('Style','pushbutton','Position',[150,80,80,30],'String','Cancel','Callback',@close_fig);

set(Config.path_1,'String',node_table(:,1));
set(Config.path_2,'String',node_table(:,1));


end

function add_path_yes(hObject, eventdata, handles)
global path_table
global node_pos

global Config


n=get(Config.path_name,'String');
p1=get(Config.path_1,'Value');

p2=get(Config.path_2,'Value');
ante=sscanf(get(Config.path_ante,'String'),'%d');
retro=sscanf(get(Config.path_retro,'String'),'%d');
amp=sscanf(get(Config.path_amp,'String'),'%d');

if p1~=p2
    path_len=((node_pos(p1,1)-node_pos(p2,1))^2+(node_pos(p1,2)-node_pos(p2,2))^2)^.5;
    path_slope=(node_pos(p2,2)-node_pos(p1,2))/(node_pos(p2,1)-node_pos(p1,1));

    Tante_def=round(path_len/ante);
    Tante_cur=Tante_def;
    Tretro_def=round(path_len/retro);
    Tretro_cur=Tretro_def;

    path_table=[path_table;{n,1,p1,p2,amp,ante,retro,Tante_cur,Tante_def,Tretro_cur,Tretro_def,path_len,path_slope}];
figure(Config.Handle);
    Config.path_plot(end+1)=line([node_pos(p1,1),node_pos(p2,1)],[node_pos(p1,2),node_pos(p2,2)],'LineWidth',3);
end

close(Config.test);
end

function slidebar(hObject, eventdata, handles)
global Config

val=get(hObject,'Value');

% set(Config.speed,'String',sprintf('Speed:%.2fms',val));
Config.delay=val;
end

function pace_deliver(hObject, eventdata, handles)
global pace_panel_para
global Config
global egm_table


pace_panel_para.s1=sscanf(get(Config.s1,'String'),'%d');
pace_panel_para.s1n=sscanf(get(Config.s1n,'String'),'%d');
pace_panel_para.s2=sscanf(get(Config.s2,'String'),'%d');
pace_panel_para.s2n=sscanf(get(Config.s2n,'String'),'%d');
pace_panel_para.pulse_w=sscanf(get(Config.pulse_w,'String'),'%d');
pace_panel_para.pulse_a=sscanf(get(Config.pulse_a,'String'),'%d');
pace_panel_para.pace_probe=egm_table{get(Config.pace_probe,'Value'),2};
pace_panel_para.state=1;
if get(Config.pace_deliver,'Value')==0
    pace_panel_para.pace_state=0;
else
    pace_panel_para.pace_state=1;
end
end
