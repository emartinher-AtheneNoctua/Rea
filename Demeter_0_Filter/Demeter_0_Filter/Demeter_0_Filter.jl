
# Demeter project
# Edgar Martin Hernandez, 2018, USAL

using JuMP
using Ipopt
using GLPKMathProgInterface
using Clp
# using PyPlot
# using NLopt
# using NLsolve
using LightGraphs
# using MetaGraphs
using GraphPlot


sets_matrix         =   readdlm("sets.csv", ',')
parameters_matrix   =   readdlm("parameters.csv", ',')
nodes_matrix        =   readdlm("nodes_expandido.csv", ',')


units   =   sets_matrix[:,1]
comp    =   sets_matrix[:,2]
nodes   =   nodes_matrix[:,1]

elements_wet = comp[[1, 2 ,3, 4, 5, 6]] #SUBSET wet digestate elements
elements_dry = comp[[2 ,3, 4, 5, 6]] #SUBSET dry digestate elements
nutrients = comp[[4,5]] #SUBSET nutients

elements_dry

#Unit conversion
mmHg_to_Pa = 1E5/750
L_to_m3 = 1E-3
L_to_ft3 =0.0353147
m3_to_USgalon = 264.172
kg_to_lb = 2.20462
m_to_ft = 3.28084
Dolar_to_Euro = 0.886533

MW                      =   Dict(zip(comp, parameters_matrix[:,2]))
c_p_liq_sol             =   Dict(zip(comp, parameters_matrix[:,3]))
dH_vap_0                =   Dict(zip(comp, parameters_matrix[:,4]))
Tc                      =   Dict(zip(comp, parameters_matrix[:,5]))
Tb                      =   Dict(zip(comp, parameters_matrix[:,6]))
dH_f                    =   Dict(zip(comp, parameters_matrix[:,7]))
dH_c                    =   Dict(zip(comp, parameters_matrix[:,8]))
c_p_v_1                 =   Dict(zip(comp, parameters_matrix[:,9]))
c_p_v_2                 =   Dict(zip(comp, parameters_matrix[:,10]))
c_p_v_3                 =   Dict(zip(comp, parameters_matrix[:,11]))
c_p_v_4                 =   Dict(zip(comp, parameters_matrix[:,12]))
coef_vapor_pressure_1   =   Dict(zip(comp, parameters_matrix[:,13]))
coef_vapor_pressure_2   =   Dict(zip(comp, parameters_matrix[:,14]))
coef_vapor_pressure_3   =   Dict(zip(comp, parameters_matrix[:,15]))


MWDry_CS    =   16          #Other molecular weights
MWDry_PS    =   14          #Other molecular weights
MWDry_PoS   =   14.5945     #Other molecular weights
MWDry_SS    =   14.90306071 #Other molecular weights
MWDry_D     =   16          #Other molecular weights


nu_p        =   0.80    #polytropic efficiency
k_p         =   1.4     #polytropic coefficient
n_watson    =   0.38    #exponent in Watson correlation
epsilon     =   1E-5   #small number to avoid div. by zero

T_amb = 25+273
P_ref = 1E5

# Chemical Engineering Index
CEI_1979 = 238.7
CEI_1985 = 325.0
CEI_1998 = 389.8
CEI_2004 = 444.2
CEI_2007 = 525.4
CEI_2014 = 576.1
CEI_2016 = 533.9

digestate_pH = 8.0 # New markets for digestate from anaerobic digestion (WRAP, 2011)
reactor_pH = 9.0 # pH in the reactor for struvite formation
digestate_density = 0.95 # Digestate density (Kg/L) New markets for digestate from anaerobic digestion (WRAP, 2011)

SS_316_density = 7.99 #SS 316 density (kg/L) http://www.aksteel.com/pdf/markets_products/stainless/austenitic/316_316l_data_sheet.pdf
FeCl3_disolution_density = 1.415 # FeCl3 disolution density (kg/L) (concentration: 40 %wt) http://www.ens-lyon.fr/DSM/AGREG-Physique/oral/Notices/N063-001.pdf
operations_number = 1 # Operations number

