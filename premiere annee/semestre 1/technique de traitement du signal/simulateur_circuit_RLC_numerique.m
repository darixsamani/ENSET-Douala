function simulateur_circuit_RLC()
% =========================================================================
% SIMULATEUR DE CIRCUITS RC / RLC + FILTRES NUMERIQUES
% Interface graphique MATLAB pour tester des circuits RC/RLC et
% des filtres numériques FIR / IIR avec visualisation Transformée en Z
%
% Signaux analogiques : Impulsion Dirac, Peigne Dirac, Echelon,
%                       Rampe, Sinus
% Filtres numériques  : FIR (fenêtrage), Butterworth, Chebyshev I/II,
%                       Elliptique — Passe-bas/haut/bande/coupe
% Visualisations      : Bode, Plan Z, Réponse impulsionnelle,
%                       Réponse fréquentielle, Signaux temporels
%
% Développé par : Darix SAMANI SIEWE
% =========================================================================

clc; close all;

%% -----------------------------------------------------------------------
%  FIGURE PRINCIPALE
%% -----------------------------------------------------------------------
fig = figure('Name', 'Simulateur RC/RLC + Filtres Numériques  —  Darix SAMANI SIEWE', ...
    'NumberTitle','off', ...
    'Position',[30 30 1540 870], ...
    'Color',[0.12 0.14 0.18], ...
    'Resize','on', ...
    'MenuBar','none', ...
    'ToolBar','none');

%% -----------------------------------------------------------------------
%  PANNEAU GAUCHE
%% -----------------------------------------------------------------------
pLeft = uipanel(fig, ...
    'Position',[0.005 0.01 0.265 0.98], ...
    'BackgroundColor',[0.16 0.18 0.24], ...
    'ForegroundColor',[0.55 0.85 1.0], ...
    'Title','  PARAMÈTRES', ...
    'FontName','Consolas','FontSize',11,'FontWeight','bold', ...
    'BorderType','line','HighlightColor',[0.3 0.6 0.9]);

% --- Bandeau titre ---
uicontrol(pLeft,'Style','text', ...
    'String','⚡  SIMULATEUR RC/RLC + NUMÉRIQUE  ⚡', ...
    'Units','normalized','Position',[0.02 0.960 0.96 0.034], ...
    'FontName','Consolas','FontSize',9,'FontWeight','bold', ...
    'ForegroundColor',[0.3 0.9 0.7],'BackgroundColor',[0.16 0.18 0.24], ...
    'HorizontalAlignment','center');

% --- Signature auteur ---
uicontrol(pLeft,'Style','text', ...
    'String','✎  Développé par  Darix SAMANI SIEWE', ...
    'Units','normalized','Position',[0.02 0.928 0.96 0.028], ...
    'FontName','Consolas','FontSize',8,'FontWeight','bold','FontAngle','italic', ...
    'ForegroundColor',[0.98 0.72 0.18],'BackgroundColor',[0.13 0.13 0.18], ...
    'HorizontalAlignment','center');

% --- Onglets Analogique / Numérique ---
tg = uitabgroup(pLeft,'Units','normalized','Position',[0.01 0.03 0.98 0.888]);
tabA = uitab(tg,'Title',' ⚙ Analogique ','BackgroundColor',[0.16 0.18 0.24], ...
    'ForegroundColor',[0.3 0.9 0.7]);
tabD = uitab(tg,'Title',' 〽 Numérique ','BackgroundColor',[0.16 0.18 0.24], ...
    'ForegroundColor',[1 0.5 0.7]);

%% =======================================================================
%%  ONGLET ANALOGIQUE
%% =======================================================================
mkLabel(tabA,'── TYPE DE CIRCUIT ──',[0.02 0.940 0.96 0.038],[0.55 0.85 1.0]);

mkLabel(tabA,'Circuit :',[0.02 0.903 0.36 0.030],[0.85 0.85 0.85]);
hdl.popCircuit = uicontrol(tabA,'Style','popupmenu', ...
    'String',{'RC (Passe-bas)','RC (Passe-haut)','RLC Série','RLC Parallèle'}, ...
    'Units','normalized','Position',[0.38 0.905 0.59 0.035], ...
    'FontName','Consolas','FontSize',8, ...
    'BackgroundColor',[0.22 0.26 0.34],'ForegroundColor',[0.3 0.9 0.7], ...
    'Callback',@updateInterface);

% --- Composants ---
mkLabel(tabA,'── COMPOSANTS ──',[0.02 0.865 0.96 0.033],[0.55 0.85 1.0]);

mkLabel(tabA,'R (Ω) :',[0.02 0.830 0.40 0.028],[0.85 0.85 0.85]);
hdl.editR = mkEdit(tabA,'1000',[0.44 0.832 0.52 0.031]);

mkLabel(tabA,'C (µF) :',[0.02 0.796 0.40 0.028],[0.85 0.85 0.85]);
hdl.editC = mkEdit(tabA,'1',[0.44 0.798 0.52 0.031]);

mkLabel(tabA,'L (mH) :',[0.02 0.762 0.40 0.028],[0.85 0.85 0.85]);
hdl.editL = mkEdit(tabA,'10',[0.44 0.764 0.52 0.031]);
hdl.lblL  = uicontrol(tabA,'Style','text','String','(RLC uniquement)', ...
    'Units','normalized','Position',[0.02 0.737 0.96 0.023], ...
    'FontName','Consolas','FontSize',7,'FontAngle','italic', ...
    'ForegroundColor',[0.5 0.5 0.5],'BackgroundColor',[0.16 0.18 0.24], ...
    'HorizontalAlignment','center');

% --- Signal d'entrée ---
mkLabel(tabA,'── SIGNAL D''ENTRÉE ──',[0.02 0.705 0.96 0.030],[0.55 0.85 1.0]);

mkLabel(tabA,'Signal :',[0.02 0.670 0.36 0.028],[0.85 0.85 0.85]);
hdl.popSignal = uicontrol(tabA,'Style','popupmenu', ...
    'String',{'Impulsion de Dirac','Peigne de Dirac','Échelon Unité','Rampe','Sinus'}, ...
    'Units','normalized','Position',[0.38 0.672 0.59 0.035], ...
    'FontName','Consolas','FontSize',8, ...
    'BackgroundColor',[0.22 0.26 0.34],'ForegroundColor',[1 0.5 0.7], ...
    'Callback',@updateSignalParams);

% --- Params signal ---
mkLabel(tabA,'── PARAMS SIGNAL ──',[0.02 0.635 0.96 0.030],[0.55 0.85 1.0]);

mkLabel(tabA,'Amplitude (V) :',[0.02 0.600 0.50 0.028],[0.85 0.85 0.85]);
hdl.editAmp = mkEdit(tabA,'1',[0.54 0.602 0.42 0.031]);

