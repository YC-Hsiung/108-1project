% Date:        2016/10/21
% Purpose:     fitting curve and finding peak and output array
% Vers:        
%%%
% modified date:2019/10/11
% modified for 4 channel 20points assay
clear;
%pre_folder_list=dir(pwd);
%folder_list={};
%for i=1:length(pre_folder_list)
%    if pre_folder_list(i).isdir==1 & i>2
%        folder_list=[folder_list;pre_folder_list(i).name]
%    end
%end
folder_list={'6 EDCNHS';'7 EDCNHS wash';'8 antibody 100 ug-ml';'9 antibody wash';'10 blocking';'11 blocking wash';'12 antigen secreted TNF';'13 antigen wash'};
start_index=0
steps=[]
for j = 1:length(folder_list)
    file_path=[char(folder_list(j)) '/*.txt'];
    file_struct = dir(file_path);
    for i = 1:length(file_struct)
        %讀入檔案
        [X Y] = textread([char(folder_list(j)) '/' file_struct(i).name], '%n %n', 'headerlines', 173);

       

        %fitting    
        [xData, yData] = prepareCurveData(X, Y );
        % Set up fittype and options.

        % Fit model to data.
        F = fit( xData, yData, 'poly8');
        c = coeffvalues(F);
        cd = polyder(c);
        rootoffit = roots(cd);

        %找出最大值
        ind = rootoffit == real(rootoffit);
        realroot = rootoffit(ind(:,1),:);  %把虛數去除
        toosmall = find(500>realroot); 
        realroot(toosmall)=[];
        toobig = find(700<realroot); 
        realroot(toobig)=[];
        tentimes=mod(i,20);
        if tentimes==0
            tentimes=20;
        end
        %plot(F);
        %grid on;
        [y,position]=max(F(realroot));
        peak(ceil(i/20)+start_index,tentimes)=realroot(position);
        clear realroot rootoffit ind toosmall toobig tentimes 
    end
    steps=[steps;strings(length(file_struct)/20,1)];
    steps(start_index+1,1)=folder_list(j);
    hold on
    start_index=start_index+length(file_struct)/20;
end
add_column=4;
peak=[peak(:,1:5) zeros(size(peak,1),add_column) peak(:,6:10) zeros(size(peak,1),add_column) peak(:,11:15) zeros(size(peak,1),add_column) peak(:,16:20) zeros(size(peak,1),add_column)];%每個channel後面加三column
first={'channe1','','','','','average','shift','STD','-offset','channe2','','','','','average','shift','STD','-offset','channe3','','','','','average','shift','STD','-offset','channe4','','','','','average','shift','STD','-offset'};
line_format={'b-','g-','r-','k-'};
for i=0:3
    peak(:,9*i+6)=sum(peak(:,(i*9+1):(i*9+5)),2)/5; %average
    peak(2:end,9*i+7)=peak(2:end,(i*9+6))-peak(1,(i*9+6)); %shift
    peak(:,9*i+8)=std(peak(:,(i*9+1):(i*9+5)),0,2); %STD
    peak(:,9*i+9)=peak(:,9*i+7)-peak(2,9*i+7); %-offset
    %plot
    time_x=0:size(peak,1)-1;
    time_x=time_x*4;
    set(gcf,'Visible', 'off');
    errorbar(time_x,peak(:,9*i+9),peak(:,9*i+8),char(line_format(i+1)),'DisplayName',['channel' char(i+49)]);
    
    
    
end

%plot adjustment
legend('Location','northwest','AutoUpdate', 'off');
xlabel('time(min)');
ylabel('peak shifts(nm)');
for i=1:size(steps,1)
    if steps(i)~=""
        xline(i*4-4);
    end
end
%prepare xls content
peak=num2cell(peak);
whole=[first;peak];
steps=['';steps];
whole=[steps whole];
%adjust some text
whole(2,[8,10,17,19,26,28,35,37])=strings(1,8);
%output
xlswrite('result',whole);
saveas(gcf,'result.jpg','jpg');
hold off;
close(gcf);