worked_days = 334 # Worked days per year
worked_hours = 24 # Worked hours per day
salary = 50000 # Salary per worker per year
price_P = 0.3148 # EUR per kg  357.16 $ / 1000kg Note! Precio de P (�/kg) (ejemplo). Se ha tomado el precio de fertilizante de P http://www.indexmundi.com/commodities/?commodity=dap-fertilizer
price_N =0.45 # EUR per kg  http://adlib.everysite.co.uk/adlib/defra/content.aspx?doc=245926&id=246003
price_K = 0.24 # EUR per kg http://adlib.everysite.co.uk/adlib/defra/content.aspx?doc=245926&id=246003
price_struvite = 0.763 # EUR per kg 763� / 1000kg Economic Feasibility Study for Phosphorus Recovery Processes DOI 10.1007/s13280-010-0101-9

# General design data
Fm_prec = 2.1 #for SS 316. Walas vessel cost estimation material coefficient (SS 316)
agitator_prec = [8.8200, 0.1235, 0.0818] # Walas motor cost estimation agitator coefficients (speed 2, ss 316, dual impeller)
agitator_specific_power_prec = 10 # HP per 1000gal. Type of fluid: slurries. Agitator power. Rule of thumb. Heuristics in Chemical Engineering. Material from Chemical Process Equipment Selection and Design. Walas, 1990
max_size_centrifuge = 49.21 # in Centrifuge max size (in) (Perry, pag 18-136)


agitator_prec = [8.8200, 0.1235, 0.0818]

agitator_prec[2]

# VbiogasCS = 0.25
# wDMCS = 0.06
# wVSCS = 0.80
# RcnCS = 13
# wNCS = 0.026
# wNoCS = 0.020499999999999997
# wPCS = 0.0105
# wKCS = 0.0665

# wCCS = RcnCS*(wNCS+wNoCS)
# wRestCS = 1-wCCS-wNCS-wNoCS-wPCS-wKCS

Filtration = DiGraph(4)

add_edge!(Filtration, 1, 2)
add_edge!(Filtration, 2, 3)
add_edge!(Filtration, 2, 4)

gplot(Filtration, nodelabel=[units[1], units[2], units[3], units[4]], nodefillc="white")

# filter_units   =   nodes_matrix[5:19,1]
filter_matrix         =   readdlm("Filter.csv", ',')
filter_media = filter_matrix[:,1]
# filter_yieldP = Dict(zip(filter_media, filter_matrix[:,2]))
# filter_yieldN = Dict(zip(filter_media, filter_matrix[:,3]))
# capacity_filter_media = Dict(zip(filter_media, filter_matrix[:,4]))
# filter_price = Dict(zip(filter_media, filter_matrix[:,5]))
filter_yieldP = Dict(zip(nodes[11:15], filter_matrix[:,2]))
filter_yieldN = Dict(zip(nodes[11:15], filter_matrix[:,3]))
capacity_filter_media = Dict(zip(nodes[11:15], filter_matrix[:,4]))
filter_price = Dict(zip(nodes[11:15], filter_matrix[:,5]))

filter_max_capacity = 1300 #Filter max capacity ft3 per min Process Equipmetn Cost Estimation. Final Report. Loh, Lyons and White, 2002 (NETL)http://www.osti.gov/scitech/servlets/purl/797810/ Material A2895C, 1998 $ Filter type: cartridge filter

nodes

# # Model definition
# m=Model()
# # m = Model(solver=GLPKSolverLP())

# # General variables
# @variable(m, fc[comp,nodes] >= 0)   # product flow (snd,rec,prod) kg/s
# @variable(m, F[nodes] >= 0)         # total flow (snd,rec,prod) kg/s
# @variable(m, x[comp,nodes] >= 0)    # mass fraction(snd,rec,prod)
# # @variable(m, T[nodes] >= 0)         # temperature of stream in K
# # @variable(m, Q[units[1:5]])              # heat produced or consumed of unit in kW  (efficiency included)

# @constraint(m, x["C","Src1Filter"] == 2.478/100)
# @constraint(m, x["Ca","Src1Filter"] == 0.117/100)
# @constraint(m, x["K","Src1Filter"] == 0.253/100)
# @constraint(m, x["N","Src1Filter"] == 0.2266/100) #NH4 fraction
# @constraint(m, x["P","Src1Filter"] == 0.0319/100) #PO4 fraction
# @constraint(m, x["Rest","Src1Filter"] == 0.0256) 
# @constraint(m, x["Wa","Src1Filter"] == 1-sum(x[c, "Src1Filter"] for c in elements_dry))

