/*
################################################################################
Name            :  SavedCE (table)
Date            :  2016-06-30
Author          :  Wayne Hauck
Company         :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose         :  This stored procedure calculates cost effectiveness.
Usage           :  n/a
Called by       :  n/a
Copyright       :  Developed by Pinnacle Consulting Group (aka Intech Energy,
                :  Inc.) for California Public Utilities Commission (CPUC),
                :  All Rights Reserved
Change History  :  2021-05-28  Robert Hansen added "SupplyCost" and 
                :  "TotalSystemBenefits" fields
                :  2021-07-08  Robert Hansen renamed "TotalSystemBenefits" to
                :  "TotalSystemBenefit"
                :  2021-07-09  Robert Hansen added OtherBenGross and
                :  OtherCostGross to outputs.
                :  2022-09-02  Robert Hansen added water energy fields to
                :  outputs:
                :    + WaterEnergyBen
                :    + WaterEnergyBenGross
                :    + WaterEnergyCost
                :    + WaterEnergyCostGross
				:  2024-04-23  Robert Hansen renamed the "PA" field to
				:  "IOU_AC_Territory"
				:  2024-06-20  Robert Hansen reverted "IOU_AC_Territory" to "PA"
################################################################################
*/

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('dbo.SavedCE') IS NOT NULL
    DROP TABLE dbo.SavedCE
GO

CREATE TABLE dbo.SavedCE(
	ID INT IDENTITY(1,1) NOT NULL,
	JobID INT NOT NULL,
	PA NVARCHAR(8) NULL,
	PrgID NVARCHAR(255) NULL,
	CET_ID NVARCHAR(255) NOT NULL,
	ElecBen FLOAT NULL,
	GasBen FLOAT NULL,
	WaterEnergyBen FLOAT NULL,
	ElecBenGross FLOAT NULL,
	GasBenGross FLOAT NULL,
	WaterEnergyBenGross FLOAT NULL,
	OtherBen FLOAT NULL,
	OtherBenGross FLOAT NULL,
	ElecSupplyCost FLOAT NULL,
  GasSupplyCost FLOAT NULL,
	WaterEnergyCost FLOAT NULL,
  ElecSupplyCostGross FLOAT NULL,
  GasSupplyCostGross FLOAT NULL,
	WaterEnergyCostGross FLOAT NULL,
	OtherCost FLOAT NULL,
	OtherCostGross FLOAT NULL,
	TotalSystemBenefit FLOAT NULL,
	TotalSystemBenefitGross FLOAT NULL,
	TRCCost FLOAT NULL,
	PACCost FLOAT NULL,
	TRCCostGross FLOAT NULL,
	TRCCostNoAdmin FLOAT NULL,
	PACCostNoAdmin FLOAT NULL,
	TRCRatio FLOAT NULL,
	PACRatio FLOAT NULL,
	TRCRatioNoAdmin FLOAT NULL,
	PACRatioNoAdmin FLOAT NULL,
	BillReducElec FLOAT NULL,
	BillReducGas FLOAT NULL,
	RIMCost FLOAT NULL,
	WeightedBenefits FLOAT NULL,
	WeightedElecAlloc FLOAT NULL,
	WeightedProgramCost FLOAT NULL
) ON [PRIMARY]
GO

ALTER TABLE dbo.SavedCE ADD CONSTRAINT [PK_SavedCE] PRIMARY KEY CLUSTERED ([ID]) WITH (STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_CET_ID] ON [dbo].[SavedCE] ([CET_ID]) WITH (STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_JobID] ON [dbo].[SavedCE] ([JobID]) WITH (STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_PA] ON [dbo].[SavedCE] ([PA]) WITH (STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_PrgID] ON [dbo].[SavedCE] ([PrgID]) WITH (STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO