clc, clear
pkg load io

%%% YUMA Yörünge Formatı %%%
%%% Uydu numarası
ID = ;
%%% 0: Çalışıyor
Healt = ;
%%% Eccentricity | e []
Eccentricity = ;
%%% Time of Applicability (s) | t0 [s] (Yörünge ve saat referans anı)
Time_of_Applicability = ;
%%% Orbital Inclination (rad) | i0 [rad]
Orbital_Inclination = ;
%%% Rate of Right Ascen (r/s) | Δl [rad/s]
Rate_of_Right_Ascen = ;
%%% SQRT (A) (m 1/2) | a^0.5 [m^0.5]
SQRT = ;
%%% Right Ascen at Week (rad) | l0 [rad]
Right_Ascen_at_Week = ;
%%% Argument of Perigee (rad) | w0 [rad]
Argument_of_Perigee = ;
%%% Mean Anom (rad) | M0 [rad]
Mean_Anom = ;
%%% Af0 (s) | a0 [s]
Af0 = ;
%%% Af1 (s/s) | a1 []
Af1 = ;
%%% week | Değiştirilmiş GPS Haftası
%%% 2048 eklenecek
week = ;

%%% Yerçekimi sabiti m^3/s^2
GM = 3.986005E+14;
%%% Yerin açısal dönme hızı rad/s
We = 7292115.1467E-11;
%%% t [s]
t = ;

time = t;
i = 1;
while (t <= time + 86400)

    %fprintf("Time: %.f\n", t);

    t0 = Time_of_Applicability;
    tk = t - t0;

    %%% M' = n = (GM/a^3)^1/2
    a = SQRT;
    a_2 = a ^ 2;
    n = (GM / a_2 ^ 3) ^ 0.5;

    %%% Mk = M0 + n * tk
    Mk = Mean_Anom + n * tk;
    Mk_grad = Mk * 200 / pi;

    %%% İterasyon
    e = Eccentricity;
    Ek = Mk;
    Ek = Mk + e * sin(Ek);
    Ek = Mk + e * sin(Ek);
    Ek = Mk + e * sin(Ek);
    Ek = Mk + e * sin(Ek);
    Ek = Mk + e * sin(Ek);
    Ek = Mk + e * sin(Ek);
    Ek = Mk + e * sin(Ek);
    Ek = Mk + e * sin(Ek);
    Ek = Mk + e * sin(Ek);
    Ek = Mk + e * sin(Ek);
    Ek = Mk + e * sin(Ek);
    Ek = Mk + e * sin(Ek);
    Ek = Mk + e * sin(Ek);
    Ek_grad = Ek * 200 / pi;

    pay = sqrt(1-e*e) * sin(Ek);
    payda = cos(Ek) - e;

    % 1. bölge
    if (pay > 0 && payda > 0)
        fk = atan(pay / payda);
        fk_grad = fk * 200 / pi;
    % 2. bölge
    elseif (pay > 0 && payda < 0)
        fk = atan(pay / payda);
        fk = fk + pi;
        fk_grad = fk * 200 / pi;
    % 3. bölge
    elseif (pay < 0 && payda < 0)
        fk = atan(pay / payda);
        fk = fk + pi;
        fk_grad = fk * 200 / pi;
    % 4. bölge
    elseif (pay < 0 && payda > 0)
        fk = atan(pay / payda);
        fk = fk + 2 * pi;
        fk_grad = fk * 200 / pi;
    endif;
    %fprintf("fk_grad: %8.17f", fk_grad);

    W0 = Argument_of_Perigee;
    uk = W0 + fk;
    uk_grad = uk * 200 / pi;


    i0 = Orbital_Inclination;
    ik = i0;
    ik_grad = ik * 200 / pi;

    Delta_l = Rate_of_Right_Ascen;
    l0 = Right_Ascen_at_Week;
    lk = l0 + (Delta_l - We) * tk - We * t0;
    if lk < 0
        lk = mod(lk, -2*pi);
    elseif lk > 0
        lk = mod(lk, 2*pi);
    end
    lk_grad = lk * 200 / pi;

    % metre cinsinden rk
    rk = a_2 * (1 - e * cos(Ek));
    % km çevrildi
    rk = rk / 1000;
    %fprintf("rk: %4.7f km", rk);


    Xk = rk * (cos(lk)*cos(uk) - sin(lk)*sin(uk)*cos(ik));
    %fprintf("Xk: %4.7f km ", Xk);
    Yk = rk * (sin(lk)*cos(uk) + cos(lk)*sin(uk)*cos(ik));
    %fprintf("Yk: %4.7f km ", Yk);
    Zk =rk * sin(uk)* sin(ik);
    %fprintf("Zk: %4.7f km ", Zk);
    M(i,2) = Xk;
    M(i,3) = Yk;
    M(i,4) = Zk;


    % Mikrosaniye (µs)
    a0 = Af0;
    a1 = Af1;
    Delta_time = a0 + a1 * tk;
    Delta_time = Delta_time * 1000000;
    %fprintf("Delta_time: %4.7f µs \n", Delta_time);
    M(i,5) = Delta_time;

    M(i,1) = t;
    t = t + 900;

    i = i + 1;

