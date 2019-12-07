# QIC - DVCW Data Wrangling

## Terms

* The target file is the exported .csv that is fed to Qualtrics.
* The source or input files are the raw .csv or .xls(x) files from project sites.
* Project site is a partner organization supplying data. There are three.

## Questions

## Models

### Case

* case worker first name
* case worker last name
* case worker email
* case id
* site name
* site office name
* survey number

### Adult

* id
* first name
* last name
* street one
* street two
* city
* state
* ZIP
* email
* phone
* dob

### Child

* id
* first name
* last name
* dob

## Randomization

The target file should contain randomized selection of cases, 2-3 cases per case worker per month per site.

List of potential focal children per case, criteria:

* Age 10 and under as of 2020-01-01
* in order of preference:
  * between 3-8 years old
  * 9yo
  * under 3yo

The target has 1 case worker, all potential focal children, up to 9 "parent" adults.

Adults are flagged in source data as:
* mother
* father
* other

The "parent" adults are flagged "mother" or "father". For sex equity representation, we want 100% of available parents represented by a single sex, up to 50% of the available adult slots.
e.g. if there are 3 mothers and 10 fathers, we want the 9 adults to include all 3 mothers and 6 of the 10 fathers.



