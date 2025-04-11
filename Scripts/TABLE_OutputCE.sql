/*
################################################################################
 Name             :  OutputCE (table)
 Date             :  2016-06-30
 Author           :  Wayne Hauck
 Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
 Purpose          :  This stored procedure calculates cost effectiveness.
 Usage            :  n/a
 Called by        :  n/a
 Copyright        :  Developed by Pinnacle Consulting Group (aka Intech Energy,
 				  :  Inc.) for California Public Utilities Commission (CPUC),
				  :  All Rights Reserved
 Change History   :  2016-06-30  Wayne Hauck added comment header
                  :  2021-05-14  Robert Hansen added negative benefit
                  :              for fuel substitution
                  :  2021-07-08  Robert Hansen renamed "TotalSystemBenefits" to
                  :  			 "TotalSystemBenefit"
                  :  2021-07-09  Robert Hansen added OtherBenGross and
                  :     		 OtherCostGross to outputs
                  :  2022-09-02  Robert Hansen added water energy fields to
                  :   			 output:
                  :    			   + WaterEnergyBen
                  :    			   + WaterEnergyBenGross
                  :    			   + WaterEnergyCost
                  :    			   + WaterEnergyCostGross
				  :  2024-04-23  Robert Hansen renamed the "PA" field to
				  :	 			 "IOU_AC_Territory"
				  :  2024-06-20  Robert Hansen reverted "IOU_AC_Territory" to
				  :              "PA"
				  :  2025-02-11  Robert Hansen added fields for the Societal
				  :				 Cost Test:
				  :                + ElecBen_SB
				  :                + ElecBen_SH
				  :                + ElecBenGross_SB
				  :                + ElecBenGross_SH
				  :                + ElecSupplyCost_SB
				  :                + ElecSupplyCost_SH
				  :                + ElecSupplyCostGross_SB
				  :                + ElecSupplyCostGross_SH
				  :                + SCBCost
				  :                + SCHCost
				  :                + SCBCostGross
				  :                + SCBCostNoAdmin
				  :                + SCHCost
				  :                + SCHCostGross
				  :                + SCHCostNoAdmin
				  :                + SCBRatio
				  :                + SCHRatio
				  :                + SCBRatioNoAdmin
				  :                + SCHRatioNoAdmin
				  :  2025-04-10  Robert Hansen added tax credits fields to output:
				  :                + TaxCredits
				  :                + TaxCreditsGross
################################################################################
*/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('dbo.OutputCE') IS NOT NULL
    DROP TABLE dbo.OutputCE
GO

CREATE TABLE dbo.OutputCE(
	ID INT IDENTITY(1,1) NOT NULL,
	JobID INT NULL,
	PA NVARCHAR(8) NULL,
	PrgID NVARCHAR(255) NULL,
	CET_ID NVARCHAR(255) NULL,
	ElecBen FLOAT NULL,
	ElecBen_SB FLOAT NULL,
	ElecBen_SH FLOAT NULL,
	GasBen FLOAT NULL,
	WaterEnergyBen FLOAT NULL,
	ElecBenGross FLOAT NULL,
	ElecBenGross_SB FLOAT NULL,
	ElecBenGross_SH FLOAT NULL,
	GasBenGross FLOAT NULL,
	TaxCredits FLOAT NULL,
	TaxCreditsGross FLOAT NULL,
	WaterEnergyBenGross FLOAT NULL,
	OtherBen FLOAT NULL,.
	OtherBenGross FLOAT NULL,
	ElecSupplyCost FLOAT NULL,
	ElecSupplyCost_SB FLOAT NULL,
	ElecSupplyCost_SH FLOAT NULL,
	GasSupplyCost FLOAT NULL,
	WaterEnergyCost FLOAT NULL,
	ElecSupplyCostGross FLOAT NULL,
	ElecSupplyCostGross_SB FLOAT NULL,
	ElecSupplyCostGross_SH FLOAT NULL,
	GasSupplyCostGross FLOAT NULL,
	WaterEnergyCostGross FLOAT NULL,
	OtherCost FLOAT NULL,
	OtherCostGross FLOAT NULL,
	TotalSystemBenefit FLOAT NULL,
	TotalSystemBenefitGross FLOAT NULL,
	SCBCost FLOAT NULL,
	SCHCost FLOAT NULL,
	TRCCost FLOAT NULL,
	PACCost FLOAT NULL,
	SCBCostGross FLOAT NULL,
	SCBCostNoAdmin FLOAT NULL,
	SCHCostGross FLOAT NULL,
	SCHCostNoAdmin FLOAT NULL,
	TRCCostGross FLOAT NULL,
	TRCCostNoAdmin FLOAT NULL,
	PACCostNoAdmin FLOAT NULL,
	SCBRatio FLOAT NULL,
	SCHRatio FLOAT NULL,
	TRCRatio FLOAT NULL,
	PACRatio FLOAT NULL,
	SCBRatioNoAdmin FLOAT NULL,
	SCHRatioNoAdmin FLOAT NULL,
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

ALTER TABLE dbo.OutputCE ADD CONSTRAINT PK_OutputCE PRIMARY KEY CLUSTERED (ID) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX IX_CET_ID ON dbo.OutputCE(CET_ID) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX IX_JobID ON dbo.OutputCE(JobID) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX IX_PA ON dbo.OutputCE(PA) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX IX_PrgID ON dbo.OutputCE(PrgID) ON [PRIMARY]
GO