mkLabel(tabA,'Durée (ms) :',[0.02 0.566 0.50 0.028],[0.85 0.85 0.85]);
hdl.editDuree = mkEdit(tabA,'50',[0.54 0.568 0.42 0.031]);

hdl.lblFreq = mkLabel(tabA,'Fréquence (Hz) :',[0.02 0.532 0.50 0.028],[0.85 0.85 0.85]);
set(hdl.lblFreq,'Visible','off');
hdl.editFreq = mkEdit(tabA,'50',[0.54 0.534 0.42 0.031]);
set(hdl.editFreq,'Visible','off');

hdl.lblPeriode = mkLabel(tabA,'Période peigne (ms) :',[0.02 0.498 0.56 0.028],[0.85 0.85 0.85]);
set(hdl.lblPeriode,'Visible','off');
hdl.editPeriode = mkEdit(tabA,'10',[0.60 0.500 0.36 0.031]);
set(hdl.editPeriode,'Visible','off');

mkLabel(tabA,'Offset DC (V) :',[0.02 0.462 0.50 0.028],[0.85 0.85 0.85]);
hdl.editOffset = mkEdit(tabA,'0',[0.54 0.464 0.42 0.031]);

% --- Affichage ---
mkLabel(tabA,'── AFFICHAGE ──',[0.02 0.428 0.96 0.030],[0.55 0.85 1.0]);

hdl.chkEntree = mkCheck(tabA,' Signal entrée',[0.02 0.393 0.96 0.030],1,[0.4 0.9 0.4]);
hdl.chkSortie = mkCheck(tabA,' Signal sortie (Vc)',[0.02 0.361 0.96 0.030],1,[1 0.6 0.2]);
hdl.chkBode   = mkCheck(tabA,' Diagramme de Bode',[0.02 0.329 0.96 0.030],1,[0.7 0.5 1.0]);

mkLabel(tabA,'Échelle temps :',[0.02 0.294 0.50 0.028],[0.85 0.85 0.85]);
hdl.popEchelle = uicontrol(tabA,'Style','popupmenu', ...
    'String',{'Linéaire','Logarithmique'}, ...
    'Units','normalized','Position',[0.54 0.296 0.42 0.033], ...
    'FontName','Consolas','FontSize',8, ...
    'BackgroundColor',[0.22 0.26 0.34],'ForegroundColor',[0.85 0.85 0.85]);

% --- Boutons Analogique ---
hdl.btnSim = uicontrol(tabA,'Style','pushbutton','String','▶  SIMULER', ...
    'Units','normalized','Position',[0.04 0.220 0.92 0.052], ...
    'FontName','Consolas','FontSize',11,'FontWeight','bold', ...
    'BackgroundColor',[0.10 0.58 0.28],'ForegroundColor',[1 1 1], ...
    'Callback',@simuler);

hdl.btnReset = uicontrol(tabA,'Style','pushbutton','String','↺  RÉINITIALISER', ...
    'Units','normalized','Position',[0.04 0.155 0.92 0.042], ...
    'FontName','Consolas','FontSize',10, ...
    'BackgroundColor',[0.50 0.18 0.08],'ForegroundColor',[1 1 1], ...
    'Callback',@reinitialiser);

hdl.btnExport = uicontrol(tabA,'Style','pushbutton','String','💾  EXPORTER PNG', ...
    'Units','normalized','Position',[0.04 0.100 0.92 0.042], ...
    'FontName','Consolas','FontSize',10, ...
    'BackgroundColor',[0.20 0.30 0.55],'ForegroundColor',[1 1 1], ...
    'Callback',@exporterFig);

hdl.txtInfo = uicontrol(tabA,'Style','text','String','Prêt.', ...
    'Units','normalized','Position',[0.02 0.008 0.96 0.082], ...
    'FontName','Consolas','FontSize',8, ...
    'ForegroundColor',[0.4 0.8 0.4],'BackgroundColor',[0.10 0.12 0.16], ...
    'HorizontalAlignment','left');

%% =======================================================================
%%  ONGLET NUMÉRIQUE
%% =======================================================================
mkLabel(tabD,'── TYPE DE FILTRE NUMÉRIQUE ──',[0.02 0.940 0.96 0.038],[1 0.5 0.7]);

mkLabel(tabD,'Famille :',[0.02 0.903 0.36 0.028],[0.85 0.85 0.85]);
hdl.popFiltreType = uicontrol(tabD,'Style','popupmenu', ...
    'String',{'FIR  (fenêtrage)','IIR  Butterworth','IIR  Chebyshev I','IIR  Chebyshev II','IIR  Elliptique'}, ...
    'Units','normalized','Position',[0.38 0.905 0.59 0.035], ...
    'FontName','Consolas','FontSize',8, ...
    'BackgroundColor',[0.22 0.26 0.34],'ForegroundColor',[1 0.5 0.7], ...
    'Callback',@updateFiltreParams);

mkLabel(tabD,'Réponse :',[0.02 0.867 0.36 0.028],[0.85 0.85 0.85]);
hdl.popFiltreReponse = uicontrol(tabD,'Style','popupmenu', ...
    'String',{'Passe-bas','Passe-haut','Passe-bande','Coupe-bande'}, ...
    'Units','normalized','Position',[0.38 0.869 0.59 0.035], ...
    'FontName','Consolas','FontSize',8, ...
    'BackgroundColor',[0.22 0.26 0.34],'ForegroundColor',[0.3 0.9 0.7], ...
    'Callback',@updateFiltreParams);

% --- Paramètres filtre ---
mkLabel(tabD,'── PARAMÈTRES FILTRE ──',[0.02 0.830 0.96 0.033],[1 0.5 0.7]);

mkLabel(tabD,'Ordre :',[0.02 0.794 0.40 0.028],[0.85 0.85 0.85]);
hdl.editOrdre = mkEdit(tabD,'4',[0.44 0.796 0.52 0.031]);

mkLabel(tabD,'Fe  (Hz) :',[0.02 0.760 0.40 0.028],[0.85 0.85 0.85]);
hdl.editFe = mkEdit(tabD,'8000',[0.44 0.762 0.52 0.031]);

mkLabel(tabD,'Fc1 (Hz) :',[0.02 0.726 0.40 0.028],[0.85 0.85 0.85]);
hdl.editFc1 = mkEdit(tabD,'1000',[0.44 0.728 0.52 0.031]);

hdl.lblFc2  = mkLabel(tabD,'Fc2 (Hz) :',[0.02 0.692 0.40 0.028],[0.85 0.85 0.85]);
set(hdl.lblFc2,'Visible','off');
hdl.editFc2 = mkEdit(tabD,'3000',[0.44 0.694 0.52 0.031]);
set(hdl.editFc2,'Visible','off');

hdl.lblFenetre = mkLabel(tabD,'Fenêtre FIR :',[0.02 0.658 0.40 0.028],[0.85 0.85 0.85]);
hdl.popFenetre = uicontrol(tabD,'Style','popupmenu', ...
    'String',{'Hamming','Hanning','Blackman','Kaiser (β=8.6)','Rectangulaire'}, ...
    'Units','normalized','Position',[0.44 0.660 0.52 0.035], ...
    'FontName','Consolas','FontSize',8, ...
    'BackgroundColor',[0.22 0.26 0.34],'ForegroundColor',[0.4 0.85 1.0]);

hdl.lblRp  = mkLabel(tabD,'Rp ondulation (dB) :',[0.02 0.622 0.56 0.028],[0.85 0.85 0.85]);
set(hdl.lblRp,'Visible','off');
hdl.editRp = mkEdit(tabD,'1',[0.60 0.624 0.36 0.031]);
set(hdl.editRp,'Visible','off');

hdl.lblRs  = mkLabel(tabD,'Rs atténuation (dB) :',[0.02 0.587 0.58 0.028],[0.85 0.85 0.85]);
set(hdl.lblRs,'Visible','off');
hdl.editRs = mkEdit(tabD,'40',[0.62 0.589 0.34 0.031]);
set(hdl.editRs,'Visible','off');

% --- Signal de test numérique ---
mkLabel(tabD,'── SIGNAL DE TEST ──',[0.02 0.552 0.96 0.030],[1 0.5 0.7]);

mkLabel(tabD,'Signal test :',[0.02 0.516 0.40 0.028],[0.85 0.85 0.85]);
hdl.popSignalNum = uicontrol(tabD,'Style','popupmenu', ...
    'String',{'Impulsion δ[n]','Bruit Blanc','Sinusoïde (Fc1)','Multi-sinus','Échelon'}, ...
    'Units','normalized','Position',[0.42 0.518 0.55 0.035], ...
    'FontName','Consolas','FontSize',8, ...
    'BackgroundColor',[0.22 0.26 0.34],'ForegroundColor',[1 0.5 0.7]);

mkLabel(tabD,'N échantillons :',[0.02 0.482 0.48 0.028],[0.85 0.85 0.85]);
hdl.editNpts = mkEdit(tabD,'256',[0.52 0.484 0.44 0.031]);

% --- Affichage numérique ---
mkLabel(tabD,'── AFFICHAGE ──',[0.02 0.447 0.96 0.030],[1 0.5 0.7]);

hdl.chkSignalNum = mkCheck(tabD,' Signaux x[n] / y[n]',[0.02 0.412 0.96 0.030],1,[0.4 0.85 0.9]);
hdl.chkRepFreq   = mkCheck(tabD,' Réponse en fréquence |H|',[0.02 0.380 0.96 0.030],1,[1 0.6 0.2]);
hdl.chkZeros     = mkCheck(tabD,' Plan Z  (pôles & zéros)',[0.02 0.348 0.96 0.030],1,[0.7 0.5 1.0]);
hdl.chkRepImp    = mkCheck(tabD,' Réponse impulsionnelle h[n]',[0.02 0.316 0.96 0.030],1,[0.4 0.9 0.4]);

% --- Boutons Numérique ---
hdl.btnSimNum = uicontrol(tabD,'Style','pushbutton','String','▶  CALCULER FILTRE', ...
    'Units','normalized','Position',[0.04 0.238 0.92 0.055], ...
    'FontName','Consolas','FontSize',11,'FontWeight','bold', ...
    'BackgroundColor',[0.46 0.08 0.58],'ForegroundColor',[1 1 1], ...
    'Callback',@simulerNumerique);

hdl.btnResetNum = uicontrol(tabD,'Style','pushbutton','String','↺  RÉINITIALISER', ...
    'Units','normalized','Position',[0.04 0.170 0.92 0.042], ...
    'FontName','Consolas','FontSize',10, ...
    'BackgroundColor',[0.50 0.18 0.08],'ForegroundColor',[1 1 1], ...
    'Callback',@reinitialiserNum);

hdl.btnExportNum = uicontrol(tabD,'Style','pushbutton','String','💾  EXPORTER PNG', ...
    'Units','normalized','Position',[0.04 0.114 0.92 0.042], ...
    'FontName','Consolas','FontSize',10, ...
    'BackgroundColor',[0.20 0.30 0.55],'ForegroundColor',[1 1 1], ...
    'Callback',@exporterFig);

hdl.txtInfoNum = uicontrol(tabD,'Style','text','String','Prêt.', ...
    'Units','normalized','Position',[0.02 0.006 0.96 0.096], ...
    'FontName','Consolas','FontSize',8, ...
    'ForegroundColor',[0.4 0.8 0.4],'BackgroundColor',[0.10 0.12 0.16], ...
    'HorizontalAlignment','left');

%% =======================================================================
%%  PANNEAU DROIT — Graphiques
%% =======================================================================
pRight = uipanel(fig, ...
    'Position',[0.277 0.01 0.720 0.98], ...
    'BackgroundColor',[0.10 0.12 0.16], ...
    'ForegroundColor',[0.55 0.85 1.0], ...
    'Title','  VISUALISATION', ...
    'FontName','Consolas','FontSize',11,'FontWeight','bold', ...
    'BorderType','line','HighlightColor',[0.3 0.6 0.9]);

% Bande info haut
hdl.txtCircuit = uicontrol(pRight,'Style','text', ...
    'String','Sélectionnez un circuit / filtre puis appuyez sur SIMULER ou CALCULER', ...
    'Units','normalized','Position',[0.01 0.967 0.98 0.025], ...
    'FontName','Consolas','FontSize',8,'FontWeight','bold', ...
    'ForegroundColor',[0.3 0.9 0.7],'BackgroundColor',[0.10 0.12 0.16], ...
    'HorizontalAlignment','center');

% ---- AXES ANALOGIQUES ----
hdl.ax1 = mkAxe(pRight,[0.06 0.69 0.89 0.245]);
title(hdl.ax1,'Signal d''Entrée  e(t)','Color',[0.4 0.9 0.4],'FontName','Consolas','FontSize',9,'FontWeight','bold');
xlabel(hdl.ax1,'Temps (ms)','Color',[0.7 0.7 0.7],'FontName','Consolas','FontSize',8);
ylabel(hdl.ax1,'Amplitude (V)','Color',[0.7 0.7 0.7],'FontName','Consolas','FontSize',8);

hdl.ax2 = mkAxe(pRight,[0.06 0.395 0.89 0.245]);
title(hdl.ax2,'Signal de Sortie  s(t) — Tension aux bornes de C','Color',[1 0.6 0.2],'FontName','Consolas','FontSize',9,'FontWeight','bold');
xlabel(hdl.ax2,'Temps (ms)','Color',[0.7 0.7 0.7],'FontName','Consolas','FontSize',8);
ylabel(hdl.ax2,'Amplitude (V)','Color',[0.7 0.7 0.7],'FontName','Consolas','FontSize',8);

hdl.ax3 = mkAxe(pRight,[0.06 0.060 0.89 0.285]);
set(hdl.ax3,'XScale','log');
title(hdl.ax3,'Diagramme de Bode  —  |H(jω)| & ∠H(jω)','Color',[0.7 0.5 1.0],'FontName','Consolas','FontSize',9,'FontWeight','bold');
xlabel(hdl.ax3,'Fréquence (Hz)','Color',[0.7 0.7 0.7],'FontName','Consolas','FontSize',8);
ylabel(hdl.ax3,'Gain (dB)','Color',[0.7 0.7 0.7],'FontName','Consolas','FontSize',8);

% ---- AXES NUMÉRIQUES (masqués au départ) ----

% N1 : Signaux temporels x[n] / y[n]
hdl.axN1 = mkAxe(pRight,[0.06 0.740 0.89 0.205]);
set(hdl.axN1,'Visible','off');
title(hdl.axN1,'Signaux Temporels  x[n]  →  y[n]','Color',[0.4 0.85 0.9],'FontName','Consolas','FontSize',9,'FontWeight','bold');
xlabel(hdl.axN1,'Échantillon  n','Color',[0.7 0.7 0.7],'FontName','Consolas','FontSize',8);
ylabel(hdl.axN1,'Amplitude','Color',[0.7 0.7 0.7],'FontName','Consolas','FontSize',8);

% N2 : Réponse en fréquence numérique
hdl.axN2 = mkAxe(pRight,[0.06 0.430 0.89 0.270]);
set(hdl.axN2,'Visible','off');
title(hdl.axN2,'Réponse en Fréquence  |H(e^{jω})|  &  ∠H(e^{jω})','Color',[1 0.6 0.2],'FontName','Consolas','FontSize',9,'FontWeight','bold');
xlabel(hdl.axN2,'Fréquence (Hz)','Color',[0.7 0.7 0.7],'FontName','Consolas','FontSize',8);

% N3 : Plan Z — pôles & zéros
hdl.axN3 = mkAxe(pRight,[0.06 0.065 0.42 0.320]);
set(hdl.axN3,'Visible','off');
title(hdl.axN3,'Plan Z  —  Pôles (✕)  &  Zéros (○)','Color',[0.7 0.5 1.0],'FontName','Consolas','FontSize',9,'FontWeight','bold');
xlabel(hdl.axN3,'Partie réelle','Color',[0.7 0.7 0.7],'FontName','Consolas','FontSize',8);
ylabel(hdl.axN3,'Partie imaginaire','Color',[0.7 0.7 0.7],'FontName','Consolas','FontSize',8);

% N4 : Réponse impulsionnelle h[n]
hdl.axN4 = mkAxe(pRight,[0.55 0.065 0.40 0.320]);
set(hdl.axN4,'Visible','off');
title(hdl.axN4,'Réponse Impulsionnelle  h[n]','Color',[0.4 0.9 0.4],'FontName','Consolas','FontSize',9,'FontWeight','bold');
xlabel(hdl.axN4,'Échantillon  n','Color',[0.7 0.7 0.7],'FontName','Consolas','FontSize',8);
ylabel(hdl.axN4,'h[n]','Color',[0.7 0.7 0.7],'FontName','Consolas','FontSize',8);

%% Sauvegarde handles
guidata(fig, hdl);
updateInterface(fig,[]);
updateSignalParams(fig,[]);
updateFiltreParams(fig,[]);

%% =======================================================================
%%  CALLBACKS ANALOGIQUES
%% =======================================================================

    function updateInterface(~,~)
        h = guidata(fig);
        idx = get(h.popCircuit,'Value');
        if idx >= 3
            set(h.editL,'Enable','on','ForegroundColor',[1 0.85 0.3]);
        else
            set(h.editL,'Enable','off','ForegroundColor',[0.4 0.4 0.4]);
        end
    end

    function updateSignalParams(~,~)
        h = guidata(fig);
        idx = get(h.popSignal,'Value');
        visFreq    = onoff(idx == 5);
        visPeriode = onoff(idx == 2);
        set(h.lblFreq,'Visible',visFreq);
        set(h.editFreq,'Visible',visFreq);
        set(h.lblPeriode,'Visible',visPeriode);
        set(h.editPeriode,'Visible',visPeriode);
    end

    function simuler(~,~)
        h = guidata(fig);
        set(h.txtInfo,'String','⏳ Simulation en cours…','ForegroundColor',[1 0.8 0.2]);
        drawnow;
        try
            % Lecture paramètres
            R  = str2double(get(h.editR,'String'));
            C  = str2double(get(h.editC,'String')) * 1e-6;
            L  = str2double(get(h.editL,'String')) * 1e-3;
            Amp= str2double(get(h.editAmp,'String'));
            Dur= str2double(get(h.editDuree,'String'));
            Off= str2double(get(h.editOffset,'String'));
            Fr = str2double(get(h.editFreq,'String'));
            Tp = str2double(get(h.editPeriode,'String'))*1e-3;

            if any(isnan([R C L Amp Dur Off]))
                set(h.txtInfo,'String','❌ Paramètres invalides.','ForegroundColor',[1 0.3 0.3]);
                return;
            end

            setAxesVisibility(h,'analog');

            % Grille temporelle
            Duree = Dur*1e-3;
            Fs = max(1e5, 1000/Dur*1e3);
            dt = 1/Fs;
            t  = 0:dt:Duree;
            N  = length(t);
            idxC = get(h.popCircuit,'Value');
            idxS = get(h.popSignal,'Value');

            % Signal d'entrée
            switch idxS
                case 1, e=zeros(1,N); e(1)=Amp/dt;
                case 2
                    e=zeros(1,N);
                    idx_i=round(0:Tp*Fs:N-1)+1;
                    idx_i=idx_i(idx_i<=N);
                    e(idx_i)=Amp/dt;
                case 3, e=Amp*ones(1,N); e(1:max(1,round(N*0.05)))=0;
                case 4, e=Amp*t/Duree;
                case 5, e=Amp*sin(2*pi*Fr*t);
            end
            e = e + Off;

            % Fonction de transfert H(s)
            switch idxC
                case 1
                    num=[1];         den=[R*C 1];
                    lbl=sprintf('RC Passe-bas  |  R=%g Ω  C=%g µF  |  fc = %.2f Hz', R,C*1e6,1/(2*pi*R*C));
                case 2
                    num=[R*C 0];     den=[R*C 1];
                    lbl=sprintf('RC Passe-haut  |  R=%g Ω  C=%g µF  |  fc = %.2f Hz', R,C*1e6,1/(2*pi*R*C));
                case 3
                    w0=1/sqrt(L*C); Q=(1/R)*sqrt(L/C);
                    num=[w0^2];      den=[1,R/L,1/(L*C)];
                    lbl=sprintf('RLC Série  |  f₀=%.2f Hz  Q=%.3f  |  R=%g Ω  L=%g mH  C=%g µF', w0/(2*pi),Q,R,L*1e3,C*1e6);
                case 4
                    w0=1/sqrt(L*C); Q=R*sqrt(C/L);
                    num=[w0^2];      den=[1,w0/Q,w0^2];
                    lbl=sprintf('RLC Parallèle  |  f₀=%.2f Hz  Q=%.3f  |  R=%g Ω  L=%g mH  C=%g µF', w0/(2*pi),Q,R,L*1e3,C*1e6);
            end

            sys=[tf(num,den)];
            [s,t_out]=lsim(sys,e,t);
            s=s'; t_out=t_out';
            t_ms=t*1e3; to_ms=t_out*1e3;
            ech=get(h.popEchelle,'Value');

            % --- Axe 1 : Entrée ---
            cla(h.ax1); hold(h.ax1,'on');
            if get(h.chkEntree,'Value')
                if idxS<=2
                    nz=find(e~=0);
                    if ~isempty(nz)
                        stem(h.ax1,t_ms(nz),Amp*ones(size(nz)),'Color',[0.3 0.95 0.5],'LineWidth',1.8,'MarkerSize',6);
                    end
                else
                    plot(h.ax1,t_ms,e,'Color',[0.3 0.95 0.5],'LineWidth',1.5);
                end
                legend(h.ax1,'e(t)','TextColor',[0.3 0.95 0.5],'Color',[0.08 0.10 0.15],'EdgeColor',[0.3 0.4 0.5],'FontName','Consolas','FontSize',8,'Location','northeast');
            end
            hold(h.ax1,'off');
            decorAxe(h.ax1,'Signal d''Entrée  e(t)',[0.4 0.9 0.4],'Temps (ms)','Amplitude (V)');
            if ech==2, set(h.ax1,'XScale','log'); end

            % --- Axe 2 : Sortie ---
            cla(h.ax2);
            if get(h.chkSortie,'Value')
                plot(h.ax2,to_ms,s,'Color',[1 0.6 0.2],'LineWidth',1.8);
                legend(h.ax2,'s(t) = Vc(t)','TextColor',[1 0.6 0.2],'Color',[0.08 0.10 0.15],'EdgeColor',[0.3 0.4 0.5],'FontName','Consolas','FontSize',8,'Location','northeast');
            end
            decorAxe(h.ax2,'Signal de Sortie  s(t)',[1 0.6 0.2],'Temps (ms)','Amplitude (V)');
            if ech==2, set(h.ax2,'XScale','log'); end

            % --- Axe 3 : Bode ---
            cla(h.ax3);
            if get(h.chkBode,'Value')
                fb=logspace(0,6,2000); wb=2*pi*fb;
                [mag,ph]=bode(sys,wb);
                mag=squeeze(mag); ph=squeeze(ph);
                mdb=20*log10(mag+eps);

                yyaxis(h.ax3,'left');
                semilogx(h.ax3,fb,mdb,'Color',[0.7 0.5 1.0],'LineWidth',1.8);
                ylabel(h.ax3,'Gain (dB)','Color',[0.7 0.5 1.0],'FontName','Consolas','FontSize',8);
                set(h.ax3,'YColor',[0.7 0.5 1.0]);

                yyaxis(h.ax3,'right');
                semilogx(h.ax3,fb,ph,'Color',[0.4 0.8 0.9],'LineWidth',1.2,'LineStyle','--');
                ylabel(h.ax3,'Phase (°)','Color',[0.4 0.8 0.9],'FontName','Consolas','FontSize',8);
                set(h.ax3,'YColor',[0.4 0.8 0.9]);

                yyaxis(h.ax3,'left');
                hold(h.ax3,'on');
                yline(h.ax3,max(mdb)-3,'--','Color',[1 0.4 0.4],'LineWidth',1, ...
                    'Label','-3 dB','LabelHorizontalAlignment','left','FontName','Consolas','FontSize',7);
                hold(h.ax3,'off');
                legend(h.ax3,{'|H(f)| (dB)','∠H(f) (°)'},'TextColor',[0.85 0.85 0.85],'Color',[0.08 0.10 0.15],'EdgeColor',[0.3 0.4 0.5],'FontName','Consolas','FontSize',8,'Location','southwest');
            end
            set(h.ax3,'Color',[0.06 0.08 0.12],'XColor',[0.5 0.7 0.9], ...
                'GridColor',[0.3 0.35 0.4],'XGrid','on','YGrid','on','XScale','log');
            title(h.ax3,'Diagramme de Bode  —  |H(jω)| & ∠H(jω)','Color',[0.7 0.5 1.0],'FontName','Consolas','FontSize',9,'FontWeight','bold');
            xlabel(h.ax3,'Fréquence (Hz)','Color',[0.7 0.7 0.7],'FontName','Consolas','FontSize',8);

            set(h.txtCircuit,'String',lbl);
            set(h.txtInfo,'String',sprintf('✓ Simulation OK  |  N = %d points  |  Fs = %.1f kHz',N,Fs/1e3), ...
                'ForegroundColor',[0.4 0.9 0.4]);
        catch ME
            set(h.txtInfo,'String',['❌ ' ME.message],'ForegroundColor',[1 0.3 0.3]);
        end
    end % simuler

    function reinitialiser(~,~)
        h = guidata(fig);
        set(h.editR,'String','1000'); set(h.editC,'String','1');
        set(h.editL,'String','10');   set(h.editAmp,'String','1');
        set(h.editDuree,'String','50');set(h.editFreq,'String','50');
        set(h.editPeriode,'String','10');set(h.editOffset,'String','0');
        set(h.popCircuit,'Value',1); set(h.popSignal,'Value',1);
        set(h.chkEntree,'Value',1); set(h.chkSortie,'Value',1);
        set(h.chkBode,'Value',1);   set(h.popEchelle,'Value',1);
        cla(h.ax1); cla(h.ax2); cla(h.ax3);
        set(h.txtInfo,'String','Réinitialisé.','ForegroundColor',[0.4 0.8 0.4]);
        set(h.txtCircuit,'String','Sélectionnez un circuit et appuyez sur SIMULER');
        updateInterface(fig,[]); updateSignalParams(fig,[]);
    end

%% =======================================================================
%%  CALLBACKS FILTRES NUMÉRIQUES
%% =======================================================================

    function updateFiltreParams(~,~)
        h = guidata(fig);
        idxT = get(h.popFiltreType,'Value');
        idxR = get(h.popFiltreReponse,'Value');
        isBand = (idxR==3 || idxR==4);
        isFIR  = (idxT==1);
        needRp = (idxT==3 || idxT==5);
        needRs = (idxT==4 || idxT==5);
        set(h.lblFc2,'Visible',onoff(isBand));
        set(h.editFc2,'Visible',onoff(isBand));
        set(h.lblFenetre,'Visible',onoff(isFIR));
        set(h.popFenetre,'Visible',onoff(isFIR));
        set(h.lblRp,'Visible',onoff(needRp));
        set(h.editRp,'Visible',onoff(needRp));
        set(h.lblRs,'Visible',onoff(needRs));
        set(h.editRs,'Visible',onoff(needRs));
    end

    function simulerNumerique(~,~)
        h = guidata(fig);
        set(h.txtInfoNum,'String','⏳ Calcul du filtre…','ForegroundColor',[1 0.8 0.2]);
        drawnow;
        try
            % --- Lecture paramètres ---
            ord  = max(1, round(str2double(get(h.editOrdre,'String'))));
            Fe   = str2double(get(h.editFe,'String'));
            Fc1  = str2double(get(h.editFc1,'String'));
            Fc2  = str2double(get(h.editFc2,'String'));
            Npts = max(32, round(str2double(get(h.editNpts,'String'))));
            Rp   = str2double(get(h.editRp,'String'));
            Rs   = str2double(get(h.editRs,'String'));

            if isnan(Fe)||isnan(Fc1)||Fe<=0||Fc1<=0
                set(h.txtInfoNum,'String','❌ Paramètres invalides.','ForegroundColor',[1 0.3 0.3]);
                return;
            end

            idxT = get(h.popFiltreType,'Value');
            idxR = get(h.popFiltreReponse,'Value');
            idxF = get(h.popFenetre,'Value');
            idxS = get(h.popSignalNum,'Value');

            % Fréquences normalisées (0…1, 1 ≡ Fe/2)
            Wn1 = clip01(2*Fc1/Fe);
            Wn2 = clip01(2*Fc2/Fe);
            isBand = (idxR==3 || idxR==4);
            if isBand
                Wn = [min(Wn1,Wn2) max(Wn1,Wn2)];
            else
                Wn = Wn1;
            end
            switch idxR
                case 1, rType='low';
                case 2, rType='high';
                case 3, rType='bandpass';
                case 4, rType='stop';
            end

            % --- Calcul des coefficients b,a ---
            switch idxT
                case 1  % FIR fenêtrage
                    if isBand && mod(ord,2)~=0, ord=ord+1; end
                    switch idxF
                        case 1, win=hamming(ord+1);
                        case 2, win=hanning(ord+1);
                        case 3, win=blackman(ord+1);
                        case 4, win=kaiser(ord+1,8.6);
                        case 5, win=rectwin(ord+1);
                    end
                    b=fir1(ord,Wn,rType,win);  a=1;
                    fenNoms={'Hamming','Hanning','Blackman','Kaiser','Rectwin'};
                    lbl=sprintf('FIR %s  ord=%d  Fc=%.0f Hz  Fe=%.0f Hz  [%s]', ...
                        upper(rType),ord,Fc1,Fe,fenNoms{idxF});

                case 2  % Butterworth IIR
                    [b,a]=butter(ord,Wn,rType);
                    lbl=sprintf('IIR Butterworth  %s  ord=%d  Fc=%.0f Hz  Fe=%.0f Hz', ...
                        upper(rType),ord,Fc1,Fe);

                case 3  % Chebyshev I
                    if isnan(Rp), Rp=1; end
                    [b,a]=cheby1(ord,Rp,Wn,rType);
                    lbl=sprintf('IIR Chebyshev I  %s  ord=%d  Fc=%.0f Hz  Rp=%.1f dB', ...
                        upper(rType),ord,Fc1,Rp);

                case 4  % Chebyshev II
                    if isnan(Rs), Rs=40; end
                    [b,a]=cheby2(ord,Rs,Wn,rType);
                    lbl=sprintf('IIR Chebyshev II  %s  ord=%d  Fc=%.0f Hz  Rs=%.1f dB', ...
                        upper(rType),ord,Fc1,Rs);

                case 5  % Elliptique
                    if isnan(Rp), Rp=1; end
                    if isnan(Rs), Rs=40; end
                    [b,a]=ellip(ord,Rp,Rs,Wn,rType);
                    lbl=sprintf('IIR Elliptique  %s  ord=%d  Fc=%.0f Hz  Rp=%.1f dB  Rs=%.1f dB', ...
                        upper(rType),ord,Fc1,Rp,Rs);
            end

            % --- Signal de test ---
            n_vec = 0:Npts-1;
            switch idxS
                case 1, x=zeros(1,Npts); x(1)=1;
                case 2, x=randn(1,Npts);
                case 3, x=sin(2*pi*Fc1/Fe*n_vec);
                case 4
                    f1=Fc1*0.2; f2=Fc1; f3=min(Fe/2*0.9, Fc1*4);
                    x=sin(2*pi*f1/Fe*n_vec)+sin(2*pi*f2/Fe*n_vec)+sin(2*pi*f3/Fe*n_vec);
                case 5, x=ones(1,Npts); x(1:max(1,round(Npts*0.05)))=0;
            end

            % Filtrage
            y = filter(b,a,x);

            % Réponse en fréquence (freqz)
            NFFT = max(2048, 8*Npts);
            [H,f_hz] = freqz(b,a,NFFT,Fe);
            H_dB  = 20*log10(abs(H)+eps);
            H_ph  = angle(H)*180/pi;

            % Réponse impulsionnelle
            Nimp = max(64, min(400, 20*ord));
            h_imp = impz(b,a,Nimp);

            % Pôles et zéros (Transformée en Z)
            z_zeros = roots(b);
            z_poles = roots(a);

            % ================================================================
            % INFORMATION TRANSFORMÉE EN Z
            % H(z) = B(z)/A(z)
            % ================================================================
            stable   = all(abs(z_poles) < 1-1e-9);
            nPoles   = length(z_poles);
            nZeros   = length(z_zeros);
            if idxT==1
                typeStr='FIR  (phase linéaire garantie)';
            else
                typeStr='IIR  (retour récursif)';
            end
            maxPoleR = max([abs(z_poles);0]);

            % Construire l'expression H(z) pour petits ordres
            if ord <= 3 && idxT==1
                hz_num = poly2str_z(b);
                hz_str = sprintf('H(z) = (%s) / 1', hz_num);
            elseif ord <= 3
                hz_num = poly2str_z(b);
                hz_den = poly2str_z(a);
                hz_str = sprintf('H(z) = (%s) / (%s)', hz_num, hz_den);
            else
                hz_str = sprintf('H(z) = [%d coefficients b] / [%d coefficients a]', length(b), length(a));
            end

            info_z = sprintf(['Type: %s\n' ...
                'Pôles: %d  |  Zéros: %d  |  Stable: %s  |  |p|max = %.4f\n' ...
                '%s'], ...
                typeStr, nPoles, nZeros, onoff_str(stable), maxPoleR, hz_str);

            % ================================================================
            % AFFICHAGE
            % ================================================================
            setAxesVisibility(h,'digital');

            % --- axN1 : Signaux x[n] / y[n] ---
            cla(h.axN1);
            if get(h.chkSignalNum,'Value')
                hold(h.axN1,'on');
                plot(h.axN1,n_vec,x,'Color',[0.3 0.92 0.55],'LineWidth',1.2);
                plot(h.axN1,n_vec,y,'Color',[1 0.50 0.18],'LineWidth',1.6);
                legend(h.axN1,{'x[n]  entrée','y[n]  sortie'}, ...
                    'TextColor',[0.85 0.85 0.85],'Color',[0.08 0.10 0.15], ...
                    'EdgeColor',[0.3 0.4 0.5],'FontName','Consolas','FontSize',8,'Location','northeast');
                hold(h.axN1,'off');
            end
            decorAxeNum(h.axN1,'Signaux Temporels  x[n]  →  y[n]',[0.4 0.85 0.9], ...
                'Échantillon  n','Amplitude');

            % --- axN2 : Réponse en fréquence ---
            cla(h.axN2);
            if get(h.chkRepFreq,'Value')
                yyaxis(h.axN2,'left');
                plot(h.axN2,f_hz,H_dB,'Color',[1 0.6 0.2],'LineWidth',2);
                ylabel(h.axN2,'Gain (dB)','Color',[1 0.6 0.2],'FontName','Consolas','FontSize',8);
                set(h.axN2,'YColor',[1 0.6 0.2]);

                yyaxis(h.axN2,'right');
                plot(h.axN2,f_hz,H_ph,'Color',[0.4 0.8 0.9],'LineWidth',1.2,'LineStyle','--');
                ylabel(h.axN2,'Phase (°)','Color',[0.4 0.8 0.9],'FontName','Consolas','FontSize',8);
                set(h.axN2,'YColor',[0.4 0.8 0.9]);

                yyaxis(h.axN2,'left');
                hold(h.axN2,'on');
                yline(h.axN2,max(H_dB)-3,'--','Color',[1 0.3 0.3],'LineWidth',1, ...
                    'Label','-3 dB','LabelHorizontalAlignment','left','FontName','Consolas','FontSize',7);
                hold(h.axN2,'off');
                legend(h.axN2,{'|H(e^{jω})| dB','∠H(e^{jω}) °'}, ...
                    'TextColor',[0.85 0.85 0.85],'Color',[0.08 0.10 0.15], ...
                    'EdgeColor',[0.3 0.4 0.5],'FontName','Consolas','FontSize',8,'Location','southwest');
            end
            set(h.axN2,'Color',[0.06 0.08 0.12],'XColor',[0.5 0.7 0.9], ...
                'GridColor',[0.3 0.35 0.4],'XGrid','on','YGrid','on','Box','on');
            title(h.axN2,'Réponse en Fréquence  |H(e^{jω})|  &  ∠H(e^{jω})', ...
                'Color',[1 0.6 0.2],'FontName','Consolas','FontSize',9,'FontWeight','bold');
            xlabel(h.axN2,'Fréquence (Hz)','Color',[0.7 0.7 0.7],'FontName','Consolas','FontSize',8);

            % --- axN3 : Plan Z ---
            cla(h.axN3);
            if get(h.chkZeros,'Value')
                hold(h.axN3,'on');
                th=linspace(0,2*pi,300);
                % Cercle unité
                fill(h.axN3,cos(th),sin(th),[0.08 0.12 0.18],'EdgeColor',[0.35 0.45 0.55],'LineWidth',1.2,'FaceAlpha',0.5);
                % Grille radiale
                for r_g=[0.5 1.5]
                    plot(h.axN3,r_g*cos(th),r_g*sin(th),':','Color',[0.25 0.30 0.38],'LineWidth',0.6);
                end
                % Axes Im/Re
                plot(h.axN3,[-2.2 2.2],[0 0],'Color',[0.30 0.35 0.45],'LineWidth',0.9);
                plot(h.axN3,[0 0],[-2.2 2.2],'Color',[0.30 0.35 0.45],'LineWidth',0.9);
                % Zéros
                if ~isempty(z_zeros)
                    plot(h.axN3,real(z_zeros),imag(z_zeros),'o', ...
                        'MarkerSize',11,'Color',[0.25 0.95 0.55],'LineWidth',2.2,'MarkerFaceColor','none');
                end
                % Pôles
                if ~isempty(z_poles)
                    plot(h.axN3,real(z_poles),imag(z_poles),'x', ...
                        'MarkerSize',13,'Color',[1 0.35 0.35],'LineWidth',2.8);
                end
                hold(h.axN3,'off');
                axis(h.axN3,'equal');
                lim_z=max(1.6, 1.25*max([abs(z_zeros);abs(z_poles);1]));
                xlim(h.axN3,[-lim_z lim_z]); ylim(h.axN3,[-lim_z lim_z]);
                legend(h.axN3,{'Disque unité','','','','Zéros ○','Pôles ×'}, ...
                    'TextColor',[0.85 0.85 0.85],'Color',[0.08 0.10 0.15], ...
                    'EdgeColor',[0.3 0.4 0.5],'FontName','Consolas','FontSize',8,'Location','northeast');
            end
            decorAxeNum(h.axN3,'Plan Z  —  Pôles (✕)  &  Zéros (○)',[0.7 0.5 1.0], ...
                'Partie réelle','Partie imaginaire');

            % --- axN4 : Réponse impulsionnelle ---
            cla(h.axN4);
            if get(h.chkRepImp,'Value')
                stem(h.axN4,0:length(h_imp)-1,h_imp, ...
                    'Color',[0.4 0.9 0.4],'LineWidth',1.3,'MarkerSize',4, ...
                    'MarkerFaceColor',[0.4 0.9 0.4]);
            end
            decorAxeNum(h.axN4,'Réponse Impulsionnelle  h[n]',[0.4 0.9 0.4], ...
                'Échantillon  n','h[n]');

            set(h.txtCircuit,'String',lbl);
            set(h.txtInfoNum,'String',info_z,'ForegroundColor',[0.4 0.9 0.4]);

        catch ME
            set(h.txtInfoNum,'String',['❌ ' ME.message],'ForegroundColor',[1 0.3 0.3]);
        end
    end % simulerNumerique

    function reinitialiserNum(~,~)
        h = guidata(fig);
        set(h.editOrdre,'String','4'); set(h.editFe,'String','8000');
        set(h.editFc1,'String','1000'); set(h.editFc2,'String','3000');
        set(h.editNpts,'String','256');
        set(h.editRp,'String','1');  set(h.editRs,'String','40');
        set(h.popFiltreType,'Value',1); set(h.popFiltreReponse,'Value',1);
        set(h.popFenetre,'Value',1);   set(h.popSignalNum,'Value',1);
        set(h.chkRepImp,'Value',1); set(h.chkRepFreq,'Value',1);
        set(h.chkZeros,'Value',1);  set(h.chkSignalNum,'Value',1);
        cla(h.axN1); cla(h.axN2); cla(h.axN3); cla(h.axN4);
        set(h.txtInfoNum,'String','Réinitialisé.','ForegroundColor',[0.4 0.8 0.4]);
        set(h.txtCircuit,'String','Sélectionnez un filtre et appuyez sur CALCULER');
        updateFiltreParams(fig,[]);
    end

    function exporterFig(~,~)
        h  = guidata(fig);
        fn = ['simulateur_RLC_num_' datestr(now,'yyyymmdd_HHMMSS') '.png'];
        try
            exportgraphics(fig,fn,'Resolution',150);
        catch
            saveas(fig,fn);
        end
        try, set(h.txtInfo,'String',['💾 Exporté : ' fn],'ForegroundColor',[0.3 0.9 0.7]); catch; end
        try, set(h.txtInfoNum,'String',['💾 Exporté : ' fn],'ForegroundColor',[0.3 0.9 0.7]); catch; end
    end

