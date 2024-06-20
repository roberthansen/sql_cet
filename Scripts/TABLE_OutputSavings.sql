/*
################################################################################
Name            :  OutputSavings (table)
Date            :  2016-06-30
Author          :  Wayne Hauck
Company         :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose         :  This stored procedure creates the OutputSavings table.
Usage           :  n/a
Called by       :  n/a
Copyright       :  Developed by Pinnacle Consulting Group (aka Intech Energy,
                :  Inc.) for California Public Utilities Commission (CPUC),
                :  All Rights Reserved
Change History  :  2016-06-30  Original version (reconstructed from
                :  documentation without header)
                :  2023-03-13  Robert Hansen added new fields for Water Energy
                :              Nexus calculated savings
                :  2023-03-16  Robert Hansen added separate direct and embedded
                :              (i.e., water-energy nexus) savings fields, and
                :              added "Annual" label to otherwise unlabelled
                :              fields
                :  2023-04-04  Robert Hansen removed GoalAttainment fields and
                :              renamed "Direct" savings fields to "Site".
                :  2024-04-23  Robert Hansen renamed the "PA" field to
                :              "IOU_AC_Territory"
                :  2024-06-20  Robert Hansen reverted "IOU_AC_Territory" to "PA"
################################################################################
*/
CREATE TABLE [dbo].[OutputSavings]
(
    ID INT NOT NULL IDENTITY(1, 1),
    JobID INT NULL,
    PA NVARCHAR (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PrgID NVARCHAR (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CET_ID NVARCHAR (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    AnnualGrosskWh FLOAT NULL,
    AnnualGrosskWhSite FLOAT NULL,
    AnnualGrosskWhWater FLOAT NULL,
    AnnualGrosskW FLOAT NULL,
    AnnualGrossThm FLOAT NULL,
    AnnualNetkWh FLOAT NULL,
    AnnualNetkWhSite FLOAT NULL,
    AnnualNetkWhWater FLOAT NULL,
    AnnualNetkW FLOAT NULL,
    AnnualNetThm FLOAT NULL,
    LifecycleGrosskWh FLOAT NULL,
    LifecycleGrosskWhSite FLOAT NULL,
    LifecycleGrosskWhWater FLOAT NULL,
    LifecycleGrossThm FLOAT NULL,
    LifecycleNetkWh FLOAT NULL,
    LifecycleNetkWhSite FLOAT NULL,
    LifecycleNetkWhWater FLOAT NULL,
    LifecycleNetThm FLOAT NULL,
    FirstYearGrosskWh FLOAT NULL,
    FirstYearGrosskWhSite FLOAT NULL,
    FirstYearGrosskWhWater FLOAT NULL,
    FirstYearGrosskW FLOAT NULL,
    FirstYearGrossThm FLOAT NULL,
    FirstYearNetkWh FLOAT NULL,
    FirstYearNetkWhSite FLOAT NULL,
    FirstYearNetkWhWater FLOAT NULL,
    FirstYearNetkW FLOAT NULL,
    FirstYearNetThm FLOAT NULL,
    WeightedSavings FLOAT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[OutputSavings] ADD CONSTRAINT [PK_OutputSavings] PRIMARY KEY
CLUSTERED (ID) WITH (STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO