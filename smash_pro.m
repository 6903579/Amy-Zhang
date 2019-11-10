%%
%/**********************************************
% 
% *@PROJECT:    SMASH PRO
% *@VERSOPM:    1.0
% *@AUTHOR:     Amy Zhang
%               Neo(Zhihui) Li
% 
% *********************************************/

%% main
function smash_pro
clc;
close all;
disp('Smash Pro!')
fprintf('\n')
% Assign different lands
fprintf('Select Land: \n')
fprintf('    1. Flat ground \n')
fprintf('    2. Tilted ground \n')
fprintf('    3. A short hill in the middle \n')
fprintf('    4. A tall hill in the middle \n')
fprintf('    5. Player A on a hill \n')
fprintf('    6. Player B on a hill \n')
fprintf('    7. Random land \n')
fprintf('\n')
choice1=input('Land Choice: ');
if choice1==7
    choice1=randi(6);
end

% Assign wind strengths
fprintf('Select Wind: \n')
fprintf('    1. No wind \n')
fprintf('    2. Gentle breeze \n')
fprintf('    3. Strong breeze \n')
fprintf('    4. Strong gale \n')
fprintf('    5. Hurricane \n')
fprintf('    6. Random wind \n')
fprintf('\n')
choice2=input('Wind Choice: ');
if choice2==6
    choice2=randi(5);
end

% Assign different lands and wind strengths
rand1=rand;
rand2=rand;
if choice1==1
    land=@(x) zeros(size(x));
end
if choice1==2
    land=@(x) (0.6*rand1-0.3)*x;
end
if choice1==3
    land=@(x) (10*rand1+10)*cos(2*pi*(x-(30*rand2+40))/100)+(0.6*...
        rand1-0.3)*x;
end
if choice1==4
    land=@(x) (20*rand1+20)*cos(2*pi*(x-(30*rand2+40))./100)+(0.6*...
        rand1-0.3)*x;
end
if choice1==5
    land=@(x) (20*rand1+30)./(1+exp(0.2*(x - 50)));
end
if choice1==6
    land=@(x) (20*rand1+30)./(1+exp(-0.2*(x - 50)));
end
rand3=rand;
rand4=rand;
if choice2==1
    wind=0;
end
if choice2==2
    wind=sign(rand3-0.5)*(2*rand4+4);
end
if choice2==3
    wind=sign(rand3-0.5)*(4*rand4+8);
end
if choice2==4
    wind=sign(rand3-0.5)*(8*rand4+16);
end
if choice2==5
    wind=sign(rand3-0.5)*(12*rand4+24);
end
wind_str=@(t) [wind;0];

% Assign player positions
pos1=[0;land(0)];
pos2=[100;land(100)];

% Display wind situation
fprintf('Wind situation: \n')
if wind==0
    fprintf('There is no wind. \n')
end
if wind>0
    dir='right';
    fprintf('Wind strength: %.2f m/s; direction: %s \n',wind,dir)
end
if wind<0
    dir='left';
    fprintf('Wind strength: %.2f m/s; direction: %s \n',abs(wind),dir)
end

% Initialize turn and game status
win=0;
turn='A';

% Plot scene
fig=plot_scene(pos1,pos2,land);

while (win==0)
    disp("It's "+turn+"'s turn.")
    fprintf('\n')
    angle=input('Choose an angle (in degrees): ');
    vel=input('Choose velocity to attack: ');
    if (turn=='A')
        [win,route,dt]=traject(pos1,pos2,angle,vel,land,wind_str);
    end
    if (turn=='B')
        angle=180-angle;
        [win,route,dt]=traject(pos2,pos1,angle,vel,land,wind_str);
    end
    plottraj(fig,route,dt,turn);
    if (win==0)
        fprintf('You missed! \n\n')
        if (turn=='A')
            turn='B';
        else
            turn='A';
        end
    end
end
fprintf('Player %c wins!',turn)
c1=uicontrol('Style','pushbutton','String','Quit','Position',[20,250,60,...
    20],'FontSize',10);
c2=uicontrol('Style','pushbutton','String','Restart','Position',[...
    485,250,60,20],'FontSize',10);
c1.Callback=@c1pushed;
c2.Callback=@c2pushed;
end

function c1pushed(src,event)
clc
close all
end
function c2pushed(src,event)
smash_pro
end
%% scenery
function fig=plot_scene(pos1,pos2,land)
% generate figure
fig=figure;
hold on
dis_hori=100;
dis_perp=abs(pos2(2)-pos1(2));
max_d=max(dis_hori,dis_perp);
mid=(pos1+pos2)./2;
minx=mid(1)-max_d/2-30;
maxx=mid(1)+max_d/2+30;
miny=mid(2)-max_d/2-30;
maxy=mid(2)+max_d/2+30;
axis([minx,maxx,miny,maxy])
axis square;

% Generate horizon points
horx=linspace(minx,maxx);
hory=land(horx);

% Plot ground and sky
patch([horx,maxx,minx],[hory,miny,miny],[0.5,0.7,0]);
patch([horx,maxx,minx],[hory,maxy,maxy],[0,0.8,1]);

% Mark the players
plot(pos1(1),pos1(2),'Marker','s','MarkerFaceColor','red',...
    'MarkerSize',25)
text(pos1(1),pos1(2)-10,'A')
hold on
plot(pos2(1),pos2(2),'Marker','s','MarkerFaceColor','black',...
    'MarkerSize',25)
text(pos2(1),pos2(2)-10,'B')
end
%% trajectory
function [hit,traj,dt]=traject(yourpos,enempos,angle,vel,land,wind_str)
m=10;
r=0.1;
air_den=1.225;
cd=0.47;
area=pi*r^2;
g=[0;-9.8];
dt=0.01;

% Initialization of the trajectory
traj=yourpos;
t=0;
velvec=[vel*cosd(angle);vel*sind(angle)];

% Compute trajectory
while traj(2,end)>=land(traj(1,end))
% After the bullet started shooting, before it reaches the ground
    % Compute position, velocity, and acceleration
    u=wind_str(t)-velvec(:,end);
    fd=0.5*norm(u)*u*air_den*cd*area;
    a=(m*g+fd)/m;
    pos=traj(:,end);
    vel=velvec(:,end);
    
    % velocity, time, and position of the next step
    nextvel=vel+a*dt;
    nextpos=pos+nextvel*dt;
    t=t+dt;
    velvec=[velvec,nextvel];
    traj=[traj,nextpos];
end

% check hit
hit=0;
if (norm(traj(:,end)-enempos)<5)
    hit=1;
else
    hit=0;
end
end

function plottraj(fig,traj,dt,turn)
n=size(traj,2);
if (turn=='A')
    color='red';
end
if (turn=='B')
    color='black';
end
figure(fig)
for i=2:n
    plot([traj(1,i-1),traj(1,i)],[traj(2,i-1),traj(2,i)],'Color', color);
end
plot(traj(1,end),traj(2,end),'Marker','o','MarkerFaceColor','yellow',...
    'MarkerSize',15);
end