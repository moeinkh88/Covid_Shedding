# plots for paramters obtained from Turing ODE 14, when Λ=Birth rate and fitting only to C and R.
# comparing the results with those modified by optimized fractional orders

using Statistics
using CSV, DataFrames
using Interpolations,LinearAlgebra
using Optim, FdeSolver
using SpecialFunctions, StatsBase, Random, DifferentialEquations
using Plots, StatsPlots

# Dataset
dataset_CC = CSV.read("time_series_covid19_confirmed_global.csv", DataFrame) # all data of confirmed
Confirmed=dataset_CC[dataset_CC[!,2].=="South Africa",70:250] #comulative confirmed data of Portugal from 3/2/20 to 5/17/20
C=diff(Float64.(Vector(Confirmed[1,:])))# Daily new confirmed cases

#initial conditons and parameters

IS0=17;R0=0;D0=0;
Λ=19.995e-3 # birth rate (19.995 births per 1000 people)
μ=9.468e-3 # natural human death rate
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

# Open the file
AA=readlines("Output_CSC/26huhti ODE/output14CSC.txt")

BB=map(x -> parse.(Float64, split(x)), AA)

plot(; legend=false)
Err=zeros(length(BB))
for ii in 1:length(BB)
	μp,ϕ1,ϕ2,β1,β2,δ,ψ,ω,σ2,γS,γA,ηS,ηA = BB[ii][2:14]
	p1= [Λ,μ,μp,ϕ1,ϕ2,β1,β2,δ,ψ,ω,σ2,γS,γA,ηS,ηA]
	S0=BB[ii][1]
	IA0=BB[ii][15]
	P0=BB[ii][16]
	E0=BB[ii][17]
	N0=S0+E0+IA0+IS0+R0
	X0=[S0,E0,IA0,IS0,R0,P0,D0,N0]

	prob = ODEProblem(F, X0, tSpan, p1)
	sol = solve(prob, alg_hints=[:stiff]; saveat=1)
	# if reduce(vcat,sol.u')[50,4] < 840
		Pred1=reduce(vcat,sol.u')[:,4]
		plot!(Pred1[:,1]; alpha=0.1, color="#BBBBBB")
		# Err[ii]=rmsd([C TrueR], Pred1)
		Err[ii]=rmsd(C, Pred1)
	# end
end
Err=replace!(Err, 0=>Inf) # filter inacceptable results
Ind=sortperm(Err)
Candidate=BB[Ind[1:300]]
for ii in 1:length(Candidate)
	μp,ϕ1,ϕ2,β1,β2,δ,ψ,ω,σ2,γS,γA,ηS,ηA = Candidate[ii][2:14]
	p1= [Λ,μ,μp,ϕ1,ϕ2,β1,β2,δ,ψ,ω,σ2,γS,γA,ηS,ηA]
	S0=Candidate[ii][1]
	IA0=Candidate[ii][15]
	P0=Candidate[ii][16]
	E0=Candidate[ii][17]
	N0=S0+E0+IA0+IS0+R0
	X0=[S0,E0,IA0,IS0,R0,P0,D0,N0]

	prob = ODEProblem(F, X0, tSpan, p1)
	sol = solve(prob, alg_hints=[:stiff]; saveat=1)
		Pred1=reduce(vcat,sol.u')[:,4]
		plot!(Pred1[:,1]; alpha=0.1, color="darkorange1")
end

# Plot real
scatter!(C, color=:gray25,markerstrokewidth=0)
#plot the best

valErr,indErr=findmin(Err)
display(["MinErr",valErr])
function myshowall(io, x, limit = false)
	println(io, summary(x), ":")
	Base.print_matrix(IOContext(io, :limit => limit), x)
end

myshowall(stdout, BB[indErr,:], false)

μp,ϕ1,ϕ2,β1,β2,δ,ψ,ω,σ2,γS,γA,ηS,ηA = BB[indErr][2:14]
p1= [Λ,μ,μp,ϕ1,ϕ2,β1,β2,δ,ψ,ω,σ2,γS,γA,ηS,ηA]
S0=BB[indErr][1]
IA0=BB[indErr][15]
P0=BB[indErr][16]
E0=BB[indErr][17]
N0=S0+E0+IA0+IS0+R0
X0=[S0,E0,IA0,IS0,R0,P0,D0,N0]
prob = ODEProblem(F, X0, tSpan, p1)
sol = solve(prob, alg_hints=[:stiff]; saveat=1)
plot!(reduce(vcat,sol.u')[:,4], lw=3, color=:dodgerblue1)

rmsd(C, reduce(vcat,sol.u')[:,4])

##
AAf=readlines("Output_CSC/26huhti ODE/output_final300plot.txt")
BBf=map(x -> parse.(Float64, split(x)), AAf)

plot(; legend=false)
Order=ones(8)
Errf=zeros(length(BBf))
for ii in 1:length(BBf)
	i=Int(BBf[ii][1])
	μp,ϕ1,ϕ2,β1,β2,δ,ψ,ω,σ2,γS,γA,ηS,ηA = Candidate[i][2:14]
	par= [Λ,μ,μp,ϕ1,ϕ2,β1,β2,δ,ψ,ω,σ2,γS,γA,ηS,ηA]
	S0=Candidate[i][1]
	IA0=Candidate[i][15]
	P0=Candidate[i][16]
	E0=BBf[ii][9]
	N0=S0+E0+IA0+IS0+R0
	X0=[S0,E0,IA0,IS0,R0,P0,D0,N0]

	Order[1:6]=BBf[ii][2:7]
	Order[8]=BBf[ii][8]

	_, x1 = FDEsolver(Ff, [1,length(C)], X0, Order, par, h=.05, nc=4)
	Pred1=x1[1:20:end,4]
		plot!(Pred1; alpha=0.1, color="darkorange1")
		Errf[ii]=rmsd(C, Pred1)
end
scatter!(C, color=:gray25, markerstrokewidth=0)

#plot the best
valErrf,indErrf=findmin(Errf)
display(["MinErrf",valErrf])

myshowall(stdout, BBf[indErrf,:], false)
i=Int(BBf[indErrf][1])
μp,ϕ1,ϕ2,β1,β2,δ,ψ,ω,σ2,γS,γA,ηS,ηA = Candidate[i][2:14]
p1= [Λ,μ,μp,ϕ1,ϕ2,β1,β2,δ,ψ,ω,σ2,γS,γA,ηS,ηA]
S0=Candidate[i][1]
IA0=Candidate[i][15]
P0=Candidate[i][16]
E0=BBf[indErrf][9]
N0=S0+E0+IA0+IS0+R0
X0=[S0,E0,IA0,IS0,R0,P0,D0,N0]
Order[1:6]=BBf[indErrf][2:7]
Order[8]=BBf[indErrf][8]
_, x1 = FDEsolver(Ff, [1,length(C)], X0, Order, p1, h=.05, nc=4)
Pred1=x1[1:20:end,4]
plot!(Pred1, lw=3, color=:dodgerblue1)

##

plot([reduce(vcat,sol.u')[:,1] x1[1:20:end,1]])

plot([reduce(vcat,sol.u')[:,2] x1[1:20:end,2]])

plot([reduce(vcat,sol.u')[:,3] x1[1:20:end,3]])

plot([reduce(vcat,sol.u')[:,4] x1[1:20:end,4]])
scatter!(C)

plot([reduce(vcat,sol.u')[:,5] x1[1:20:end,5]])
scatter!(TrueR)

plot([reduce(vcat,sol.u')[:,6] x1[1:20:end,6]])

plot([reduce(vcat,sol.u')[:,7] x1[1:20:end,7]])
scatter!(TrueD)

#population
plot([reduce(vcat,sol.u')[:,8] x1[1:20:end,8]])

non300=290

mean(Err[Ind][1:300])
std(Err[Ind][1:300])
var(Err[Ind][1:300])
median(Err[Ind][1:300])
mean(Errf[sortperm(Errf)][1:300])
std(Errf[sortperm(Errf)][1:300])
var(Errf[sortperm(Errf)][1:300])
median(Errf[sortperm(Errf)][1:300])

violin(ones(non300), Err[Ind][1:non300], side = :left)
# boxplot!(ones(non300), Err[Ind][1:non300], side = :left, fillalpha=0.75, linewidth=.02)
# dotplot!(ones(non300), Err[Ind][1:non300], side = :left, marker=(:black, stroke(0)))
violin!(ones(non300), Errf[sortperm(Errf)][1:non300], side = :right)
# scatter!([1.], [mean(Err[Ind][1:non300])])
# scatter!([1.], [mean(Errf[sortperm(Errf)][1:non300])])

boxplot(reduce(vcat,BB[Ind][1:300]')[:,2:14],legend=:false)
boxplot(reduce(vcat,BB[Ind][1:300]')[:,[3,5,6,11]],legend=:false, yaxis=:log)
boxplot(reduce(vcat,BB[Ind][1:300]')[:,[1,15,16]],legend=:false, yaxis=:log)
boxplot(reduce(vcat,BB[Ind][1:300]')[:,[1,15,16]],legend=:false, yaxis=:log)

boxplot(reduce(vcat,BBf')[:,2:8],legend=:false,yaxis=:log)
violin(reduce(vcat,BBf')[:,9],legend=:false, yaxis=:log)


mean(reduce(vcat,BBf')[:,9])
median(reduce(vcat,BBf')[:,9]*1e10)
std(reduce(vcat,BBf')[:,9])
