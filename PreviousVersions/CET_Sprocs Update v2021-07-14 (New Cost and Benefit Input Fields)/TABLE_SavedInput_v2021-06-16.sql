/*
Name            : SavedInput (table)
Date            : c.2016-30-2016
Author          : Wayne Huack
Company         : Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose         : Creates one of tables that stores measures for use in the CET
Usage           : Automated interfaces populate this table and trigger the
                  RunCET procedure
Copyright       : Developed by Pinnacle Consulting Group (aka Intech Energy,
                  Inc.) for the California Public Utilities Commission (CPUC)
                  All Rights Reserved
Change History  : 2021-04-18  Robert Hansen added columns for additional load
                  for use with fuel substitution measures
                : 2021-05-13  Robert Hansen renamed additional load columns per
                  email from DNV GL
				: 2021-05-17  Robert Hansen added the following new cost and 
				  benefit fields:
					+ UnitGasInfraBens - per-unit benefits due to offsetting
					  gas infrastructure costs
					+ UnitRefrigCosts - per-unit costs due to increased or
					  higher GWP refrigerant use
					+ UnitRefrigBens - per-unit benefits due to less or lower
					  GWP refrigerant use
					+ UnitMiscCosts - per-unit miscellaneous costs (for future
					  use)
					+ MiscCostsDesc - descriptizn of miscellaneous costs (for
					  future use)
					+ UnitMiscBens - per-unit miscellaneous benefits (for
					  future use)
					+ MiscBensDesc - description of miscellaneous benefits (for
					  future use)
				: 2021-05-25  Robert Hansen removed MarketEffectsBenefits and
				  MarketEffectsCosts fields
				: 2021-06-16  Robert Hansen commented out new fields for fuel
				  substitution for implementation at a later date
*/

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('dbo.SavedInput') IS NOT NULL
    DROP TABLE dbo.SavedInput
GO


CREATE TABLE [dbo].[SavedInput](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[JobID] [int] NOT NULL,
	[CET_ID] [nvarchar](255) NOT NULL,
	[PA] [nvarchar](24) NULL,
	[PrgID] [nvarchar](255) NULL,
	[ProgramName] [nvarchar](255) NULL,
	[MeasureName] [nvarchar](255) NULL,
	[MeasureID] [nvarchar](255) NULL,
	[TS] [nvarchar](100) NOT NULL,
	[EU] [nvarchar](4000) NOT NULL,
	--[EUAL] [nvarchar](4000) NOT NULL,
	[CZ] [nvarchar](6) NOT NULL,
	[GS] [nvarchar](100) NOT NULL,
	[GP] [nvarchar](100) NOT NULL,
	--[GPAL] [nvarchar](100) NOT NULL,
	[CombType] [nvarchar](100) NULL,
	[Qtr] [nvarchar](50) NULL,
	[Qm] [int] NULL,
	[Qty] [float] NOT NULL,
	[kW1] [float] NOT NULL,
	[kWh1] [float] NOT NULL,
	[Thm1] [float] NOT NULL,
	[kW2] [float] NOT NULL,
	[kWh2] [float] NOT NULL,
	[Thm2] [float] NOT NULL,
	--[kW1_AL] [float] NOT NULL,
	--[kWh1_AL] [float] NOT NULL,
	--[Thm1_AL] [float] NOT NULL,
	--[kW2_AL] [float] NOT NULL,
	--[kWh2_AL] [float] NOT NULL,
	--[Thm2_AL] [float] NOT NULL,
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
	[EndUserRebate] [float] NOT NULL,
	[DILaborCost] [float] NOT NULL,
	[DIMaterialCost] [float] NOT NULL,
	[UnitMeasureGrossCost] [float] NOT NULL,
	[UnitMeasureGrossCost_ER] [float] NOT NULL,
	[MeasIncrCost] [float] NOT NULL,
	[MeasInflation] [int] NOT NULL,
	[UnitGasInfraBens] [float],
	[UnitRefrigCosts] [float],
	[UnitRefrigBens] [float],
	[UnitMiscCosts] [float],
	[MiscCostsDesc] [nvarchar](255),
	[UnitMiscBens] [float],
	[MiscBensDesc] [nvarchar](255),
	[Sector] [nvarchar](255) NULL,
	[EndUse] [nvarchar](255) NULL,
	[BuildingType] [nvarchar](255) NULL,
	[MeasureGroup] [nvarchar](255) NULL,
	[SolutionCode] [nvarchar](255) NULL,
	[Technology] [nvarchar](255) NULL,
	[Channel] [nvarchar](255) NULL,
	[IsCustom] [nvarchar](255) NULL,
	[Location] [nvarchar](255) NULL,
	[ProgramType] [nvarchar](255) NULL,
	[UnitType] [nvarchar](255) NULL,
	[Comments] [nvarchar](255) NULL,
	[DataField] [nvarchar](255) NULL
) ON [PRIMARY]
GO

CREATE CLUSTERED INDEX IX_JobID_CETID ON dbo.SavedInput(JobID,CET_ID) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX IX_CET_ID ON dbo.SavedInput(CET_ID) WITH (STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX IX_JobID ON dbo.SavedInput(JobID) WITH (STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX IX_PA ON dbo.SavedInput(PA) WITH (STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX IX_PrgID ON dbo.SavedInput(PrgID) WITH (STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO