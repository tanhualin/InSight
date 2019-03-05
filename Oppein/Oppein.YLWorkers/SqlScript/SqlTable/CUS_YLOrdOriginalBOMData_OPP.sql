
-- DROP TABLE [dbo].[CUS_YLOrdOriginalBOMData_OPP]

CREATE TABLE [dbo].[CUS_YLOrdOriginalBOMData_OPP]
(
	Idx INT IDENTITY(1,1)
	,ordId INT NOT NULL
	,pageName NVARCHAR(50) NOT NULL
	,itmID INT NOT NULL
	,itmIDInstance SMALLINT NOT NULL
	,olnID INT NOT NULL
	,olnIDInstance SMALLINT NOT NULL
	,itmIDParent INT NOT NULL
	,itmIDParentInstance SMALLINT NOT NULL
	,itmIDSA INT NOT NULL
	,itmDescriptionSA NVARCHAR(100)
	,dlCode NVARCHAR(2)	--批量删除时使用
	,oriReqQty DECIMAL(18,2)
	,primaryUOMCode NCHAR(5)
	,actions TINYINT NOT NULL DEFAULT 0
	,itmItemNumber NVARCHAR(50)
	,itmDescription NVARCHAR(100)
	,itmfCode NVARCHAR(50)
	,itmfDescription NVARCHAR(100)
	,topSurCode NVARCHAR(50)
	,corCode NVARCHAR(50)
	,edgeCode NVARCHAR(10)
	,dimCX DECIMAL(18,2)
	,dimCY DECIMAL(18,2)
	,dimCZ DECIMAL(18,2)
	,dimFX DECIMAL(18,2)
	,dimFY DECIMAL(18,2) 
	,dimFZ DECIMAL(18,2) 
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
	,CONSTRAINT PK_YLOrdOriginalBOMData_PageName_itmID_itmIDInstance_olnID_olnIDInstance PRIMARY KEY(itmID,itmIDInstance,olnID,olnIDInstance)
	,CONSTRAINT IX_YLOrdOriginalBOMData_Idx UNIQUE CLUSTERED(Idx)	--聚集索引
	,INDEX IX_YLOrdOriginalBOMData_OrdID(OrdID)	--非聚集，不唯一索引
	,INDEX IX_YLOrdOriginalBOMData_OrdID_itmID(OrdID,itmID)	--非聚集，不唯一索引
	,INDEX IX_YLOrdOriginalBOMData_ItmID_OlnID(itmID,olnID)	--非聚集，不唯一索引
	,INDEX IX_YLOrdOriginalBOMData_OrdID_PageName_ItmID_OlnID(OrdID,PageName,itmID,olnID)	--非聚集，不唯一索引
	,INDEX IX_YLOrdOriginalBOMData_OrdID_PageName(OrdID,PageName)	--非聚集，不唯一索引
	,INDEX IX_YLOrdOriginalBOMData_OrdID_actions(OrdID,actions)	--非聚集，不唯一索引
	,INDEX IX_YLOrdOriginalBOMData_OrdID_PageName_actions(OrdID,PageName,actions)	--非聚集，不唯一索引
)