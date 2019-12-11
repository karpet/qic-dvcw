# QIC - DVCW Data Wrangling

## Terms

* The target file is the exported .csv that is fed to Qualtrics.
* The source or input files are the raw .csv or .xls(x) files from project sites.
* Project site is a partner organization supplying data. There are three.


## Target file

The target .csv file has dates formatted as `yyyy/mm/dd`. This is proper ISO8601 format. If you open the .csv
file in Excel, it may re-format all the dates as `dd/mm/yy` (which is an ambiguous format)
but that will depend on your particular system preferences.

**DO NOT SAVE THE CSV** if you open it in Excel in case Excel re-writes the dates.

### Format

The target CSV file contains attributes for:

* site
* case
* case worker
* focal child
* list of potential focal children
* list of parents for selecting survivor

The focal child is randomly selected from the list of potential focal children,
according to the [Randomization](#randomization) section.

### Attributes

* case_id
* site_name
* site_office_name
* survey_number
* case_worker_id
* case_worker_first_name
* case_worker_last_name
* case_worker_email
* focal_child_id
* focal_child_first_name
* focal_child_last_name
* focal_child_dob
* child_1_id
* child_1_first_name
* child_1_last_name
* child_1_dob
* child_2_id
* child_2_first_name
* child_2_last_name
* child_2_dob
* child_3_id
* child_3_first_name
* child_3_last_name
* child_3_dob
* child_4_id
* child_4_first_name
* child_4_last_name
* child_4_dob
* child_5_id
* child_5_first_name
* child_5_last_name
* child_5_dob
* child_6_id
* child_6_first_name
* child_6_last_name
* child_6_dob
* child_7_id
* child_7_first_name
* child_7_last_name
* child_7_dob
* child_8_id
* child_8_first_name
* child_8_last_name
* child_8_dob
* child_9_id
* child_9_first_name
* child_9_last_name
* child_9_dob
* child_10_id
* child_10_first_name
* child_10_last_name
* child_10_dob
* child_11_id
* child_11_first_name
* child_11_last_name
* child_11_dob
* child_12_id
* child_12_first_name
* child_12_last_name
* child_12_dob
* child_13_id
* child_13_first_name
* child_13_last_name
* child_13_dob
* child_14_id
* child_14_first_name
* child_14_last_name
* child_14_dob
* child_15_id
* child_15_first_name
* child_15_last_name
* child_15_dob
* child_16_id
* child_16_first_name
* child_16_last_name
* child_16_dob
* child_17_id
* child_17_first_name
* child_17_last_name
* child_17_dob
* child_18_id
* child_18_first_name
* child_18_last_name
* child_18_dob
* child_19_id
* child_19_first_name
* child_19_last_name
* child_19_dob
* child_20_id
* child_20_first_name
* child_20_last_name
* child_20_dob
* adult_1_role
* adult_1_id
* adult_1_first_name
* adult_1_last_name
* adult_1_dob
* adult_1_street_one
* adult_1_street_two
* adult_1_city
* adult_1_state
* adult_1_zipcode
* adult_1_phone
* adult_1_email
* adult_2_role
* adult_2_id
* adult_2_first_name
* adult_2_last_name
* adult_2_dob
* adult_2_street_one
* adult_2_street_two
* adult_2_city
* adult_2_state
* adult_2_zipcode
* adult_2_phone
* adult_2_email
* adult_3_role
* adult_3_id
* adult_3_first_name
* adult_3_last_name
* adult_3_dob
* adult_3_street_one
* adult_3_street_two
* adult_3_city
* adult_3_state
* adult_3_zipcode
* adult_3_phone
* adult_3_email
* adult_4_role
* adult_4_id
* adult_4_first_name
* adult_4_last_name
* adult_4_dob
* adult_4_street_one
* adult_4_street_two
* adult_4_city
* adult_4_state
* adult_4_zipcode
* adult_4_phone
* adult_4_email
* adult_5_role
* adult_5_id
* adult_5_first_name
* adult_5_last_name
* adult_5_dob
* adult_5_street_one
* adult_5_street_two
* adult_5_city
* adult_5_state
* adult_5_zipcode
* adult_5_phone
* adult_5_email
* adult_6_role
* adult_6_id
* adult_6_first_name
* adult_6_last_name
* adult_6_dob
* adult_6_street_one
* adult_6_street_two
* adult_6_city
* adult_6_state
* adult_6_zipcode
* adult_6_phone
* adult_6_email
* adult_7_role
* adult_7_id
* adult_7_first_name
* adult_7_last_name
* adult_7_dob
* adult_7_street_one
* adult_7_street_two
* adult_7_city
* adult_7_state
* adult_7_zipcode
* adult_7_phone
* adult_7_email
* adult_8_role
* adult_8_id
* adult_8_first_name
* adult_8_last_name
* adult_8_dob
* adult_8_street_one
* adult_8_street_two
* adult_8_city
* adult_8_state
* adult_8_zipcode
* adult_8_phone
* adult_8_email
* adult_9_role
* adult_9_id
* adult_9_first_name
* adult_9_last_name
* adult_9_dob
* adult_9_street_one
* adult_9_street_two
* adult_9_city
* adult_9_state
* adult_9_zipcode
* adult_9_phone
* adult_9_email

## QIC model

The QIC data model reflects the normalized attributes from all partner sites. We have selected
attribute names specific to our project, which may not match
exactly how partner data models name them.

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

Different random cases every month (do not repeat any cases).

List of potential focal children per case, criteria:

* Age 10 and under as of 2020-01-01
* in order of preference:
  * between 5-9 years old
  * 10yo
  * under 5yo

The target has 1 case worker, all potential focal children, up to 9 "parent" adults.

Adults are flagged in source data as:
* mother
* father
* other

The "parent" adults are flagged "mother" or "father". For sex equity representation, we want 100% of available parents represented by a single sex, up to 50% of the available adult slots.
e.g. if there are 3 mothers and 10 fathers, we want the 9 adults to include all 3 mothers and 6 of the 10 fathers.


## TODO