end
%csvwrite("veri.xlsx", M)

%%% Verileri çek
filename = 'xyz.ods';
data_source = xlsread(filename);

k = 1;
[m,n] = size(data_source);
for k = 1:m;

    ryuma(k,1) = M(k,2);
    ryuma(k,2) = M(k,3);
    ryuma(k,3) = M(k,4);
    ryuma(k,4) = M(k,5);

    rpre(k,1) = data_source(k,5);
    rpre(k,2) = data_source(k,6);
    rpre(k,3) = data_source(k,7);
    rpre(k,4) = data_source(k,8);

    k = k + 1;

end;

time = 0;
j = 1;
[m,n] = size(data_source);
for j = 1:m;

    rpre_ryuma(j,1) = time;
    rpre_ryuma(j,2) = rpre(j,1) - ryuma(j,1);
    rpre_ryuma(j,3) = rpre(j,2) - ryuma(j,2);
    rpre_ryuma(j,4) = rpre(j,3) - ryuma(j,3);
    rpre_ryuma(j,6) = (rpre(j,4) - ryuma(j,4))*1000;
    rpre_ryuma(j,5) = sqrt(rpre(j,1)*rpre(j,1) + rpre(j,2)*rpre(j,2) + rpre(j,3)*rpre(j,3)) - sqrt(ryuma(j,1)*ryuma(j,1) + ryuma(j,2)*ryuma(j,2) + ryuma(j,3)*ryuma(j,3));


    j = j + 1;
    time = time + 0.25;

end;
%csvwrite("veri.xlsx", rpre_ryuma);



[m,n] = size(data_source);
for j = 1:m;

    x(j,1) = (rpre_ryuma(j,2));
    y(j,1) = (rpre_ryuma(j,3));
    z(j,1) = (rpre_ryuma(j,4));
    s(j,1) = (rpre_ryuma(j,5));
    %% HATALI KULLANIM DOĞRU BULUNCA DÜZELT!!!
##    t(j,1) = (rpre_ryuma(j,5))*1000;
    t(j,1) = (rpre_ryuma(j,6));
##    t(j,1)

    abc(j,1) = rpre_ryuma(j,1);

    j = j + 1;

end;

%%% M dosyasını dosyaya yazdır
%M
%xlswrite('abc.xlsx', M);
csvwrite('figure_1.csv', rpre_ryuma);



##hold on;
##plot(abc, x);
##hold on;
##plot(abc, y);
##hold on;
##plot(abc, z);
##hold on;
##plot(abc, s);
##hold on;
####plot(abc, t);
##hold off;
##grid on;
##
##set(gca, 'xtick', 0:2:24);
######set(gca, 'y2ticks', 0:10:1000);
######set(gca, 'ytick', 0:10:1000);
######y2label
######x1y2
##
##legend({'Vx', 'Vy', 'Vz', 'Vs', 'Vt'});
##title('PRECISE - ALMANAC_Y_U_M_A');
##
######set (gca, "xaxislocation", "left");
##set (gca, "yaxislocation", "left");





