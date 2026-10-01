function interface_filtres_numeriques
% INTERFACE_FILTRES_NUMERIQUES
% Interface graphique interactive et hyperparametrable pour simuler
% tous les chapitres du cours "Filtres Numeriques" (Dr OBONO BIYOBO Arnaud) :
%   1. Signaux de base (impulsion, echelon, exponentielle, sinusoide, bruit)
%   2. Transformee en Z (poles/zeros, ROC, reponse en frequence)
%   3. Passage H(z) <-> equation de recurrence + etude de stabilite
%   4. Filtres RIF (coefficients manuels, moyenneur, design par fenetrage)
%   5. Filtres RII (Butterworth, Chebyshev I/II, elliptique, coefficients manuels)
%   6. Etude de la stabilite (poles / cercle unite / reponse a l'echelon)
%   7. Comparaison RIF vs RII (meme gabarit, ordres, phase, stabilite)
%
% Tous les parametres (ordre, frequences, coefficients, fenetres, bruit...)
% sont modifiables depuis l'interface : c'est une interface "hyperparametrable".
%
% Utilisation : taper  interface_filtres_numeriques  dans la fenetre de commande.
% Necessite le Signal Processing Toolbox (butter, cheby1, cheby2, ellip,
% fir1, freqz, zplane, impz, filter).

% ------------------------------------------------------------------
% FENETRE PRINCIPALE
% ------------------------------------------------------------------
fig = uifigure('Name','Simulateur Pedagogique - Filtres Numeriques', ...
    'Position',[60 40 1500 900],'Color',[0.96 0.97 0.99]);

tg = uitabgroup(fig,'Position',[10 10 1480 880]);

tab1 = uitab(tg,'Title','1. Signaux de base');
tab2 = uitab(tg,'Title','2. Transformee en Z');
tab3 = uitab(tg,'Title','3. H(z) <-> Recurrence');
tab4 = uitab(tg,'Title','4. Filtre RIF');
tab5 = uitab(tg,'Title','5. Filtre RII');
tab6 = uitab(tg,'Title','6. Stabilite');
tab7 = uitab(tg,'Title','7. RIF vs RII');

% Structure partagee contenant tous les handles (widgets/axes)
H = struct();

buildTab1(tab1);
buildTab2(tab2);
buildTab3(tab3);
buildTab4(tab4);
buildTab5(tab5);
buildTab6(tab6);
buildTab7(tab7);

% Calculs initiaux par defaut pour que l'utilisateur voie tout de suite
% quelque chose a l'ouverture de l'application
onGenSignal();
onCalcZ();
onCalcRecurrence();
onDesignRIF();
onDesignRII();
onAnalyseStab();
onCompareRIFRII();

% ==================================================================
% OUTILS COMMUNS
% ==================================================================
    function s = hzString(b,a)
        % Construit une chaine de caracteres representant H(z) a partir
        % des vecteurs de coefficients b (numerateur) et a (denominateur,
        % a(1) doit valoir 1).
        s = ['H(z) = [' polyString(b) '] / [' polyString(a) ']'];
    end

    function s = polyString(c)
        terms = {};
        for k = 1:length(c)
            coef = c(k);
            if coef == 0
                continue;
            end
            p = k-1;
            if p == 0
                terms{end+1} = sprintf('%.4g', coef); %#ok<AGROW>
            else
                terms{end+1} = sprintf('%.4g z^{-%d}', coef, p); %#ok<AGROW>
            end
        end
        if isempty(terms)
            s = '0';
        else
            s = strjoin(terms, ' + ');
        end
    end

    function s = recurrenceString(b,a)
        % a(1) = 1 toujours (normalise). Construit y[n] = ... a partir de b,a
        terms = {};
        for k = 2:length(a)
            if a(k) ~= 0
                terms{end+1} = sprintf('%+.4g*y[n-%d]', -a(k), k-1); %#ok<AGROW>
            end
        end
        for k = 1:length(b)
            if b(k) ~= 0
                if k == 1
                    terms{end+1} = sprintf('%+.4g*x[n]', b(k)); %#ok<AGROW>
                else
                    terms{end+1} = sprintf('%+.4g*x[n-%d]', b(k), k-1); %#ok<AGROW>
                end
            end
        end
        s = ['y[n] = ' strjoin(terms, ' ')];
        s = strrep(s,'= +','= ');
    end

    function [stable, txt, poles] = stabilityCheck(a)
        poles = roots(a);
        if isempty(poles)
            stable = true;
            txt = 'STABLE (aucun pole - filtre RIF pur)';
            return;
        end
        m = max(abs(poles));
        if m < 1 - 1e-9
            stable = true;
            txt = sprintf('STABLE  (max|pole| = %.4f < 1)', m);
        elseif m <= 1 + 1e-9
            stable = false;
            txt = sprintf('MARGINALEMENT STABLE  (max|pole| = %.4f = 1)', m);
        else
            stable = false;
            txt = sprintf('INSTABLE  (max|pole| = %.4f > 1)', m);
        end
    end

    function v = parseVec(str, defaultVec)
        try
            v = str2num(['[' char(str) ']']); %#ok<ST2NM>
            if isempty(v)
                v = defaultVec;
            end
        catch
            v = defaultVec;
        end
    end

    function plotPoleZero(ax, b, a)
        cla(ax); hold(ax,'on');
        theta = linspace(0,2*pi,300);
        plot(ax, cos(theta), sin(theta), 'k--','LineWidth',1);
        z = roots(b); p = roots(a);
        if ~isempty(z)
            plot(ax, real(z), imag(z), 'bo','MarkerSize',9,'LineWidth',1.5);
        end
        if ~isempty(p)
            plot(ax, real(p), imag(p), 'rx','MarkerSize',11,'LineWidth',2);
        end
        axis(ax,'equal'); grid(ax,'on');
        xlabel(ax,'Re(z)'); ylabel(ax,'Im(z)');
        title(ax,'Diagramme poles (x) - zeros (o)');
        lim = max([1.3, abs(z(:)); 1.3, abs(p(:))]);
        xlim(ax,[-lim lim]); ylim(ax,[-lim lim]);
        hold(ax,'off');
    end

    function plotFreqResp(ax, b, a, Fe)
        [Hf,w] = freqz(b,a,1024);
        f = w/pi*(Fe/2);
        plot(ax, f, 20*log10(abs(Hf)+1e-12), 'b','LineWidth',1.8);
        grid(ax,'on'); xlabel(ax,'Frequence (Hz)'); ylabel(ax,'|H(f)| (dB)');
        title(ax,'Reponse en frequence (module)');
        xlim(ax,[0 Fe/2]);
    end

    function plotImpz(ax, b, a, N)
        [h,t] = impz(b,a,N);
        stem(ax, t, h, 'filled','LineWidth',1.2);
        grid(ax,'on'); xlabel(ax,'n'); ylabel(ax,'h[n]');
        title(ax,'Reponse impulsionnelle');
    end

    function plotStep(ax, b, a, N)
        u = ones(1,N);
        y = filter(b,a,u);
        stem(ax, 0:N-1, y, 'filled','LineWidth',1.2,'Color',[0.85 0.2 0.2]);
        grid(ax,'on'); xlabel(ax,'n'); ylabel(ax,'y[n]');
        title(ax,'Reponse a l''echelon unite');
    end

% ==================================================================
% TAB 1 : SIGNAUX DE BASE
% ==================================================================
    function buildTab1(parent)
        gl = uigridlayout(parent,[1 2]);
        gl.ColumnWidth = {320,'1x'};

        p = uipanel(gl,'Title','Parametres du signal');
        p.Layout.Column = 1;
        pg = uigridlayout(p,[9 2]);
        pg.RowHeight = repmat({30},1,9);

        uilabel(pg,'Text','Type de signal :');
        H.t1_type = uidropdown(pg,'Items', ...
            {'Impulsion delta[n]','Echelon u[n]','Exponentielle a^n u[n]', ...
             'Sinusoide','Bruit blanc gaussien','Exponentielle + bruit'}, ...
            'Value','Impulsion delta[n]');

        uilabel(pg,'Text','Nombre d''echantillons N :');
        H.t1_N = uieditfield(pg,'numeric','Value',50,'Limits',[5 2000]);

        uilabel(pg,'Text','Frequence Fe (Hz) :');
        H.t1_Fe = uieditfield(pg,'numeric','Value',1000,'Limits',[10 1e6]);

        uilabel(pg,'Text','Coefficient a (exponentielle) :');
        H.t1_a = uieditfield(pg,'numeric','Value',0.8,'Limits',[-2 2]);

        uilabel(pg,'Text','Frequence f0 (Hz, sinusoide) :');
        H.t1_f0 = uieditfield(pg,'numeric','Value',50,'Limits',[0.1 1e5]);

        uilabel(pg,'Text','Amplitude du bruit :');
        H.t1_noise = uieditfield(pg,'numeric','Value',0.3,'Limits',[0 10]);

        uilabel(pg,'Text','');
        b = uibutton(pg,'Text','Generer et afficher','ButtonPushedFcn',@(~,~) onGenSignal());
        b.Layout.Column = [1 2];

        ax = uiaxes(gl); ax.Layout.Column = 2;
        H.t1_ax = ax;
        title(ax,'Signal genere x[n]'); xlabel(ax,'n'); ylabel(ax,'Amplitude'); grid(ax,'on');
    end

    function onGenSignal()
        N  = H.t1_N.Value;
        Fe = H.t1_Fe.Value;
        a  = H.t1_a.Value;
        f0 = H.t1_f0.Value;
        namp = H.t1_noise.Value;
        n = 0:N-1;
        switch H.t1_type.Value
            case 'Impulsion delta[n]'
                x = double(n==0);
            case 'Echelon u[n]'
                x = double(n>=0);
            case 'Exponentielle a^n u[n]'
                x = (a.^n);
            case 'Sinusoide'
                x = sin(2*pi*f0/Fe*n);
            case 'Bruit blanc gaussien'
                x = namp*randn(1,N);
            case 'Exponentielle + bruit'
                x = (a.^n) + namp*randn(1,N);
        end
        stem(H.t1_ax, n, x, 'filled','LineWidth',1.2);
        grid(H.t1_ax,'on'); xlabel(H.t1_ax,'n'); ylabel(H.t1_ax,'Amplitude');
        title(H.t1_ax, ['Signal genere : ' H.t1_type.Value]);
    end

% ==================================================================
% TAB 2 : TRANSFORMEE EN Z
% ==================================================================
    function buildTab2(parent)
        gl = uigridlayout(parent,[1 2]);
        gl.ColumnWidth = {330,'1x'};

        p = uipanel(gl,'Title','Signal x[n] et parametres');
        p.Layout.Column = 1;
        pg = uigridlayout(p,[9 2]);
        pg.RowHeight = repmat({30},1,9);

        uilabel(pg,'Text','Signal x[n] :');
        H.t2_type = uidropdown(pg,'Items', ...
            {'a^n u[n]','u[n]','delta[n-k]','n a^n u[n]','Somme (a1)^n u[n] + (a2)^n u[n]'}, ...
            'Value','Somme (a1)^n u[n] + (a2)^n u[n]');

        uilabel(pg,'Text','a (ou a1) :');
        H.t2_a1 = uieditfield(pg,'numeric','Value',0.5,'Limits',[-2 2]);

        uilabel(pg,'Text','a2 (si somme) :');
        H.t2_a2 = uieditfield(pg,'numeric','Value',-0.3,'Limits',[-2 2]);

        uilabel(pg,'Text','k (delai, si delta[n-k]) :');
        H.t2_k = uieditfield(pg,'numeric','Value',2,'Limits',[0 50]);

        uilabel(pg,'Text','Fe (Hz) :');
        H.t2_Fe = uieditfield(pg,'numeric','Value',1000,'Limits',[10 1e6]);

        uilabel(pg,'Text','');
        b = uibutton(pg,'Text','Calculer X(z) et tracer','ButtonPushedFcn',@(~,~) onCalcZ());
        b.Layout.Column = [1 2];

        H.t2_info = uitextarea(pg,'Value',{'X(z) = ...'},'Editable','off');
        H.t2_info.Layout.Column = [1 2];
        H.t2_info.Layout.Row = 9;

        gr = uigridlayout(gl,[2 2]); gr.Layout.Column = 2;
        H.t2_ax1 = uiaxes(gr); H.t2_ax2 = uiaxes(gr);
        H.t2_ax3 = uiaxes(gr); H.t2_ax4 = uiaxes(gr);
    end

    function onCalcZ()
        a1 = H.t2_a1.Value; a2 = H.t2_a2.Value; k = round(H.t2_k.Value);
        Fe = H.t2_Fe.Value;
        switch H.t2_type.Value
            case 'a^n u[n]'
                b = 1; a = [1 -a1];
                roc = sprintf('ROC : |z| > %.3g', abs(a1));
            case 'u[n]'
                b = 1; a = [1 -1];
                roc = 'ROC : |z| > 1';
            case 'delta[n-k]'
                b = [zeros(1,k) 1]; a = 1;
                roc = 'ROC : C \ {0} (tout le plan sauf z=0)';
            case 'n a^n u[n]'
                b = [0 a1]; a = [1 -2*a1 a1^2];
                roc = sprintf('ROC : |z| > %.3g', abs(a1));
            case 'Somme (a1)^n u[n] + (a2)^n u[n]'
                b = [2 -(a1+a2)]; a = [1 -(a1+a2) a1*a2];
                roc = sprintf('ROC : |z| > max(%.3g,%.3g) = %.3g', abs(a1),abs(a2),max(abs(a1),abs(a2)));
        end
        H.t2_info.Value = {hzString(b,a), roc};
        plotPoleZero(H.t2_ax1, b, a);
        plotFreqResp(H.t2_ax2, b, a, Fe);
        plotImpz(H.t2_ax3, b, a, 40);
        % Phase
        [Hf,w] = freqz(b,a,1024);
        plot(H.t2_ax4, w/pi*(Fe/2), unwrap(angle(Hf))*180/pi,'m','LineWidth',1.6);
        grid(H.t2_ax4,'on'); xlabel(H.t2_ax4,'Frequence (Hz)'); ylabel(H.t2_ax4,'Phase (deg)');
        title(H.t2_ax4,'Reponse en phase'); xlim(H.t2_ax4,[0 Fe/2]);
    end

% ==================================================================
% TAB 3 : H(z) <-> EQUATION DE RECURRENCE
% ==================================================================
    function buildTab3(parent)
        gl = uigridlayout(parent,[1 2]);
        gl.ColumnWidth = {350,'1x'};

        p = uipanel(gl,'Title','Coefficients de H(z) = B(z)/A(z)');
        p.Layout.Column = 1;
        pg = uigridlayout(p,[8 1]);
        pg.RowHeight = repmat({30},1,8);

        uilabel(pg,'Text','Coefficients b (numerateur), separes par virgules :');
        H.t3_b = uieditfield(pg,'text','Value','1, 2');

        uilabel(pg,'Text','Coefficients a1, a2... (denominateur, a0=1 implicite) :');
        H.t3_a = uieditfield(pg,'text','Value','-0.5');

        uilabel(pg,'Text','Nombre d''echantillons (reponses) :');
        H.t3_N = uieditfield(pg,'numeric','Value',30,'Limits',[5 500]);

        b = uibutton(pg,'Text','Calculer recurrence + stabilite', ...
            'ButtonPushedFcn',@(~,~) onCalcRecurrence());

        H.t3_eq = uitextarea(pg,'Value',{'y[n] = ...'},'Editable','off');
        H.t3_stab = uilabel(pg,'Text','Stabilite : -','FontWeight','bold','FontSize',14);

        gr = uigridlayout(gl,[2 2]); gr.Layout.Column = 2;
        H.t3_ax1 = uiaxes(gr); H.t3_ax2 = uiaxes(gr);
        H.t3_ax3 = uiaxes(gr); H.t3_ax4 = uiaxes(gr);
    end

    function onCalcRecurrence()
        b = parseVec(H.t3_b.Value, 1);
        avec = parseVec(H.t3_a.Value, []);
        a = [1 avec];
        N = H.t3_N.Value;

        H.t3_eq.Value = {hzString(b,a), '', recurrenceString(b,a)};
        [stable, txt, ~] = stabilityCheck(a);
        H.t3_stab.Text = ['Stabilite : ' txt];
        if stable
            H.t3_stab.FontColor = [0.1 0.6 0.1];
        else
            H.t3_stab.FontColor = [0.75 0.1 0.1];
        end

        plotPoleZero(H.t3_ax1, b, a);
        plotFreqResp(H.t3_ax2, b, a, 1000);
        plotImpz(H.t3_ax3, b, a, N);
        plotStep(H.t3_ax4, b, a, N);
    end

% ==================================================================
% TAB 4 : FILTRE RIF
% ==================================================================
    function buildTab4(parent)
        gl = uigridlayout(parent,[1 2]);
        gl.ColumnWidth = {350,'1x'};

        p = uipanel(gl,'Title','Conception du filtre RIF');
        p.Layout.Column = 1;
        pg = uigridlayout(p,[14 2]);
        pg.RowHeight = repmat({28},1,14);

        uilabel(pg,'Text','Methode :');
        H.t4_method = uidropdown(pg,'Items', ...
            {'Moyenneur (ordre M)','Design par fenetrage (fir1)','Coefficients manuels'}, ...
            'Value','Design par fenetrage (fir1)');
        H.t4_method.Layout.Column = [1 2];

        uilabel(pg,'Text','Ordre M :');
        H.t4_M = uieditfield(pg,'numeric','Value',30,'Limits',[1 500]);

        uilabel(pg,'Text','Fenetre (fir1) :');
        H.t4_win = uidropdown(pg,'Items',{'hamming','hanning','blackman','rectwin'},'Value','hamming');

        uilabel(pg,'Text','Type de filtre :');
        H.t4_ftype = uidropdown(pg,'Items',{'low','high','bandpass','stop'},'Value','low');

        uilabel(pg,'Text','Frequence de coupure fc (Hz) :');
        H.t4_fc = uieditfield(pg,'numeric','Value',150,'Limits',[1 1e6]);

        uilabel(pg,'Text','fc2 (Hz, si bande) :');
        H.t4_fc2 = uieditfield(pg,'numeric','Value',300,'Limits',[1 1e6]);

        uilabel(pg,'Text','Frequence d''echantillonnage Fe (Hz) :');
        H.t4_Fe = uieditfield(pg,'numeric','Value',1000,'Limits',[10 1e6]);

        uilabel(pg,'Text','Coeffs b manuels (virgules) :');
        H.t4_bman = uieditfield(pg,'text','Value','1,1,1,1');

        uilabel(pg,'Text','N echantillons signal test :');
        H.t4_N = uieditfield(pg,'numeric','Value',300,'Limits',[20 5000]);

        uilabel(pg,'Text','f0 signal utile (Hz) :');
        H.t4_f0 = uieditfield(pg,'numeric','Value',50,'Limits',[0.1 1e5]);

        uilabel(pg,'Text','Amplitude bruit :');
        H.t4_noise = uieditfield(pg,'numeric','Value',0.8,'Limits',[0 10]);

        b = uibutton(pg,'Text','Concevoir et appliquer le filtre RIF', ...
            'ButtonPushedFcn',@(~,~) onDesignRIF());
        b.Layout.Column = [1 2];

        H.t4_info = uitextarea(pg,'Value',{'Info filtre RIF'},'Editable','off');
        H.t4_info.Layout.Column = [1 2];

        gr = uigridlayout(gl,[3 2]); gr.Layout.Column = 2;
        H.t4_ax1 = uiaxes(gr); H.t4_ax2 = uiaxes(gr);
        H.t4_ax3 = uiaxes(gr); H.t4_ax4 = uiaxes(gr);
        H.t4_ax5 = uiaxes(gr); H.t4_ax5.Layout.Column = [1 2];
    end

    function onDesignRIF()
        Fe = H.t4_Fe.Value; fc = H.t4_fc.Value; fc2 = H.t4_fc2.Value;
        M = round(H.t4_M.Value); N = round(H.t4_N.Value);
        f0 = H.t4_f0.Value; namp = H.t4_noise.Value;
        wc = min(max(fc/(Fe/2),0.001),0.999);
        wc2 = min(max(fc2/(Fe/2),0.001),0.999);

        switch H.t4_method.Value
            case 'Moyenneur (ordre M)'
                b = ones(1,M+1)/(M+1);
            case 'Design par fenetrage (fir1)'
                winFcn = str2func(H.t4_win.Value);
                switch H.t4_ftype.Value
                    case {'low','high'}
                        b = fir1(M, wc, H.t4_ftype.Value, winFcn(M+1));
                    otherwise
                        b = fir1(M, sort([wc wc2]), H.t4_ftype.Value, winFcn(M+1));
                end
            case 'Coefficients manuels'
                b = parseVec(H.t4_bman.Value, [1 1 1 1]);
        end
        a = 1;

        n = 0:N-1;
        signal_utile = sin(2*pi*f0/Fe*n);
        bruit = namp*randn(1,N);
        x = signal_utile + bruit;
        y = filter(b,a,x);

        RSB_avant = 10*log10(sum(signal_utile.^2)/sum(bruit.^2));
        err = y - signal_utile;
        RSB_apres = 10*log10(sum(signal_utile.^2)/sum(err.^2));

        H.t4_info.Value = { ...
            sprintf('Ordre du filtre : %d  (%d coefficients)', length(b)-1, length(b)), ...
            'Filtre RIF : toujours stable (pas de poles hors origine).', ...
            sprintf('RSB avant filtrage : %.2f dB', RSB_avant), ...
            sprintf('RSB apres filtrage : %.2f dB', RSB_apres), ...
            sprintf('Amelioration : %.2f dB', RSB_apres-RSB_avant)};

        plotPoleZero(H.t4_ax1, b, a);
        plotFreqResp(H.t4_ax2, b, a, Fe);
        plotImpz(H.t4_ax3, b, a, min(M+10,200));
        [Hf,w] = freqz(b,a,1024);
        plot(H.t4_ax4, w/pi*(Fe/2), unwrap(angle(Hf))*180/pi,'m','LineWidth',1.6);
        grid(H.t4_ax4,'on'); xlabel(H.t4_ax4,'Frequence (Hz)'); ylabel(H.t4_ax4,'Phase (deg)');
        title(H.t4_ax4,'Reponse en phase'); xlim(H.t4_ax4,[0 Fe/2]);

        cla(H.t4_ax5); hold(H.t4_ax5,'on');
        plot(H.t4_ax5, n, x, 'Color',[0.7 0.7 0.7]);
        plot(H.t4_ax5, n, y, 'r','LineWidth',1.4);
        plot(H.t4_ax5, n, signal_utile, 'b--','LineWidth',1.2);
        legend(H.t4_ax5, {'x[n] bruite','y[n] filtre','signal utile'}, 'Location','best');
        grid(H.t4_ax5,'on'); xlabel(H.t4_ax5,'n'); ylabel(H.t4_ax5,'Amplitude');
        title(H.t4_ax5,'Filtrage RIF du signal test'); hold(H.t4_ax5,'off');
    end

% ==================================================================
% TAB 5 : FILTRE RII
% ==================================================================
    function buildTab5(parent)
        gl = uigridlayout(parent,[1 2]);
        gl.ColumnWidth = {350,'1x'};

        p = uipanel(gl,'Title','Conception du filtre RII');
        p.Layout.Column = 1;
        pg = uigridlayout(p,[15 2]);
        pg.RowHeight = repmat({28},1,15);

        uilabel(pg,'Text','Methode :');
        H.t5_method = uidropdown(pg,'Items', ...
            {'Butterworth','Chebyshev I','Chebyshev II','Elliptique','Coefficients manuels'}, ...
            'Value','Butterworth');
        H.t5_method.Layout.Column = [1 2];

        uilabel(pg,'Text','Ordre N :');
        H.t5_N = uieditfield(pg,'numeric','Value',4,'Limits',[1 30]);

        uilabel(pg,'Text','Type de filtre :');
        H.t5_ftype = uidropdown(pg,'Items',{'low','high','bandpass','stop'},'Value','low');

        uilabel(pg,'Text','Frequence de coupure fc (Hz) :');
        H.t5_fc = uieditfield(pg,'numeric','Value',150,'Limits',[1 1e6]);

        uilabel(pg,'Text','fc2 (Hz, si bande) :');
        H.t5_fc2 = uieditfield(pg,'numeric','Value',300,'Limits',[1 1e6]);

        uilabel(pg,'Text','Frequence d''echantillonnage Fe (Hz) :');
        H.t5_Fe = uieditfield(pg,'numeric','Value',1000,'Limits',[10 1e6]);

        uilabel(pg,'Text','Ondulation bande passante Rp (dB) :');
        H.t5_Rp = uieditfield(pg,'numeric','Value',1,'Limits',[0.01 10]);

        uilabel(pg,'Text','Attenuation bande coupee Rs (dB) :');
        H.t5_Rs = uieditfield(pg,'numeric','Value',40,'Limits',[1 120]);

        uilabel(pg,'Text','Coeffs b manuels (virgules) :');
        H.t5_bman = uieditfield(pg,'text','Value','1');

        uilabel(pg,'Text','Coeffs a1,a2... manuels (virgules) :');
        H.t5_aman = uieditfield(pg,'text','Value','-1.5,0.75');

        uilabel(pg,'Text','N echantillons signal test :');
        H.t5_Nsig = uieditfield(pg,'numeric','Value',300,'Limits',[20 5000]);

        uilabel(pg,'Text','f0 signal utile (Hz) :');
        H.t5_f0 = uieditfield(pg,'numeric','Value',50,'Limits',[0.1 1e5]);

        uilabel(pg,'Text','Amplitude bruit :');
        H.t5_noise = uieditfield(pg,'numeric','Value',0.8,'Limits',[0 10]);

        b = uibutton(pg,'Text','Concevoir et appliquer le filtre RII', ...
            'ButtonPushedFcn',@(~,~) onDesignRII());
        b.Layout.Column = [1 2];

        H.t5_info = uitextarea(pg,'Value',{'Info filtre RII'},'Editable','off');
        H.t5_info.Layout.Column = [1 2];

        gr = uigridlayout(gl,[3 2]); gr.Layout.Column = 2;
        H.t5_ax1 = uiaxes(gr); H.t5_ax2 = uiaxes(gr);
        H.t5_ax3 = uiaxes(gr); H.t5_ax4 = uiaxes(gr);
        H.t5_ax5 = uiaxes(gr); H.t5_ax5.Layout.Column = [1 2];
    end

    function onDesignRII()
        Fe = H.t5_Fe.Value; fc = H.t5_fc.Value; fc2 = H.t5_fc2.Value;
        N  = round(H.t5_N.Value); Rp = H.t5_Rp.Value; Rs = H.t5_Rs.Value;
        Nsig = round(H.t5_Nsig.Value); f0 = H.t5_f0.Value; namp = H.t5_noise.Value;
        wc = min(max(fc/(Fe/2),0.001),0.999);
        wc2 = min(max(fc2/(Fe/2),0.001),0.999);
        ftype = H.t5_ftype.Value;

        if any(strcmp(ftype,{'bandpass','stop'}))
            wArg = sort([wc wc2]);
        else
            wArg = wc;
        end

        switch H.t5_method.Value
            case 'Butterworth'
                [b,a] = butter(N, wArg, ftype);
            case 'Chebyshev I'
                [b,a] = cheby1(N, Rp, wArg, ftype);
            case 'Chebyshev II'
                [b,a] = cheby2(N, Rs, wArg, ftype);
            case 'Elliptique'
                [b,a] = ellip(N, Rp, Rs, wArg, ftype);
            case 'Coefficients manuels'
                b = parseVec(H.t5_bman.Value, 1);
                a = [1 parseVec(H.t5_aman.Value, [-1.5 0.75])];
        end

        [stable, stxt, ~] = stabilityCheck(a);

        n = 0:Nsig-1;
        signal_utile = sin(2*pi*f0/Fe*n);
        bruit = namp*randn(1,Nsig);
        x = signal_utile + bruit;
        y = filter(b,a,x);
        RSB_avant = 10*log10(sum(signal_utile.^2)/sum(bruit.^2));
        err = y - signal_utile;
        RSB_apres = 10*log10(sum(signal_utile.^2)/sum(err.^2));

        H.t5_info.Value = { ...
            sprintf('Ordre : %d   |  Coeffs num=%d, denom=%d', length(a)-1, length(b), length(a)), ...
            ['Stabilite : ' stxt], ...
            sprintf('RSB avant filtrage : %.2f dB', RSB_avant), ...
            sprintf('RSB apres filtrage : %.2f dB', RSB_apres), ...
            sprintf('Amelioration : %.2f dB', RSB_apres-RSB_avant)};

        plotPoleZero(H.t5_ax1, b, a);
        plotFreqResp(H.t5_ax2, b, a, Fe);
        plotImpz(H.t5_ax3, b, a, 80);
        plotStep(H.t5_ax4, b, a, 80);

        cla(H.t5_ax5); hold(H.t5_ax5,'on');
        plot(H.t5_ax5, n, x, 'Color',[0.7 0.7 0.7]);
        plot(H.t5_ax5, n, y, 'r','LineWidth',1.4);
        plot(H.t5_ax5, n, signal_utile, 'b--','LineWidth',1.2);
        legend(H.t5_ax5, {'x[n] bruite','y[n] filtre','signal utile'}, 'Location','best');
        grid(H.t5_ax5,'on'); xlabel(H.t5_ax5,'n'); ylabel(H.t5_ax5,'Amplitude');
        title(H.t5_ax5,'Filtrage RII du signal test'); hold(H.t5_ax5,'off');
    end

% ==================================================================
% TAB 6 : STABILITE
% ==================================================================
    function buildTab6(parent)
        gl = uigridlayout(parent,[1 2]);
        gl.ColumnWidth = {330,'1x'};

        p = uipanel(gl,'Title','Analyse de la stabilite');
        p.Layout.Column = 1;
        pg = uigridlayout(p,[7 1]);
        pg.RowHeight = repmat({30},1,7);

        uilabel(pg,'Text','Preset :');
        H.t6_preset = uidropdown(pg,'Items', ...
            {'Filtre A (marginalement stable)','Filtre B (stable)','Filtre C (instable)','Personnalise'}, ...
            'Value','Filtre A (marginalement stable)', ...
            'ValueChangedFcn',@(~,~) onPresetChange());

        uilabel(pg,'Text','Coefficients a1, a2... (denominateur) :');
        H.t6_a = uieditfield(pg,'text','Value','-1.5, 0.5');

        uilabel(pg,'Text','N (nombre d''echantillons) :');
        H.t6_N = uieditfield(pg,'numeric','Value',50,'Limits',[5 500]);

        b = uibutton(pg,'Text','Analyser la stabilite','ButtonPushedFcn',@(~,~) onAnalyseStab());

        H.t6_verdict = uilabel(pg,'Text','Verdict : -','FontWeight','bold','FontSize',15);
        H.t6_poles = uitextarea(pg,'Value',{'Poles : -'},'Editable','off');

        gr = uigridlayout(gl,[2 2]); gr.Layout.Column = 2;
        H.t6_ax1 = uiaxes(gr); H.t6_ax2 = uiaxes(gr);
        H.t6_ax3 = uiaxes(gr); H.t6_ax4 = uiaxes(gr);
    end

    function onPresetChange()
        switch H.t6_preset.Value
            case 'Filtre A (marginalement stable)'
                H.t6_a.Value = '-1.5, 0.5';
            case 'Filtre B (stable)'
                H.t6_a.Value = '-0.9';
            case 'Filtre C (instable)'
                H.t6_a.Value = '-1.2';
        end
        onAnalyseStab();
    end

    function onAnalyseStab()
        avec = parseVec(H.t6_a.Value, [-1.5 0.5]);
        a = [1 avec]; b = 1;
        N = round(H.t6_N.Value);
        [stable, txt, poles] = stabilityCheck(a); %#ok<ASGLU>

        H.t6_verdict.Text = ['Verdict : ' txt];
        if ~isempty(strfind(txt,'INSTABLE')) %#ok<STREMP>
            H.t6_verdict.FontColor = [0.75 0.1 0.1];
        elseif ~isempty(strfind(txt,'MARGINAL')) %#ok<STREMP>
            H.t6_verdict.FontColor = [0.85 0.55 0];
        else
            H.t6_verdict.FontColor = [0.1 0.6 0.1];
        end

        polesTxt = {'Poles et modules :'};
        p = roots(a);
        for i = 1:length(p)
            polesTxt{end+1} = sprintf('  p%d = %.4f %+.4fi   |p%d| = %.4f', ...
                i, real(p(i)), imag(p(i)), i, abs(p(i))); %#ok<AGROW>
        end
        H.t6_poles.Value = polesTxt;

        plotPoleZero(H.t6_ax1, b, a);
        plotFreqResp(H.t6_ax2, b, a, 1000);

        Nplot = min(N,200);
        yStep = min(max(abs(filter(b,a,ones(1,Nplot))), [], 'all'), 1e6);
        stem(H.t6_ax3, 0:Nplot-1, filter(b,a,ones(1,Nplot)),'filled','LineWidth',1.2);
        grid(H.t6_ax3,'on'); xlabel(H.t6_ax3,'n'); ylabel(H.t6_ax3,'y[n]');
        title(H.t6_ax3, sprintf('Reponse a l''echelon (max |y| affiche = %.3g)', yStep));

        [h,t] = impz(b,a,Nplot);
        stem(H.t6_ax4, t, h,'filled','LineWidth',1.2,'Color',[0.2 0.5 0.8]);
        grid(H.t6_ax4,'on'); xlabel(H.t6_ax4,'n'); ylabel(H.t6_ax4,'h[n]');
        title(H.t6_ax4,'Reponse impulsionnelle');
    end

% ==================================================================
% TAB 7 : COMPARAISON RIF vs RII
% ==================================================================
    function buildTab7(parent)
        gl = uigridlayout(parent,[1 2]);
        gl.ColumnWidth = {330,'1x'};

        p = uipanel(gl,'Title','Gabarit commun');
        p.Layout.Column = 1;
        pg = uigridlayout(p,[9 1]);
        pg.RowHeight = repmat({30},1,9);

        uilabel(pg,'Text','Frequence de coupure fc (Hz) :');
        H.t7_fc = uieditfield(pg,'numeric','Value',200,'Limits',[1 1e6]);

        uilabel(pg,'Text','Frequence d''echantillonnage Fe (Hz) :');
        H.t7_Fe = uieditfield(pg,'numeric','Value',1000,'Limits',[10 1e6]);

        uilabel(pg,'Text','Ordre du RII (Butterworth) :');
        H.t7_NRII = uieditfield(pg,'numeric','Value',4,'Limits',[1 30]);

        uilabel(pg,'Text','Ordre du RIF (fenetrage Hamming) :');
        H.t7_MRIF = uieditfield(pg,'numeric','Value',30,'Limits',[2 500]);

        b = uibutton(pg,'Text','Comparer RIF vs RII','ButtonPushedFcn',@(~,~) onCompareRIFRII());

        H.t7_info = uitextarea(pg,'Value',{'Comparaison RIF vs RII'},'Editable','off');

        gr = uigridlayout(gl,[2 2]); gr.Layout.Column = 2;
        H.t7_ax1 = uiaxes(gr); H.t7_ax2 = uiaxes(gr);
        H.t7_ax3 = uiaxes(gr); H.t7_ax4 = uiaxes(gr);
    end

    function onCompareRIFRII()
        fc = H.t7_fc.Value; Fe = H.t7_Fe.Value;
        NRII = round(H.t7_NRII.Value); MRIF = round(H.t7_MRIF.Value);
        wc = min(max(fc/(Fe/2),0.001),0.999);

        [b_rii,a_rii] = butter(NRII, wc, 'low');
        b_rif = fir1(MRIF, wc, 'low', hamming(MRIF+1));
        a_rif = 1;

        H.t7_info.Value = { ...
            sprintf('RII Butterworth : ordre %d  (%d coefficients)', NRII, length(a_rii)+length(b_rii)-1), ...
            sprintf('RIF (fenetrage Hamming) : ordre %d  (%d coefficients)', MRIF, length(b_rif)), ...
            '1) Phase lineaire : RIF oui, RII non.', ...
            '2) Ordre necessaire pour un meme gabarit : RIF >> RII en general.', ...
            '3) Stabilite : RIF toujours stable, RII a verifier (poles).', ...
            '4) Cout de calcul : RIF generalement plus couteux (plus de coefficients).'};

        [Hrii,w] = freqz(b_rii,a_rii,1024);
        Hrif = freqz(b_rif,a_rif,1024);
        f = w/pi*(Fe/2);

        cla(H.t7_ax1); hold(H.t7_ax1,'on');
        plot(H.t7_ax1, f, 20*log10(abs(Hrii)+1e-12), 'b','LineWidth',1.8);
        plot(H.t7_ax1, f, 20*log10(abs(Hrif)+1e-12), 'r--','LineWidth',1.8);
        xline(H.t7_ax1, fc, 'k--');
        legend(H.t7_ax1, {'RII Butterworth','RIF Hamming'}, 'Location','best');
        grid(H.t7_ax1,'on'); xlabel(H.t7_ax1,'Frequence (Hz)'); ylabel(H.t7_ax1,'|H| (dB)');
        title(H.t7_ax1,'Reponse en frequence (module)'); xlim(H.t7_ax1,[0 Fe/2]); hold(H.t7_ax1,'off');

        cla(H.t7_ax2); hold(H.t7_ax2,'on');
        plot(H.t7_ax2, f, unwrap(angle(Hrii))*180/pi, 'b','LineWidth',1.8);
        plot(H.t7_ax2, f, unwrap(angle(Hrif))*180/pi, 'r--','LineWidth',1.8);
        legend(H.t7_ax2, {'RII (non lineaire)','RIF (lineaire)'}, 'Location','best');
        grid(H.t7_ax2,'on'); xlabel(H.t7_ax2,'Frequence (Hz)'); ylabel(H.t7_ax2,'Phase (deg)');
        title(H.t7_ax2,'Reponse en phase'); xlim(H.t7_ax2,[0 Fe/2]); hold(H.t7_ax2,'off');

        cla(H.t7_ax3); hold(H.t7_ax3,'on');
        [h_rii,t_rii] = impz(b_rii,a_rii,60);
        [h_rif,t_rif] = impz(b_rif,a_rif,60);
        stem(H.t7_ax3, t_rii, h_rii, 'filled','Color','b');
        stem(H.t7_ax3, t_rif, h_rif, 'r');
        legend(H.t7_ax3, {'RII','RIF'}, 'Location','best');
        grid(H.t7_ax3,'on'); xlabel(H.t7_ax3,'n'); ylabel(H.t7_ax3,'h[n]');
        title(H.t7_ax3,'Reponse impulsionnelle'); hold(H.t7_ax3,'off');

        plotPoleZero(H.t7_ax4, b_rii, a_rii);
        title(H.t7_ax4,'Poles-zeros du RII (le RIF n''a pas de poles)');
    end

end