# @constraint(m, e1[J in comp, n in nodes], fc[J,n] == F[n]*x[J,n]);
# @constraint(m, e2[n in nodes], sum(fc[c,n] for c in comp) == F[n]);

# # Model definition
# m=Model()
# # m = Model(solver=GLPKSolverLP())

# # General variables
# @variable(m, fc[comp,nodes] >= 0)   # product flow (snd,rec,prod) kg/s
# @variable(m, F[nodes] >= 0)         # total flow (snd,rec,prod) kg/s
# @variable(m, x[comp,nodes] >= 0)    # mass fraction(snd,rec,prod)
# # @variable(m, T[nodes] >= 0)         # temperature of stream in K
# # @variable(m, Q[units[1:5]])              # heat produced or consumed of unit in kW  (efficiency included)

# @constraint(m, x["C","Src1Filter"] == 2.478/100)
# # @constraint(m, x["Ca","Src1Filter"] == 0.117/100)
# @constraint(m, x["K","Src1Filter"] == 0.253/100)
# @constraint(m, x["N","Src1Filter"] == 0.2266/100) #NH4 fraction
# @constraint(m, x["P","Src1Filter"] == 0.0319/100) #PO4 fraction
# @constraint(m, x["Rest","Src1Filter"] == 1-(x["C","Src1Filter"]+x["K","Src1Filter"]+x["N","Src1Filter"]+x["P","Src1Filter"]+x["Wa","Src1Filter"])) 
# # @constraint(m, x["Wa","Src1Filter"] == 1-sum(x[c, "Src1Filter"] for c in elements_dry))
# @constraint(m, x["Wa","Src1Filter"] == 0.95)


# @constraint(m, e1[J in comp, n in nodes], fc[J,n] == F[n]*x[J,n])
# @constraint(m, e2[n in nodes], sum(fc[c,n] for c in comp) == F[n])
# # @constraint(m, e3[n in nodes], sum(x[c,n] for c in comp) == 1);


# # @constraint(m, fc["CattleSlurry","Src1Filter"] == 1)
# @constraint(m, F["Src1Filter"] == 1)
# # @constraint(m, F["Src1Filter"] == F["FilterSink2"]+F["FilterSink1"])


# @constraint(m, fc["C","FilterSink1"] == 0)
# @constraint(m, fc["K","FilterSink1"] == 0)
# @constraint(m, fc["Rest","FilterSink1"] == 0)

# # for i in comp
# #     if i != "Wa" && i != "C" && i != "N" && i != "P" && i != "K" && i != "Rest"
# #         @constraint(m, fc[i,"Src1Filter"] == 0)
# #     end
# # end

# # for i in comp
# #     if i != "Wa" && i != "C" && i != "N" && i != "P" && i != "K" && i != "Rest"
# #         @constraint(m, fc[i,"FilterSink2"] == 0)
# #     end
# # end

# # for i in comp
# #     if i != "Wa" && i != "C" && i != "N" && i != "P" && i != "K" && i != "Rest"
# #         @constraint(m, fc[i,"FilterSink1"] == 0)
# #     end
# # end

# @constraint(m, fc["P","FilterSink2"] == fc["P","Src1Filter"]*filter_yieldP["Metal_slag"])
# @constraint(m, fc["N","FilterSink2"] == fc["N","Src1Filter"]*filter_yieldN["Metal_slag"])
# @constraint(m, fc["P", "FilterSink1"] == fc["P","Src1Filter"]*(1-filter_yieldP["Metal_slag"]))
# @constraint(m, fc["N", "FilterSink1"] == fc["N","Src1Filter"]*(1-filter_yieldN["Metal_slag"]))
# @constraint(m, fc["Rest", "FilterSink2"] == fc["Rest","Src1Filter"])
# @constraint(m, fc["C", "FilterSink2"] == fc["C","Src1Filter"])
# @constraint(m, fc["K", "FilterSink2"] == fc["K","Src1Filter"])
# @constraint(m, fc["Wa", "FilterSink1"] == fc["Wa","Src1Filter"]-fc["Wa", "FilterSink2"])
# @constraint(m, fc["Wa", "FilterSink2"] == (0.15/0.85)*sum(fc[c,"FilterSink2"] for c in elements_dry))

