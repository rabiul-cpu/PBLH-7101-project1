/*
Title: Project 1: Data Management, Analytics and Visualization 26
Name: Md. Rabiul Islam
Date: 2/24/2026
Course name: PBHLT 6101/7101: Data Management, Analytics and Presentation for Health Research
   
   BRIEF DESCRIPTION:
   This do-file follows a logical step-by-step flow:
   Step 1: Setup
   Step 2: Explore
   Step 3: Clean
   Step 4: Create New Variables
   Step 5: Analysis
   Step 6: Save
  */
     
   /*===========================================================================
   STEP 1: SETUP
   
   WHY FIRST?
   - I need to set up the environment before doing anything
   - Need to create a unique ID first so every original observation 
     has a permanent identifier before any changes are made
   -  start a log file to record everything do
===========================================================================*/

* Set working directory - change this to your own folder path
cd "C:\Users\u1592799\Box\0. Utah\Course works & TA\2nd sem_SP26\D.JVan\Project 1 updated"

* Open the dataset
use "C:\Users\u1592799\Box\0. Utah\Course works & TA\2nd sem_SP26\D.JVan\Project 1 updated\ansur2allV2.dta", clear

* Start a log file to record all output. This is important for documentation
log using "ansur_log.txt", replace text


* Create unique key variable FIRST before any changes
* This gives every observation a permanent ID number. Starting from 1 going to the last observation
gen unique_id = _n
label variable unique_id "Unique observation identifier (created before any changes)"

* Confirm uniqueness
isid unique_id
//  completed without error

/*altenative way
assert unique_id == _n   /* will error if not unique */
di "unique_id created: all `c(N)' values unique"
* Ran without any error. Welldone! */

* Confirm total number of observations before any cleaning
count
* 7,031 observations


/*===========================================================================
   STEP 2: EXPLORE
   
   WHY BEFORE CLEANING?
   - I must understand the data before I can fix it
   - Exploring helps me spot problems that need to fix
   - Never change data that i do not understand first
===========================================================================*/

* Get a full overview of all variables
* This shows variable names, types, and labels
describe

* Look at detailed information for each variable
* This shows ranges, missing values, and unique values
codebook

* Basic summary statistics for all numeric variables
* This shows min, max, mean for every variable
summarize _all

* Check distribution of categorical variables
* These help to understand the sample composition
tab gender
tab component
tab branch
tab writingpreference

* Check the date variable
* We need to know how many observations have missing dates
codebook date
tab date if date == .
* Observations with no date are likely duplicates

* Check age distribution
* I need to find anyone under 18 who should not be in the study
summarize age, detail
tab age if age < 18

* Quick check of key measurement variables
* Just to get a sense of ranges before any cleaning
summarize stature weightkg weightlbs heightin, detail


/*===========================================================================
   STEP 3: CLEAN
   
   CLEANING ORDER MATTERS:
   
Recode missing values to stata missing values before duplicates remove. Why???
What if a duplicate row has -99 in the date variable?
Stata sees -99 as a NUMBER not as missing.
So flag_duplicate = 0 (not flagged as duplicate)
That duplicate stays in your dataset
	
		
Step	Task	Why
3a=	Fix missing codes (mvdecode)	Must be first — -99 in date affects duplicate detection
3b=	Remove duplicates	Remove before any other cleaning
3c=	Remove under-18	Now no duplicates exist to confuse things
3d=	Fix suspect values	Only real unique observations remain
3e=	Convert mm to cm	After fixing suspect values
3f=	Flag suspect cm values	After conversion
3g=	Label all variables	Last — makes dataset professional
===========================================================================*/

*---------------------------------------------------------------------------
* STEP 3a: REPLACE MISSING VALUE CODES
*
* WHY BEFORE CHECKING SUSPECT VALUES?
* - The dataset uses negative numbers to mean missing:
*   -77 = not recorded
*   -88 = refused measurement  
*   -99 = unknown missing
* - Stata does not know these are missing - it treats them as real numbers
* - If i do not fix this first, -99 will look like an outlier
* - i must convert them to Stata special missing values (MV) first
*
* I use different missing codes to track WHY the value is missing:
*   .a = not recorded (-77)
*   .b = refused (-88)
*   .c = unknown missing (-99)
*---------------------------------------------------------------------------

* Replace all coded missing values across ALL variables at once. This is the most efficient way to do this in Stata
mvdecode _all, mv(-77=.a \ -88=.b \ -99=.c)


* Check how many missing values i now have in each variable

mdesc // if not work for the first time, run it: ssc install mdesc

/*
alternative way

foreach var of varlist _all {
    capture confirm numeric variable `var'
    if !_rc {
        replace `var' = .a if `var' == -77 //not recorded
        replace `var' = .b if `var' == -88 //refused
        replace `var' = .c if `var' == -99 //unknown
    }
} 
*/

* Check all types of missing including .a .b .c
misstable summarize _all


*---------------------------------------------------------------------------

* STEP 3b: HANDLE DUPLICATES
*
* WHY earlier?
* - We remove duplicates first because there is no reason to fix data that we will delete anyway
* - I will delete these observations anyway
* - It saves time to delete them earlier
* - Then we only clean the observations we actually keep
* - Rows without a measurement date are duplicates because:
*   Every real survey observation must have a date
*---------------------------------------------------------------------------

* Flag observations without a valid measurement date
* These are the duplicate records
gen flag_duplicate = (date == .)
label variable flag_duplicate "1 = duplicate observation (no measurement date)"

* Create value labels for the flag variable
label define dup_lbl 0 "Not duplicate" 1 "Duplicate"
label values flag_duplicate dup_lbl

