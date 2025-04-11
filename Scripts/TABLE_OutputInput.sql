/*
################################################################################
Name            : OutputInput (table)
Date            : c.2016-06-30
Author          : Wayne Huack
Company         : Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose         : Creates one of tables that stores measures for use in the CET
Usage           : Automated interfaces populate this table and trigger the
                : RunCET procedure
Copyright       : Developed by Pinnacle Consulting Group (aka Intech Energy,
                : Inc.) for the California Public Utilities Commission (CPUC)
                : All Rights Reserved
Change History  : 2023-03-16  Robert Hansen added the following new fields:
                :   + UnitGasInfraBens
                :   + UnitRefrigCosts
                :   + UnitRefrigBens
                :   + UnitMiscCosts
                :   + MiscCostsDesc
                :   + UnitMiscBens
                :   + MiscBensDesc
                :   + kWhWater1
                :   + kWhWater2
                :   + WaterUse
                : 2024-04-23  Robert Hansen renamed the "PA" field to
                :             "IOU_AC_Territory"
                : 2024-06-20  Robert Hansen reverted "IOU_AC_Territory" to "PA"
                : 2025-04-11  Robert Hansen added new UnitTaxCredits field
################################################################################
*/

CREATE TABLE [dbo].[OutputInput]
(
    [ID] [int] NOT NULL IDENTITY(1, 1),
    [JobID] [int] NOT NULL,
    [CET_ID] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [PA] [nvarchar] (24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [PrgID] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [ProgramName] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [MeasureName] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [MeasureID] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [TS] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [EU] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [CZ] [nvarchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [GS] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [GP] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [CombType] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [Qtr] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [Qm] [int] NULL,
    [Qty] [float] NOT NULL,
    [kW1] [float] NOT NULL,
    [kWh1] [float] NOT NULL,
    [Thm1] [float] NOT NULL,
/* new water-energy nexus field */
    [kWhWater1] [float] NOT NULL,
/* end new water-energy nexus field */
    [kW2] [float] NOT NULL,
    [kWh2] [float] NOT NULL,
    [Thm2] [float] NOT NULL,
/* new water-energy nexus field */
    [kWhWater2] [float] NOT NULL,
/* end new water-energy nexus field */
    [EUL] [float] NOT NULL,
    [RUL] [float] NOT NULL,
    [eulq] [float] NOT NULL,
    [eulq1] [float] NULL,
    [eulq2] [float] NOT NULL,
    [rulq] [float] NOT NULL,
    [NTGRkW] [float] NULL,
    [NTGRkWh] [float] NOT NULL,
    [NTGRThm] [float] NULL,
    [NTGRCost] [float] NULL,
    [IR] [float] NOT NULL,
    [IRkW] [float] NOT NULL,
    [IRkWh] [float] NOT NULL,
    [IRThm] [float] NOT NULL,
    [RR] [float] NOT NULL,
    [RRkWh] [float] NOT NULL,
    [RRkW] [float] NOT NULL,
    [RRThm] [float] NOT NULL,
    [IncentiveToOthers] [float] NOT NULL,
/* new costs and benefits fields: */
    [UnitGasInfraBens] [float] NULL,
    [UnitRefrigCosts] [float] NULL,
    [UnitRefrigBens] [float] NULL,
    [UnitMiscCosts] [float] NULL,
    [MiscCostsDesc] [nvarchar] (255) NULL,
    [UnitMiscBens] [float] NULL,
    [MiscBensDesc] [nvarchar] (255) NULL,
    [UnitTaxCredits] [float] NULL,
/* end new costs and benefits fields */
    [EndUserRebate] [float] NOT NULL,
    [DILaborCost] [float] NOT NULL,
    [DIMaterialCost] [float] NOT NULL,
    [UnitMeasureGrossCost] [float] NOT NULL,
    [UnitMeasureGrossCost_ER] [float] NOT NULL,
    [MeasIncrCost] [float] NOT NULL,
    [MeasInflation] [int] NOT NULL,
    [MEBens] [float] NULL,
    [MECost] [float] NULL,
    [Sector] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [EndUse] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [BuildingType] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [MeasureGroup] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [SolutionCode] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [Technology] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [Channel] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [IsCustom] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [Location] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [ProgramType] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [UnitType] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
/* new water-energy nexus field */
    [WaterUse] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
/* end new water-energy nexus field */
    [Comments] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [DataField] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[OutputInput] ADD CONSTRAINT [PK_OutputInput] PRIMARY KEY CLUSTERED
([ID]) WITH (STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO