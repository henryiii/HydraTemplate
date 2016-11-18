/*----------------------------------------------------------------------------
 *
 *   Copyright (C) 2016 Antonio Augusto Alves Junior
 *
 *   This file is part of Hydra Data Analysis Framework.
 *
 *   Hydra is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   Hydra is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with Hydra.  If not, see <http://www.gnu.org/licenses/>.
 *
 *---------------------------------------------------------------------------*/
/*
 *  PhSp.cpp
 *
 *  Created on: Oct 21, 2016
 *      Author: Henry Schreiner, Antonio Augusto Alves Junior
 */

#include <iostream>
#include <assert.h>
#include <time.h>
#include <vector>
#include <memory>
#include <chrono>

//this lib
#include <hydra/Types.h>
#include <hydra/Vector4R.h>
#include <hydra/PhaseSpace.h>
#include <hydra/Containers.h>
#include <hydra/Evaluate.h>
#include <hydra/Function.h>
#include <hydra/FunctorArithmetic.h>
#include <hydra/FunctionWrapper.h>
#include <hydra/Copy.h>

//root
#ifdef ROOT_FOUND
#include <TROOT.h>
#include <TH1D.h>
#include <TF1.h>
#include <TH2D.h>
#include <TApplication.h>
#include <TCanvas.h>
#include <TColor.h>
#include <TString.h>
#include <TStyle.h>
#endif

#if THRUST_DEVICE_SYSTEM==THRUST_DEVICE_SYSTEM_OMP
#include <omp.h>
#endif
/**
 * @file
 * @example PhSp.cpp
 * @brief This is a simple file that runs a hard-coded example, Lambda_c -> pKpi. This
 * is intendend to be as simple as possible.
 *
 * Usage:
 *
 *./PhSp
**/

/// Simple timer object, prints time when it goes out of scope
class TimeIt {
    decltype(std::chrono::high_resolution_clock::now()) start;
    std::string name;

    public:
    TimeIt(std::string name_ = ""): name(name_) {start = std::chrono::high_resolution_clock::now();}
    ~TimeIt() {
        auto end = std::chrono::high_resolution_clock::now();
        std::chrono::duration<double, std::milli> elapsed = end - start;

        std::cout << "-----------------------------------------" << std::endl;
        std::cout << name <<  " | Time = "<< elapsed.count() << " ms" << std::endl;
        std::cout << "-----------------------------------------" << std::endl;
    }
};

// These two types are used too often to write "hydra::" every time
using hydra::GInt_t;
using hydra::GReal_t;

GInt_t main(int argv, char** argc) {
    size_t  nentries       = 10000000;
    GReal_t mother_mass    = 2.28646;
    GReal_t daughter1_mass = 1.007276466879;
    GReal_t daughter2_mass = .13957018;
    GReal_t daughter3_mass = .493677;

    // Masses of the particles
    hydra::Vector4R mother(mother_mass, 0.0, 0.0, 0.0);
    std::vector<GReal_t> masses_daughters{ daughter1_mass, daughter2_mass, daughter3_mass };

    // Create PhaseSpace object 
    hydra::PhaseSpace<3> phsp(mother.mass(), masses_daughters);

    // Prepare an event list
    hydra::Events<3, hydra::device> event_list(nentries);

#if THRUST_DEVICE_SYSTEM==THRUST_DEVICE_SYSTEM_CUDA
        std::cout << "Running on CUDA" << std::endl;
#endif
#if THRUST_DEVICE_SYSTEM==THRUST_DEVICE_SYSTEM_OMP
        std::cout << "Running on " << omp_get_max_threads() << " OMP cores" << std::endl;
#endif
#if THRUST_DEVICE_SYSTEM==THRUST_DEVICE_SYSTEM_TBB
        std::cout << "Running on TBB" << std::endl;
#endif

    // Fill the event list
    {
        TimeIt time("Generating using HYDRA");
        phsp.Generate(mother, event_list.begin(), event_list.end());
    }

    // Copy the events to the host
    auto time_ptr = std::make_shared<TimeIt>("Copying to host");
    hydra::Events<3, hydra::host> event_list_host(event_list);
    time_ptr.reset();

#ifdef ROOT_FOUND
    // Prepare a ROOT histogram
    TH2D dalitz("dalitz", ";M(K#pi); M(J/#Psi#pi)", 100,
            pow(daughter2_mass+daughter3_mass,2), pow(mother_mass - daughter1_mass,2),
            100,    pow(daughter1_mass+daughter3_mass,2), pow(mother_mass - daughter2_mass,2));

    // Fill the histogram
    {
        TimeIt time("Making histogram");
    for(auto event: event_list_host){

        GReal_t weight = thrust::get<0>(event);

        hydra::Vector4R Jpsi = thrust::get<1>(event);
        hydra::Vector4R K    = thrust::get<2>(event);
        hydra::Vector4R pi   = thrust::get<3>(event);

        hydra::Vector4R Jpsipi = Jpsi + pi;
        hydra::Vector4R Kpi    = K + pi;
        GReal_t mass1 = Kpi.mass();
        GReal_t mass2 = Jpsipi.mass();

        dalitz.Fill(mass1*mass1 , mass2*mass2,  weight);
    }

    TApplication *myapp=new TApplication("myapp",0,0);
    TCanvas canvas_gauss("canvas_gauss", "Gaussian distribution", 500, 500);
    dalitz.Draw("colz");
    canvas_gauss.Print("PHSP.png");
    //myapp->Run();
    }
    #endif

    return 0;
}