# @variable(m, z)
# # @objective(m, Max, z == sum(fc["P",n] for n in filter_units[11:15]))
# @objective(m, Max, z == 2)

# m.solver = IpoptSolver(linear_solver = "ma57")
# status = solve(m)

# getvalue(fc)

# Model definition
m=Model()
# m = Model(solver=GLPKSolverLP())

# General variables
@variable(m, fc[comp,nodes] >= 0)   # product flow (snd,rec,prod) kg/s
@variable(m, F[nodes] >= 0)         # total flow (snd,rec,prod) kg/s
@variable(m, 0 <= x[comp,nodes] <= 1)    # mass fraction(snd,rec,prod)

# Variables # Economics/Design***************************************************************************
@variable(m, Filter_Cost_1998[nodes[11:15]] >= 0) # US dollar
@variable(m, Filter_Cost_2016[nodes[11:15]] >= 0) #  EUR
@variable(m, Flow_imperial_filter[nodes[11:15]] >= 0) # ft3 per min
@variable(m, 0 <= Design_flow_filter[nodes[11:15]] <= filter_max_capacity) # ft3 per min
@variable(m, Chemicals_Cost_filter[nodes[11:15]] >= 0) # EUR per year
@variable(m, Labour_Cost_filter[nodes[11:15]] >= 0) # EUR per year
@variable(m, Operational_cost_filter[nodes[11:15]] >= 0) #
#     @variable(m, P_benefits_filter >= 0) # EUR per year...Recovered P sales benefits
@variable(m, Operation_cost_filter[nodes[11:15]] >= 0) #
@variable(m, Benefits_filter[nodes[11:15]]) # � per year...Net profit
@variable(m, Benefits_nutrients[nodes[11:15]])
#     @variable(m, a_Filter) #
@variable(m, n_filter[nodes[11:15]] >= 0) #number of filters
@variable(m, n_auxiliar[nodes[11:15]] >= 0) #auxiliar variable for Heaviside step function

@constraint(m, e1[J in comp, n in nodes], fc[J,n] == F[n]*x[J,n])
# @constraint(m, e2[n in nodes], sum(fc[c,n] for c in comp) == F[n])
@constraint(m, e2[n in nodes[6:15]], sum(fc[c,n] for c in comp) == F[n])
# @constraint(m, e3[n in nodes[11:15]], sum(fc[c,n] for c in comp) == F[n])
# @constraint(m, e3[n in nodes], sum(x[c,n] for c in comp) == 1)

@constraint(m, sum(F[i] for i in nodes[1:5]) == 1)
# @constraint(m, F[nodes[1]] == 1)
# @constraint(m, F[nodes[2]] == 1)
# @constraint(m, F[nodes[3]] == 1)
# @constraint(m, F[nodes[4]] == 1)
# @constraint(m, F[nodes[5]] == 1)

for units_i in zip((nodes[1:5]),(nodes[6:10]),(nodes[11:15]))  

    @constraint(m, x["C",units_i[1]] == 2.478/100)
    # @constraint(m, x["Ca","Src1Filter"] == 0.117/100)
    @constraint(m, x["K",units_i[1]] == 0.253/100)
    @constraint(m, x["N",units_i[1]] == 0.2266/100) #NH4 fraction
    @constraint(m, x["P",units_i[1]] == 0.0319/100) #PO4 fraction
    @constraint(m, x["Rest",units_i[1]] == 1-(x["C",units_i[1]]+x["K",units_i[1]]+x["N",units_i[1]]+x["P",units_i[1]]+x["Wa",units_i[1]]))
    # @constraint(m, x["Wa","Src1Filter"] == 1-sum(x[c, "Src1Filter"] for c in elements_dry))
    @constraint(m, x["Wa",units_i[1]] == 0.95)

    # @constraint(m, fc["CattleSlurry","Src1Filter"] == 1)

#     @constraint(m, F[units_i[1]] == 1)
#     @constraint(m, F[units_i[2]] == 0)
#     @constraint(m, F[units_i[3]] == 0)
#     @constraint(m, F[units_i[1]] == F[units_i[2]]+F[units_i[3]])


    
#     @constraint(m, F[units_i[2]] == 0)
#     @constraint(m, F[units_i[3]] == 0)


