/*
################################################################################
Name            :  OutputSavings (table)
Date            :  06/30/2016
Author          :  Wayne Hauck
Company         :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose         :  This stored procedure creates the OutputSavings table.
Usage           :  n/a
Called by       :  n/a
Copyright �     :  Developed by Pinnacle Consulting Group (aka Intech Energy,
                :  Inc.) for California Public Utilities Commission (CPUC),
                :  All Rights Reserved
Change History  :  2016-06-30  Original version (reconstructed from
                :  documentation without header)
                :  2023-03-13  Robert Hansen added new fields for Water Energy
                :              Nexus calculated savings
################################################################################
*/
CREATE TABLE [dbo].[OutputSavings]
(
    ID INT NOT NULL IDENTITY(1, 1),
    JobID INT NULL,
    PA NVARCHAR (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PrgID NVARCHAR (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CET_ID NVARCHAR (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    GrosskWh FLOAT NULL,
    GrosskW FLOAT NULL,
    GrossThm FLOAT NULL,
    GrosskWhWater FLOAT NULL,
    NetkWh FLOAT NULL,
    NetkW FLOAT NULL,
    NetThm FLOAT NULL,
    NetkWhWater FLOAT NULL,
    LifecycleGrosskWh FLOAT NULL,
    LifecycleGrossThm FLOAT NULL,
    LifecycleGrosskWhWater FLOAT NULL,
    LifecycleNetkWh FLOAT NULL,
    LifecycleNetThm FLOAT NULL,
    LifecycleNetkWhWater FLOAT NULL,
    GoalAttainmentkWh FLOAT NULL,
    GoalAttainmentkW FLOAT NULL,
    GoalAttainmentThm FLOAT NULL,
    GoalAttainmentkWhWater
    FirstYearGrosskWh FLOAT NULL,
    FirstYearGrosskW FLOAT NULL,
    FirstYearGrossThm FLOAT NULL,
    FirstYearGrosskWhWater FLOAT NULL,
    FirstYearNetkWh FLOAT NULL,
    FirstYearNetkW FLOAT NULL,
    FirstYearNetThm FLOAT NULL,
    FirstYearNetkWhWater FLOAT NULL,
    WeightedSavings FLOAT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[OutputSavings] ADD CONSTRAINT [PK_OutputSavings] PRIMARY KEY
CLUSTERED (ID) WITH (STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO