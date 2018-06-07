function plot_robot3(x,y,z,H1_0,H2_0,H3_0,bH1_0,bH2_0,bH3_0)
%~ishandle(h)

persistent figureHandlers;

    if (isempty(figureHandlers)) %1 ~= figureHandlers{1})
        figureHandlers = {};
        figureHandlers{1}=1;
        figureHandlers{2} = figure(1);
        hold off;
        plot3(0,0,0,'*g'), hold on;
        xlabel('x'), ylabel('y'), zlabel('z')
        %title(gca, ['(X,Y,Z) = (', num2str(x), ', ',num2str(y),', ',num2str(z) ')']);
        grid on
        axis([-25 25 -25 25 0 25])

        figureHandlers{3}=plot3([25 x x x x x],[y y 25 y y y],[z z z z 0 z],'r');
        figureHandlers{4}=plot3(x,y,z,'*b');
        figureHandlers{5}=plot3([H1_0(1,4) H2_0(1,4)],[H1_0(2,4) H2_0(2,4)],[H1_0(3,4) H2_0(3,4)],'b','linewidth',5);
        figureHandlers{6}=plot3([H2_0(1,4) H3_0(1,4)],[H2_0(2,4) H3_0(2,4)],[H2_0(3,4) H3_0(3,4)],'b','linewidth',5);

        figureHandlers{7}=plot3([bH1_0(1,4) bH2_0(1,4)],[bH1_0(2,4) bH2_0(2,4)],[bH1_0(3,4) bH2_0(3,4)],'r','linewidth',5);
        figureHandlers{8}=plot3([bH2_0(1,4) bH3_0(1,4)],[bH2_0(2,4) bH3_0(2,4)],[bH2_0(3,4) bH3_0(3,4)],'r','linewidth',5);
        hold off
        drawnow
        disp('init');
        return;
    end

    figureHandlers{3}.XData = [25 x x x x x];
    figureHandlers{3}.YData = [y y 25 y y y];
    figureHandlers{3}.ZData = [z z z z 0 z];

    figureHandlers{4}.XData = x;
    figureHandlers{4}.YData = y;
    figureHandlers{4}.ZData = z;

    figureHandlers{5}.XData = [H1_0(1,4) H2_0(1,4)];
    figureHandlers{5}.YData = [H1_0(2,4) H2_0(2,4)];
    figureHandlers{5}.ZData = [H1_0(3,4) H2_0(3,4)];

    figureHandlers{6}.XData = [H2_0(1,4) H3_0(1,4)];
    figureHandlers{6}.YData = [H2_0(2,4) H3_0(2,4)];
    figureHandlers{6}.ZData = [H2_0(3,4) H3_0(3,4)];

    figureHandlers{7}.XData = [bH1_0(1,4) bH2_0(1,4)];
    figureHandlers{7}.YData = [bH1_0(2,4) bH2_0(2,4)];
    figureHandlers{7}.ZData = [bH1_0(3,4) bH2_0(3,4)];

    figureHandlers{8}.XData = [bH2_0(1,4) bH3_0(1,4)];
    figureHandlers{8}.YData = [bH2_0(2,4) bH3_0(2,4)];
    figureHandlers{8}.ZData = [bH2_0(3,4) bH3_0(3,4)];
    drawnow
end
