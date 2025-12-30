function [indic_opp,indic_att, indic_hom] = classifier_mp_events(mps)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to classify the MP announcements from a Central Bank following
% the classification proposed by HHL between HOM, Attenuation and events
% with opposite Target/Path 
%
% Inputs:
% - mps: table containing Target and Path factors from Gurkaynak et al
%
% Output:
% - indic_opp: dummy variable indicating whether path and factors have
% opposite signs
% - indic_att: dummy variable indicating whether target is larger than path
% when both have opposite sign (attennuation)
% - indic_hom: dummy variable indicating whether path is larger than target
% when both have opposite sign (hom)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Product of path and target factor
    opp_announcements = mps.Target.*mps.Path;
    indic_opp = opp_announcements < 0;

    % Computation of a dummy for attenuation event
    indic_att = (abs(mps.Path) < abs(mps.Target)) & (indic_opp == 1);

    % Computation of a dummy for hom event
    indic_hom = (abs(mps.Path) >= abs(mps.Target)) & (indic_opp == 1);
end