* Check how many are flagged as duplicates
tab flag_duplicate
* 963 flagged as duplicates

* Save duplicates to a separate dataset BEFORE removing them. This is important - i keep them just in case I need them later

* Always run preserve and restore TOGETHER. Never run them separately
preserve
    keep if flag_duplicate == 1
    save "ansur_duplicates.dta", replace
restore

* Now remove the duplicate observations from the main dataset. I keep only observations with valid measurement dates
drop if flag_duplicate == 1

* Verify how many observations remain
count
* I got 6,068 observations


*[preserve // make a photocopy (Take a snapshot of your full dataset) and put it aside safely. Take a snapshot of your full dataset. Stata memorizes everything at this point. 
*keep if flag_duplicate == 1 // Keep ONLY the duplicate rows. This deletes all non-duplicate rows TEMPORARILY
*save "ansur_duplicates.dta", replace // Save these duplicate rows as a separate file
*restore // Go back to the full dataset we saved in preserve. Everything is back to normal - nothing was permanently changed

/* Why I Save Duplicates Separately? 
| **Documentation** | Assignment asks me to move duplicates to separate dataset |
| **Safety** | If i make a mistake i still have them |
| **Evidence** | i can prove what i removed and why |
| **Marking** | Professor can check what i identified as duplicates */

/* Alternative approaches to save a dupliate dataset
* safest approach wothout restore and preserve command. Save full dataset first
save "ansur_temp.dta", replace
* Save only duplicates to separate file
use "ansur_temp.dta", clear
keep if flag_duplicate == 1
save "ansur_duplicates.dta", replace
* Go back to full dataset
use "ansur_temp.dta", clear
* Now remove duplicates
drop if flag_duplicate == 1

*Or
* Just use keep and reload. Save duplicates
keep if flag_duplicate == 1
save "ansur_duplicates.dta", replace
* Reload original dataset
use "ansur_data.dta", clear
* Redo cleaning steps and remove duplicates
drop if flag_duplicate == 1
*/


*---------------------------------------------------------------------------
* STEP 3c: REMOVE UNDER-18 SUBJECTS
* WHY?
* - The military approval for this survey required participants to be at least 18 years of age
*---------------------------------------------------------------------------
* First check who is under 18
tab age if age < 18
list unique_id gender age if age < 18

* Remove subjects under 18
drop if age < 18

* Verify
count
* 7,029 observations in the dataset



*---------------------------------------------------------------------------
* STEP 3d: FIX SUSPECT AND IMPLAUSIBLE VALUES
*
* WHY AFTER MISSING VALUES?
* - Now that missing codes are gone, only real values remain
* - We can now check which real values are implausible
* - We create a flag variable to document all problems found
*
* FLAG VARIABLE RULES:
*   0 = no problem found
*   1 = suspect or implausible value found
*---------------------------------------------------------------------------

* Create the suspect flag variable
* Start everyone at 0 (no problem)
gen flag_suspect = 0
label variable flag_suspect "1 = suspect or unreasonable value"
label define suspect_lbl 0 "No problem" 1 "Suspect value"
label values flag_suspect suspect_lbl

* --- FIX WEIGHTKG ---
* Codebook says weightkg is recorded as kg*10
* However after checking tab weightkg the values are already in kg
* For example values like 70, 80, 85 confirm it is already in kg
* Therefore NO conversion or division needed
* We only flag and remove impossible values

* Flag zero weight — impossible
replace flag_suspect = 1 if weightkg == 0
replace weightkg = .d if weightkg == 0

* Flag values outside plausible US Army range (40 to 160 kg)
replace flag_suspect = 1 if weightkg < 40  & weightkg != .
replace flag_suspect = 1 if weightkg > 160 & weightkg != .
replace weightkg = .d if weightkg < 40     & weightkg != .
replace weightkg = .d if weightkg > 160    & weightkg != .

* Verify weightkg is in plausible range
summarize weightkg, detail
* Expected mean around 80-85 kg

* --- FIX WEIGHTLBS ---
* US Army weight range: 80 to 320 lbs
* Values outside this range are suspect

replace flag_suspect = 1 if weightlbs == 0
replace weightlbs = .d if weightlbs == 0
replace flag_suspect = 1 if weightlbs < 80  & weightlbs != .
replace flag_suspect = 1 if weightlbs > 320 & weightlbs != .
replace weightlbs = .d if weightlbs < 80    & weightlbs != .
replace weightlbs = .d if weightlbs > 320   & weightlbs != .

* --- FIX HEIGHTIN ---
* US Army height range: 58 to 80 inches (4ft10 to 6ft8)
* Values outside this range are suspect
replace flag_suspect = 1 if heightin < 58 & heightin != .
replace flag_suspect = 1 if heightin > 80 & heightin != .
replace heightin = .d if heightin < 58 & heightin != .
replace heightin = .d if heightin > 80 & heightin != .

* Check how many observations are flagged so far
tab flag_suspect
* List all flagged observations to review them
list unique_id gender age weightkg weightlbs heightin if flag_suspect == 1


*---------------------------------------------------------------------------
* STEP 3e: CONVERT MM TO CM
*
* WHY GENERATE NEW VARIABLES INSTEAD OF REPLACE?
* - Generating new variables keeps the original mm values safe
* - If we make a mistake we can always go back to the original
* - We can compare old and new values to verify the conversion
* - Safer approach for beginners
*
* CONVERSION FORMULA: CM = MM / 10
*
* NOTE: Do NOT convert these variables - they are already correct units:
*   weightkg  = already in kg
*   weightlbs = already in lbs  
*   heightin  = already in inches
*---------------------------------------------------------------------------

* Generate new cm variables for all length measurements
* Each new variable gets an underscore prefix and _cm suffix
gen _stature_cm               = stature / 10
gen _cervicaleheight_cm       = cervicaleheight / 10
gen _trochanterionheight_cm   = trochanterionheight / 10
gen _waistheightomphalion_cm  = waistheightomphalion / 10
gen _kneeheightmidpatella_cm  = kneeheightmidpatella / 10
gen _functionalleglength_cm   = functionalleglength / 10
gen _footlength_cm            = footlength / 10
gen _thumbtipreach_cm         = thumbtipreach / 10
gen _span_cm                  = span / 10
gen _chestcircumference_cm    = chestcircumference / 10
gen _waistcircumference_cm    = waistcircumference / 10
gen _hipbreadth_cm            = hipbreadth / 10
gen _hipbreadthsitting_cm     = hipbreadthsitting / 10
gen _bicristalbreadth_cm      = bicristalbreadth / 10



*---------------------------------------------------------------------------
* TRANSFER MISSING CODES FROM ORIGINAL TO NEW CM VARIABLES
*
* WHY DO THIS?
* - When we created new cm variables by dividing by 10
* - Stata did NOT automatically copy the missing codes
* - We must manually transfer them from original to new variables
*
* We transfer ALL missing types:
*   .a = not recorded (-77)
*   .b = refused (-88)
*   .c = unknown (-99)
*   .d = decided missing (suspect values we set to missing)
*---------------------------------------------------------------------------

* STATURE
replace _stature_cm = .a if stature == .a
replace _stature_cm = .b if stature == .b
replace _stature_cm = .c if stature == .c
replace _stature_cm = .d if stature == .d

* CERVICALE HEIGHT
replace _cervicaleheight_cm = .a if cervicaleheight == .a
replace _cervicaleheight_cm = .b if cervicaleheight == .b
replace _cervicaleheight_cm = .c if cervicaleheight == .c
replace _cervicaleheight_cm = .d if cervicaleheight == .d

* TROCHANTERION HEIGHT
replace _trochanterionheight_cm = .a if trochanterionheight == .a
replace _trochanterionheight_cm = .b if trochanterionheight == .b
replace _trochanterionheight_cm = .c if trochanterionheight == .c
replace _trochanterionheight_cm = .d if trochanterionheight == .d

* WAIST HEIGHT OMPHALION
replace _waistheightomphalion_cm = .a if waistheightomphalion == .a
replace _waistheightomphalion_cm = .b if waistheightomphalion == .b
replace _waistheightomphalion_cm = .c if waistheightomphalion == .c
replace _waistheightomphalion_cm = .d if waistheightomphalion == .d

* KNEE HEIGHT MIDPATELLA
replace _kneeheightmidpatella_cm = .a if kneeheightmidpatella == .a
replace _kneeheightmidpatella_cm = .b if kneeheightmidpatella == .b
replace _kneeheightmidpatella_cm = .c if kneeheightmidpatella == .c
replace _kneeheightmidpatella_cm = .d if kneeheightmidpatella == .d

* FUNCTIONAL LEG LENGTH
replace _functionalleglength_cm = .a if functionalleglength == .a
replace _functionalleglength_cm = .b if functionalleglength == .b
replace _functionalleglength_cm = .c if functionalleglength == .c
replace _functionalleglength_cm = .d if functionalleglength == .d

* FOOT LENGTH
replace _footlength_cm = .a if footlength == .a
replace _footlength_cm = .b if footlength == .b
replace _footlength_cm = .c if footlength == .c
replace _footlength_cm = .d if footlength == .d

* THUMBTIP REACH
replace _thumbtipreach_cm = .a if thumbtipreach == .a
replace _thumbtipreach_cm = .b if thumbtipreach == .b
replace _thumbtipreach_cm = .c if thumbtipreach == .c
replace _thumbtipreach_cm = .d if thumbtipreach == .d

* SPAN
replace _span_cm = .a if span == .a
replace _span_cm = .b if span == .b
replace _span_cm = .c if span == .c
replace _span_cm = .d if span == .d

* CHEST CIRCUMFERENCE
replace _chestcircumference_cm = .a if chestcircumference == .a
replace _chestcircumference_cm = .b if chestcircumference == .b
replace _chestcircumference_cm = .c if chestcircumference == .c
replace _chestcircumference_cm = .d if chestcircumference == .d

* WAIST CIRCUMFERENCE
replace _waistcircumference_cm = .a if waistcircumference == .a
replace _waistcircumference_cm = .b if waistcircumference == .b
replace _waistcircumference_cm = .c if waistcircumference == .c
replace _waistcircumference_cm = .d if waistcircumference == .d

* HIP BREADTH
replace _hipbreadth_cm = .a if hipbreadth == .a
replace _hipbreadth_cm = .b if hipbreadth == .b
replace _hipbreadth_cm = .c if hipbreadth == .c
replace _hipbreadth_cm = .d if hipbreadth == .d

* HIP BREADTH SITTING
replace _hipbreadthsitting_cm = .a if hipbreadthsitting == .a
replace _hipbreadthsitting_cm = .b if hipbreadthsitting == .b
replace _hipbreadthsitting_cm = .c if hipbreadthsitting == .c
replace _hipbreadthsitting_cm = .d if hipbreadthsitting == .d

* BICRISTAL BREADTH
replace _bicristalbreadth_cm = .a if bicristalbreadth == .a
replace _bicristalbreadth_cm = .b if bicristalbreadth == .b
replace _bicristalbreadth_cm = .c if bicristalbreadth == .c
replace _bicristalbreadth_cm = .d if bicristalbreadth == .d

* VERIFY - check missing values transferred correctly
misstable summarize _stature_cm _cervicaleheight_cm     ///
    _trochanterionheight_cm _waistheightomphalion_cm    ///
    _kneeheightmidpatella_cm _functionalleglength_cm    ///
    _footlength_cm _thumbtipreach_cm _span_cm           ///
    _chestcircumference_cm _waistcircumference_cm       ///
    _hipbreadth_cm _hipbreadthsitting_cm                ///
    _bicristalbreadth_cm


* Label all new cm variables so we know what they are
label variable _stature_cm              "Stature (cm)"
label variable _cervicaleheight_cm      "Cervicale Height (cm)"
label variable _trochanterionheight_cm  "Trochanterion Height (cm)"
label variable _waistheightomphalion_cm "Waist Height Omphalion (cm)"
label variable _kneeheightmidpatella_cm "Knee Height Midpatella (cm)"
label variable _functionalleglength_cm  "Functional Leg Length (cm)"
label variable _footlength_cm           "Foot Length (cm)"
label variable _thumbtipreach_cm        "Thumbtip Reach (cm)"
label variable _span_cm                 "Span/Arm Wingspan (cm)"
label variable _chestcircumference_cm   "Chest Circumference (cm)"
label variable _waistcircumference_cm   "Waist Circumference (cm)"
label variable _hipbreadth_cm           "Hip Breadth (cm)"
label variable _hipbreadthsitting_cm    "Hip Breadth Sitting (cm)"
label variable _bicristalbreadth_cm     "Bicristal Breadth (cm)"


* to check cm variables
mdesc _stature_cm _cervicaleheight_cm _thumbtipreach_cm


* Verify conversions are correct by checking the means
* Each mean should now be roughly 1/10 of original value
summarize _stature_cm _cervicaleheight_cm _trochanterionheight_cm ///
    _waistheightomphalion_cm _kneeheightmidpatella_cm


*---------------------------------------------------------------------------
* STEP 3f: FLAG SUSPECT VALUES IN NEW CM VARIABLES
*
* WHY AFTER CONVERSION?
* - We can now check plausible ranges in familiar cm units
* - Based on US Army standards and observed data distributions
* - We add to the existing flag_suspect variable
*
* RANGES BASED ON:
* - US Army height standards (AR 40-501)
* - ANSUR II observed data distributions
* - Physiological plausibility
*---------------------------------------------------------------------------

* --- STATURE (HEIGHT) ---
* US Army standard: 147cm (4ft10) to 203cm (6ft8)
* --- STATURE (HEIGHT) ---
* US Army standard: 147cm (4ft10) to 203cm (6ft8)
replace flag_suspect = 1 if _stature_cm < 147 & _stature_cm != .
replace flag_suspect = 1 if _stature_cm > 203 & _stature_cm != .
replace _stature_cm = .d if _stature_cm < 147 & _stature_cm != .
replace _stature_cm = .d if _stature_cm > 203 & _stature_cm != .

* --- CERVICALE HEIGHT ---
* Expected range: 110 to 180 cm
* Should be about 85-88% of stature
replace flag_suspect = 1 if _cervicaleheight_cm < 110 & _cervicaleheight_cm != .
replace flag_suspect = 1 if _cervicaleheight_cm > 180 & _cervicaleheight_cm != .

* --- TROCHANTERION HEIGHT ---
* Expected range: 60 to 115 cm
* Should be about 50-55% of stature
replace flag_suspect = 1 if _trochanterionheight_cm < 60 & _trochanterionheight_cm != .
replace flag_suspect = 1 if _trochanterionheight_cm > 115 & _trochanterionheight_cm != .

* --- WAIST HEIGHT OMPHALION ---
* Expected range: 80 to 130 cm
* Should be about 58-62% of stature
replace flag_suspect = 1 if _waistheightomphalion_cm < 80 & _waistheightomphalion_cm != .
replace flag_suspect = 1 if _waistheightomphalion_cm > 130 & _waistheightomphalion_cm != .

* --- KNEE HEIGHT MIDPATELLA ---
* Expected range: 38 to 63 cm
* Should be about 28-30% of stature
replace flag_suspect = 1 if _kneeheightmidpatella_cm < 38 & _kneeheightmidpatella_cm != .
replace flag_suspect = 1 if _kneeheightmidpatella_cm > 63 & _kneeheightmidpatella_cm != .

* --- FUNCTIONAL LEG LENGTH ---
* Expected range: 78 to 138 cm
* Should be about 60-68% of stature
replace flag_suspect = 1 if _functionalleglength_cm < 78 & _functionalleglength_cm != .
replace flag_suspect = 1 if _functionalleglength_cm > 138 & _functionalleglength_cm != .

* --- FOOT LENGTH ---
* Expected range: 19 to 34 cm
replace flag_suspect = 1 if _footlength_cm < 19 & _footlength_cm != .
replace flag_suspect = 1 if _footlength_cm > 34 & _footlength_cm != .

* --- THUMBTIP REACH ---
* Expected range: 55 to 105 cm
* Values above 200 cm are clearly data entry errors
replace flag_suspect = 1 if _thumbtipreach_cm < 55  & _thumbtipreach_cm != .
replace flag_suspect = 1 if _thumbtipreach_cm > 105 & _thumbtipreach_cm != .
replace _thumbtipreach_cm = .d if _thumbtipreach_cm > 105 & _thumbtipreach_cm != .

* --- SPAN (ARM WINGSPAN) ---
* Expected range: 132 to 215 cm
* Should be approximately equal to stature
replace flag_suspect = 1 if _span_cm < 132 & _span_cm != .
replace flag_suspect = 1 if _span_cm > 215 & _span_cm != .

* --- CHEST CIRCUMFERENCE ---
* Expected range: 65 to 150 cm
replace flag_suspect = 1 if _chestcircumference_cm < 65  & _chestcircumference_cm != .
replace flag_suspect = 1 if _chestcircumference_cm > 150 & _chestcircumference_cm != .

* --- WAIST CIRCUMFERENCE ---
* Expected range: 55 to 140 cm
replace flag_suspect = 1 if _waistcircumference_cm < 55  & _waistcircumference_cm != .
replace flag_suspect = 1 if _waistcircumference_cm > 140 & _waistcircumference_cm != .

* --- HIP BREADTH ---
* Expected range: 25 to 50 cm
replace flag_suspect = 1 if _hipbreadth_cm < 25 & _hipbreadth_cm != .
replace flag_suspect = 1 if _hipbreadth_cm > 50 & _hipbreadth_cm != .

* --- HIP BREADTH SITTING ---
* Expected range: 25 to 58 cm
replace flag_suspect = 1 if _hipbreadthsitting_cm < 25 & _hipbreadthsitting_cm != .
replace flag_suspect = 1 if _hipbreadthsitting_cm > 58 & _hipbreadthsitting_cm != .

* --- BICRISTAL BREADTH ---
* Expected range: 17 to 40 cm
replace flag_suspect = 1 if _bicristalbreadth_cm < 17 & _bicristalbreadth_cm != .
replace flag_suspect = 1 if _bicristalbreadth_cm > 40 & _bicristalbreadth_cm != .

* Check total number of suspect observations
tab flag_suspect

* List all suspect observations with key variables
list unique_id gender age _stature_cm weightkg if flag_suspect == 1


*---------------------------------------------------------------------------
* STEP 3g: LABEL ALL VARIABLES
*
* WHY LABEL?
* - Labels make your dataset professional and easy to understand
* - Anyone reading the dataset will know what each variable means
* - Required for a high quality analytic dataset
*---------------------------------------------------------------------------

* Label original measurement variables
label variable stature              "Stature/Height (mm - original)"
label variable cervicaleheight      "Cervicale Height (mm - original)"
label variable trochanterionheight  "Trochanterion Height (mm - original)"
label variable waistheightomphalion "Waist Height Omphalion (mm - original)"
label variable kneeheightmidpatella "Knee Height Midpatella (mm - original)"
label variable functionalleglength  "Functional Leg Length (mm - original)"
label variable footlength           "Foot Length (mm - original)"
label variable thumbtipreach        "Thumbtip Reach (mm - original)"
label variable span                 "Span/Arm Wingspan (mm - original)"
label variable chestcircumference   "Chest Circumference (mm - original)"
label variable waistcircumference   "Waist Circumference (mm - original)"
label variable hipbreadth           "Hip Breadth (mm - original)"
label variable hipbreadthsitting    "Hip Breadth Sitting (mm - original)"
label variable bicristalbreadth     "Bicristal Breadth (mm - original)"
label variable weightkg "Measured weight (kg) — verified already in kg not kg*10"
label variable weightlbs            "Self-reported weight (lbs)"
label variable heightin             "Self-reported height (inches)"
label variable age                  "Age (years)"

* Encode categorical string variables to numeric
* encode creates a numeric version with value labels automatically
encode gender,           gen(gender_num)
encode component,        gen(component_num)
encode branch,           gen(branch_num)
encode writingpreference, gen(writingpref_num)

* Label the new numeric variables
label variable gender_num       "Sex (numeric)"
label variable component_num    "Military component (numeric)"
label variable branch_num       "Branch (numeric)"
label variable writingpref_num  "Writing preference (numeric)"


/*===========================================================================
   STEP 4: CREATE NEW VARIABLES
   
   WHY AFTER CLEANING AND CONVERTING?
   - New variables are calculated FROM existing variables
   - If existing variables have errors the new ones will too
   - Always clean and convert first then create new variables
   
   NEW VARIABLES TO CREATE:
   a) unique_id     - already done in Step 1
   b) bmi + bmi_cat - continuous and categorical BMI
   c) season        - season of measurement
   d) gender_num    - already done in Step 3g
   e) body_type     - body type categories by sex
   f) tshirt_size   - unisex t-shirt size
   
   ADDITIONAL VARIABLES FOR ANALYSIS:
   - age_cat        - age categories (NCHS standard)
   - hip_height_ratio - hip height as % of stature
   - height_diff    - reported minus measured height
   - weight_diff    - reported minus measured weight
===========================================================================*/

* --- (b) BMI CONTINUOUS ---
* Formula: weight in kg divided by height in meters squared
* Height must be converted from cm to meters by dividing by 100
gen bmi = weightkg / (_stature_cm / 100)^2
label variable bmi "Body Mass Index (kg/m2)"

* Check BMI distribution
summarize bmi, detail

* --- (b) BMI CATEGORICAL ---
* Using standard WHO cutpoints:
* Underweight = below 18.5
* Normal      = 18.5 to below 25
* Overweight  = 25 to below 30
* Obese       = 30 and above
gen bmi_cat = .
replace bmi_cat = 1 if bmi < 18.5
replace bmi_cat = 2 if bmi >= 18.5 & bmi < 25
replace bmi_cat = 3 if bmi >= 25   & bmi < 30
replace bmi_cat = 4 if bmi >= 30   & bmi != .

* Add value labels
label define bmi_lbl 1 "Underweight" 2 "Normal" 3 "Overweight" 4 "Obese"
label values bmi_cat bmi_lbl
label variable bmi_cat "BMI Category (WHO standard)"

* Check distribution
tab bmi_cat


* --- (c) SEASON OF MEASUREMENT ---
* We extract the month from the date variable first
* Then assign seasons based on month:
* Winter = December January February (months 12 1 2)
* Spring = March April May           (months 3 4 5)
* Summer = June July August          (months 6 7 8)
* Fall   = September October November (months 9 10 11)
gen month = month(date)
label variable month "Month of measurement"

gen season = .
replace season = 1 if inlist(month, 12, 1, 2)
replace season = 2 if inlist(month, 3, 4, 5)
replace season = 3 if inlist(month, 6, 7, 8)
replace season = 4 if inlist(month, 9, 10, 11)

* Add value labels
label define season_lbl 1 "Winter" 2 "Spring" 3 "Summer" 4 "Fall"
label values season season_lbl
label variable season "Season of measurement"

* Check distribution
tab season


* --- (e) BODY TYPE CATEGORIES ---
* Rationale: We use stature and BMI to define body types
* Applied separately for males and females
* because height distributions differ between sexes
*
* MALE categories (based on male stature percentiles):
* Short     = stature below 170 cm (below 25th percentile for males)
* Average   = stature 170 to below 180 cm
* Tall-Lean = stature 180+ cm AND BMI below 25
* Tall-Heavy= stature 180+ cm AND BMI 25 or above
*
* FEMALE categories (based on female stature percentiles):
* Short     = stature below 158 cm (below 25th percentile for females)
* Average   = stature 158 to below 168 cm
* Tall-Lean = stature 168+ cm AND BMI below 25
* Tall-Heavy= stature 168+ cm AND BMI 25 or above

gen body_type = .

* Male body types
replace body_type = 1 if gender == "Male" & _stature_cm < 170 & _stature_cm != .
replace body_type = 2 if gender == "Male" & _stature_cm >= 170 & _stature_cm < 180
replace body_type = 3 if gender == "Male" & _stature_cm >= 180 & bmi <  25 & bmi != .
replace body_type = 4 if gender == "Male" & _stature_cm >= 180 & bmi >= 25 & bmi != .

* Female body types
replace body_type = 1 if gender == "Female" & _stature_cm < 158 & _stature_cm != .
replace body_type = 2 if gender == "Female" & _stature_cm >= 158 & _stature_cm < 168
replace body_type = 3 if gender == "Female" & _stature_cm >= 168 & bmi <  25 & bmi != .
replace body_type = 4 if gender == "Female" & _stature_cm >= 168 & bmi >= 25 & bmi != .

* Add value labels
label define bt_lbl 1 "Short" 2 "Average" 3 "Tall-Lean" 4 "Tall-Heavy"
label values body_type bt_lbl
label variable body_type "Body type category (sex-specific, based on stature and BMI)"

* Check distribution by sex
tab body_type gender, col


* --- (f) T-SHIRT SIZE ---
* Based on ASTM D5585 unisex sizing guide
* Using chest circumference in cm:
* XS  = below 86 cm
* S   = 86 to below 91 cm
* M   = 91 to below 99 cm
* L   = 99 to below 107 cm
* XL  = 107 to below 116 cm
* XXL = 116 cm and above
gen tshirt_size = .
replace tshirt_size = 1 if _chestcircumference_cm <  86 & _chestcircumference_cm != .
replace tshirt_size = 2 if _chestcircumference_cm >= 86  & _chestcircumference_cm < 91
replace tshirt_size = 3 if _chestcircumference_cm >= 91  & _chestcircumference_cm < 99
replace tshirt_size = 4 if _chestcircumference_cm >= 99  & _chestcircumference_cm < 107
replace tshirt_size = 5 if _chestcircumference_cm >= 107 & _chestcircumference_cm < 116
replace tshirt_size = 6 if _chestcircumference_cm >= 116 & _chestcircumference_cm != .

* Add value labels
label define ts_lbl 1 "XS" 2 "S" 3 "M" 4 "L" 5 "XL" 6 "XXL"
label values tshirt_size ts_lbl
label variable tshirt_size "Unisex T-shirt size (ASTM D5585 sizing guide)"

* Check distribution
tab tshirt_size


* --- ADDITIONAL: AGE CATEGORIES ---
* Using NCHS standard age categories
gen age_cat = .
replace age_cat = 1 if age >= 18 & age <= 24
replace age_cat = 2 if age >= 25 & age <= 44
replace age_cat = 3 if age >= 45 & age <= 64
replace age_cat = 4 if age >= 65

* Add value labels
label define age_lbl 1 "18-24" 2 "25-44" 3 "45-64" 4 "65+"
label values age_cat age_lbl
label variable age_cat "Age category (NCHS standard)"

* Check distribution
tab age_cat gender, col


* --- ADDITIONAL: HIP HEIGHT RATIO ---
* This calculates hip height as a percentage of total stature
* Used in Section 3.1b of the report
gen hip_height_ratio = (_trochanterionheight_cm / _stature_cm) * 100
label variable hip_height_ratio "Trochanterion height as % of stature"

* Check by sex
bysort gender: summarize hip_height_ratio


* --- ADDITIONAL: REPORTED VS MEASURED DIFFERENCES ---
* These variables compare self-reported to directly measured values
* Used in Section 4.2 of the report

* First convert reported height from inches to cm
gen heightin_cm = heightin * 2.54
label variable heightin_cm "Self-reported height converted to cm"

* Convert reported weight from lbs to kg
gen weightlbs_kg = weightlbs * 0.453592
label variable weightlbs_kg "Self-reported weight converted to kg"

* Calculate differences: reported minus measured
* Positive value = person reported more than measured
* Negative value = person reported less than measured
gen height_diff = heightin_cm - _stature_cm
gen weight_diff = weightlbs_kg - weightkg
label variable height_diff "Height difference: reported minus measured (cm)"
label variable weight_diff "Weight difference: reported minus measured (kg)"

* Quick check of differences
summarize height_diff weight_diff, detail


/*===========================================================================
   STEP 5: ANALYSIS
   
   NOW WE CAN ANALYZE BECAUSE:
   - Data is clean
   - Missing values are properly coded
   - Units are correct (cm)
   - New variables are created
   - Everything is labeled
   
   SECTIONS:
   3.1 - Anthropometric characteristics
   3.1b - Hip height ratio by sex
   4.1 - Correlations between stature measures
   4.2 - Reported vs measured height and weight
   4.3 - Body type vs BMI and weight
   5   - BMI and demographics (7101 students)
===========================================================================*/

*---------------------------------------------------------------------------
* SECTION 3.1 - ANTHROPOMETRIC CHARACTERISTICS
* Summary statistics table for all measurements
*---------------------------------------------------------------------------

* Full descriptive statistics table
* Organized by body region as required by the assignment
tabstat _stature_cm _cervicaleheight_cm _trochanterionheight_cm    ///
    _waistheightomphalion_cm _kneeheightmidpatella_cm               ///
    _functionalleglength_cm _footlength_cm _thumbtipreach_cm        ///
    _span_cm _chestcircumference_cm _waistcircumference_cm          ///
    _hipbreadth_cm _hipbreadthsitting_cm _bicristalbreadth_cm       ///
    weightkg bmi,                                                   ///
    statistics(n mean sd min p25 p50 p75 max) columns(statistics)   ///
    format(%8.1f)

* Count missing values for each variable
mdesc _stature_cm _cervicaleheight_cm _trochanterionheight_cm      ///
    _waistheightomphalion_cm _kneeheightmidpatella_cm               ///
    _functionalleglength_cm _footlength_cm _thumbtipreach_cm        ///
    _span_cm _chestcircumference_cm _waistcircumference_cm          ///
    _hipbreadth_cm _hipbreadthsitting_cm _bicristalbreadth_cm       ///
    weightkg bmi


*---------------------------------------------------------------------------
* SECTION 3.1b - HIP HEIGHT RATIO BY SEX
*---------------------------------------------------------------------------

* Summary of hip height ratio by sex
bysort gender: summarize hip_height_ratio

* Histogram showing hip height ratio by sex
twoway (histogram hip_height_ratio if gender == "Female",  ///
        fcolor(red%40) lcolor(red%40) width(0.3))          ///
       (histogram hip_height_ratio if gender == "Male",    ///
        fcolor(navy%40) lcolor(navy%40) width(0.3)),       ///
       legend(order(1 "Female" 2 "Male"))                  ///
       xtitle("Hip Height as % of Total Stature")          ///
       ytitle("Frequency")                                 ///
       title("Figure 3.1b-1: Hip Height Ratio by Sex")
graph export "fig_3_1b_hip_ratio.png", replace width(900)


*---------------------------------------------------------------------------
* SECTION 4.1 - CORRELATIONS BETWEEN STATURE MEASURES
*---------------------------------------------------------------------------

* Correlation matrix for all stature measures
* This shows how strongly each measure relates to the others
pwcorr _stature_cm _cervicaleheight_cm _trochanterionheight_cm  ///
    _waistheightomphalion_cm _kneeheightmidpatella_cm            ///
    _functionalleglength_cm _footlength_cm                      ///
    _thumbtipreach_cm _span_cm, star(0.05)

* Most correlated pair: stature and cervicale height (r=0.991)
* Scatter plot showing this relationship
twoway (scatter _cervicaleheight_cm _stature_cm if gender == "Female", ///
        mcolor(red%30) msize(tiny))                                     ///
       (scatter _cervicaleheight_cm _stature_cm if gender == "Male",   ///
        mcolor(navy%30) msize(tiny))                                    ///
       (lfit _cervicaleheight_cm _stature_cm, lcolor(black)),          ///
       legend(order(1 "Female" 2 "Male" 3 "Regression line"))          ///
       xtitle("Stature (cm)")                                          ///
       ytitle("Cervicale Height (cm)")                                 ///
       title("Figure 4.1a-1: Stature vs Cervicale Height (r=0.991)")
graph export "fig_4_1a_scatter.png", replace width(900)

* Correlations with stature stratified by sex
* Table 4.1-1
foreach sex in "Female" "Male" {
    di "=== `sex' ==="
    pwcorr _stature_cm _cervicaleheight_cm _trochanterionheight_cm ///
        _waistheightomphalion_cm _kneeheightmidpatella_cm           ///
        _functionalleglength_cm _footlength_cm                     ///
        _thumbtipreach_cm _span_cm                                 ///
        if gender == "`sex'", star(0.05)
}


*---------------------------------------------------------------------------
* SECTION 4.2 - REPORTED VS MEASURED HEIGHT AND WEIGHT
*---------------------------------------------------------------------------

* 4.2a - Distribution of weight difference
summarize weight_diff, detail

histogram weight_diff,                                     ///
    normal                                                 ///
    xtitle("Reported minus Measured Weight (kg)")          ///
    ytitle("Frequency")                                    ///
    title("Figure 4.2a-1: Distribution of Weight Difference")
graph export "fig_4_2a_weight_diff.png", replace width(900)

* 4.2b - Weight difference by sex
bysort gender: summarize weight_diff

twoway (histogram weight_diff if gender == "Female",  ///
        fcolor(red%40) lcolor(red%40) width(0.5))     ///
       (histogram weight_diff if gender == "Male",    ///
        fcolor(navy%40) lcolor(navy%40) width(0.5)),  ///
       legend(order(1 "Female" 2 "Male"))             ///
       xtitle("Reported minus Measured Weight (kg)")  ///
       title("Figure 4.2b-1: Weight Difference by Sex")
graph export "fig_4_2b_weight_diff_sex.png", replace width(900)

* 4.2c - Distribution of height difference
summarize height_diff, detail

histogram height_diff,                                      ///
    normal                                                  ///
    xtitle("Reported minus Measured Height (cm)")           ///
    ytitle("Frequency")                                     ///
    title("Figure 4.2c-1: Distribution of Height Difference")
graph export "fig_4_2c_height_diff.png", replace width(900)

* Summary by sex
bysort gender: summarize height_diff


*---------------------------------------------------------------------------
* SECTION 4.3 - BODY TYPE VS BMI AND WEIGHT
*---------------------------------------------------------------------------

* Summary of BMI and weight by body type
bysort body_type: summarize bmi weightkg

* Proportion in each BMI category by body type
bysort body_type: tab bmi_cat

* Boxplot of BMI by body type
graph box bmi, over(body_type)            ///
    ytitle("BMI (kg/m2)")                 ///
    title("Figure 4.3a-1: BMI by Body Type")
graph export "fig_4_3a_bmi_bodytype.png", replace width(900)

* Boxplot of weight by body type
graph box weightkg, over(body_type)       ///
    ytitle("Weight (kg)")                 ///
    title("Figure 4.3a-2: Weight by Body Type")
graph export "fig_4_3a_weight_bodytype.png", replace width(900)


*---------------------------------------------------------------------------
* SECTION 5 - BMI AND DEMOGRAPHICS (7101 STUDENTS ONLY)
*---------------------------------------------------------------------------

* 5a - BMI vs age continuous by sex
* Pearson correlation
pwcorr bmi age if gender == "Female", sig
pwcorr bmi age if gender == "Male",   sig

* Scatter plot - Female
twoway (scatter bmi age if gender == "Female",           ///
        mcolor(red%15) msize(vtiny))                     ///
       (lfit bmi age if gender == "Female",              ///
        lcolor(red) lwidth(medium)),                     ///
       xtitle("Age (years)") ytitle("BMI (kg/m2)")       ///
       title("Figure 5a-1: BMI vs Age - Female")
graph export "fig_5a_bmi_age_female.png", replace width(900)

* Scatter plot - Male
twoway (scatter bmi age if gender == "Male",             ///
        mcolor(navy%15) msize(vtiny))                    ///
       (lfit bmi age if gender == "Male",                ///
        lcolor(navy) lwidth(medium)),                    ///
       xtitle("Age (years)") ytitle("BMI (kg/m2)")       ///
       title("Figure 5a-2: BMI vs Age - Male")
graph export "fig_5a_bmi_age_male.png", replace width(900)

* 5b - BMI by categorical age and sex
* Table 5b-1
bysort gender age_cat: summarize bmi

* Proportion in each BMI category by age and sex
bysort gender age_cat: tab bmi_cat

* Boxplot - Female
graph box bmi if gender == "Female", over(age_cat)    ///
    ytitle("BMI (kg/m2)")                             ///
    title("Figure 5b-1: BMI by Age Category - Female")
graph export "fig_5b_bmi_agecat_female.png", replace width(900)

* Boxplot - Male
graph box bmi if gender == "Male", over(age_cat)      ///
    ytitle("BMI (kg/m2)")                             ///
    title("Figure 5b-2: BMI by Age Category - Male")
graph export "fig_5b_bmi_agecat_male.png", replace width(900)


/*===========================================================================
   STEP 6: SAVE
   
   WHY SAVE AT THE END?
   - We save the final clean dataset with all new variables
   - This is the analytic dataset we submit with our report
   - It includes original variables, cleaned variables,
     new variables, value labels, and missing value codes
===========================================================================*/

* Save the final analytic dataset
save "ansur_analytic_dataset.dta", replace

* Confirm what is in the final dataset
describe
count

* Close the log file
log close

/*===========================================================================
   END OF DO-FILE
   
   FILES CREATED:
   1. ansur_log.txt            - complete log of all output
   2. ansur_duplicates.dta     - removed duplicate observations
   3. ansur_analytic_dataset.dta - final clean analytic dataset
   4. fig_3_1b_hip_ratio.png   - Figure 3.1b-1
   5. fig_4_1a_scatter.png     - Figure 4.1a-1
   6. fig_4_2a_weight_diff.png - Figure 4.2a-1
   7. fig_4_2b_weight_diff_sex.png - Figure 4.2b-1
   8. fig_4_2c_height_diff.png - Figure 4.2c-1
   9. fig_4_3a_bmi_bodytype.png - Figure 4.3a-1
  10. fig_4_3a_weight_bodytype.png - Figure 4.3a-2
  11. fig_5a_bmi_age_female.png - Figure 5a-1
  12. fig_5a_bmi_age_male.png  - Figure 5a-2
  13. fig_5b_bmi_agecat_female.png - Figure 5b-1
  14. fig_5b_bmi_agecat_male.png - Figure 5b-2
===========================================================================*/
