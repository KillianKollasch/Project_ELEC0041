Include "Cable_data.pro";

DefineConstant[
  Flag_AnalysisType = {3,
    Choices{
      0 = "Electrodynamic",
      1 = "Magnetoquasistatic",
      2 = "Magneto-thermal",
      3 = "Magneto-Thermal_non_lin"
    },
    Name "{00FE param./Type of analysis", Highlight "ForestGreen",
    ServerAction Str["Reset", StrCat[ "GetDP/1ResolutionChoices", ",", "GetDP/2PostOperationChoices"]] }
];





Function{
  Resolution_name() = Str['Electrodynamics', 'Magnetoquasistatics', 'Magnetothermal', 'MagnetoThermalCoupling'];
  PostOperation_name() = Str['Post_Ele', 'Post_Mag', 'Post_MagTher', ' Post_MagTher_non_lin'];
}

DefineConstant[
  r_ = {Str[Resolution_name(Flag_AnalysisType)], Name "GetDP/1ResolutionChoices"}
  c_ = {"-solve -v2 -pos", Name "GetDP/9ComputeCommand"},
  p_ = {Str[PostOperation_name(Flag_AnalysisType)], Name "GetDP/2PostOperationChoices"}
];

Group {
  
  Ind_1 = Region[ 11 ];
  Ind_2 = Region[ 21 ];
  Ind_3 = Region[ 31 ];

  Semiconductor = Region[{12, 22, 24, 32, 34} ];
  Copper = Region[{25, 35, 15}];

  Insolating_XLPE = Region[{13, 23, 33 }];

  Insolating_PP = Region[41];
  Insolating_PET = Region[42];

  Insolating_PVC = Region[45];
  Ground = Region[50];


  Semiconductor += Region[14];
  If(defect == 1)
    Air = Region[4];
  EndIf
  
  If (armour == 1)
      SteelPipe += Region[44];
      Insolating_PVC += Region[43];
  Else
      SteelPipe += Region[{}];
  EndIf

  // electrodynamics
  Sur_Dirichlet_Ele = Region[{60}];
  Domain_Ele = Region[ {Ground, SteelPipe, Semiconductor, Ind_1, Ind_2, Ind_3, Copper, Insolating_PET, Insolating_PVC, Insolating_XLPE, Insolating_PP} ];
  
  // Magnetoquasistatics
  Sur_Dirichlet_Mag = Region[{60}];
  DomainS_Mag       = Region[{Ind_1, Ind_2, Ind_3}];

  DomainNC_Mag  = Region[ {Ground, Semiconductor, Ind_1, Ind_2, Ind_3, Insolating_PET, Insolating_PP, Insolating_PVC, Insolating_XLPE} ]; // non-conducting regions
  DomainC_Mag   = Region[ {SteelPipe, Copper} ]; //conducting regions
  Domain_Mag = Region[ {DomainNC_Mag, DomainC_Mag} ];
  
  Domain_tot = Region[{Ground, SteelPipe, Semiconductor, Ind_1, Ind_2, Ind_3, Copper, Insolating_PET, Insolating_PVC, Insolating_XLPE, Insolating_PP}];
  If(defect == 1)
    Domain_tot += Region[Air];
    Domain_Ele += Region[Air];
    Domain_Mag += Region[Air];
  EndIf
  DomainDummy = Region[1234]; //postpro

  Conductor = Region[{SteelPipe, Copper, Ind_1, Ind_2, Ind_3}];
  Semi = Region[{Semiconductor}];
  Conductor_screen = Region[{Copper}];
  Insolating = Region[{Insolating_PET, Insolating_PVC, Insolating_XLPE, Insolating_PP}];
}

Function {
  mu0 = 4.e-7 * Pi;
  eps0 = 8.854187818e-12;
  mur_steel = 4;

  
  sigma[Semiconductor] = 2; // note Louis, useless as not conducting
  sigma[Ground] = 28; 
  sigma[Region[{Insolating_PET, Insolating_PP, Insolating_PVC, Insolating_XLPE}]] = 1e-6; // 1e-6 semble bien ou 1e-5 ? 
  
  If(Flag_AnalysisType == 3)
    sigma[Copper] = 5.99e7/(1 + 0.00386*($1 - 20));
    sigma[SteelPipe] = 4.7e6/(1 + 0.00386*($1 - 20));
    sigma[DomainS_Mag] = 5.99e7/(1 + 0.00386*($1 - 20));
  Else
    sigma[Copper] = 5.99e7;
    sigma[SteelPipe] = 4.7e6;
    sigma[DomainS_Mag] = 5.99e7;
  EndIf

  epsilon[Region[{Ground, SteelPipe, Ind_1, Ind_2, Ind_3, Copper, Insolating_PET, Insolating_PP, Insolating_PVC, Insolating_XLPE}]] = eps0;
  epsilon[Semiconductor] = eps0*2.25;

  nu[Region[{Ground, Semiconductor, Ind_1, Ind_2, Ind_3, Insolating_PET, Insolating_PP, Insolating_PVC, Insolating_XLPE, Copper}]]  = 1./mu0;
  nu[Region[{SteelPipe}]]  = 1./(mu0*mur_steel);
  If(defect == 1 )
      sigma[Air] = 1e-6; 
      epsilon[Air] = eps0; 
      nu[Air] = 1./mu0;
  EndIf

    DefineConstant[
    Freq = {50, Min 1, Max 10000, Step 1,
      Name "Parameters/frequency [Hz]"}];
 
  
  Omega = 2*Pi*Freq;

  Pa = 0.; Pb = -120./180.*Pi; Pc = -240./180.*Pi;
  I = 406; // maximum value current in data sheet
  Vrms = 42e3; // RMS value in the line voltage [V]
  V0 = Vrms/Sqrt[3]; // peak value

  Ns[]= 1;
  Sc[]= SurfaceArea[];
}

Constraint {
  // Electrical constraints
  { Name ElectricScalarPotential;
    Case {
      { Region Ind_1; Value V0; TimeFunction F_Cos_wt_p[]{2*Pi*Freq, Pa}; }
      { Region Ind_2; Value V0; TimeFunction F_Cos_wt_p[]{2*Pi*Freq, Pb}; }
      { Region Ind_3; Value V0; TimeFunction F_Cos_wt_p[]{2*Pi*Freq, Pc}; }

      { Region Sur_Dirichlet_Ele; Value 0; }
    }
  }

  // Magnetic constraints
  { Name MagneticVectorPotential;
    Case {
      { Region Sur_Dirichlet_Mag; Value 0.; }
    }
  }

  { Name Voltage;
    Case {
    }
  }

  { Name Current;
    Case {
      { Region Ind_1; Value I; TimeFunction F_Cos_wt_p[]{2*Pi*Freq, Pa}; }
      { Region Ind_2; Value I; TimeFunction F_Cos_wt_p[]{2*Pi*Freq, Pb}; }
      { Region Ind_3; Value I; TimeFunction F_Cos_wt_p[]{2*Pi*Freq, Pc}; }
    }
  }

}

//---------------------------------------------------------------------

Jacobian {
  { Name Vol;
    Case {
      { Region All; Jacobian Vol; }
    }
  }
  { Name Sur;
    Case {
      { Region All; Jacobian Sur; }
    }
  }
}
Integration {
  { Name I1;
    Case {
      { Type Gauss;
        Case {
          { GeoElement Triangle;   NumberOfPoints  4; }
          { GeoElement Quadrangle; NumberOfPoints  4; }
        }
      }
    }
  }
}