%% =======================================================================
%%  FONCTIONS UTILITAIRES (fonctions imbriquées)
%% =======================================================================

    % Afficher/masquer les groupes d'axes selon le mode
    function setAxesVisibility(h,mode)
        anaAxes = {h.ax1, h.ax2, h.ax3};
        numAxes = {h.axN1, h.axN2, h.axN3, h.axN4};
        if strcmp(mode,'analog')
            cellfun(@(ax)set(ax,'Visible','on'), anaAxes);
            cellfun(@(ax)set(ax,'Visible','off'),numAxes);
        else
            cellfun(@(ax)set(ax,'Visible','off'),anaAxes);
            cellfun(@(ax)set(ax,'Visible','on'), numAxes);
        end
    end

    function decorAxe(ax,ttl,clr,xl,yl)
        set(ax,'Color',[0.06 0.08 0.12],'XColor',[0.5 0.7 0.9],'YColor',[0.5 0.7 0.9], ...
            'GridColor',[0.3 0.35 0.4],'XGrid','on','YGrid','on','Box','on');
        title(ax,ttl,'Color',clr,'FontName','Consolas','FontSize',9,'FontWeight','bold');
        xlabel(ax,xl,'Color',[0.7 0.7 0.7],'FontName','Consolas','FontSize',8);
        ylabel(ax,yl,'Color',[0.7 0.7 0.7],'FontName','Consolas','FontSize',8);
    end

    function decorAxeNum(ax,ttl,clr,xl,yl)
        set(ax,'Color',[0.06 0.08 0.12],'XColor',[0.5 0.7 0.9],'YColor',[0.5 0.7 0.9], ...
            'GridColor',[0.3 0.35 0.4],'XGrid','on','YGrid','on','Box','on');
        title(ax,ttl,'Color',clr,'FontName','Consolas','FontSize',9,'FontWeight','bold');
        xlabel(ax,xl,'Color',[0.7 0.7 0.7],'FontName','Consolas','FontSize',8);
        ylabel(ax,yl,'Color',[0.7 0.7 0.7],'FontName','Consolas','FontSize',8);
    end

    % Retourner 'on' ou 'off' selon valeur booléenne
    function s = onoff(v)
        if v, s='on'; else, s='off'; end
    end

    function s = onoff_str(v)
        if v, s='OUI ✓'; else, s='NON ✗ (INSTABLE!)'; end
    end

    % Clipper en [eps, 1-eps]
    function v = clip01(x)
        v = max(1e-4, min(1-1e-4, x));
    end

