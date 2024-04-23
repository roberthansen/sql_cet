The SQL Version of the CPUC's Energy Efficiency Cost Effectiveness Tool (CET) reads two user-defined tables representing individual measures and programs, calculates avoided electric and gas costs based on avoided cost tables generated by E3's Avoided Cost Calculator (https://www.ethree.com/public_proceedings/energy-efficiency-calculator/). The scripts are written in Transact-SQL for Microsoft SQL Server 2012.

The current version of the SQL CET is based on extracted scripts from the CET database and has undergone multiple updates to reflect changing policies. The most important calculations can be found in the CalcCE, CalcEmissions, and CalcSavings scripts, which each create or update a stored procedure. Numerous other scripts create or update tables and stored queries (VIEWS) to support the calculations in the three main stored procedures.

The SQL CET is deployed as a back-end application accessible through the CET-UI website on California Energy Data and Reporting System (CEDARS), with production (https://cedars.sound-data.com/) and staging (https://staging-cedars.sound-data.com/) environments available to registered users. See CEDARS for instructions on using the CET.

When performing extensive updates or building the database from scratch, the scripts must be executed in a certain order, generally starting scripts labelled TABLE in the filename, then VIEW, and finally PROCEDURE.
1. TABLEs:
    1.1. TABLE_InputMeasure.sql
    1.2. TABLE_InputMeasureCEDARS.sql
    1.3. TABLE_OutputInput.sql
    1.4. TABLE_OutputCE.sql
    1.5. TABLE_OutputSavings.sql
    1.6. TABLE_SavedInput.sql
    1.7. TABLE_SavedInputCEDARS.sql
    1.8. TABLE_SavedCE.sql
    1.9. TABLE_SavedSavings.sql
2. VIEWs:
    2.1. VIEW_AvoidedCostElecvw.sql
    2.2. VIEW_AvoidedCostGasvw.sql
    2.3. VIEW_E3RateScheduleGasvw.sql
    2.4. VIEW_InputMeasureNonResourcevw.sql
3. PROCEDUREs: Can be executed in any order