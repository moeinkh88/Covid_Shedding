# This code is for fitting parameters Λ,ϕ2,δ,γA  when others parameters are obtained from unbounded initial fitting
using CSV, DataFrames
using Optim, FdeSolver, StatsBase

# Dataset
dataset_CC = CSV.read("time_series_covid19_confirmed_global.csv", DataFrame) # all data of confirmed
Confirmed=dataset_CC[dataset_CC[!,2].=="South Africa",70:250] #comulative confirmed data of Portugal from 3/2/20 to 5/17/20
C=diff(Float64.(Vector(Confirmed[1,:])))# Daily new confirmed cases

dataset_R = CSV.read("time_series_covid19_recovered_global.csv", DataFrame) # all data of Recover
RData=dataset_R[dataset_R[!,2].=="South Africa",70:250]
TrueR=diff(Float64.(Vector(RData[1,:])))

dataset_D = CSV.read("time_series_covid19_deaths_global.csv", DataFrame) # all data of Recover
DData=dataset_D[dataset_D[!,2].=="South Africa",70:249]
TrueD=(Float64.(Vector(DData[1,:])))

#initial conditons and parameters

S0=1.765239357851899e6;E0=0;IA0=0;IS0=17;R0=0;P0=0;D0=0;N0=S0+E0+IA0+IS0+R0
x0=[S0,E0,IA0,IS0,R0,P0,D0,N0] # initial conditons S0,E0,IA0,IS0,R0,P0,D0,N0


pp=[ 0.03255008480745857
    14.858164922911593
    0.0019534731862089643
    1.9701078182517523e-7
    0.8167732148061541
    3.3303562586264358e-6
    4.915958509895935e-10
    0.5971825544021288
    0.0014978053497659918
    0.1199799323762963
    0.02020996148740671
    0.0017309900596145895
    0.2935998931476053
    2.000315974316195e-7
    0.48987945846046593]
μ ,Λ,μp,ϕ1,ϕ2,β1,β2,δ,ψ,ω,σ,γS,γA,ηS,ηA = pp[1:15]
par = [Λ,μ,μp,ϕ1,ϕ2,β1,β2,δ,ψ,ω,σ,γS,γA,ηS,ηA]


tSpan=[1,length(C)]

# Define the equation

function  F(t, x, par)

    Λ,μ,μp,ϕ1,ϕ2,β1,β2,δ,ψ,ω,σ,γS,γA,ηS,ηA=par
    S,E,IA,IS,R,P,D,N=x

    dS= Λ - β1*S*P/(1+ϕ1*P) - β2*S*(IA + IS)/(1+ϕ2*(IA+IS)) + ψ*E - µ*S
    dE= β1*S*P/(1+ϕ1*P)+β2*S*(IA+IS)/(1+ϕ2*(IA+IS)) - ψ*E - μ*E - ω*E
    dIA= (1-δ)*ω*E - (μ+σ)*IA - γA*IA
    dIS= δ*ω*E - (μ + σ)*IS - γS*IS
    dR=γS*IS + γA*IA - μ*R
    dP=ηA*IA + ηS*IS - μp*P
    dD=σ*(IA+IS)
    dN=Λ - σ*(IA+IS) - μ*N
    return [dS,dE,dIA,dIS,dR,dP,dD,dN]

end

Order=ones(8)
#optimization
function loss(args)

	Order[1:7]=args[1:7]
	S0,IA0,P0 = args[8:10]
	Λ,μp,ϕ1,ϕ2,β1,β2,δ,σ,γA,ηS,ηA=args[11:21]
	N0=S0+E0+IA0+IS0+R0
    x0=[S0,E0,IA0,IS0,R0,P0,D0,N0] # initial conditons S0,E0,IA0,IS0,R0,P0,D0,N0

	p=[Λ,μ,μp,ϕ1,ϕ2,β1,β2,δ,ψ,ω,σ,γS,γA,ηS,ηA]
	if size(x0,2) != Int64(ceil(maximum(Order))) # to prevent any errors regarding orders higher than 1
		indx=findall(x-> x>1, Order)
		Order[indx]=ones(length(indx))
	end
	_, x = FDEsolver(F, tSpan, x0, Order, p, h=.05, nc=4)
	Pred=x[1:20:end,[4,5,7]]
	rmsd([C TrueR TrueD], Pred)

end
p_lo_1=vcat(.5*ones(7),1e4,zeros(2),1e-10*ones(11)) #lower bound
p_up_1=vcat(ones(7),2e6,30*ones(2),222,4*ones(10)) # upper bound
p_vec_1=vcat(ones(7),S0,IA0,P0,Λ,μp,ϕ1,ϕ2,β1,β2,δ,σ,γA,ηS,ηA)

print("Λ,μp,ϕ1,ϕ2,β1,β2,δ,σ,γA,ηS,ηA")

Res=optimize(loss,p_lo_1,p_up_1,p_vec_1,Fminbox(LBFGS()),# Broyden–Fletcher–Goldfarb–Shanno algorithm
# Res=optimize(loss,p_lo_1,p_up_1,p_vec_1,SAMIN(rt=.4999), # Simulated Annealing algorithm (sometimes it has better perfomance than (L-)BFGS)
			Optim.Options(#outer_iterations = 10,
						  # iterations=200,
						  show_trace=true,
						  show_every=1)
			)
# obtained for fitting CRF when P-Up=5 [0.9999999998004621, 0.9999999964668235, 0.9265172839266816, 0.9835508220131483, 0.999999999046695, 0.9999999907091582, 1.221807552538849e-5, 3.768795628177853, 0.592964835141523, 0.5983303276384108]
# obtained for fitting CRF when P-Up=1 [0.999663461604957, 0.9999999999999964, 0.9408486963376657, 0.9999999999999716, 0.9999999999999992, 0.9999999999999962, 1.0000003690572517e-5, 0.9999999999999672, 0.5891565550722695, 0.5150955698380737]
display(Res)

Result=vcat(Optim.minimizer(Res))
# display(Result)

function myshowall(io, x, limit = false)
  println(io, summary(x), ":")
  Base.print_matrix(IOContext(io, :limit => limit), x)
end

myshowall(stdout, Array(Result), false)