//--------------------------------------------------------------------------
If (Flag_AnalysisType == 0)
  // Electrodynamics
  //------------------------------------------------------------------------

  FunctionSpace {

    { Name Hgrad_v_Ele; Type Form0;
      BasisFunction { // v = \sum_n v_n  s_n,  for all nodes
        { Name sn; NameOfCoef vn; Function BF_Node;
          Support Domain_Ele; Entity NodesOf[ All ]; }
      }

      Constraint {
        { NameOfCoef vn; EntityType NodesOf;
          NameOfConstraint ElectricScalarPotential; }
      }
    }

  }

  Formulation {

    { Name Electrodynamics_v; Type FemEquation;
      Quantity {
        { Name v; Type Local; NameOfSpace Hgrad_v_Ele; }
      }
      Equation {
        Galerkin { [ sigma[] * Dof{d v} , {d v} ] ;
          In Domain_Ele; Jacobian Vol ; Integration I1 ; }
        Galerkin { DtDof[ epsilon[] * Dof{d v} , {d v} ];
          In Domain_Ele; Jacobian Vol; Integration I1; }
      }
    }

  }

  Resolution {

    { Name Electrodynamics;
      System {
        { Name Sys_Ele; NameOfFormulation Electrodynamics_v;
          Type Complex; Frequency Freq; }
      }
      Operation {
        CreateDir["res"];
        Generate[Sys_Ele]; Solve[Sys_Ele]; SaveSolution[Sys_Ele];
      }
    }

  }

  PostProcessing {

    { Name EleDyn_v; NameOfFormulation Electrodynamics_v;
      Quantity {
        { Name v; Value { Term { [ {v} ]; In Domain_Ele; Jacobian Vol; } } }
        { Name e; Value { Term { [ -{d v} ]; In Domain_Ele; Jacobian Vol; } } }
        { Name norm_e; Value { Term { [ Norm[-{d v}] ]; In Domain_Ele; Jacobian Vol; } } }

        { Name d; Value { Term { [ -epsilon[] * {d v} ]; In Domain_Ele; Jacobian Vol; } } }
        { Name norm_d; Value { Term { [ Norm[-epsilon[] * {d v}] ]; In Domain_Ele; Jacobian Vol; } } }

        { Name j ; Value { Term { [ -sigma[] * {d v} ] ; In Domain_Ele ; Jacobian Vol; } } }
        { Name Ix ; Value { Integral { [ CompX[-sigma[] * {d v}] ] ; In Domain_Ele ; Jacobian Vol; Integration I1 ;} } }
        { Name Iy ; Value { Integral { [ CompY[-sigma[] * {d v}] ] ; In Domain_Ele ; Jacobian Vol; Integration I1 ;} } }
        { Name j_dis ; Value { Term { [ Complex[0, 1]*Omega*(-epsilon[] * {d v}) ] ; In Domain_Ele ; Jacobian Vol; } } }

        { Name j_all ; Value { Term { [ -sigma[] * {d v} + Complex[0, 1]*Omega*(-epsilon[] * {d v})] ; In Domain_Ele ; Jacobian Vol; } } }
        { Name norm_j ; Value { Term { [ Norm[-sigma[] * {d v}] ] ; In Domain_Ele ; Jacobian Vol; } } }

        { Name ElectricEnergy; Value {
            Integral {
              [ 0.5 * epsilon[] * SquNorm[{d v}] ];
              In Domain_Ele; Jacobian Vol; Integration I1;
            }
          }
        }

        { Name V0 ; Value {// For recovering the imposed voltage in post-pro
            Term { Type Global ; [ V0 * F_Cos_wt_p[]{2*Pi*Freq, Pa}] ; In Ind_1 ; }
          } }

        { Name C_from_Energy ; Value { Term { Type Global; [ 2*$We/SquNorm[$voltage] ] ; In DomainDummy ; } } }
      }
    }
  }

  PostOperation{

  { Name Post_Ele; NameOfPostProcessing EleDyn_v;
    Operation {
      Print[ v,  OnElementsOf Domain_Ele, File "res/v.pos" ];
      Print[ norm_e, OnElementsOf Domain_Ele, Name "|E| [V/m]",  File "res/em.pos" ]; // Name is not compulsory, it may be adapted
      Print[ norm_d, OnElementsOf Domain_Ele, Name "|D| [A/mÂ²]", File "res/dm.pos" ];
      Print[ e,  OnElementsOf Domain_Ele, Name "E [V/m]",  File "res/e.pos" ];
      Print[ d,  OnElementsOf Domain_Ele, Name "D [A/mÂ²]",  File "res/d.pos" ];
      Print[ j,  OnElementsOf Domain_Ele, Name "J [A/m²]",  File "res/j.pos" ];
      //Print[ j,  OnElementsOf Insolating_PP, Name "J2 [A/m²]",  File "res/j2.pos" ];
      Print[ j_dis,  OnElementsOf Domain_Ele, Name "J Displacement [A/m²]",  File "res/j_dis.pos" ];
      Print[ j_all,  OnElementsOf Domain_Ele, Name "J All (cond + displa) [A/m²]",  File "res/j_all.pos" ];

      Print[ ElectricEnergy[Domain_Ele], OnGlobal, Format Table, StoreInVariable $We,
        SendToServer "{01Global ELE results/0Electric energy", File > "res/energy.dat" ];
      Print[ V0, OnRegion Ind_1, Format Table, StoreInVariable $voltage,
        SendToServer "{01Global ELE results/0Voltage", Units "V", File > "res/U.dat" ];
      Print[ C_from_Energy, OnRegion DomainDummy, Format Table, StoreInVariable $C1,
        SendToServer "{01Global ELE results/1Capacitance", Units "F/m", File > "res/C.dat" ];
      Print[ Ix, OnRegion Domain_Ele, Format Table, StoreInVariable $Ix,
        SendToServer "{01Global ELE results/1Current x", Units "A/m", File > "res/Ix.dat" ];
        Print[ Iy, OnRegion Domain_Ele, Format Table, StoreInVariable $Iy,
        SendToServer "{01Global ELE results/1Current y", Units "A/m", File > "res/Iy.dat" ];
    }
  }
}
EndIf