# for i in comp
#     if i != "Wa" && i != "C" && i != "N" && i != "P" && i != "K" && i != "Rest"
#         @constraint(m, fc[i,"Src1Filter"] == 0)
#     end
# end

# for i in comp
#     if i != "Wa" && i != "C" && i != "N" && i != "P" && i != "K" && i != "Rest"
#         @constraint(m, fc[i,"FilterSink2"] == 0)
#     end
# end

# for i in comp
#     if i != "Wa" && i != "C" && i != "N" && i != "P" && i != "K" && i != "Rest"
#         @constraint(m, fc[i,"FilterSink1"] == 0)
#     end
# end

    @constraint(m, fc["P",units_i[3]] == fc["P",units_i[1]]*filter_yieldP[units_i[3]])
    @constraint(m, fc["N",units_i[3]] == fc["N",units_i[1]]*filter_yieldN[units_i[3]])
    @constraint(m, fc["Rest", units_i[3]] == fc["Rest",units_i[1]])
    @constraint(m, fc["C", units_i[3]] == fc["C",units_i[1]])
    @constraint(m, fc["K", units_i[3]] == fc["K",units_i[1]])
    @constraint(m, fc["Wa", units_i[3]] == (0.15/0.85)*sum(fc[c,units_i[3]] for c in elements_dry))
    @constraint(m, fc["P", units_i[2]] == fc["P",units_i[1]]*(1-filter_yieldP[units_i[3]]))
    @constraint(m, fc["N", units_i[2]] == fc["N",units_i[1]]*(1-filter_yieldN[units_i[3]]))
    @constraint(m, fc["Wa", units_i[2]] == fc["Wa",units_i[1]]-fc["Wa", units_i[3]])
    @constraint(m, fc["C",units_i[2]] == 0)
    @constraint(m, fc["K",units_i[2]] == 0)
    @constraint(m, fc["Rest",units_i[2]] == 0)


    
# Economics/Design****************************************************************************


    # Constraints
    # Process Equipmetn Cost Estimation. Final Report. Loh, Lyons and White, 2002 (NETL)
    # http://www.osti.gov/scitech/servlets/purl/797810/
    # Material A2895C, 1998 $
    # Filter type: cartridge filter
    # Filter_cost_1998: 1998 $; Filter_cost_2016: 2016 �; Flow: flow rate in ft3 per minute
    # 1 L=0.0353147 ft3; 1 min=60 s
    @constraint(m, Flow_imperial_filter[units_i[3]] == (F[units_i[1]]/digestate_density)*L_to_ft3*60)
#     @NLconstraint(m, n_filter == ceil(Flow_imperial_filter/filter_max_capacity))
    @constraint(m, n_auxiliar[units_i[3]] == (Flow_imperial_filter[units_i[3]]/filter_max_capacity))
    @NLconstraint(m, n_filter[units_i[3]] == sum(1/(1+e^(-10000*((n_auxiliar[units_i[3]]+1)-n))) for n in collect(1:100)))
#     @NLconstraint(m, n_filter == Flow_imperial_filter/filter_max_capacity+(1-mod(Flow_imperial_filter,filter_max_capacity)/filter_max_capacity))
#     @NLconstraint(m, Design_flow_filter[units_i[3]] == min(filter_max_capacity,Flow_imperial_filter[units_i[3]]))
    @constraint(m, Design_flow_filter[units_i[3]] == Flow_imperial_filter[units_i[3]])
    @constraint(m, Filter_Cost_1998[units_i[3]] == 4.7436*Design_flow_filter[units_i[3]]+807.6923)
    #     Cost_filter_2.. Filter_Cost_1998 =E= 4.7436*Design_flow_filter+807.6923;
    # Fixed capital = Filter_Cost_filter_2016
    @constraint(m, Filter_Cost_2016[units_i[3]] == (Filter_Cost_1998[units_i[3]]*(CEI_2016/CEI_1998))*Dolar_to_Euro)
    @constraint(m, Chemicals_Cost_filter[units_i[3]] == ((fc["P",units_i[1]]*3600*worked_hours*worked_days)/capacity_filter_media[units_i[3]])*filter_price[units_i[3]])
    # Ref: Vian Ortuno....Labour_Cost_filter=(worker per hour per production ton and per operation)�(max annual production)�(salary per worker and per worked hour)�(operations number)
    @constraint(m, Labour_Cost_filter[units_i[3]] == (61.33*(fc["P",units_i[1]]*1E-3*3600*worked_hours^(-0.82)))*(fc["P",units_i[1]]*1E-3*3600*worked_hours*worked_days)*(salary)*operations_number)
    @NLconstraint(m, Operational_cost_filter[units_i[3]]== (Chemicals_Cost_filter[units_i[3]]+1.5*Labour_Cost_filter[units_i[3]]+0.3*Filter_Cost_2016[units_i[3]]*3.15*1.4)/0.8*1E-5)
    @NLconstraint(m, Benefits_nutrients[units_i[3]] == (fc["P",units_i[3]]
                *price_P+fc["N",units_i[3]]*price_N+fc["K",units_i[3]]*price_K)*3600*worked_hours*worked_days/(F[units_i[3]]+epsilon)*1E-5)
    @constraint(m, Benefits_filter[units_i[3]] == Benefits_nutrients[units_i[3]]-Operational_cost_filter[units_i[3]])
