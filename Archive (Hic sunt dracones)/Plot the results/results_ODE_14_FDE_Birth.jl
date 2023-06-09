# plots for paramters obtained from Turing ODE 14, when Λ=Birth rate and fitting only to C and R.
# comparing the results with those modified by optimized fractional orders

using Statistics
using CSV, DataFrames
using Interpolations,LinearAlgebra
using Optim, FdeSolver
using SpecialFunctions, StatsBase, Random, DifferentialEquations

# Dataset
dataset_CC = CSV.read("time_series_covid19_confirmed_global.csv", DataFrame) # all data of confirmed
Confirmed=dataset_CC[dataset_CC[!,2].=="South Africa",70:250] #comulative confirmed data of Portugal from 3/2/20 to 5/17/20
C=diff(Float64.(Vector(Confirmed[1,:])))# Daily new confirmed cases

dataset_R = CSV.read("time_series_covid19_recovered_global.csv", DataFrame) # all data of Recover
RData=dataset_R[dataset_R[!,2].=="South Africa",70:250]
TrueR=diff(Float64.(Vector(RData[1,:])))

dataset_D = CSV.read("time_series_covid19_deaths_global.csv", DataFrame) # all data of Recover
DData=dataset_D[dataset_D[!,2].=="South Africa",70:250]
TrueD=diff(Float64.(Vector(DData[1,:])))

#initial conditons and parameters

E0=0;IA0=100;IS0=17;R0=0;P0=100;D0=0;

tSpan=(1,length(C))

# Define the equation

function  F(dx, x, par, t)

    Λ,μ,μp,ϕ1,ϕ2,β1,β2,δ,ψ,ω,σ,γS,γA,ηS,ηA=par
    S,E,IA,IS,R,P,D,N=x

    dx[1]= Λ*N - β1*S*P/(1+ϕ1*P) - β2*S*(IA + IS)/(1+ϕ2*(IA+IS)) + ψ*E - µ*S
    dx[2]= β1*S*P/(1+ϕ1*P)+β2*S*(IA+IS)/(1+ϕ2*(IA+IS)) - ψ*E - μ*E - ω*E
    dx[3]= (1-δ)*ω*E - (μ+σ)*IA - γA*IA
    dx[4]= δ*ω*E - (μ + σ)*IS - γS*IS
    dx[5]=γS*IS + γA*IA - μ*R
    dx[6]=ηA*IA + ηS*IS - μp*P
    dx[7]=σ*(IA+IS) - μ*D
    dx[8]=Λ*N - σ*(IA+IS) - μ*N
    return nothing

end

function  Ff(t, x, par)

    Λ,μ,μp,ϕ1,ϕ2,β1,β2,δ,ψ,ω,σ,γS,γA,ηS,ηA=par
    S,E,IA,IS,R,P,D,N=x

    dS= Λ*N - β1*S*P/(1+ϕ1*P) - β2*S*(IA + IS)/(1+ϕ2*(IA+IS)) + ψ*E - µ*S
    dE= β1*S*P/(1+ϕ1*P)+β2*S*(IA+IS)/(1+ϕ2*(IA+IS)) - ψ*E - μ*E - ω*E
    dIA= (1-δ)*ω*E - (μ+σ)*IA - γA*IA
    dIS= δ*ω*E - (μ + σ)*IS - γS*IS
    dR=γS*IS + γA*IA - μ*R
    dP=ηA*IA + ηS*IS - μp*P
    dD=σ*(IA+IS) - μ*D
    dN=Λ*N - σ*(IA+IS) - μ*N
    return [dS,dE,dIA,dIS,dR,dP,dD,dN]

end

  pp=[25060.216457227714
  	0.17016670078596785
	  1.781847356255663e-7
	  0.6553727445190615
	  1.279308675438442e-5
	  4.305136647875811e-5
	  0.8580730111477723
	  0.08585144261559632
	  0.6837796665562463
	  0.11184180526657209
	  6.752788944397819e-5
	  0.9748087783772565
	  0.11779422117231593
	  0.061658367897578344
    167.56655046390654
	10.718478095775652]
	Λ=19.995e-3 # birth rate (19.995 births per 1000 people)
	μ=9.468e-3 # natural human death rate
	μp,ϕ1,ϕ2,β1,β2,δ,ψ,ω,σ2,γS,γA,ηS,ηA = pp[2:14]
 	p = [Λ,μ,μp,ϕ1,ϕ2,β1,β2,δ,ψ,ω,σ2,γS,γA,ηS,ηA]
	S0=pp[1]
	IA0=pp[15]
 	P0=pp[16]
	# E0= 35.96791914222955; IA0 = 299.97231992088854; P0 = 0.05424285701446199
 	N0=S0+E0+IA0+IS0+R0
 	X0=[S0,E0,IA0,IS0,R0,P0,D0,N0]
p = [Λ,μ,μp,ϕ1,ϕ2,β1,β2,δ,ψ,ω,σ2,γS,γA,ηS,ηA]

prob = ODEProblem(F, X0, tSpan, p)
sol = solve(prob, alg_hints=[:stiff]; p=p, saveat=1)
# plot(reduce(vcat,sol.u')[:,8])
Pred=reduce(vcat,sol.u')[:,[4]]
# PredI=reduce(vcat,sol.u')[:,4]
# PredR=reduce(vcat,sol.u')[:,5]
# rmsd([C TrueR.^2], [PredI PredR.^2])
rmsd(C, Pred)

Order=ones(8)
# args = [0.5001175408172511, 0.9999970873210817, 0.9999978721509972, 0.9999999999999988, 0.9999719051580541, 0.9999267647915293, 0.693003453777595, 2.9774980971158542, 167.56215478257218, 10.675403466403734, 0.22431926350819367, 0.550958207895055, 0.6350436154728419, 1.9825537020182498]
args = [0.9909265167105732, 0.9999429475333177, 0.9999406399381575, 0.9999997893504942, 0.500000977757587, 0.9440649208781777, 0.9999999431118562, 35.96791914222955, 299.97231992088854, 0.05424285701446199]
Order[1:6]=args[1:6];
Order[8]=args[7]
# E0, IA0, P0, ϕ2, δ, ω, γA = args[8:14]
E0, IA0, P0 = args[8:10]
N0=S0+E0+IA0+IS0+R0
X0=[S0,E0,IA0,IS0,R0,P0,D0,N0]
par1 = [Λ,μ,μp,ϕ1,ϕ2,β1,β2,δ,ψ,ω,σ2,γS,γA,ηS,ηA]
_, x1 = FDEsolver(Ff, [1,length(C)], X0, Order, par1, h=.05, nc=4)
Pred1=x1[1:20:end,4]
rmsd(C, Pred1)

using Plots
plot(reduce(vcat,sol.u')[:,4])
plot!(Pred1[:,1])
scatter!(C)

plot(reduce(vcat,sol.u')[:,5])
plot!(x1[1:20:end,5])
scatter!(TrueR)

plot(reduce(vcat,sol.u')[:,7])
plot!(x1[1:20:end,7])
scatter!(TrueD)

#population
plot(reduce(vcat,sol.u')[:,8])
plot!(x1[1:20:end,8])