//--------------------------------------------------------------------------
If (Flag_AnalysisType > 0)
  // Magnetoquasistatics
  //------------------------------------------------------------------------
  FunctionSpace {

    { Name Hcurl_a_Mag_2D; Type Form1P;
      BasisFunction {
        { Name se; NameOfCoef ae; Function BF_PerpendicularEdge;
          Support Domain_Mag; Entity NodesOf[ All ]; }
      }
      Constraint {
        { NameOfCoef ae;
          EntityType NodesOf; NameOfConstraint MagneticVectorPotential ; }
      }
    }

    { Name Hregion_i_2D ; Type Vector ;
      BasisFunction {
        { Name sr ; NameOfCoef ir ; Function BF_RegionZ ;
          Support DomainS_Mag ; Entity DomainS_Mag ; }
      }
      GlobalQuantity {
        { Name Is ; Type AliasOf        ; NameOfCoef ir ; }
        { Name Us ; Type AssociatedWith ; NameOfCoef ir ; }
      }
      Constraint {
        { NameOfCoef Us ; EntityType Region ; NameOfConstraint Voltage ; }
        { NameOfCoef Is ; EntityType Region ; NameOfConstraint Current ; }
      }
    }
  }

  Formulation {

      { Name MQS_a_2D; Type FemEquation; // Magnetoquasistatics
        Quantity {
          { Name a;  Type Local; NameOfSpace Hcurl_a_Mag_2D; }

          // stranded conductors (source)
          { Name ir ; Type Local  ; NameOfSpace Hregion_i_2D ; }
          { Name Us ; Type Global ; NameOfSpace Hregion_i_2D[Us] ; }
          { Name Is ; Type Global ; NameOfSpace Hregion_i_2D[Is] ; }
        }

        Equation {
          Galerkin { [ nu[] * Dof{d a} , {d a} ];
            In Domain_Mag; Jacobian Vol; Integration I1; }
          
          Galerkin { DtDof [ sigma[] * Dof{a} , {a} ];
            In DomainC_Mag; Jacobian Vol; Integration I1; }

          // or you use the constraints => allows accounting for sigma[]
          Galerkin { [ -Ns[]/Sc[] * Dof{ir}, {a} ] ;
            In DomainS_Mag ; Jacobian Vol ; Integration I1 ; }
          Galerkin { DtDof [ Ns[]/Sc[] * Dof{a}, {ir} ] ;
            In DomainS_Mag ; Jacobian Vol ; Integration I1 ; }

          Galerkin { [ Ns[]/Sc[] / sigma[] * Ns[]/Sc[]* Dof{ir} , {ir} ] ; // resistance term
            In DomainS_Mag ; Jacobian Vol ; Integration I1 ; }
          //GlobalTerm { [ Rdc * Dof{Is} , {Is} ] ; In DomainS ; } // OR this resitance term
          GlobalTerm { [ Dof{Us}, {Is} ] ; In DomainS_Mag ; }
        }
      }

    }


    Resolution {

      { Name Magnetoquasistatics;
        System {
          { Name Sys_Mag; NameOfFormulation MQS_a_2D;
            Type Complex; Frequency Freq; }
        }
        Operation {
          CreateDir["res"];

          InitSolution[Sys_Mag];
          Generate[Sys_Mag]; Solve[Sys_Mag]; SaveSolution[Sys_Mag];
        }
      }

    }

    PostProcessing {

      { Name MQS_a_2D; NameOfFormulation MQS_a_2D;
        PostQuantity {
          { Name a; Value { Term { [ {a} ]; In Domain_Mag; Jacobian Vol; } } }
          { Name az; Value { Term { [ CompZ[{a}] ]; In Domain_Mag; Jacobian Vol; } } }
          { Name b; Value { Term { [ {d a} ]; In Domain_Mag; Jacobian Vol; } } }
          { Name norm_b; Value { Term { [ Norm[{d a}] ]; In Domain_Mag; Jacobian Vol; } } }

          { Name j; Value {
              Term { [ -sigma[]*Dt[{a}]]; In DomainC_Mag; Jacobian Vol; }
              Term { [ Ns[]/Sc[]*{ir} ]; In DomainS_Mag; Jacobian Vol; }
            } }

          { Name jz; Value {
              Term { [ CompZ[-sigma[]*Dt[{a}]] ]; In DomainC_Mag; Jacobian Vol; }
              Term { [ CompZ[ Ns[]/Sc[]*{ir} ]]; In DomainS_Mag; Jacobian Vol; }
            } }

          { Name norm_j; Value {
              Term { [ Norm[-sigma[]*Dt[{a}]] ]; In DomainC_Mag; Jacobian Vol; }
              Term { [ Norm[ Ns[]/Sc[]*{ir} ]]; In DomainS_Mag; Jacobian Vol; }
            } }

          { Name local_losses; Value {
              Term { [ 0.5*sigma[]*SquNorm[Dt[{a}]] ]; In DomainC_Mag; Jacobian Vol; }
              Term { [ 0.5/sigma[]*SquNorm[Ns[]/Sc[]*{ir}] ]; In DomainS_Mag; Jacobian Vol; }
            }
          }

          { Name global_losses; Value {
              Integral { [ 0.5*sigma[]*SquNorm[Dt[{a}]] ]   ; In DomainC_Mag  ; Jacobian Vol ; Integration I1 ; }
              Integral { [ 0.5/sigma[]*SquNorm[Ns[]/Sc[]*{ir}] ] ; In DomainS_Mag  ; Jacobian Vol ; Integration I1 ; }
            }
          }

          { Name U ; Value {
              Term { [ {Us} ] ; In DomainS_Mag ; }
            }
          }

          { Name I ; Value {
              Term { [ {Is} ] ; In DomainS_Mag ; }
            }
          }

          { Name R ; Value {
              Term { [ -Re[{Us}/{Is}] ] ; In DomainS_Mag ; }
            }
          }

          { Name L ; Value {
              Term { [ -Im[{Us}/{Is}]/(2*Pi*Freq) ] ; In DomainS_Mag ; }
            }
          }
          { Name MagneticEnergy; Value {
              Integral {
                [ 0.5 * nu[] * SquNorm[{d a}] ];
                In Domain_Mag; Jacobian Vol; Integration I1;
              }
            }
          }
          { Name I0 ; Value {// For recovering the imposed current in post-pro
              Term { Type Global ; [ I * F_Cos_wt_p[]{2*Pi*Freq, Pa}] ; In Ind_1 ; }
            } 
          }

          { Name L_from_Energy ; Value { Term { Type Global; [ 2*$Wm/SquNorm[$current] ] ; In DomainDummy ; } } }
        }
      }

    }


    PostOperation{
      // Magnetic
      //-------------------------------

      { Name Post_Mag; NameOfPostProcessing MQS_a_2D;
        Operation {
          // local results
          Print[ az, OnElementsOf Domain_Mag,
            Name "flux lines: Az [T m]", File "res/az.pos" ];
          Print[ b, OnElementsOf Domain_Mag,
            Name "B [T]", File "res/b.pos" ];
          Print[ norm_b , OnElementsOf Domain_Mag,
            Name "|B| [T]", File "res/bm.pos" ];
          Print[ jz , OnElementsOf Region[{DomainC_Mag}],
            Name "jz [A/m^2]", File "res/jz_inds.pos" ];
          Print[ norm_j , OnElementsOf DomainC_Mag,
            Name "|j| [A/m^2]", File "res/jm.pos" ];

          // global results
          Print[ global_losses[DomainC_Mag], OnGlobal, Format Table,
            SendToServer "{01Global MAG results/0Losses conducting domain",
            Units "W/m", File > "res/losses_total.dat" ];

          Print[ global_losses[DomainS_Mag], OnGlobal, Format Table,
            SendToServer "{01Global MAG results/0Losses source",
            Units "W/m", File > "res/losses_inds.dat" ];
          Print[ R, OnRegion Ind_1, Format Table,
            SendToServer "{01Global MAG results/1Resistance", Units "Î©/m", File > "res/Rinds.dat" ];
          Print[ L, OnRegion Ind_1, Format Table,
            SendToServer "{01Global MAG results/2Inductance", Units "H/m", File > "res/Linds.dat" ];

          Print[ MagneticEnergy[Domain_Mag], OnGlobal, Format Table, StoreInVariable $Wm,
            SendToServer "{01Global MAG results/3Magnetic energy", File > "res/MagEnergy.dat" ];
          Print[ I0, OnRegion Ind_1, Format Table, StoreInVariable $current,
            SendToServer "{01Global MAG results/4Current", Units "I", File > "res/I.dat" ];
          Print[ L_from_Energy, OnRegion DomainDummy, Format Table, StoreInVariable $L1,
            SendToServer "{01Global MAG results/5Inductance from energy", Units "H/m", File > "res/L.dat" ];
        }
      }

    }

