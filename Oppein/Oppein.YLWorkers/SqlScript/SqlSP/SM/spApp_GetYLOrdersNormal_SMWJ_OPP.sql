ALTER PROC [dbo].[spApp_GetYLOrdersNormal_SMWJ_OPP]
	@ordID INT
	,@pageName NVARCHAR(50)=N'实木五金'
	,@Factory NVARCHAR(50) = NULL
AS
SET NOCOUNT ON;

--DECLARE @ordID INT = 3914472
--	,@pageName NVARCHAR(50) = N'普通五金'
--	,@Factory NVARCHAR(50)

DECLARE @PlateCategory NVARCHAR(50)
SELECT @PlateCategory=PlateCategory FROM [dbo].[CUS_YLOrdPagesData_OPP] WHERE PageName=@pageName
SELECT @Factory=FactoryDefualt FROM [dbo].[CUS_YLOrdPageFactoryDefualt_OPP] WHERE Factory=@Factory AND PageName=@pageName 
--判断原始表数据是否存在(若存则关联，若不存在则插入)
IF EXISTS(SELECT 1 FROM [dbo].[CUS_YLOrdOriginalBOMData_OPP] WHERE ordId=@ordID AND pageName=@pageName)
BEGIN
	;WITH T AS
	(
		SELECT 
			org.itmID
			,org.itmItemNumber
			,org.itmDescription
			,org.PrimaryUOMCode
			,org.itmfCode
			,org.info1
			,MAX(org.actions) AS actions
			,SUM(CASE WHEN org.info5 IS NOT NULL AND ISNUMERIC(org.info5)=1 THEN CAST(org.info5 AS FLOAT) ELSE 0 END)AS oriReqQty
			,CAST(org.dimCX AS FLOAT) AS dimCX
			,CAST(org.dimCY AS FLOAT) AS dimCY
			,CAST(org.dimCZ AS FLOAT) AS dimCZ
			--,CAST(org.dimFX AS FLOAT) AS dimFX
			--,CAST(org.dimFY AS FLOAT) AS dimFY
			--,CAST(org.dimFZ AS FLOAT) AS dimFZ
		FROM [dbo].[CUS_YLOrdOriginalBOMData_OPP] org
		WHERE org.ordId=@ordID
			AND org.pageName=@pageName
			AND org.info1 IS NULL	--排除取上级尺寸的品项
		GROUP BY org.itmID
			,org.itmItemNumber
			,org.itmDescription
			,org.PrimaryUOMCode
			,org.itmfCode
			,org.info1
			,org.dimCX
			,org.dimCY
			,org.dimCZ
	),TT AS
	(
		SELECT 
			ori.itmID
			,ori.itmIDInstance
			,ori.olnID
			,ori.olnIDInstance
			,ori.itmIDParent
			,ori.itmIDParentInstance
			,ori.dlCode
			,ori.oriIsPurchased
			,ori.itmpID
			,ori.oriReqQty
			,itm.itmItemNumber
			,itm.itmDescription
			,itm.itmDescription2
			,itm.PrimaryUOMCode
			,itmf.itmfCode
		FROM dbo.Orders ord (NOLOCK)
		JOIN dbo.OrderLines oln (NOLOCK) ON oln.ordID = ord.ordID
		JOIN dbo.OrderItems ori (NOLOCK) ON ori.olnID = oln.olnID
		JOIN dbo.Items itm (NOLOCK) ON itm.itmID = ori.itmID
		JOIN dbo.ItemItemFamilies itmf (NOLOCK) ON itm.itmID=itmf.itmID
		WHERE ord.ordID = @ordID
	),TC AS
	(
		SELECT
			t.itmID
			,t.itmIDInstance
			,t.olnID
			,t.olnIDInstance
			,t.oriReqQty AS oriReqQty
			,(CASE WHEN t.itmfCode = 'Hardware_SPP_SM' AND oriChild.PrimaryUOMCode IS NOT NULL then oriChild.PrimaryUOMCode ELSE t.PrimaryUOMCode END) AS PrimaryUOMCode
			,(CASE WHEN t.itmfCode = 'Hardware_SM' THEN t.itmItemNumber WHEN t.itmfCode = 'Hardware_SPP_SM' AND oriChild.itmItemNumber IS NOT NULL THEN oriChild.itmItemNumber ELSE t.itmItemNumber END) as itmItemNumber
			,(CASE WHEN t.itmfCode = 'Hardware_SM' THEN t.itmDescription WHEN t.itmfCode = 'Hardware_SPP_SM' AND oriChild.itmDescription IS NOT NULL THEN oriChild.itmDescription ELSE t.itmDescription END) as itmDescription
			,t.itmfCode
			,dim.dimX as dimFX
			,dim.dimY as dimFY
			,dim.dimZ as dimFZ
			,(CASE WHEN t.itmfCode = 'Hardware_SM' THEN N'个' WHEN t.itmfCode = 'Hardware_SPP_SM' then N'条' END) as UOMDescription
		FROM TT t
		--JOIN TT SA ON t.olnID=SA.olnID AND SA.dlCode=N'SA'
		JOIN TT oriChild (NOLOCK)
			ON t.itmID=oriChild.itmIDParent  
			AND t.itmIDParentInstance=oriChild.itmIDParentInstance  
			AND t.olnID=oriChild.olnID  
			AND t.olnIDInstance=oriChild.olnIDInstance
		LEFT JOIN dbo.ItemDimensions dim (NOLOCK) ON dim.itmID=t.itmID and dim.dimID=1
		JOIN dbo.CustomSetting_Opp cs (NOLOCK) ON CS.FurnitureKittingList ='SM' AND cs.SDesc = 'SMH' AND t.itmfCode=cs.SCode 
	),TS AS
	(
		SELECT
			t.itmID
			,CAST(SUM(t.oriReqQty)AS FLOAT) AS oriReqQty
			,t.PrimaryUOMCode
			,t.itmItemNumber
			,t.itmDescription
			,t.itmfCode
			,t.dimFX
			,t.dimFY
			,t.dimFZ
			,t.UOMDescription
		FROM TC t
		--WHERE NOT(t.oriIsPurchased = 0 AND t.itmpID = 2)
		GROUP BY t.itmID
			,t.itmItemNumber
			,t.itmDescription
			,t.PrimaryUOMCode
			,t.UOMDescription
			,t.itmfCode
			,t.dimFX
			,t.dimFY
			,t.dimFZ
	)

	SELECT 
		tt.itmID
		,tt.itmID AS olnID
		,tt.itmItemNumber
		,tt.itmDescription
		,ISNULL(t.itmDescription,tt.itmDescription) AS oItmDescription
		,tt.oriReqQty AS oriReqQty
		,t.oriReqQty AS oOriReqQty
		,tt.PrimaryUOMCode
		,t.actions
		,tt.itmfCode
		,tt.oriReqQty AS info5
		,tt.dimFX AS dimFX
		,t.dimCX AS oDimFX		----将尺寸数量保存到裁切尺寸，作为原始数据
		,tt.dimFY AS dimFY
		,t.dimCY  AS oDimFY
		,tt.dimFZ AS dimFZ
		,t.dimCZ AS oDimFZ
		,tt.dimFX AS dimCX	--保留上次更新值(判断当前尺寸是否修改)
		,tt.dimFY AS dimCY	--保留上次更新值(判断当前尺寸是否修改)
		,tt.dimFZ AS dimCZ	--保留上次更新值(判断当前尺寸是否修改)
		,ISNULL(ha.Factory,@Factory) AS Factory
		,ha.Duty
		,ISNULL(ha.PlateCategory,@PlateCategory) AS PlateCategory
		,CAST(ha.LegacyPrice AS FLOAT) AS LegacyPrice
	FROM TS tt
	LEFT JOIN T t ON t.itmID=tt.itmID
	LEFT JOIN dbo.hole_analysis ha (NOLOCK) ON ha.itmID = tt.itmID AND ha.ordID=@ordID
	ORDER BY tt.itmfCode,tt.itmItemNumber
