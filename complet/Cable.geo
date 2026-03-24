//=================================================
// Geometrical data
//=================================================
Include "Cable_data.pro";
SetFactory("OpenCASCADE");

mm = 1e-3;

t_semi1 = t_cond + t_semi1; // choix
t_isolant = t_semi1 + t_isolant_alone;
t_semi2 = t_isolant + t_semi2;// choix
t_metal_screen = t_semi2 + t_metal_screen_alone;


r_sheath_out = R_Tot;
r_binder = r_sheath_out - t_sheath_out;
r_filler = r_binder - t_binder;  // choix


If(armour == 1)
    r_sheath_out = R_Tot;
    r_armor = r_sheath_out - t_sheath_out; // en plus 
    r_sheath_in = r_armor - t_armour; // en plus 
    r_binder = r_sheath_in - t_sheath_in;
    r_filler = r_binder - t_binder;  // choix
EndIf

h = dist_cab * Sin(Pi/3); // height of equilateral triangle


dinf = 5*R_Tot; // Electromagnetic analysis

//=================================================

Function wire
    
    Disk(news) = {x0, y0, 0, t_cond};
    Disk(news) = {x0, y0, 0, t_semi1};
    Disk(news) = {x0, y0, 0, t_isolant};
    Disk(news) = {x0, y0, 0, t_semi2};
    Disk(news) = {x0, y0, 0, t_metal_screen};
    If(defect == 1 && x0 == 0)
        centre = newp; Point(centre) = {x0, y0, 0};
        angle = defect_place * Pi/180;
        point1 = newp; Point(point1) = {t_semi1*( Cos(angle)), (y0 - t_semi1*Sin(angle)), 0};
        point2 = newp; Point(point2) = {t_isolant*( Cos(angle)), (y0 - t_isolant*Sin(angle)), 0};
        theta1 = angle + defect_size/t_semi1;
        point3 = newp; Point(point3) = {t_semi1*( Cos(theta1)), (y0 - t_semi1*Sin(theta1)), 0};
        theta2 = angle + defect_size/t_semi1;
        point4 = newp; Point(point4) = {t_isolant*( Cos(theta2)), (y0 - t_isolant*Sin(theta2)), 0};

        line12 = newl; Line(line12) = {point1, point2};
        circle24 = newc; Circle(circle24) = {point2, centre, point4};
        circle13 = newc; Circle(circle13) = {point1, centre, point3};
        line34 = newl; Line(line34) = {point3, point4};

        l1 = newl; Curve Loop(l1) = {circle13, line34, -circle24, -line12};
        surf1 = news; Plane Surface(surf1) = {l1};
    EndIf
Return

//wire cables
x0 = 0; y0 = 2*h/3;

Call wire;
x0 = -dist_cab/2; y0 = -h/3;
Call wire;
x0 =  dist_cab/2; y0 = -h/3;
Call wire;

Disk(news) = {0., 0., 0., r_filler};

Disk(news) = {0., 0., 0., r_binder};
If(armour == 1)
    Disk(news) = {0., 0., 0., r_sheath_in};

    Disk(news) = {0., 0., 0., r_armor};
EndIf
Disk(news) = {0., 0., 0., r_sheath_out};

Disk(news) = {0., 0., 0., dinf};
// limit semicond material


// Intersect all surfaces (== Surface{:}) created till here
// and delete those that are destroyed
out() = BooleanFragments{Surface{:}; Delete;}{};
If(defect == 1)
    union() = BooleanUnion{Surface{out(1)}; Delete;}{Surface{out(3)}; Delete;};
    union2() = BooleanUnion{Surface{union(0)}; Delete;}{Surface{out(4)}; Delete;};
    
EndIf




// ===========================================
// Physical regions => link to pro-file and FE
// ===========================================

Physical Surface("wire 1", 11) = out(0);
Physical Surface("insolating wire 1", 13) = out(2);
Physical Surface("metallic screen wire 1", 15) = out(4+defect);
If(defect == 0)
    Physical Surface("semi1 wire 1", 12) = out(1);
    Physical Surface("semi2 wire 1", 14) = out(3);
