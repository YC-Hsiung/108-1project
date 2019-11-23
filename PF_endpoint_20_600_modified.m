
%input the conditions here


%repeat is the repeat time
%commands
down = '@0U-550';
up = '@0U550';
right = '@0V2400';
Right = '@0V3000'; %from channel2->3
left = '@0V-7800';
%delays(i) is the delay time of command i
delays=12*ones(5);

repeat = 3;

%open the com
com = serial('com3');
fopen(com);
set(com,'terminator',{'CR/LF','CR/LF'});
%variables for storing caculated peaks
com=[]

%this for loop controls the moving of the stage
%fprintf tells the stage to move
%pause makes the stage to wait for "delay" seconds between two moves
done = 0;

%move camera
for n = 1:repeat
    for i=1:4
        MoveCom(com,down,delays(1))
    end
    MoveCom(com,right,delays(3));
    for i=1:4
        MoveCom(com,up,delays(2))
    end
    MoveCom(com,Right,delays(4));
    for i=1:4
        MoveCom(com,down,delays(1))
    end
    MoveCom(com,right,delays(3));
    for i=1:4
        MoveCom(com,up,delays(2))
    end
    MoveCom(com,left,delays(5));
    
    
    %show the number of cycles have done
    done = done +1;
    disp(done);
end

%close the com
%press ctrl+c in the command window to end the program before it stops, but
%next time the computer may not find com, needs to reopen this program
fclose(com);
disp('end...');
delete(com);
close;
%saving data
%prepare xls content
saveas(gcf,'result.jpg','jpg');
hold off;
close(gcf);
function caculate_peaks()
    %set(gcf,'Visible', 'off');
    clf
    hold off;
    steps=[];
    start_index=0;
    file_count=0;
    %global variables
    global peaks shift_data
    peaks_had_caculated=sum(sum(peaks~=0,1));
    if(length(shift_data)==0)
        try
            peaks=xlsread('temp_peaks_data.xls');
            shift_data=xlsread('temp_shift_data.xls');
            peaks_had_caculated=sum(sum(peaks~=0,1))
           
        end
    end
    
    folder_list={'1 EDCNHS';'2 EDCNHS wash';'3 antibody';'4 antibody wash';'5 blocking';'6 blocking wash';'7 antigen';'8 antigen wash'};
    for j = 1:length(folder_list)
        file_path=[char(folder_list(j)) '/*.txt'];
        files = dir(file_path);
        for i = 1:length(files)
            file_count=file_count+1;
            if file_count>peaks_had_caculated
                peaks_had_caculated=peaks_had_caculated+1;
                %read file
                [X Y] = textread([char(folder_list(j)) '/' files(i).name], '%n %n', 'headerlines', 173);
                %fitting    
                [xData, yData] = prepareCurveData(X, Y );
                % Set up fittype and options.
                % Fit model to data.
                F = fit( xData, yData, 'poly8');
                c = coeffvalues(F);
                cd = polyder(c);
                rootoffit = roots(cd);
                %��X�̤j��
                ind = rootoffit == real(rootoffit);
                realroot = rootoffit(ind(:,1),:);  %���ƥh��
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
                peaks(ceil(i/20)+start_index,tentimes)=realroot(position);
                xlswrite('temp_peaks_data.xls',peaks);
                if mod(peaks_had_caculated,20)==0
                    
                    columns_add_to_store=4;
                    new_line=[];
                    for k=1:4
                        new_line=[new_line peaks(ceil(peaks_had_caculated/20),k*5-4:5*k) zeros(1,columns_add_to_store)];
                    end
                    shift_data(ceil(peaks_had_caculated/20),:)=new_line;
                    %caculate
                    for channel=1:4
                        shift_data(ceil(peaks_had_caculated/20),9*channel-3)=sum(shift_data(ceil(peaks_had_caculated/20),(channel*9-8):(channel*9-4)),2)/5; %average
                        if ceil(peaks_had_caculated/20)>1
                            shift_data(ceil(peaks_had_caculated/20),9*channel-2)=shift_data(ceil(peaks_had_caculated/20),(channel*9-3))-shift_data(1,(channel*9-3)); %shift
                            shift_data(ceil(peaks_had_caculated/20),9*channel-1)=std(shift_data(ceil(peaks_had_caculated/20),(channel*9-8):(channel*9-4))-shift_data(1,(channel*9-8):(channel*9-4)),0,2); %STD
                        end
           
                        if ceil(peaks_had_caculated/20)>2
                            shift_data(ceil(peaks_had_caculated/20),9*channel)=shift_data(ceil(peaks_had_caculated/20),9*channel-2)-shift_data(2,9*channel-2); %-offset
                        end
                    end
                    xlswrite('temp_shift_data.xls',shift_data);
                end
                clear realroot rootoffit ind toosmall toobig tentimes
            end
        end
        steps=[steps;strings(ceil(length(files)/20),1)];
        if length(files)>0
            steps(start_index+1,1)=folder_list(j);
        end
        
        start_index=start_index+length(files)/20;
    end
    %plot and caculate shifts
    if length(shift_data)==0 | mod(peaks_had_caculated,20)~=0
        return
    end
    
    
    line_format={'b-','g-','r-','k-'};
    for i=0:3
        %plot
        hold on
        time_x=0:size(shift_data,1)-2;
        time_x=time_x*4;
        errorbar(time_x,shift_data(2:end,9*i+9),shift_data(2:end,9*i+8),char(line_format(i+1)),'DisplayName',['channel' char(i+49)]);
    end
    
    %plot adjustment
    legend('Location','northwest','AutoUpdate', 'off');
    xlabel('time(min)');
    ylabel('peak shifts(nm)');
    %draw retangles
    WashingSection=[2,4,6,8];
    retangle_color=[153/255,204/255,255/255];
    section_count=1;
    last_section_x=0;
    for i=2:size(steps,1)-1
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
end
function MoveCom(com,command,delay)
    fprintf(com,command)
    tic
    caculate_peaks();
    pause(delay-toc);
end