EndIf


If (Flag_AnalysisType ==2)

  Group{
    bnd_ground = Region[{140}];
    outer_boundary = Region[{60}];
    Tot = Region[1234];

  }

  Function {
    mu0 = 4.e-7 * Pi;
    eps0 = 8.854187818e-12;
    mur_steel = 4;

    k[SteelPipe] = 50.2;
    k[Semiconductor] = 10; // note Louis, useless as not conducting
    k[Ground] = 0.4; // note Louis, useless as not conducting
    k[Region[{Insolating_PET, Insolating_PP, Insolating_PVC, Insolating_XLPE}]] = 0.46; // note Louis, useless as not conducting
    k[Region[{Ind_1, Ind_2, Ind_3, Copper}]] = 400;

    If(defect == 1)
      k[Air] = 0.02;
    EndIf
  }

  Constraint {
    // These constraints will be invoked in the function space definition.
    // 1) Dirichlet boundary condition
    { Name T_dirichlet ;
      Case {
        { Region outer_boundary ; Type Assign; Value 20 ; }
      }
    }
     
  }

  FunctionSpace {
      { Name Hgrad_T; Type Form0;
        BasisFunction {
          { Name sn; NameOfCoef Tn; Function BF_Node; Support Domain_Ele; Entity NodesOf[All]; }
        }
        
        Constraint {
          { NameOfCoef Tn; EntityType NodesOf ; NameOfConstraint T_dirichlet; }

        }   
      }
      
    }
  //Hregion_i_2D
  Formulation {

  // Injecting Fourier's law (q = -k * grad(T)) in the above expression gives the final weak formulation:
  //    ( k * grad(T) , grad(T'))_Vol_The
  //  + ( d(rho * cp * T)/dt , T')_Vol_The 
  //  + ( h(T - TConv) , T')_BND_fins
  //  - ( q_s , T')_Vol_The
  //  = 0

    { Name The_T ; Type FemEquation;
      Quantity {
        { Name T;  Type Local; NameOfSpace Hgrad_T; }
        { Name a; Type Local; NameOfSpace Hcurl_a_Mag_2D; }
        { Name ir; Type Local; NameOfSpace Hregion_i_2D; }
        
      }
      Equation {
        Galerkin { [ k[] * Dof{d T} , {d T} ];
                  In Domain_tot; Integration I1; Jacobian Vol;  }

        Galerkin { [ -0.5*sigma[]* <a>[SquNorm[Dt[{a}]]] - 0.5*<ir>[SquNorm[{ir}*Ns[]/Sc[]]]/sigma[], {T} ];
                  In Domain_tot; Integration I1; Jacobian Vol;  }

      }
    }
  }


  Resolution {
    { Name Magnetothermal;
      System {
        { Name Sys_Mag; NameOfFormulation MQS_a_2D;
            Type Complex; Frequency Freq; }
        { Name T; NameOfFormulation The_T;
        Type Complex; Frequency Freq; } 
      }      
      Operation {
          CreateDir["res"];
          InitSolution[Sys_Mag];
          Generate[Sys_Mag]; Solve[Sys_Mag]; SaveSolution[Sys_Mag];
          InitSolution[T];
          Generate[T]; Solve[T]; SaveSolution[T];
        }
    }
  }
  


  PostProcessing {
    { Name The; NameOfFormulation The_T;
      Quantity {
        { Name T; Value{ Local{ [ {T} ] ; In Domain_Mag; Jacobian Vol;} } }
        { Name q; Value{ Local{ [ -k[]*{d T} ] ; In Domain_Mag; Jacobian Vol; } } }
        { Name sigma; Value{ Local{ [ sigma[{T}] ] ; In Conductor; Jacobian Vol; } } }
        //{ Name q_vol ; Value { Term { [ Complex[0, 1]*Omega*(a*a) ] ; In Domain_tot ; Jacobian Vol; } } }
      }
    }

  }

  PostOperation {
    { Name Post_MagTher ; NameOfPostProcessing The ;
      Operation {
        Print[ T, OnElementsOf Domain_Mag , File "res/map_T.pos"];
        Print[ q, OnElementsOf Domain_Mag , File "res/map_Q.pos"];
        Print[ sigma, OnElementsOf Conductor , File "res/map_Sigma.pos"];
        //Print[ qVol, OnElementsOf Domain_tot , File "map_QVol.pos"];
      }
    }
  }
  Printf("Magneto-thermal case to be implemented!");