END
ELSE
BEGIN
	;WITH T AS
	(
		SELECT 
			ori.itmID
			,ori.itmIDInstance
			,ori.olnID
			,ori.olnIDInstance
			,ori.itmIDParent
			,ori.itmIDParentInstance
			,ori.dlCode
			,ori.oriIsPurchased
			,ori.itmpID
			,ori.oriReqQty
			,itm.itmItemNumber
			,itm.itmDescription
			,itm.itmDescription2
			,itm.PrimaryUOMCode
			,itmf.itmfCode
		FROM dbo.Orders ord (NOLOCK)
		JOIN dbo.OrderLines oln (NOLOCK) ON oln.ordID = ord.ordID
		JOIN dbo.OrderItems ori (NOLOCK) ON ori.olnID = oln.olnID
		JOIN dbo.Items itm (NOLOCK) ON itm.itmID = ori.itmID
		JOIN dbo.ItemItemFamilies itmf (NOLOCK) ON itm.itmID=itmf.itmID
		WHERE ord.ordID = @ordID
	)
	INSERT INTO [dbo].[CUS_YLOrdOriginalBOMData_OPP](ordId,pageName,itmID,itmIDInstance,olnID,olnIDInstance,itmIDParent,itmIDParentInstance,itmIDSA,dlCode,oriReqQty,primaryUOMCode
		,itmItemNumber,itmDescription,itmfCode,dimCX,dimCY,dimCZ,dimFX,dimFY,dimFZ,info1)
	SELECT
		@ordID AS ordID
		,@pageName AS pageName
		,t.itmID
		,t.itmIDInstance
		,t.olnID
		,t.olnIDInstance
		,t.itmIDParent
		,t.itmIDParentInstance
		,SA.itmID AS itmIDSA
		,t.dlCode
		,CAST(t.oriReqQty AS FLOAT) AS oriReqQty
		--,t.PrimaryUOMCode
		--,CASE WHEN t.itmItemNumber LIKE N'%加固条%' OR t.itmItemNumber LIKE N'%衣通灯%' OR t.itmItemNumber LIKE N'%层板灯%' OR t.itmItemNumber LIKE N'%挂衣杆%' OR t.itmItemNumber LIKE N'%铝包覆%'  THEN itm_1.itmItemNumber ELSE  HARDWARE.itmItemNumber END AS itmItemNumber
		--,CASE WHEN t.itmItemNumber LIKE N'%加固条%' OR t.itmItemNumber LIKE N'%衣通灯%' OR t.itmItemNumber LIKE N'%层板灯%' OR t.itmItemNumber LIKE N'%挂衣杆%' OR t.itmItemNumber LIKE N'%铝包覆%'  THEN itm_1.itmDescription2 ELSE  HARDWARE.itmDescription END AS itmDescription
		,(CASE WHEN t.itmfCode = 'Hardware_SPP_SM' AND oriChild.PrimaryUOMCode IS NOT NULL then oriChild.PrimaryUOMCode ELSE t.PrimaryUOMCode END) AS PrimaryUOMCode
		,(CASE WHEN t.itmfCode = 'Hardware_SM' THEN t.itmItemNumber WHEN t.itmfCode = 'Hardware_SPP_SM' AND oriChild.itmItemNumber IS NOT NULL THEN oriChild.itmItemNumber ELSE t.itmItemNumber END) as itmItemNumber
		,(CASE WHEN t.itmfCode = 'Hardware_SM' THEN t.itmDescription WHEN t.itmfCode = 'Hardware_SPP_SM' AND oriChild.itmDescription IS NOT NULL THEN oriChild.itmDescription ELSE t.itmDescription END) as itmDescription
		,t.itmfCode
		,dim.dimX as dimCX
		,dim.dimY as dimCY
		,dim.dimZ as dimCZ
		,dim.dimX as dimFX
		,dim.dimY as dimFY
		,dim.dimZ as dimFZ
		,(CASE WHEN t.itmfCode = 'Hardware_SM' THEN N'个' WHEN t.itmfCode = 'Hardware_SPP_SM' then N'条' END) as UOMDescription
	FROM T t
	JOIN T SA ON t.olnID=SA.olnID AND SA.dlCode=N'SA'
	JOIN T oriChild (NOLOCK)
		ON t.itmID=oriChild.itmIDParent  
		AND t.itmIDParentInstance=oriChild.itmIDParentInstance  
		AND t.olnID=oriChild.olnID  
		AND t.olnIDInstance=oriChild.olnIDInstance
	LEFT JOIN dbo.ItemDimensions dim (NOLOCK) ON dim.itmID=t.itmID and dim.dimID=1
	JOIN dbo.CustomSetting_Opp cs (NOLOCK) ON CS.FurnitureKittingList ='SM' AND cs.SDesc = 'SMH' AND t.itmfCode=cs.SCode 
	--WHERE NOT(t.oriIsPurchased = 0 AND t.itmpID = 2)
	ORDER BY t.olnID,t.olnIDInstance

	SELECT 
		tt.itmID
		,tt.itmID AS olnID	-- 替换时保存被替换的品项
		,tt.itmItemNumber
		,tt.itmDescription
		,tt.itmDescription AS oItmDescription
		,SUM(tt.oriReqQty) AS oriReqQty
		,SUM(tt.oriReqQty) AS oOriReqQty
		,tt.PrimaryUOMCode
		,MAX(tt.actions) AS actions
		,tt.itmfCode
		,tt.info1 AS UOMDescription
		,CAST(tt.dimFX AS FLOAT) AS dimFX
		,CAST(tt.dimFX AS FLOAT) AS oDimFX
		,CAST(tt.dimFY AS FLOAT) AS dimFY
		,CAST(tt.dimFY AS FLOAT) AS oDimFY
		,CAST(tt.dimFZ AS FLOAT) AS dimFZ
		,CAST(tt.dimFZ AS FLOAT) AS oDimFZ
		,CAST(tt.dimFX AS FLOAT) AS dimCX	--保留上次更新值(判断当前尺寸是否修改)
		,CAST(tt.dimFY AS FLOAT) AS dimCY	--保留上次更新值(判断当前尺寸是否修改)
		,CAST(tt.dimFZ AS FLOAT) AS dimCZ	--保留上次更新值(判断当前尺寸是否修改)
		,@Factory AS Factory
		,ha.Duty AS Duty
		,@PlateCategory AS PlateCategory
		,NULL AS LegacyPrice
	FROM [dbo].[CUS_YLOrdOriginalBOMData_OPP] tt
	LEFT JOIN dbo.hole_analysis ha (NOLOCK) ON ha.ordID=tt.ordId AND ha.itmID = tt.itmID
	WHERE tt.ordId=@ordID
		AND tt.pageName=@pageName
	GROUP BY tt.itmID
			,tt.itmItemNumber
			,tt.itmDescription
			,tt.PrimaryUOMCode
			,tt.itmfCode
			,tt.info1
			,tt.dimFX
			,tt.dimFY
			,tt.dimFZ
			,ha.Duty
	ORDER BY tt.info1,tt.itmItemNumber
END
