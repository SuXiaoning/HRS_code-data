
***********Unintended Impacts of Hydrogen Energy Infrastructure in China***********

clear all
use "D:\document\hrs_shuju.dta"

****Define post****
gen post =.
replace post = tran_year > jqz_year

*****************************************************************
***Estimated price function before and after completion of HRS***
*****************************************************************

preserve

qui: su near_dist
global h = 3*1.06*r(sd)*(_N)^(-1/5)
gen temp = int(${h})
local band = temp[1]
drop temp

di "${h}"
   
qui reg lnprice_d  lnn_mall lnxq_area lngreen lnhouse_year1 lnd_gov  ///
        lnn_bus	  i.tran_q , r

predict lp_resid, residuals

gen r=uniform()
gsort r

gen points = .
forvalues i =1/1000 {
	qui:replace points = `i'*8 in `i'
}

qui lpoly lp_resid near_dist if post ==0, gen(yhat_bf) se(se_bf) at(points)  bwidth(${h}) degree(1) kernel(gaussian) msymbol(oh) msize(small) mcolor(gs10) ci noscatter nograph
qui lpoly lp_resid near_dist if post ==1, gen(yhat_af) se(se_af) at(points)  bwidth(${h}) degree(1) kernel(gaussian) msymbol(oh) msize(small) mcolor(gs10) ciopts(lwidth(medium)) noscatter nograph

gen bf_lb = yhat_bf - 1.96*se_bf
gen bf_ub = yhat_bf + 1.96*se_bf
gen af_lb = yhat_af - 1.96*se_af
gen af_ub = yhat_af + 1.96*se_af

*Find the intersection of the 95% confidence interval of the after--before curves
gen dif = abs(af_lb - bf_ub)
replace dif = . if points<1000
su dif

gen min_dif = r(min)
gen dist = points if dif == min_dif
su dist

global dist = r(mean)

**Figure 2(A) Estimated price function before and after completion of HRS**

