/* 
cscript for strbee
was in trtchg\strbee\ado\update2011
moved 12feb2018 to C:\ado\ian\strbee & updated
*/

cd c:\ado\ian\strbee

pda
set more off
set trace off
set tracedepth 3
progver strbee
cscript strbee
set linesize 99

* Comparision of different syntaxes in Jack's data
* what is correct answer?
use example_data, clear
stset T event
gen cens = 40
strbee R, xo0(Toff) xo1(Ton) endstudy(cens) trace
local true = r(psi)

replace Ton = cond(R, min(Ton,T), T-min(Toff,T))
replace Toff = T - Ton
strbee R, xo0(Toff) xo1(Ton) endstudy(cens) trace
assert abs(r(psi) - (`true')) < 1E-5

gen double ton = cond(R, Ton, T-Toff)
gen double toff = cond(R, T - Ton, Toff)
strbee R, ton(ton) toff(toff) endstudy(cens) trace
assert abs(r(psi) - (`true')) < 1E-5

* Now in immdef data

use immdef, clear
stset progyrs prog
set seed 46806
gen x = rnormal()
gen stratum = runiform()<0.5
save z, replace

* Different analyses
strbee imm, graph(title(ITT analysis) name(zgraph_itt, replace)) debug
strbee imm, xo0(xoyrs xo)
strbee imm, xo0(xoyrs xo) 
strbee imm, xo0(xoyrs xo) endstudy(cens) 
local true -0.18116
assert abs(r(psi) - (`true')) < 1E-5

* Different tests
foreach test in stcox logrank wilcoxon tware peto "fh(1 1)" ///
	exponential gompertz loglogistic weibull lognormal { // gamma fails to converge
    dicmd strbee imm, xo0(xoyrs xo) endstudy(cens) test(`test') strata(stratum)
	assert r(psi)>-0.25 & r(psi)<-0.15
}

* Check strbee doesn't change the data
cf _all using z

* Different estimation methods
strbee imm, psimin(-4) psimax(2) psistep(0.1) xo0(xoyrs xo) ///
    endstudy(cens) savedta(temp, replace)
strbee imm, psimin(2) psimax(4) psistep(0.1) xo0(xoyrs xo) ///
    endstudy(cens) savedta(temp, append)
strbee imm, ipe psistart(-1) xo0(xoyrs xo) endstudy(cens)
strbee imm, ipe ipecens psistart(-1) xo0(xoyrs xo) endstudy(cens)

* Many options 
strbee imm, xo0(xoyrs xo) savedta(zz,replace) endstudy(cens) gen(u3) ///
    zgraph(ytitle(Z statistic) title("Crossover-adjusted analysis, no recensoring") ///
		name(zgraph_zz, replace)) ///
    level(99.5) debug hr tol(6) maxiter(50) test(weibull) adjvars(x) strata(stratum) ///
    kmgraph(title(KM graph) name(KMgraph, replace) showall ///
		lpattern(dash dot) lcolor(green red blue)) 
ret list
local psi=r(psi)

* Check saved results
strbee
assert `psi'==r(psi)
strbee using zz, list graph(title("Crossover-adjusted analysis, no recensoring") ///
    name(zgraph_zz2, replace))
assert `psi'==r(psi)

* Debugging
strbee imm, xo0(xoyrs xo) endstudy(cens) trace
strbee imm, xo0(xoyrs xo) endstudy(cens) debug

* Check HR etc.: added 31mar2016
strbee imm, xo0(xoyrs xo) endstudy(cens) hr
local hr_ITT = r(HR_ITT)
local hr = r(HR_adj)
strbee def, xo1(xoyrs xo) endstudy(cens) hr
assert abs(`hr' - 1/r(HR_adj)) < 1E-6
strbee imm, xo0(xoyrs xo) endstudy(cens) hr psimult(2)
assert abs(`hr_ITT' - r(HR_ITT)) < 1E-6
gen ton = progyrs if imm
replace ton = 0 if def & !xo
replace ton = progyrs - xoyrs if def & xo
strbee imm, ton(ton) endstudy(cens) hr
assert abs(`hr' - r(HR_adj)) < 1E-6
strbee, hr(full untr)
assert abs(`hr' - r(HR_user)) < 1E-6

* Check data haven't been changed
drop u du cu ton
cf _all using z

di "*** strbee_cscript has run successfully ***"