EndIf
If(defect ==1) 
    Physical Surface("semi fusion wire 1", 12) = union2(0);
EndIf

Physical Surface("wire 2", 21) = out(5+defect);
Physical Surface("semi1 wire 2", 22) = out(6+defect);
Physical Surface("insolating wire 2", 23) = out(7+defect);
Physical Surface("semi2 wire 2", 24) = out(8+defect);
Physical Surface("metallic screen wire 2", 25) = out(9+defect);

Physical Surface("wire 3", 31) = out(10+defect);
Physical Surface("semi1 wire 3", 32) = out(11+defect);
Physical Surface("insolating wire 3", 33) = out(12+defect);
Physical Surface("semi2 wire 3", 34) = out(13+defect);
Physical Surface("metallic screen wire 3", 35) = out(14+defect);

    
Physical Surface("filler", 41) = out(15+defect);
Physical Surface("binder", 42) = out(16+defect);
If(armour == 1)
    Physical Surface("steel sheath inner", 43) = out(17+defect);
    
    Physical Surface("steel armor", 44) = out(18+defect);
EndIf
Physical Surface("steel sheath outer", 45) = out(#out()-2);


Physical Surface("ground", 50) = out(#out()-1);

Physical Line("bnd wire 1", 110) = Boundary{Surface{out(0)};};
Physical Line("bnd wire 2", 120) = Boundary{Surface{out(5+defect)};};
Physical Line("bnd wire 3", 130) = Boundary{Surface{out(10+defect)};};


test = Boundary{Surface{out(#out()-1)};};
Physical Line("bnd ground", 140) = test(1);
Physical Line("Outer boundary", 60) = test(0);



// Adjusting some characteristic lengths

DefineConstant[ cl = {R_Tot, Name "Mesh size", Visible 1} ];
// Exemple field dans gmsh
// The order of the following instructions may influence the result of the mesh
// If you have surfaces that have common lines and therefore points, then the last instruction prevails
If(armour == 0) 
    MeshSize { PointsOf{ Surface{ out(#out()-1)}; } } = cl;
    MeshSize { PointsOf{ Surface{out(15+defect),out(16+defect), out(#out()-2), out(#out()-1)}; } } = cl/16;
    
EndIf
If(armour == 1) 
    MeshSize { PointsOf{ Surface{ out(#out()-1)}; } } = cl;
    MeshSize { PointsOf{ Surface{out(15+defect),out(16+defect), out(17+defect), out(18+defect), out(#out()-2), out(#out()-1) }; } } = cl/16;
    
EndIf

If(defect == 0)
    MeshSize { PointsOf{ Surface{out(0), out(1), out(2), out(4), out(5), out(6), out(7), out(9), out(10), out(11), 
                                out(12), out(14)}; } } = cl/16;

    
EndIf

If(defect == 1)
    MeshSize { PointsOf{ Surface{out(0), union2(0), out(2), out(4+defect), out(5+defect), out(6+defect), out(7+defect), out(8+defect), out(9+defect), out(10+defect), out(11+defect), out(12+defect), out(13+defect), out(14+defect)}; } } = cl/16;
EndIf


MeshSize { PointsOf{ Physical Line{60};} } = cl; // outer boundary of EMdom
MeshSize { PointsOf{  Surface{out(4+defect), out(9+defect), out(14+defect), out(3), out(8), out(13)}; } } = cl/32;
//Recombine Surface{out(4+defect), out(9+defect), out(14+defect)}; // to have quadrangles in the outer domain

/*
// Some colours, just for aesthetics...
// You may use elementary geometrical or physical entities
Recursive Color Cyan {Physical Surface{40};}
Recursive Color Green {Physical Surface{30};}
Recursive Color Gold {Physical Surface{20};}
Recursive Color Red {Physical Surface{11,12,13};}

*/
