mm = 1e-3;




// if armour present, the total radius of the cable is 93.5 mm, otherwise it is 79.7 mm
DefineConstant[ armour = {0, Choices{0 =" 0 : no armour",
                                     1 =" 1 : with armour"},
                        Name "Input/1Geometry/Choice armour"}];

// choice of the different thicknesses of the layers




// choice if defect in the insulant layer or not
DefineConstant[ defect = {0, Highlight "Red", Choices{0=" 0 : no defect",
                                     1 =" 1 : with defect"},
                        Name "Input/1Geometry/Choice defect in the insulant layer"}];


DefineConstant[ defect_size = {0.5*mm, Highlight "Red", Name "Input/1Geometry/Size of the defect in the insulant layer", Visible (defect == 1)}, 
                defect_place = { 45, Highlight "Red", Name "Input/1Geometry/Place of the defect in the insulant layer (angle in degree)", Visible (defect == 1)},
                defect_depth = { 2*mm, Highlight "Red", Name "Input/1Geometry/Depth of the defect in the insulant layer (angle in degree)", Visible (defect == 1)}];


DefineConstant[ t_cond = {4*mm, Name "Input/1Geometry/wires/Thickness of the central conductor"}];
DefineConstant[ t_semi1 = {0.5*mm, Name "Input/1Geometry/wires/Thickness of semicond layer 1"}]; // choix pour que ça rentre dans le diametre du cable
DefineConstant[ t_isolant_alone = {10.5*mm, Name "Input/1Geometry/wires/Thickness of the isolant layer alone"}];
DefineConstant[ t_semi2 = {0.5*mm, Name "Input/1Geometry/wires/Thickness of semicond layer 2"}];
DefineConstant[ t_metal_screen_alone = {0.17*mm, Name "Input/1Geometry/wires/Thickness of the metal screen alone"}];

DefineConstant[dist_cab = {32*mm, Name "Input/1Geometry/cable/Distance between conductors"}];

If (armour == 0)
    
DefineConstant[R_Tot = {39.85*mm, Name "Input/1Geometry/cable/(no armour) Total radius of the cable", Visible (armour != 1)}];
DefineConstant[t_sheath_out = {3.4*mm, Name "Input/1Geometry/cable/(no armour) Thickness of the sheath layer outside", Visible (armour != 1)}];
DefineConstant[ t_binder = {1.9*mm, Name "Input/1Geometry/cable/(no armour) Thickness of binder layer", Visible (armour != 1)}];
EndIf

If (armour == 1)
DefineConstant[R_Tot = {46.75*mm, Name "Input/1Geometry/cable/(armour) Total radius of the cable", Visible (armour == 1)}];
DefineConstant[t_sheath_out = {4*mm, Name "Input/1Geometry/cable/(armour) Thickness of the sheath layer outside", Visible (armour == 1)}];
DefineConstant[t_armour = {3.5*mm, Name "Input/1Geometry/cable/(armour) Thickness of the armour", Visible (armour == 1)}];
DefineConstant[t_sheath_in = {1.9*mm, Name "Input/1Geometry/cable/(armour) Thickness of the sheath layer inside", Visible (armour == 1)}];
DefineConstant[ t_binder = {1.9*mm, Name "Input/1Geometry/cable/(armour) Thickness of binder layer", Visible (armour == 1)}];
  
EndIf

DefineConstant[dinf = {5*R_Tot, Name "Input/1Geometry/cable/Outside boundary"}];