end

@variable(m, z)
# @objective(m, Max, z == sum(fc["P",n] for n in filter_units[11:15]))
@constraint(m, z == sum(Benefits_filter[ii] for ii in nodes[11:15]))
# @constraint(m, z == Benefits_filter[nodes[11:15]])
# @constraint(m, z == 2)
@objective(m, Max, z)

# m.solver = IpoptSolver(linear_solver = "ma57")
# status = solve(m)
# m.solver = IpoptSolver(linear_solver = "ma86")
# status = solve(m)
m.solver = IpoptSolver(linear_solver = "ma86")
status = solve(m)
# m.solver = ClpSolver()
# status = solve(m)

# sum(getvalue(fc[c,"Src1FilterPolonite"]) for c in comp)
# sum(getvalue(Benefits_filter[ii]) for ii in nodes[11:15])
# for i in nodes[11:15]
#     a = (getvalue(Benefits_nutrients[i])-getvalue(Operational_cost_filter[i]))
#     println(a)
# end
# getvalue(Benefits_nutrients)


println(getvalue(Benefits_filter))
println(getvalue(Benefits_nutrients))
println(getvalue(Operational_cost_filter))

## @constraint(m, fc["CattleSlurry","Src1Filter"] == 1)
# @constraint(m, F["Src1Filter"] == 1) #CattleSlurry


# @constraint(m, fc["C","FilterSink1"] == 0)
# @constraint(m, fc["K","FilterSink1"] == 0)
# @constraint(m, fc["Rest","FilterSink1"] == 0)

# for i in comp
#     if i != "Wa" && i != "C" && i != "N" && i != "P" && i != "K" && i != "Rest"
#         @constraint(m, fc[i,"Src1Filter"] == 0)
#     end
# end

# for i in comp
#     if i != "Wa" && i != "C" && i != "N" && i != "P" && i != "K" && i != "Rest"
#         @constraint(m, fc[i,"FilterSink2"] == 0)
#     end
# end

# for i in comp
#     if i != "Wa" && i != "C" && i != "N" && i != "P" && i != "K" && i != "Rest"
#         @constraint(m, fc[i,"FilterSink1"] == 0)
#     end
# end

# @constraint(m, fc["C","Src1Filter"] == wCCS*wDMCS*F["Src1Filter"])
# @constraint(m, fc["N","Src1Filter"] == wNCS*wDMCS*F["Src1Filter"])
# @constraint(m, fc["P","Src1Filter"] == wPCS*wDMCS*F["Src1Filter"])
# @constraint(m, fc["K","Src1Filter"] == wKCS*wDMCS*F["Src1Filter"])
# @constraint(m, fc["Rest","Src1Filter"] == wRestCS*wDMCS*F["Src1Filter"])
# @constraint(m, fc["Wa","Src1Filter"] == (1-wDMCS)*F["Src1Filter"])

