/*
Name            : E3AvoidedCostElecCO2Seq (table)
Date            : c.2016
Author          : Wayne Huack
Company         : Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose         : Creates one of tables that stores measures for use in the CET
Usage           : Automated interfaces populate this table and trigger the
                : RunCET procedure
Copyright       : Developed by Pinnacle Consulting Group (aka Intech Energy,
                : Inc.) for the California Public Utilities Commission (CPUC)
                : All Rights Reserved
Change History  : 2025-05-21  Robert Hansen added columns for the Societal Cost
                :             Test
*/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('dbo.E3AvoidedCostElecCO2Seq') IS NOT NULL
    DROP TABLE dbo.E3AvoidedCostElec
GO

CREATE TABLE "dbo"."E3AvoidedCostElecCO2Seq"
(
    [ID] INT NOT NULL IDENTITY(1,1),
    [PA] NVARCHAR(8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [Version] NVARCHAR(24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL, 
    [TS] NVARCHAR(24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [EU] NVARCHAR(64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [CZ] NVARCHAR(8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [Qtr] NVARCHAR(6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [Qac] INT NULL,
    [Gen] FLOAT NULL,
    [Gen_SB] FLOAT NULL,
    [Gen_SH] FLOAT NULL,
    [TD] FLOAT NULL,
    [TD_SB] FLOAT NULL,
    [TD_SH] FLOAT NULL,
    [CO2] FLOAT NULL,
    [DSType] NVARCHAR(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [ACElecKey] NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
)
GO
CREATE INDEX PA_IDX ON dbo.InputMeasure(PA)
GO
CREATE INDEX IDX_PrgID ON dbo.InputMeasure(PrgID)
GO
CREATE INDEX IDX_CET_ID ON dbo.InputMeasure(CET_ID)
GO