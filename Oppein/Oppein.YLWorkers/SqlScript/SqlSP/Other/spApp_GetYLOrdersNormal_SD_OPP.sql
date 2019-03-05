﻿/*
	趟门页签：获取数据逻辑：
	1、判断原始表是否存在该订单的趟门数据，若存在，则直接取
	2、判断原始表是否存在该订单的趟门数据，若不存在，则判断订单来源 当为“CAD单独趟门”时，则默为趟门页签数据为空，用户自己添加
	3、当非“CAD单独趟门”时，再判断订单自定义属性“趟门”没勾上时，则该订单无趟门，页签数据为空
	4、当订单自定义属性“趟门”勾上时，则该订单可能存在趟门，
		再判断订单状态是否存在“趟门下单中”,若存在，则存在趟门，若不存在，则判断产品组是否"SD"且品项系描述为“SD_1”\"SD_3"

*/

ALTER PROC [dbo].[spApp_GetYLOrdersNormal_SD_OPP]
	@ordID INT
	,@pageName NVARCHAR(10)=N'趟门'
	,@Factory NVARCHAR(50)=NULL
AS
SET NOCOUNT ON;

DECLARE @PlateCategory NVARCHAR(50)
SELECT @PlateCategory=PlateCategory FROM [dbo].[CUS_YLOrdPagesData_OPP] WHERE PageName=@pageName
SELECT @Factory=FactoryDefualt FROM [dbo].[CUS_YLOrdPageFactoryDefualt_OPP] WHERE Factory=@Factory AND PageName=@pageName 

IF NOT EXISTS(SELECT 1 FROM [dbo].[CUS_YLOrdOriginalBOMData_OPP] WHERE ordId=@ordID AND pageName=@pageName)
BEGIN
	--当非“CAD单独趟门”时
	IF NOT EXISTS(SELECT 1 FROM dbo.OrderAttributeValues WHERE ordID=@ordID AND atbID=162 AND ordavValue=N'CAD SliddingDoor')
	BEGIN
		--当订单自定义属性“趟门”勾上时
		IF EXISTS(SELECT 1 FROM dbo.OrderAttributeValues WHERE ordID=@ordID AND atbID=317 AND ordavValue=N'1')
		BEGIN
			--判断是否存在趟门数据
			IF EXISTS(SELECT TOP 1 olnp.ordID
				FROM dbo.OrderLineProducts olnp WITH(NOLOCK)
				JOIN product.ProductVersions pdv WITH(NOLOCK) on pdv.pdID = olnp.pdID            
				JOIN product.ProductGroups pdg WITH(NOLOCK) on pdg.pdgID = pdv.pdgID       
				JOIN dbo.OrderItems ori WITH(NOLOCK) ON ori.olnID = olnp.olnID
				JOIN dbo.ItemItemFamilies itmitmf WITH(NOLOCK) ON itmitmf.itmID = ori.itmID                       
				JOIN dbo.CustomSetting_Opp cs WITH(NOLOCK)ON cs.SCode = itmitmf.itmfCode     
				WHERE olnp.ordID=@ordID
					AND pdg.pdgCode=N'SD'
					AND (
							(ori.dlCode=N'MA' AND cs.FurnitureKittingList=N'SD_1')
							OR
							(ori.dlCode=N'MP' AND cs.FurnitureKittingList=N'SD_3')
							OR
							(ori.dlCode=N'PP' AND cs.FurnitureKittingList=N'SD_3')
						)
			)
			BEGIN
				--存在插入趟门虚拟数据
				INSERT INTO [dbo].[CUS_YLOrdOriginalBOMData_OPP](ordId,pageName,itmID,itmIDInstance,olnID,olnIDInstance,itmIDParent,itmIDParentInstance,itmIDSA
					,itmItemNumber,itmDescription,corCode,oriReqQty,dimCX,dimCY,info1,info2,info3,itmfCode,itmfDescription)
				SELECT 
					@ordID AS ordID
					,@pageName AS pageName
					,ISNULL(itmID,1)AS itmID
					,1 AS itmIDInstance
					,ROW_NUMBER()OVER(ORDER BY GETDATE())AS olnID
					,1 AS olnIDInstance
					,1 AS itmIDParent
					,1 AS itmIDParentInstance
					,1 AS itmIDSA
					,itmItemNumber
					,itmDescription
					,corCode
					,1 AS oriReqQty
					,Price AS dimCY
					,Price AS dimCY
					,@PlateCategory AS info1
					,@Factory AS info2
					,Duty AS info3
					,itmfCode
					,itmfDescription
				FROM [dbo].[CUS_YLOrdSliddingDoorItems_OPP]
				WHERE pageName=@pageName
			END
		END
	END
END

SELECT 
	itmID
	,itmID AS olnID
	,actions
	,itmItemNumber
	,itmDescription 
	,corCode
	,CAST(oriReqQty AS FLOAT) AS oriReqQty
	,1 AS oOriReqQty
	,CAST(dimCX AS FLOAT) AS Price
	,CAST(dimCY AS FLOAT) AS LegacyPrice
	,info1 AS PlateCategory
	,info2 AS Factory
	,info3 AS Duty
	,itmfCode
	,itmfDescription
FROM [dbo].[CUS_YLOrdOriginalBOMData_OPP] 
WHERE ordId=@ordID 
AND pageName=@pageName

