
-- DROP TABLE [dbo].[CUS_YLOrdOriginalBOMDataLog_OPP]

CREATE TABLE [dbo].[CUS_YLOrdOriginalBOMDataLog_OPP]
(
	Idx INT IDENTITY(1,1)
	,ordId INT NOT NULL
	,pageName NVARCHAR(50) NOT NULL
	,itmID INT NOT NULL
	,itmIDInstance SMALLINT NOT NULL DEFAULT 0
	,olnID INT NOT NULL
	,olnIDInstance SMALLINT NOT NULL DEFAULT 0
	,oriReqQty DECIMAL(19,6)
	,actions TINYINT NOT NULL DEFAULT 0
	,itmDescription NVARCHAR(100)
	,itmfCode NVARCHAR(50)
	,topSurCode NVARCHAR(50)
	,corCode NVARCHAR(50)
	,edgeCode NVARCHAR(10)
	,dimCX DECIMAL(19,2)
	,dimCY DECIMAL(19,2)
	,dimCZ DECIMAL(19,2)
	,dimFX DECIMAL(19,2)
	,dimFY DECIMAL(19,2) 
	,dimFZ DECIMAL(19,2) 
	,info1 NVARCHAR(50)
	,info2 NVARCHAR(50)
	,info3 NVARCHAR(50)
	,info4 NVARCHAR(50)
	,info5 NVARCHAR(50)
	,info6 NVARCHAR(500)
	,info7 NVARCHAR(50)
	,info8 NVARCHAR(50)
	,info9 NVARCHAR(50)
	,info10 NVARCHAR(50)
	,info11 NVARCHAR(50)
	,info12 NVARCHAR(50)
	,info13 NVARCHAR(50)
	,info14 NVARCHAR(50)
	,info15 NVARCHAR(50)
	,Factory NVARCHAR(50) NULL
	,Duty NVARCHAR(50) NULL
	,PlateCategory NVARCHAR(50) NULL
	,LegacyPrice DECIMAL(18,2) NULL
	,createdOn DATETIME NOT NULL
	,createdBy nvarchar(50) NOT NULL
	,CONSTRAINT PK_YLOrdOriginalBOMDataLog_Idx PRIMARY KEY(Idx)
	--,CONSTRAINT IX_YLOrdOriginalBOMDataLog_Idx UNIQUE CLUSTERED(Idx)	--聚集索引
	,INDEX IX_YLOrdOriginalBOMDataLog_OrdID(OrdID)	--非聚集，不唯一索引
	,INDEX IX_YLOrdOriginalBOMDataLog_OrdID_PageName(OrdID,PageName)	--非聚集，不唯一索引
	,INDEX IX_YLOrdOriginalBOMDataLog_itmID_itmIDInstance_olnID_olnIDInstance(itmID,itmIDInstance,olnID,olnIDInstance)	--非聚集，不唯一索引
	,INDEX IX_YLOrdOriginalBOMDataLog_PageName_itmID_itmIDInstance_olnID_olnIDInstance(PageName,itmID,itmIDInstance,olnID,olnIDInstance)	--非聚集，不唯一索引
)