EndIf


If(Flag_AnalysisType == 3 )

  Group{
    bnd_ground = Region[{140}];
    outer_boundary = Region[{60}];
    Tot = Region[1234];

  }

  Function {
    mu0 = 4.e-7 * Pi;
    eps0 = 8.854187818e-12;
    mur_steel = 4;

    k[SteelPipe] = 50.2;
    k[Semiconductor] = 10; // note Louis, useless as not conducting
    k[Ground] = 0.4; // note Louis, useless as not conducting
    k[Region[{Insolating_PET, Insolating_PP, Insolating_PVC, Insolating_XLPE}]] = 0.46; // note Louis, useless as not conducting
    k[Region[{Ind_1, Ind_2, Ind_3, Copper}]] = 400;

    T0[] = 20;
    
    If(defect == 1)
      k[Air] = 0.02;
    EndIf


    NL_tol_abs = 1e-12;
    NL_tol_rel = 1e-6;
    NL_iter_max = 20;
  }

    
Constraint {
    // These constraints will be invoked in the function space definition.
    // 1) Dirichlet boundary condition
    { Name T_init; Type Init;
      Case {
        { Region Conductor ; Value T0[] ; }
      }
    }
    { Name T_dirichlet ;
      Case {
        { Region outer_boundary ; Type Assign; Value 20 ; }
      }
    }
     
  }

  FunctionSpace {
      { Name Hgrad_T; Type Form0;
        BasisFunction {
          { Name sn; NameOfCoef Tn; Function BF_Node; Support Domain_tot; Entity NodesOf[All]; }
        }
        
        Constraint {
          { NameOfCoef Tn; EntityType NodesOf ; NameOfConstraint T_init; }
          { NameOfCoef Tn; EntityType NodesOf ; NameOfConstraint T_dirichlet; }

        }   
      }
      
    }


    Formulation {

      { Name MQS_a_2D_non_lin; Type FemEquation; // Magnetoquasistatics
        Quantity {
          { Name a;  Type Local; NameOfSpace Hcurl_a_Mag_2D; }
          { Name T;  Type Local; NameOfSpace Hgrad_T; }
          // stranded conductors (source)
          { Name ir ; Type Local  ; NameOfSpace Hregion_i_2D ; }
          { Name Us ; Type Global ; NameOfSpace Hregion_i_2D[Us] ; }
          { Name Is ; Type Global ; NameOfSpace Hregion_i_2D[Is] ; }
        }

        Equation {
          Galerkin { [ nu[] * Dof{d a} , {d a} ];
            In Domain_Mag; Jacobian Vol; Integration I1; }
          
          Galerkin { DtDof [ sigma[<T>[{T}]] * Dof{a} , {a} ];
            In DomainC_Mag; Jacobian Vol; Integration I1; }

          // or you use the constraints => allows accounting for sigma[]
          Galerkin { [ -Ns[]/Sc[] * Dof{ir}, {a} ] ;
            In DomainS_Mag ; Jacobian Vol ; Integration I1 ; }
          Galerkin { DtDof [ Ns[]/Sc[] * Dof{a}, {ir} ] ;
            In DomainS_Mag ; Jacobian Vol ; Integration I1 ; }

          Galerkin { [ Ns[]/Sc[] / sigma[<T>[{T}]] * Ns[]/Sc[]* Dof{ir} , {ir} ] ; // resistance term
            In DomainS_Mag ; Jacobian Vol ; Integration I1 ; }
          //GlobalTerm { [ Rdc * Dof{Is} , {Is} ] ; In DomainS ; } // OR this resitance term
          GlobalTerm { [ Dof{Us}, {Is} ] ; In DomainS_Mag ; }
        }
      }

      { Name The_T_non_lin ; Type FemEquation;
        Quantity {
          { Name T;  Type Local; NameOfSpace Hgrad_T; }
          { Name a; Type Local; NameOfSpace Hcurl_a_Mag_2D; }
          { Name ir; Type Local; NameOfSpace Hregion_i_2D; }
          
        }
        Equation {
          Galerkin { [ k[] * Dof{d T} , {d T} ];
                    In Domain_tot; Integration I1; Jacobian Vol;  }

          Galerkin { [ -0.5*sigma[<T>[{T}]]* <a>[SquNorm[Dt[{a}]]] -  0.5*<ir>[SquNorm[{ir}*Ns[]/Sc[]]]/sigma[<T>[{T}]], {T} ];
                  In Domain_tot; Integration I1; Jacobian Vol;  }

          

        }
      }
    }

    

    

    Resolution {
      { Name MagnetoThermalCoupling;
        System {
          { Name Sys_Mag; NameOfFormulation MQS_a_2D_non_lin;
            Type Complex; Frequency Freq; }
          { Name Sys_The; NameOfFormulation The_T_non_lin; }
        }
        Operation {
        // Initialize the temperature to the initial condition "T0[]":
        InitSolution[Sys_The];

        // First solve: magnetic with the initial temperature, then thermal:
        Generate[Sys_Mag]; Solve[Sys_Mag];
        Generate[Sys_The]; Solve[Sys_The];

        
          // Re-generate the magnetic system with the updated temperature (which
          // changes sigma), and compute the initial residual:
          Generate[Sys_Mag];
          GetResidual[Sys_Mag, $res0];

          // Initialize runtime variables to track the residual and the iteration
          // count, then print out the absolute and relative residual:
          Evaluate[ $res = $res0, $iter = 0 ];
          Print[{$iter, $res, $res / $res0},
            Format "Residual %03g: abs %14.12e rel %14.12e"];

          // Iterate until convergence (same loop structure as in tutorial 3):
          While[$res > NL_tol_abs && $res / $res0 > NL_tol_rel &&
            $res / $res0 <= 1 && $iter < NL_iter_max]{
            Solve[Sys_Mag];
            Generate[Sys_The]; Solve[Sys_The];
            Generate[Sys_Mag]; GetResidual[Sys_Mag, $res];
            Evaluate[ $iter = $iter + 1 ];
            Print[{$iter, $res, $res / $res0},
              Format "Residual %03g: abs %14.12e rel %14.12e"];
          }
        

      SaveSolution[Sys_Mag];
      SaveSolution[Sys_The];
    }
      }
    }



    PostProcessing {
    { Name The_non_lin; NameOfFormulation MQS_a_2D_non_lin;
      Quantity {
        { Name T; Value{ Local{ [ {T} ] ; In Domain_Mag; Jacobian Vol;} } }
        { Name q; Value{ Local{ [ -k[]*{d T} ] ; In Domain_Mag; Jacobian Vol; } } }
        //{ Name q_vol ; Value { Term { [ Complex[0, 1]*Omega*(a*a) ] ; In Domain_tot ; Jacobian Vol; } } }
         { Name j; Value {
              Term { [ -sigma[ <T>[{T}] ]*Dt[{a}]]; In DomainC_Mag; Jacobian Vol; }
              Term { [ Ns[]/Sc[]*{ir} ]; In DomainS_Mag; Jacobian Vol; }
            } }
          { Name jz; Value {
              Term { [ CompZ[-sigma[<T>[{T}]]*Dt[{a}]] ]; In DomainC_Mag; Jacobian Vol; }
              Term { [ CompZ[ Ns[]/Sc[]*{ir} ]]; In DomainS_Mag; Jacobian Vol; }
            } }

          { Name norm_j; Value {
              Term { [ Norm[-sigma[ <T>[{T}] ]*Dt[{a}]] ]; In DomainC_Mag; Jacobian Vol; }
              Term { [ Norm[ Ns[]/Sc[]*{ir} ]]; In DomainS_Mag; Jacobian Vol; }
            } }

          { Name local_losses; Value {
              Term { [ 0.5*sigma[ <T>[{T}] ]*SquNorm[Dt[{a}]] ]; In DomainC_Mag; Jacobian Vol; }
              Term { [ 0.5/sigma[ <T>[{T}] ]*SquNorm[Ns[]/Sc[]*{ir}] ]; In DomainS_Mag; Jacobian Vol; }
            }
          }

          { Name global_losses; Value {
              Integral { [ 0.5*sigma[ <T>[{T}]]*SquNorm[Dt[{a}]] ]   ; In DomainC_Mag  ; Jacobian Vol ; Integration I1 ; }
              Integral { [ 0.5/sigma[ <T>[{T}] ]*SquNorm[Ns[]/Sc[]*{ir}] ] ; In DomainS_Mag  ; Jacobian Vol ; Integration I1 ; }
            }
          }
          {Name sigma; Value{ Local{ [ sigma[<T>[{T}]] ] ; In Conductor; Jacobian Vol; } } }
      }
    }

  }
  PostOperation {
      { Name Post_MagTher_non_lin ; NameOfPostProcessing The_non_lin ;
        Operation {
          Print[ T, OnElementsOf Domain_Mag , File "res/map_T.pos"];
          Print[ q, OnElementsOf Domain_Mag , File "res/map_Q.pos"];
          //Print[ qVol, OnElementsOf Domain_tot , File "map_QVol.pos"];
          Print[ jz , OnElementsOf Region[{DomainC_Mag}],
              Name "jz [A/m^2]", File "res/jz_inds.pos" ];
            Print[ norm_j , OnElementsOf DomainC_Mag,
              Name "|j| [A/m^2]", File "res/jm.pos" ];

            // global results
            Print[ global_losses[DomainC_Mag], OnGlobal, Format Table,
              SendToServer "{01Global MAG results/0Losses conducting domain non lin ",
              Units "W/m", File > "res/losses_total_non_lin.dat" ];

            Print[ global_losses[DomainS_Mag], OnGlobal, Format Table,
              SendToServer "{01Global MAG results/0Losses source non lin ",
              Units "W/m", File > "res/losses_inds_non_lin.dat" ];
              Print[ sigma, OnElementsOf Conductor , File "res/map_Sigma.pos" ];
        }
      }
    }
    
   

EndIf