%% =======================================================================
%%  FONCTIONS DE CONSTRUCTION UI (sous-fonctions locales)
%% =======================================================================

    % Créer un label texte
    function h_out = mkLabel(parent,str,pos,color)
        h_out = uicontrol(parent,'Style','text','String',str, ...
            'Units','normalized','Position',pos, ...
            'FontName','Consolas','FontSize',9, ...
            'ForegroundColor',color,'BackgroundColor',[0.16 0.18 0.24], ...
            'HorizontalAlignment','left');
        if contains(str,'──')
            set(h_out,'FontWeight','bold','HorizontalAlignment','center');
        end
    end

    % Créer un champ de saisie
    function h_out = mkEdit(parent,val,pos)
        h_out = uicontrol(parent,'Style','edit','String',val, ...
            'Units','normalized','Position',pos, ...
            'FontName','Consolas','FontSize',9, ...
            'BackgroundColor',[0.22 0.26 0.34],'ForegroundColor',[1 0.85 0.3]);
    end

    % Créer une case à cocher
    function h_out = mkCheck(parent,str,pos,val,color)
        h_out = uicontrol(parent,'Style','checkbox','String',str, ...
            'Units','normalized','Position',pos,'Value',val, ...
            'FontName','Consolas','FontSize',9, ...
            'ForegroundColor',color,'BackgroundColor',[0.16 0.18 0.24]);
    end

    % Créer un axe avec le style sombre standard
    function ax = mkAxe(parent,pos)
        ax = axes(parent,'Position',pos, ...
            'Color',[0.06 0.08 0.12], ...
            'XColor',[0.5 0.7 0.9],'YColor',[0.5 0.7 0.9], ...
            'GridColor',[0.3 0.35 0.4],'GridAlpha',0.45, ...
            'FontName','Consolas','FontSize',8, ...
            'XGrid','on','YGrid','on','Box','on');
    end

end % fin de simulateur_circuit_RLC

%% =========================================================================
%%  SOUS-FONCTIONS (hors de la fonction principale)
%% =========================================================================

% Convertit les coefficients d'un polynôme en chaîne H(z^-1)
function s = poly2str_z(coeff)
    n   = length(coeff)-1;
    s   = '';
    for k=0:n
        c = coeff(k+1);
        if abs(c) < 1e-10, continue; end
        sgn = '';
        if k>0 && c>0, sgn='+'; end
        if k==0
            s = [s sprintf('%.4g',c)]; %#ok
        elseif k==1
            s = [s sprintf('%s%.4gz⁻¹',sgn,c)]; %#ok
        else
            s = [s sprintf('%s%.4gz⁻%d',sgn,c,k)]; %#ok
        end
    end
    if isempty(s), s='0'; end
end
