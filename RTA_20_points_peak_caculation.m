% Date:        2016/10/21
% Purpose:     fitting curve and finding peak and output array
% Vers:        
%%%
% modified date:2019/10/11
% modified for 4 channel 20points assay
clear;

folder_list={'1 EDCNHS';'2 EDCNHS wash';'3 antibody';'4 antibody wash';'5 blocking';'6 blocking wash';'7 antigen';'8 antigen wash'};
start_index=0
steps=[]
for j = 1:length(folder_list)
    file_path=[char(folder_list(j)) '/*.txt'];
    file_struct = dir(file_path);
    for i = 1:length(file_struct)
        
        [X Y] = textread([char(folder_list(j)) '/' file_struct(i).name], '%n %n', 'headerlines', 173);

       

        %fitting    
        [xData, yData] = prepareCurveData(X, Y );
        % Set up fittype and options.

        % Fit model to data.
        F = fit( xData, yData, 'poly8');
        c = coeffvalues(F);
        cd = polyder(c);
        rootoffit = roots(cd);

        
        ind = rootoffit == real(rootoffit);
        realroot = rootoffit(ind(:,1),:);  
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
    if length(file_struct)>0
        steps(start_index+1,1)=folder_list(j);
    end
    hold on
    start_index=start_index+length(file_struct)/20;
end
add_column=4;
peak=[peak(:,1:5) zeros(size(peak,1),add_column) peak(:,6:10) zeros(size(peak,1),add_column) peak(:,11:15) zeros(size(peak,1),add_column) peak(:,16:20) zeros(size(peak,1),add_column)];%�C��channel�᭱�[�Tcolumn
first={'channe1','','','','','average','shift','STD','-offset','channe2','','','','','average','shift','STD','-offset','channe3','','','','','average','shift','STD','-offset','channe4','','','','','average','shift','STD','-offset'};
line_format={'b-','g-','r-','k-'};

for i=0:3
    peak(:,9*i+6)=sum(peak(:,(i*9+1):(i*9+5)),2)/5; %average
    peak(2:end,9*i+7)=peak(2:end,(i*9+6))-peak(1,(i*9+6)); %shift
    peak(2:end,9*i+8)=std(peak(2:end,(i*9+1):(i*9+5))-peak(1,(i*9+1):(i*9+5)) , 0,2); %STD
    peak(:,9*i+9)=peak(:,9*i+7)-peak(2,9*i+7); %-offset
    %plot
    time_x=0:size(peak,1)-2;
    time_x=time_x*4;
    set(gcf,'Visible', 'off');
    legend_name={'10','1','5','40'};
    %errorbar(time_x,peak(2:end,9*i+9),peak(2:end,9*i+8),char(line_format(i+1)),'DisplayName',['channel' char(i+49)]);
    errorbar(time_x,peak(2:end,9*i+9),peak(2:end,9*i+8),char(line_format(i+1)),'DisplayName',[char(legend_name(i+1)) 'ug/ml']);
end

%plot adjustment
legend('Location','northwest','AutoUpdate', 'off');
xlabel('time(min)');
ylabel('peak shifts(nm)');
%draw retangles
WashingSection=[2,4,6,8];
section_count=1;
last_section_x=1;
retangle_color=[153/255,204/255,255/255];
for i=1:size(steps,1)-1
        if steps(i+1)~=""
            y_axis=ylim;
            plot([i*4-4 i*4-4],[y_axis(1) y_axis(2)],'-k');
            section_count=section_count+1;
            if find(section_count-1==WashingSection)
                rectangle('Position',[last_section_x,y_axis(1),i*4-4-last_section_x,y_axis(2)-y_axis(1)],'EdgeColor', retangle_color, 'FaceColor', retangle_color, 'LineWidth', 1);
            end
            last_section_x=i*4-4;
        end
        if i+1==size(steps,1)
            if find(section_count==WashingSection)
                rectangle('Position',[last_section_x,y_axis(1),i*4-4-last_section_x,y_axis(2)-y_axis(1)],'EdgeColor', retangle_color, 'FaceColor', retangle_color, 'LineWidth', 1);
            end
        end
end
h=get(gca,'Children');
h=flipud(h);
set(gca, 'Children', h);
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