twoway ///
(rarea bf_lb bf_ub points, sort color(gs13)) ///
(rarea af_lb af_ub points, sort color(gs13)) ///
(line yhat_bf points, lcolor(black) lpattern(dash)) ///
(line yhat_af points, lcolor(black) lpattern(solid)), ///
xtitle("Distance to the nearest HRS (m)")   ///
ytitle("Residuals of log housing price") ///
legend(order(4 "Before HRS completion" 3 "After HRS completion" 1 "95% CI") row(1)) ///
saving(lpoly_bf_af_`j'.gph,replace)

graph export lpoly_bf_af_`j'.eps,replace

restore


***Define treatment group and control group***

gen near=1
replace near=0 if near_dist>1400
gen inter=post*near

***Descriptive statistics***
sum lnprice_d post near lnxq_area lngreen lnd_gov lnn_mall lnn_bus lnntl lnndvi lnhouse_year1
sum lnprice_d post lnxq_area lngreen lnd_gov lnn_mall lnn_bus lnntl lnndvi lnhouse_year1 if near == 1
sum lnprice_d post lnxq_area lngreen lnd_gov lnn_mall lnn_bus lnntl lnndvi lnhouse_year1 if near == 0
ttest lnprice_d,by(near)
ttest post, by(near)
ttest lnxq_area  ,by(near)
ttest lngreen ,by(near)
ttest lnd_gov  ,by(near)
ttest lnn_mall  ,by(near)
ttest lnn_bus ,by(near)
ttest  lnntl ,by(near)
ttest  lnndvi ,by(near) 
ttest lnhouse_year1 ,by(near)

***********************
***Common trend test***
***********************

gen tran_jqz = tran_year-jqz_year

forvalues i=8(-1)1{
   gen pre`i' = (tran_jqz==-`i' & near==1)
}

gen current=(tran_jqz== 0 & near==1)

forvalues i=1(1)8{
  gen post`i'=(tran_jqz==`i' & near==1)
}

*Regression of dummy variables for periods before and after the policy time point 
preserve
drop pre1
reg lnprice_d pre5 pre4 pre3 pre2 current post1 post2 post3 post4 post5  lnxq_area lngreen lnd_gov lnn_mall lnn_bus lnntl lnndvi lnhouse_year1 i.tran_year i.city_id ,r 

*Figure 1(D) Common trend test
coefplot, baselevels ///
keep(pre* current post*) ///
vertical ///
coeflabels( pre5=-5 pre4=-4 pre3=-3 pre2=-2 pre1=-1 ///
current=0 post1=1 post2=2 post3=3 post4=4 post5=5 ) /// 
yline(0,lwidth(vthin) lpattern(solid) lcolor(teal)) ///
xline(5,lwidth(vthin) lpattern(solid) lcolor(teal)) ///
ylabel(-0.8(0.2)0.8,labsize(*0.85) angle(0)) xlabel(,labsize(*0.85)) ///
ytitle("Changes in log housing price (%)") ///
xtitle("Years relative to HRS completion year") ///
legend(order(3 "Estimated coefficients" 1 "95% CI") row(1)) ///
msymbol(O) msize(small) mcolor(gs1) ///
addplot(line @b @at,lcolor(gs1) lwidth(medthick)) ///
ciopts(recast(rline) lwidth(thin) lpattern(dash) lcolor(gs2)) ///
graphregion(color(white)) // 

restore

******************************
***Average treatment effect***
******************************

reghdfe lnprice_d inter post near lnxq_area lngreen lnd_gov lnn_mall lnn_bus lnntl lnndvi lnhouse_year1, noabsorb vce(r)  keepsingletons
est store m1
reghdfe lnprice_d inter post near lnxq_area lngreen lnd_gov lnn_mall lnn_bus lnntl lnndvi lnhouse_year1, absorb(tran_year jqz_id ) vce(r) keepsingletons
est store m2
reghdfe lnprice_d inter post near lnxq_area lngreen lnd_gov lnn_mall lnn_bus lnntl lnndvi lnhouse_year1, absorb(tran_year jqz_id jqz_id#c.tran_year) vce(r) keepsingletons
est store m3
reghdfe lnprice_d inter post near lnxq_area lngreen lnd_gov lnn_mall lnn_bus lnntl lnndvi lnhouse_year1, absorb(tran_year jqz_id county_id jqz_id#c.tran_year) vce(r) keepsingletons
est store m4
reghdfe lnprice_d inter post near lnxq_area lngreen lnd_gov lnn_mall lnn_bus lnntl lnndvi lnhouse_year1, absorb(tran_year jqz_id county_id jqz_id#tran_year) vce(r) keepsingletons
est store m5

estimates table m1 m2 m3 m4 m5, keep(inter) b(%7.4f) p(%7.4f) stats(N r2_a)
cd "D:\document\code"
esttab m1 m2 m3 m4 m5 using main.rtf, star(* 0.1 ** 0.05 *** 0.01) compress b(4) se(4) ar2(4) nogap  replace



*********************
***Robustness test***
*********************

*1.Change the processing group scope
*1300m
drop near inter
gen near=1
replace near=0 if near_dist>1300
gen inter=post*near

reghdfe lnprice_d inter post near lnxq_area lngreen lnd_gov lnn_mall lnn_bus lnntl lnndvi lnhouse_year1, absorb(tran_year jqz_id county_id jqz_id#c.tran_year) level(90) vce(r) keepsingletons
est store m1

*1500m
drop near inter
gen near=1
replace near=0 if near_dist>1500
gen inter=post*near

reghdfe lnprice_d inter post near lnxq_area lngreen lnd_gov lnn_mall lnn_bus lnntl lnndvi lnhouse_year1, absorb(tran_year jqz_id county_id jqz_id#c.tran_year) level(90) vce(r) keepsingletons
est store m2

*2.Data under three years old are excluded
drop near inter
gen near=1
replace near=0 if near_dist>1400
gen inter=post*near

reghdfe lnprice_d inter post near lnxq_area lngreen lnd_gov lnn_mall lnn_bus lnntl lnndvi  if house_year1 >=3, absorb(tran_year jqz_id county_id jqz_id#c.tran_year) vce(rovus)

*3.Placebo tests1
clear all
use "D:\document\shuju_an.dta"

gen post =.
replace post = tran_year > jqz_year

*Samples within 1400m and beyond 11000 are removed
drop if near_dist < 1400
drop if near_dist > 11000

gen new_near =0
replace new_near = 1 if  near_dist >9000
gen new_inter = post*new_near

reghdfe lnprice_d new_inter post new_near lnxq_area lngreen lnd_gov lnn_mall lnn_bus lnntl lnndvi lnhouse_year1, absorb(tran_year jqz_id county_id jqz_id#c.tran_year)  vce(r) keepsingletons

*4.change estimation method*
*PSM-DID*
clear all
cd "D:\document\psm"
forvalues i = 2014/2023 {
use "shuju_shiyan.dta", clear
keep if tran_year ==`i'
set seed 20231226
gen tmp = runiform()
sort tmp
psmatch2 near  lngreen lnhouse_year1, radius caliper(0.05) outcome(lnprice_d) common  odds index logit quietly ate
drop if _weight==.
save psmdid_`i' , replace
}

use "psmdid_2014.dta", clear
forvalues i = 2015/2023 {
append using psmdid_`i'
}

reghdfe lnprice_d inter post near lnxq_area lngreen lnd_gov lnn_mall lnn_bus lnntl lnndvi lnhouse_year1 if _support ==1, absorb(tran_year jqz_id county_id jqz_id#c.tran_year)  vce(robust) //
est store m5

*CEM-DID*
clear all
cd "D:\document\psm"
set maxvar 32767
forvalues i = 2014/2023 {
use "shuju_shiyan.dta", clear
keep if tran_year ==`i'
set seed 20231226
cem lngreen  lnhouse_year1, tr(near)
save cemdid_`i' , replace
}

use "cemdid_2014.dta", clear
forvalues i = 2015/2023 {
append using cemdid_`i'
}

reg lnprice_d inter post near lnxq_area lngreen lnd_gov lnn_mall lnn_bus lnntl lnndvi lnhouse_year1  i.tran_year i.jqz_id i.county_id i.jqz_id#c.tran_year [iweight = cem_weight] , r
est store m6

ereturn list
// 
scalar adj_r2 = e(r2_a)
di "Adjusted R-squared: " adj_r2

***Figure 1(A) Average treatment effects from different models***
matrix mean = (  -0.0857539, -0.0750931 , -0.0748064,  -0.0682343,-0.0723212,-0.0593822 )

matrix colnames mean = model2 model3 model4 model5 model6 model7
matrix rownames mean = mean

matrix CI = (-0.142296,-0.1309219,-0.126435,-0.1248214,-0.1239977,-0.1159057\ ///
 -0.0292118,-0.0192643, -0.0231778,  -0.0116473,-0.0206446,-0.0028587)
matrix colnames CI =  model2 model3 model4 model5 model6 model7

matrix rownames CI = ll95 ul95
coefplot matrix(mean), pstyle(p1)  ///
         xline(0)  ///
		 xtitle("Changes in log housing price (%)") ///
		 ci(CI) ciopts(recast(rcap)) ///
         legend(order(2 "Estimated coefficients" 1 "95% CI")) ///
         graphregion(color(white))
		 
*********Figure 2(B) Robustness and placebo tests. ************
matrix mean = (-0.0509009, -0.0454922, -0.0637519,  0.000388)

matrix colnames mean = Robust1300 Robust1500 Robustage>=3  Placebo
matrix rownames mean = mean

matrix CI = ( -0.0959962, -0.0879607, -0.119922, -0.033768\ ///
 -0.0058057, -0.0030236, -0.0075819, 0.034544)
matrix colnames CI = Robust1300 Robust1500  Robustage>=3 Placebo

matrix rownames CI = ll95 ul95
coefplot matrix(mean), pstyle(p1)  ///
         yline(0) xline(2.5, lp(dash) lcolor(gs11)) ///
		 xline(3.5, lp(dash) lcolor(gs11))   ///
		 ytitle("Changes in log housing price (%)") ///
         xtitle("Robustness and Placebo tests") ///
		 ci(CI) ciopts(recast(rcap)) ///
         vertical legend(order(2 "Estimated coefficients" 1 "95% CI" 1 "90% CI")) ///
         graphregion(color(white))			 

		 
*5.Placebo tests2
clear all
cd "D:\document\f"
set maxvar 32767

set matsize 11000
mat b = J(500,1,0) //
mat se = J(500,1,0) //
mat p = J(500,1,0) //

* Loop 500 times *
forvalues i =1/500 {
    use shuju_new.dta, clear
	bysort xiaoqu_id : gen aba =_n
	keep if aba ==1
	drop aba 
	sample 933, count //
	keep id //
	save matchyear.dta, replace //
	merge 1:m id using shuju_new.dta //
	gen near_awj = (_merge == 3) //
	save matchyear`i'.dta, replace 
* Pseudo policy *
    use shuju_new.dta, clear
	bsample 1, strata(id) //
	keep tran_year 
	save matchyear.dta, replace
	mkmat tran_year, matrix(sampleyear)
	use matchyear`i'.dta, clear
	gen post_awj =0
	forvalues j =1/21966 {
	 replace post_awj =1 if (id == `j' & tran_year >= sampleyear[`j',1])   
	}
	gen inter_awj = near_awj * post_awj
	sum lnprice_d inter_awj post_awj near_awj 
	reghdfe lnprice_d inter_awj post_awj near_awj lnxq_area lngreen lnd_gov lnn_mall lnn_bus lnntl lnndvi lnhouse_year1, absorb(tran_year jqz_id county_id jqz_id#c.tran_year) cluster(xiaoqu_id) keepsingletons 
	mat b[`i',1] = _b[inter_awj] //
    mat se[`i',1] = _se[inter_awj] //
    scalar df_r = e(N) - e(df_m) -1
    mat p[`i',1] = 2*ttail(df_r,abs(_b[inter_awj]/_se[inter_awj])) //
}
svmat b, names(coef) //
svmat se, names(se)
svmat p, names(pvalue)

drop if pvalue1 == .
label var pvalue1 p-value
label var coef1 coefficient
twoway (scatter pvalue1 coef1,  xlabel(-0.1(0.05)0.1, grid) yline(0.1,lp(shortdash)) xline(-0.068,lp(shortdash)) /// 
xtitle({stSerif:coefficient}) ytitle({stSerif:p value}) msymbol(smcircle_hollow) mcolor(blue) legend(off)) (kdensity coef1, title(Placebo tests))

*********Figure 1(C) Placebo test. ************
twoway (scatter pvalue1 coef1, xline(-0.068) yline(0.1) msymbol(smcircle_hollow) mcolor(gray))
* Draw a coefficient - nuclear density plot
twoway (hist coef1, vertical fcolor(gs14) lcolor(black) lwidth(vthin))(kdensity coef1,title(Placebo tests))

************************************
***Heterogeneous treatment effects**		 
************************************

*Population density
clear all
use "D:\document\hrs_shuju.dta"

gen post =.
replace post = tran_year > jqz_year

gen near=1
replace near=0 if near_dist>1400
gen inter=post*near

gen tem =pop_den
bysort city_id: egen tem1 = mean(tem)
replace tem = tem1 if tem ==.
replace pop_den = tem if pop_den ==.
drop tem tem1

preserve
drop if pop_den <= 1
sum pop_den ,d

reghdfe lnprice_d inter post near lnxq_area lngreen lnd_gov lnn_mall lnn_bus lnntl lnndvi lnhouse_year1 if pop_den < 7500, absorb(tran_year jqz_id county_id jqz_id#c.tran_year)  vce(r)  keepsingletons
est sto Low
	
reghdfe lnprice_d inter post near lnxq_area lngreen lnd_gov lnn_mall lnn_bus lnntl lnndvi lnhouse_year1 if pop_den >= 7500, absorb(tran_year jqz_id county_id jqz_id#c.tran_year) vce(r)  	keepsingletons 
est sto High	  
	  
coefplot (Low High) ,   ///
		  drop(_cons) keep(inter)  ///
		  aseq swapnames vertical  ///
          xlabel(1 "Low" 2 "High") ///
	      yline(0) ///
          ytitle("Changes in log housing price (%)") ///
          xtitle("Group by population density") ///
		  ciopts(recast(rcap) ) ///
          legend(order(2 "Estimated coefficients" 1 "95% CI")) ///
          graphregion(color(white) )

restore

*night lights
preserve
est clear
xtile n_ntl = ntl , nq(2)
forvalues i = 1/2 {
	 reghdfe lnprice_d inter post near lnxq_area lngreen lnd_gov lnn_mall lnn_bus lnntl lnndvi lnhouse_year1 if n_ntl == `i', absorb(tran_year jqz_id county_id jqz_id#c.tran_year)  vce(robust) keepsingletons  
    est store m`i'
}
estimates table m1 m2 , keep(inter) b(%7.4f) p(%7.4f) stats(N r2_a)
coefplot (m1 m2 ) ,   ///
		  drop(_cons) keep(inter)  ///
		  aseq swapnames vertical  ///
          xlabel(1 "m1" 2 "m2" ) ///
	      yline(0) ///
          ytitle("Changes in log housing price (%)") ///
          xtitle("Group by ntl") ///
		  ciopts(recast(rcap)) ///
          legend(order(2 "Estimated coefficients" 1 "95% CI")) ///
          graphregion(color(white))
restore

*Resident awareness
* Is it the first hydrogen station in the city
gen first_jqz =0
bysort city_id: egen min_year = min(jqz_year)
replace first_jqz =1 if jqz_year == min_year
drop min_year
tab first_jqz	

reghdfe lnprice_d inter post near lnxq_area lngreen lnd_gov lnn_mall lnn_bus lnntl lnndvi lnhouse_year1 if first_jqz == 1, absorb(tran_year jqz_id county_id jqz_id#c.tran_year)  vce(r) keepsingletons 		  
est sto first

reghdfe lnprice_d inter post near lnxq_area lngreen lnd_gov lnn_mall lnn_bus lnntl lnndvi lnhouse_year1 if first_jqz == 0, absorb(tran_year jqz_id county_id jqz_id#c.tran_year) vce(r)   keepsingletons  	  
est sto nofirst

* Baidu Search Index (Hydrogen)
gen participation =0
replace participation =1 if Now_later <0

reghdfe lnprice_d inter post near lnxq_area lngreen lnd_gov lnn_mall lnn_bus lnntl lnndvi lnhouse_year1 if participation == 1, absorb(tran_year jqz_id county_id jqz_id#c.tran_year) vce(r)  keepsingleton 	   
est sto Highindex

reghdfe lnprice_d inter post near lnxq_area lngreen lnd_gov lnn_mall lnn_bus lnntl lnndvi lnhouse_year1 if participation == 0, absorb(tran_year jqz_id county_id jqz_id#c.tran_year)  vce(r)  keepsingletons 	  
est sto Lowindex
	    

coefplot (first nofirst Highindex Lowindex) ,   ///
		  drop(_cons) keep(inter)  ///
		  aseq swapnames   ///
          ylabel( 1 "First" 2 "Not first"  3 "High index" 4 "Low index"  ) ///
	      xline(0)  ///
          xtitle("Changes in log housing price (%)") ///
          ciopts(recast(rcap)) ///
          legend(order(2 "Estimated coefficients" 1 "95% CI")) ///
          graphregion(color(white))	
		  
		 
*Hydrogen energy infrastructure
* New hydrogen refueling station =1; Hydrogen refueling station renovation =0	  	
reghdfe lnprice_d inter post near lnxq_area lngreen lnd_gov lnn_mall lnn_bus lnntl lnndvi lnhouse_year1 if jqz_n == 1, absorb(tran_year jqz_id county_id jqz_id#c.tran_year)  vce(r)  keepsingletons  
est sto new

reghdfe lnprice_d inter post near lnxq_area lngreen lnd_gov lnn_mall lnn_bus lnntl lnndvi lnhouse_year1 if jqz_n == 0, absorb(tran_year jqz_id county_id jqz_id#c.tran_year)  vce(r)  keepsingletons    		  
est sto rebuild

coefplot (new rebuild) ,   ///
		  drop(_cons) keep(inter)  ///
		  aseq swapnames vertical  ///
          xlabel(1 "new" 2 "rebuild") ///
	      yline(0) ///
          ytitle("Changes in log housing price (%)") ///
          xtitle("Group by hydrogen energy infrastructure") ///
		  ciopts(recast(rcap)) ///
          legend(order(2 "Estimated coefficients" 1 "95% CI")) ///
          graphregion(color(white))
		  

* Number of hydrogen production plants
sum num_hydplant,d	  
gen num_qingneng =0
replace num_qingneng=1 if num_hydplan >=  1.641493	  

reghdfe lnprice_d inter post near lnxq_area lngreen lnd_gov lnn_mall lnn_bus lnntl lnndvi lnhouse_year1 if num_qingneng == 1, absorb(tran_year city_id tran_q tran_q#city_id)  vce(r) keepsingletons 	  
est sto more_hydrogen

reghdfe lnprice_d inter post near lnxq_area lngreen lnd_gov lnn_mall lnn_bus lnntl lnndvi lnhouse_year1 if num_qingneng == 0, absorb(tran_year city_id tran_q tran_q#city_id) vce(r)  keepsingletons 	  
est sto fewer_hydrogen


coefplot (more_hydrogen fewer_hydrogen) ,   ///
		  drop(_cons) keep(inter)  ///
		  aseq swapnames vertical  ///
          xlabel(1 "more_hydrogen" 2 "fewer_hydrogen") ///
	      yline(0) ///
          ytitle("Changes in log housing price (%)") ///
          xtitle("Group by hydrogen energy infrastructure") ///
		  ciopts(recast(rcap)) ///
          legend(order(2 "Estimated coefficients" 1 "95% CI")) ///
          graphregion(color(white))

		  		 
*Policy environment
drop if government_concern==0
sum government_concern,d

gen d_gov= 0
replace d_gov=1 if government_concern>0.0036007

reghdfe lnprice_d inter post near lnxq_area lngreen lnd_gov lnn_mall lnn_bus lnntl lnndvi lnhouse_year1 if d_gov==0 , absorb(tran_year jqz_id county_id jqz_id#c.tran_year)  vce(robust)
est sto nonconcern

reghdfe lnprice_d inter post near lnxq_area lngreen lnd_gov lnn_mall lnn_bus lnntl lnndvi lnhouse_year1 if d_gov==1 , absorb(tran_year jqz_id county_id jqz_id#c.tran_year)  vce(robust)
est sto concern
		

*Geographical position
*1.According to the east, west, central region division method

clear all
use "D:\document\hrs_shuju.dta"

gen post =.
replace post = tran_year > jqz_year
gen near=1
replace near=0 if near_dist>1400
gen inter=post*near

gen eastern_region = 0
replace eastern_region =1 if province_id == 1|province_id == 4|province_id == 12|province_id == 16|province_id == 7|province_id == 10|province_id == 14|province_id == 18|province_id == 19|province_id == 22

gen western_region = 0
replace western_region =1 if province_id == 2|province_id == 3|province_id == 6|province_id == 8|province_id == 13|province_id == 23|province_id == 25|province_id == 26

gen central_region = 0
replace central_region =1 if province_id == 11|province_id == 15|province_id == 9|province_id == 17|province_id == 20|province_id == 21

tab eastern_region 
tab western_region 
tab central_region


***eastern_region***
reghdfe lnprice_d inter post near lnxq_area lngreen lnd_gov lnn_mall lnn_bus lnntl lnndvi lnhouse_year1 if eastern_region ==1, absorb(tran_year jqz_id county_id jqz_id#c.tran_year)  vce(r) keepsingletons
est store er2

***central_region***
reghdfe lnprice_d inter post near lnxq_area lngreen lnd_gov lnn_mall lnn_bus lnntl lnndvi lnhouse_year1 if central_region ==1, absorb(tran_year jqz_id county_id jqz_id#c.tran_year)  vce(r) keepsingletons
est store cr2

***western_region***
reghdfe lnprice_d inter post near lnxq_area lngreen lnd_gov lnn_mall lnn_bus lnntl lnndvi lnhouse_year1 if western_region ==1, absorb(tran_year jqz_id county_id jqz_id#c.tran_year)  vce(r) keepsingletons
est store wr2


coefplot (er2 cr2 wr2 ) ,   ///
		  drop(_cons) keep(inter)  ///
		  aseq swapnames vertical  ///
          xlabel(1 "Eastern" 2 "Central" 3 "Western" ) ///
	      yline(0)  ///
          ytitle("Changes in log housing price (%)") ///
          xtitle("Group by different regions") ///
		  ciopts(recast(rcap)) ///
          legend(order(2 "Estimated coefficients" 1 "95% CI")) ///
          graphregion(color(white))
	  
******************************************************************
*2.According to whether it is a provincial capital city
tab capital

***provincial capital city***
reghdfe lnprice_d inter post near lnxq_area lngreen lnd_gov lnn_mall lnn_bus lnntl lnndvi lnhouse_year1 if capital ==1, absorb(tran_year jqz_id county_id jqz_id#c.tran_year)  vce(r) keepsingletons
est store pcc2

***no provincial capital city***
reghdfe lnprice_d inter post near lnxq_area lngreen lnd_gov lnn_mall lnn_bus lnntl lnndvi lnhouse_year1 if capital ==0, absorb(tran_year jqz_id county_id jqz_id#c.tran_year) vce(r) keepsingletons
est store npcc2

coefplot (pcc2 npcc2) ,   ///
		  drop(_cons) keep(inter)  ///
		  aseq swapnames vertical  ///
          xlabel(1 "Provincial capital" 2 "Non-provincial capital" ) ///
	      yline(0)  ///
          ytitle("Changes in log housing price (%)") ///
          xtitle("Group by different regions") ///
		  ciopts(recast(rcap)) ///
          legend(order(2 "Estimated coefficients" 1 "95% CI")) ///
          graphregion(color(white))

*3.According to the resource-based city division method


gen resource_city1=0
replace resource_city1=1 if resource_city ==1|resource_city ==2|resource_city ==3|resource_city ==4
tab resource_city1

reghdfe lnprice_d inter post near lnxq_area lngreen lnd_gov lnn_mall lnn_bus lnntl lnndvi lnhouse_year1 if resource_city1 ==0, absorb(tran_year jqz_id county_id jqz_id#c.tran_year)  vce(r) keepsingletons
est store rec0

reghdfe lnprice_d inter post near lnxq_area lngreen lnd_gov lnn_mall lnn_bus lnntl lnndvi lnhouse_year1 if resource_city1 ==1, absorb(tran_year jqz_id county_id jqz_id#c.tran_year)  vce(r) keepsingletons
est store rec1

coefplot (rec0 rec1) ,   ///
		  drop(_cons) keep(inter)  ///
		  aseq swapnames vertical  ///
          xlabel(1 "Non-resource-based city" 2 "Resource-based city" ) ///
	      yline(0)  ///
          ytitle("Changes in log housing price (%)") ///
          xtitle("Group by different resource-based citys") ///
		  ciopts(recast(rcap)) ///
          legend(order(2 "Estimated coefficients" 1 "95% CI")) ///
          graphregion(color(white))
		  
***********************************************************************
*4.According to the first, second, third, fourth and fifth tier cities

clear all
use "D:\document\hrs_shuju_city.dta"

gen post =.
replace post = tran_year > jqz_year
gen near=1
replace near=0 if near_dist>1400
gen inter=post*near

***yixian***
reghdfe lnprice_d inter post near lnxq_area lngreen lnd_gov lnn_mall lnn_bus lnntl lnndvi lnhouse_year1 if bigcity ==1|bigcity ==2, absorb(tran_year jqz_id county_id jqz_id#c.tran_year) vce(r) keepsingletons
est store yx2

***erxian***
reghdfe lnprice_d inter post near lnxq_area lngreen lnn_mall lnn_bus lnntl lnndvi lnhouse_year1 if bigcity ==3, absorb(tran_year jqz_id county_id jqz_id#c.tran_year)  vce(r) keepsingletons
est store ex2

***sanxian***
reghdfe lnprice_d inter post near lnxq_area lngreen lnd_gov lnn_mall lnn_bus lnntl lnndvi lnhouse_year1 if bigcity ==4, absorb(tran_year jqz_id county_id jqz_id#c.tran_year) vce(r) keepsingletons
est store tx2

***sixian***
reghdfe lnprice_d inter post near lnxq_area lngreen lnd_gov lnn_mall lnn_bus lnntl lnndvi lnhouse_year1 if bigcity ==5, absorb(tran_year jqz_id county_id jqz_id#c.tran_year) vce(r) keepsingletons
est store fx2

***wuxian***
reghdfe lnprice_d inter post near lnxq_area lngreen lnd_gov lnn_mall lnn_bus lnntl lnndvi lnhouse_year1 if bigcity ==6, absorb(tran_year jqz_id county_id jqz_id#c.tran_year)  vce(r) keepsingletons
est store wx2

coefplot (yx2 ex2 tx2 fx2 wx2) ,   ///
		  drop(_cons) keep(inter)  ///
		  aseq swapnames vertical  ///
          xlabel(1 "First-tier" 2 "Second-tier" 3 "Third-tier" 4 "Fourth-tier" 5 "Fifth-tier" ) ///
	      yline(0)  ///
          ytitle("Changes in log housing price (%)") ///
          xtitle("Group by different regions") ///
		  ciopts(recast(rcap)) ///
          legend(order(2 "Estimated coefficients" 1 "95% CI")) ///
          graphregion(color(white))
		  

	 
**Figure 3 Heterogeneous treatment effects of HRSs a.********************

matrix mean = (-0.0839276,-0.0707547,-0.0049358,-0.1680522,-0.0959065,-0.0689422,0.0690875,0.1384632,-0.1904585,-0.022424,-0.1206005,0.0334618)

matrix colnames mean = Eastern Central Western First-tier Second-tier Third-tier Fourth-tier Fifth-tier Provincial Non-provincial Non-resource-based Resource-based
matrix rownames mean = mean

matrix CI = (-0.1456553,-0.2114624,-0.1022614,-0.270032,-0.1753055,-0.1424031,-0.0498652,0.0163502,-0.2994923,-0.0742368,-0.185991,-0.0449713\ ///
-0.0221999,0.0699531,0.0923898,-0.0660723,-0.0165074,0.0045187,0.1880402,0.2605762,-0.0814248,0.0293889,-0.0552101,0.1118949)
matrix colnames CI = Eastern Central Western First-tier Second-tier Third-tier Fourth-tier Fifth-tier Provincial Non-provincial Non-resource-based Resource-based

matrix rownames CI = ll95 ul95

coefplot matrix(mean), pstyle(p1) vertical ///
         yline(0,lp(solid) )  ///
		 xlabel(1 "Eastern" 2 "Central" 3 "Western" 4 "First-tier" 5 "Second-tier" 6 "Third-tier" 7 "Fourth-tier" 8 "Fifth-tier" 9 "Provincial capital" 10 "Non-provincial capital" 11 "Non-resource-based" 12 "Resource-based" )  ///
		 ytitle("Changes in log housing price (%)") ///       
		 ci(CI) ciopts(recast(rcap)) ///
		 legend(order(2 "Estimated coefficients" 1 "95% CI")) ///
         graphregion(color(white)) 		 
		 
**Figure 3 Heterogeneous treatment effects of HRSs b.********************

matrix mean = (-0.073258,-0.1162289,-0.0308104,-0.095844,-0.108403,0.0371661,-0.0737557,-0.0944071,-0.09178,-0.0467248,-0.056099,-0.1034743,-0.1319984,0.0056289)

matrix colnames mean = Low_Population_Density High_Population_Density Low_VIIRS  High_VIIRS first nofirst Highindex Lowindex new rebuild  more_hydrogen fewer_hydrogen Low_attention High_attention
matrix rownames mean = mean

matrix CI = (-0.1312911,-0.2381341,-0.0981285,-0.1788189,-0.1654989,-0.0718688,-0.1367143,-0.1878601,-0.165487,-0.1077914,-0.1535389,-0.17838223,-0.2002699,-0.0660672\ ///
-0.0152249,0.0056764,0.0365077,-0.0128692,-0.051307,0.1462009,-0.0107972,-0.000954,-0.018073,0.0143418,0.0413589,-0.0285664,-0.0637268,0.0773249)
matrix colnames CI = Low_Population_Density High_Population_Density Low_VIIRS  High_VIIRS first nofirst Highindex Lowindex new rebuild  more_hydrogen fewer_hydrogen Low_attention High_attention

matrix rownames CI = ll95 ul95

coefplot matrix(mean), pstyle(p1) vertical ///
         yline(0,lp(solid) )  ///
		 xlabel(-0.4(0.2)0.4) ///
		 xlabel(1 "Low_Population_Density" 2 "High_Population_Density" 3 "Low_VIIRS"  4 "High_VIIRS" 5 "First" 6 "Not first"  7 "High index" 8 "Low index" 9 "New" 10 "Rebuild"  11 "More_hydrogen" 12 "Fewer_hydrogen" 13 "Low_attention" 14 "High_attention" )  ///	
		 ytitle("Changes in log housing price (%)") /// 
		 ci(CI) ciopts(recast(rcap)) ///
		 legend(order(2 "Estimated coefficients" 1 "95% CI")) ///
         graphregion(color(white)) 	
		 
********************************************************************************
*Event study estimators******************
clear all
set maxvar 32767
set niceness 10
use "D:\document\hrs_shuju.dta"

gen post =.
replace post = tran_year > jqz_year
gen near=1
replace near=0 if near_dist>1400
gen inter=post*near


*1.Borusyak*
gen K = tran_year - jqz_year
forvalues l = 0/4 {
	gen L`l'event = K==`l'
}
forvalues l = 1/4 {
	gen F`l'event = K==-`l'
}

did_imputation lnprice_d xiaoqu_id tran_year jqz_year if K>=-4 & K<=4, horizons(0/4) autosample pretrend(4) fe( tran_year#city_id city_id tran_year ) tol(500) c( lnxq_area lngreen lnd_gov lnn_mall lnn_bus lnntl lnndvi lnhouse_year1)

event_plot, default_look graph_opt(xtitle( "{stSerif:Periods since the event}") ytitle( "{stSerif:Average causal effect}") title( "{stSerif:Borusyak et al. (2021) imputation estimator}") xlabel(-4(1)4)) 
estimates store bjs

*2.Sun and Abraham (2020)*
gen K1 = tran_year - jqz_year
forvalues l = 0/4 {
	gen LL`l'event = K1==`l'
}
forvalues l = 1/5{
	gen FF`l'event = K1==-`l'
}
gen never_treat = 0
replace never_treat =1 if near ==0

eventstudyinteract lnprice_d LL*event FF*event, absorb(tran_year city_id##tran_q) vce(cluster province_id) cohort(tran_year) control_cohort(never_treat) covariates(lnxq_area lnd_gov lnntl lnndvi)

event_plot e(b_iw)#e(V_iw), default_look graph_opt(xtitle("Periods since the event") ytitle("Average causal effect") xlabel(-5(1)4) title("Sun and Abraham (2020)")) stub_lag(LL#event) stub_lead(FF#event) together

matrix sa_b = e(b_iw) // storing the estimates for later
matrix sa_v = e(V_iw)

*3.OLS*
gen M = tran_year - jqz_year
forvalues l = 0/8 {
	gen A`l'event = (M==`l' & near==1)
}
forvalues l = 1/8 {
	gen B`l'event = (M==-`l' & near==1)
}
reghdfe lnprice_d  B4event B3event B2event B1event A0event A1event A2event A3event A4event A5event  lnxq_area lngreen lnd_gov lnn_mall lnn_bus lnntl lnndvi lnhouse_year1   , a(tran_year city_id)     
event_plot, default_look stub_lag(A#event) stub_lead(B#event) together graph_opt(xtitle("Days since the event") ytitle("OLS coefficients") xlabel(-4(1)4) title("OLS"))

estimates store ols 	

*4.Callaway B, Sant'Anna P H C*
*unrepeated/balanced*
bysort xiaoqu_id tran_year: gen aba =_n
keep if aba ==1
csdid lnprice_d  lnd_gov lnn_bus  , ivar(xiaoqu_id) time(tran_year) gvar(jqz_year)  agg(event) 
est store cs
estimates table cs, keep(Tm3 Tm2 Tm1 Tp0 Tp1 Tp2 Tp3) b(%7.4f) p(%7.4f) stats(N r2_a)
estat event, estore(cs) // this produces and stores the estimates at the same time
event_plot cs, default_look graph_opt(xtitle("Periods since the event") ytitle("Average causal effect") xlabel(-4(1)4) ///
title("Callaway and Sant' Anna (2020) ")) stub_lag(Tp#) stub_lead(Tm#) together

*figure
event_plot cs sa_b#sa_v  ols bjs, ///
	stub_lag(Tp# LL#event  A#event tau# ) stub_lead(Tm#   FF#event  B#event pre# ) plottype(scatter) ciplottype(rcap) ///
	together perturb(-0.2(0.1)0.2) trimlead(4) trimlag(4) noautolegend ///
	graph_opt(xtitle("Periods since the event") ytitle("Average causal effect") xlabel(-4(1)4) ylabel(-1(0.5)0.5) ///
		legend(order(   1 "Callaway-Sant'Anna" 3 "Sun-Abraham" 5 "OLS"  7 "Borusyak et al.") rows(1) region(lcolor(black) lwidth(medium))) ///the following lines replace default_look with something more elaborate
		xline(-0.5, lcolor(gs8) lpattern(dash)) yline(0, lcolor(gs8)) graphregion(color(white)) bgcolor(white) ylabel(, angle(horizontal))) ///
	lag_opt1(msymbol(O) mfc(none) color(dkorange)) lag_ci_opt1(color(dkorange)) ///
	lag_opt2(msymbol(+) color(cranberry)) lag_ci_opt2(color(cranberry)) ///
	lag_opt3(msymbol(Th) color(forest_green)) lag_ci_opt3(color(forest_green)) ///
	lag_opt4(msymbol(Dh) color(navy)) lag_ci_opt4(color(navy)) 



**Figure 1(B) Event study estimators********************
event_plot sa_b#sa_v  ols bjs, ///
	stub_lag(LL#event  A#event tau# ) stub_lead(FF#event  B#event pre# ) plottype(scatter) ciplottype(rcap) ///
	together perturb(-0.2(0.1)0.2) trimlead(4) trimlag(4) noautolegend ///
	graph_opt(xtitle("Periods since the event") ytitle("Average causal effect") xlabel(-4(1)4) ylabel(-1(0.25)0.5) ///
		legend(order( 1 "Sun-Abraham"   3 "OLS"  5 "Borusyak et al.") rows(1) region(style(none))) ///the following lines replace default_look with something more elaborate
		xline(0, lcolor(gs8) lpattern(dash)) yline(0, lcolor(gs8)) graphregion(color(white)) bgcolor(white) ylabel(, angle(horizontal))) ///
	lag_opt1(msymbol(+) color(cranberry)) lag_ci_opt1(color(cranberry)) ///
	lag_opt2(msymbol(Th) color(forest_green)) lag_ci_opt2(color(forest_green)) ///
	lag_opt3(msymbol(Dh) color(navy)) lag_ci_opt3(color(navy)) 
	
graph export "five_estimators_example.png", replace


