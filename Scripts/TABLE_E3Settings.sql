/*
################################################################################
Name            : E3Settings (table)
Date            : c.2016
Author          : Wayne Huack
Company         : Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose         : Creates one of tables that stores measures for use in the CET
Usage           : Automated interfaces populate this table and trigger the
                : RunCET procedure
Copyright       : Developed by Pinnacle Consulting Group (aka Intech Energy,
                : Inc.) for the California Public Utilities Commission (CPUC)
                : All Rights Reserved
Change History  : 2025-05-21  Robert Hansen added fields for societal discount
                : rate for use in the Societal Cost Test
################################################################################
*/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('dbo.E3Settings') IS NOT NULL
    DROP TABLE dbo.E3Settings
GO

CREATE TABLE "dbo"."E3Settings"
(
    [ID] INT NOT NULL IDENTITY(1, 1),
    [PA] NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [Version] NVARCHAR(24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [AvoidedCostVersion] NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [DiscountRateAnnual] DECIMAL(18,6) NULL,
    [DiscountRateQtr] DECIMAL(18,6) NULL,
    [SocietalDiscountRateAnnual] DECIMAL(18,6) NULL,
    [SocietalDiscountRateQtr] DECIMAL(18,6) NULL,
)
GO
CREATE INDEX PA_IDX ON dbo.InputMeasure(PA)
GO
CREATE INDEX IDX_PrgID ON dbo.InputMeasure(PrgID)
GO
CREATE INDEX IDX_CET_ID ON dbo.InputMeasure(CET_ID)
GO