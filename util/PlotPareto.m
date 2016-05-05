function PlotPareto(F1, F2, rank)

global generation Setslog setno figure_handle F_bad
%-------------------------------------------------
% Plot Paretorank
%-------------------------------------------------
ran = 1e-2;
if Setslog.ploton == 0 && generation == Setslog.generations
    figure(4)
    F = [F2(rank == 0) F1(rank == 0)];
    F = sortrows(F, 1);
    plot(F(:,1), F(:,2),'--d', 'LineWidth', 2);
    xlabel('F1'); ylabel('F2');
    xlim([min(F2(rank == 0))-ran max(F2(rank == 0))+ran]);
    ylim([min(F1(rank == 0))-ran max(F1(rank == 0))+ran]); pause(0.1); hold off
    text(0.95, 0.95, [num2str(generation)], 'HorizontalAlignment', 'center', 'FontSize', 14,'Units','normalized')
elseif Setslog.ploton
    h = [figure_handle(3) figure_handle(4) figure_handle(1)];
    
    set(0,'CurrentFigure',h(1))
    plot(F2(F1 < F_bad), F1(F1 < F_bad),'b.');
    xlabel('F1'); ylabel('F2');
    
    if ~isempty([min(F2(F1 < F_bad))-ran max(F2(F1 < F_bad))+ran])
        xlim([min(F2(F1 < F_bad))-ran max(F2(F1 < F_bad))+ran]); 
        ylim([min(F1(F1 < F_bad))-ran max(F1(F1 < F_bad))+ran]); pause(0.1)
    end
    
    text(0.95, 0.95, [num2str(generation)], 'HorizontalAlignment', 'center', 'FontSize', 14,'Units','normalized')
    FinalPlotSave(h(1),'all_fronts');
    
    set(0,'CurrentFigure',h(2))
    F = [F2(rank == 0) F1(rank == 0)];
    F = sortrows(F, 1);
    plot(F(:,1), F(:,2),'-.*', 'LineWidth',1);
    xlabel('F1'); ylabel('F2');
    if ~isempty([min(F2(rank == 0))-ran max(F2(rank == 0))+ran])
        xlim([min(F2(rank == 0))-ran max(F2(rank == 0))+ran])
        ylim([min(F1(rank == 0))-ran max(F1(rank == 0))+ran]); pause(0.1)
    end
    text(0.95, 0.95, [num2str(generation)], 'HorizontalAlignment', 'center', 'FontSize', 14,'Units','normalized')
    FinalPlotSave(h(2),'front-1');
    
    set(0,'CurrentFigure',h(3))
    clf
    if ~isempty(setno)
        text(0.5, 0.8, ['Training Dataset ' num2str(setno) ': Multi Obj EvoNN'], 'HorizontalAlignment', 'center', 'FontSize', 14)
        text(0.5, 0.6, ['Generation: ' num2str(generation)], 'HorizontalAlignment', 'center', 'FontSize', 14)
        text(0.5, 0.4, ['Population: ' num2str(length(F1)) ' Prey; ' num2str(Setslog.Predator_popsize) ' Predator'], 'HorizontalAlignment', 'center', 'FontSize', 14)
        text(0.5, 0.2, ['Best fitness: ' num2str(min(F1))], 'HorizontalAlignment', 'center', 'FontSize', 14)
    else
        text(0.5, 0.6, ['Generation: ' num2str(generation)], 'HorizontalAlignment', 'center', 'FontSize', 14)
        text(0.5, 0.4, ['Population: ' num2str(length(F1)) ' Prey; ' num2str(Setslog.Predator_popsize) ' Predator'], 'HorizontalAlignment', 'center', 'FontSize', 14)
    end
    xlim([0 1]); ylim([0 1]);
    axis off
    set(h(3), 'Color', 'w')
    FinalPlotSave(h(3),'gen');
    pause(0.1)
    
end
end