# @constraint(m, fc["P","FilterSink2"] == fc["P","Src1Filter"]*filter_yieldP["Metal_slag"])
# @constraint(m, fc["N","FilterSink2"] == fc["N","Src1Filter"]*filter_yieldN["Metal_slag"])
# @constraint(m, fc["P", "FilterSink1"] == fc["P","Src1Filter"]*(1-filter_yieldP["Metal_slag"])
# @constraint(m, fc["N", "FilterSink1"] == fc["N","Src1Filter"]*(1-filter_yieldN["Metal_slag"])
# @constraint(m, fc["Rest", "FilterSink2"] == fc["Rest","Src1Filter"])
# @constraint(m, fc["C", "FilterSink2"] == fc["C","Src1Filter"])
# @constraint(m, fc["K", "FilterSink2"] == fc["K","Src1Filter"])
# @constraint(m, fc["Wa", "FilterSink1"] == fc["Wa","Src1Filter"]-fc["Wa", "FilterSink2"])
# @constraint(m, fc["Wa", "FilterSink2"] == (0.15/0.85)*sum(fc[c,"FilterSink2"] for c in comp))

# # Variables
# @variable(m, Filter_cost_1998 >= 0) # US dollar
# @variable(m, Filter_cost_2016 >= 0) #  EUR
# @variable(m, Flow_imperial_filter >= 0) # ft3 per min
# @variable(m, 0 <= Design_flow_filter <= filter_max_capacity) # ft3 per min
# @variable(m, Chemicals_cost_filter >= 0) # EUR per year
# @variable(m, Labour_cost_filter >= 0) # EUR per year
# @variable(m, Operational_cost_filter >= 0) #
# @variable(m, P_benefits_filter >= 0) # EUR per year...Recovered P sales benefits
# @variable(m, Operation_cost_Filter >= 0) #
# @variable(m, Benefits_filter) # � per year...Net profit
# @variable(m, a_Filter) #

# # Constraints
# # Process Equipmetn Cost Estimation. Final Report. Loh, Lyons and White, 2002 (NETL)
# # http://www.osti.gov/scitech/servlets/purl/797810/
# # Material A2895C, 1998 $
# # Filter type: cartridge filter
# # Filter_cost_1998: 1998 $; Filter_cost_2016: 2016 �; Flow: flow rate in ft3 per minute
# # 1 L=0.0353147 ft3; 1 min=60 s
# @constraint(m, Flow_imperial_filter == (F["Src1Filter"]/digestate_density)*L_to_ft3*60)
# @constraint(m, n_filter == ceil(Flow_imperial_filter/filter_max_capacity)
# @constraint(m, Design_flow_filter == min(filter_max_capacity,Flow_imperial_filter))
# @constraint(m, Filter_Cost_1998 == 4.7436*Design_flow_filter+807.6923)
# #     Cost_filter_2.. Filter_Cost_1998 =E= 4.7436*Design_flow_filter+807.6923;
# # Fixed capital = Filter_Cost_filter_2016
# @constraint(m, Filter_Cost_2016 == (Filter_Cost_1998*(CEI_2016/CEI_1998))*Dolar_to_Euro)
# @constraint(m, Chemicals_Cost_filter == ((fc["P","Src1Filter"]*3600*worked_hours*worked_days)/capacity_filter_media["Metal_slag"])*filter_price["Metal_slag"])
# # Ref: Vian Ortu�o....Labour_Cost_filter=(worker per hour per production ton and per operation)�(max annual production)�(salary per worker and per worked hour)�(operations number)
# @constraint(m, Labour_Cost_filter == (61.33*(fc["P","Src1Filter"]*1E-3*3600*worked_hours**(-0.82)))*(fc["P","Src1Filter"]*1E-3*3600*worked_hours*worked_days)*(salary*Dolar_to_Euro/worked_hours/worked_days)*operations_number)
# @constraint(m, Operational_cost_filter == (Chemicals_cost_filter+1.5*Labour_cost_filter+0.3*Filter_cost_2016*3.15*1.4)/0.8)
# @constraint(m, 
# Cost_filter_7.. P_benefits_filter =E= fc('P','Filter','Snk8')*price_P*3600*worked_hours*worked_days;
# Cost_filter_8.. Benefits_filter =E= (fc('P','Filter','SnkFilter2')/(F('Filter','SnkFilter2')+epsilon)*price_P+fc('N','Filter','SnkFilter2')/(F('Filter','SnkFilter2')+epsilon)*price_N+fc('K','Filter','SnkFilter2')/(F('Filter','SnkFilter2')+epsilon)*price_K)*3600*worked_hours*worked_days-Operation_cost_Filter;


sum(1/(1+1*e^(-1000*((0.002+1)-n))) for n in collect(1:100))

10/0.001
